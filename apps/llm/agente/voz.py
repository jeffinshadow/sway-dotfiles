#!/usr/bin/env python3
"""voz.py — escuta "ei giratina, ..." e executa (protótipo com Vosk, tudo na CPU, nada gravado em disco).

Roda pelo venv ~/.local/share/giratina-voz/venv (pip install vosk) como serviço de usuário
(giratina-voz.service). Modelo: vosk-model-small-pt-0.3 em ~/.local/share/giratina-voz/modelos.

Como funciona: o áudio do microfone (já limpo pelo Easy Effects/RNNoise, fonte easyeffects_source)
vai, em memória, pra DOIS reconhecedores:
  - gatilho: gramática fechada só com a frase "ei gira tina" (o modelo não tem "giratina", tem
    "gira" e "tina" — soa igual); mais preciso pra detectar o chamado;
  - livre: transcreve a fala pra pegar o comando.
Falou tudo junto ("ei giratina, liga o modo tv") → executa o que veio depois do gatilho.
Falou só o gatilho → bipe e escuta o próximo pedido por até 6 s.
O comando passa primeiro pela camada rápida (rotas.py, sem LLM); se não casar, vai pro agente
(giratina.py --rofi), que sobe o LLM só fora do modo jogo.
Modo jogo ligado ($XDG_RUNTIME_DIR/modo-jogo): para de ouvir (solta o microfone) até sair.
"""
import collections, json, os, re, subprocess, sys, time
from pathlib import Path

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))
import vosk  # noqa: E402
import rotas  # noqa: E402

BASE = Path.home() / ".local/share/giratina-voz"
MODELO = BASE / "modelos/vosk-model-small-pt-0.3"
RUN = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
MODO_JOGO = RUN / "modo-jogo"
ESTADO = RUN / "giratina-voz"           # existe enquanto está ouvindo (indicador da waybar)
SONS = Path("/usr/share/sounds/freedesktop/stereo")
TAXA = 16000
JANELA_COMANDO = 6.0                     # s pra falar o pedido depois do bipe
GATILHO_FRASES = ["ei gira tina", "hei gira tina", "oi gira tina", "gira tina", "[unk]"]
GATILHO_RX = re.compile(r"\b(e[iy]|hei|oi|o)?\s*gira\s*(a\s*)?tina\b|\bgiratina\b")


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def som(nome):
    subprocess.Popen(["pw-play", str(SONS / f"{nome}.oga")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def avisar(titulo, texto="", tempo=4000):
    subprocess.Popen(["notify-send", "-a", "giratina", "-t", str(tempo),
                      "-h", "string:x-canonical-private-synchronous:giratina-voz", titulo, texto],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def waybar():
    subprocess.run(["pkill", "-RTMIN+11", "waybar"], capture_output=True)


def fonte():
    fontes = subprocess.run(["pactl", "list", "short", "sources"], capture_output=True, text=True).stdout
    return "easyeffects_source" if "easyeffects_source" in fontes else None


def executar(texto):
    """Executa o que veio depois do gatilho (ou o texto todo, se estiver na janela pós-bipe).
    Devolve False se não sobrou pedido (só o gatilho)."""
    m = GATILHO_RX.search(texto)
    pedido = (texto[m.end():] if m else texto).strip()
    if not pedido:
        return False
    if re.fullmatch(r"(cancela|esquece|nada|deixa)( pra la)?", rotas.normaliza(pedido)):
        som("dialog-information"); avisar("Giratina", "cancelado"); return True
    log("pedido:", pedido)
    try:
        r = rotas.rotear(pedido)
    except Exception as e:
        r = (f"erro: {e}", "")
    if r:
        som("complete")
        avisar("Giratina", f"🎙 “{pedido}”\n{r[0]}", 6000)
        return True
    if MODO_JOGO.exists():
        som("dialog-warning"); avisar("Giratina", f"🎙 “{pedido}”\nModo jogo: só comandos rápidos."); return True
    avisar("Giratina", f"🎙 “{pedido}”\npensando…")
    subprocess.Popen(["python3", str(AQUI / "giratina.py"), "--rofi", pedido],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return True


def ouvir(modelo):
    """Só o detector de gatilho (gramática fechada, leve) roda o tempo todo. Ao ouvir "gira tina"
    (já no resultado parcial), liga o reconhecedor livre pro comando, com ~0,4 s de áudio de folga."""
    src = fonte()
    cmd = ["pw-record", "--raw", "--rate", str(TAXA), "--channels", "1", "--format", "s16", "--latency", "100ms"]
    if src:
        cmd += ["--target", src]
    proc = subprocess.Popen(cmd + ["-"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    gat = vosk.KaldiRecognizer(modelo, TAXA, json.dumps(GATILHO_FRASES))
    livre = None
    folga = collections.deque(maxlen=3)            # ~0,4 s antes do disparo
    ESTADO.touch(); waybar()
    log("ouvindo", src or "(fonte padrão)")
    ate = 0.0
    try:
        while True:
            if MODO_JOGO.exists():
                log("modo jogo: soltando o microfone")
                return
            dados = proc.stdout.read(4000)              # 125 ms de áudio
            if not dados:
                return
            if livre is None:
                folga.append(dados)
                fim = gat.AcceptWaveform(dados)
                txt = json.loads(gat.Result() if fim else gat.PartialResult()).get("text" if fim else "partial", "")
                if fim and txt and txt != "[unk]":
                    log("gatilho ouviu:", txt)
                if "gira tina" in txt:
                    log("gatilho:", txt)
                    som("message-new-instant"); avisar("Giratina", "🎙 ouvindo…", 3000)
                    gat.Reset()
                    livre = vosk.KaldiRecognizer(modelo, TAXA)
                    for b in folga:
                        livre.AcceptWaveform(b)
                    folga.clear()
                    ate = time.time() + JANELA_COMANDO
                continue
            fim = livre.AcceptWaveform(dados)
            t = json.loads(livre.Result()).get("text", "") if fim else ""
            if not fim and time.time() > ate:
                t = json.loads(livre.FinalResult()).get("text", ""); fim = True
            if not fim:
                continue
            log("ouvi:", t or "(nada)")
            if t and executar(t):
                livre = None
            elif time.time() > ate:
                log("janela do comando expirou"); avisar("Giratina", "🎙 não entendi", 2000)
                livre = None
    finally:
        proc.terminate()
        ESTADO.unlink(missing_ok=True); waybar()


def main():
    vosk.SetLogLevel(-1)
    if not MODELO.exists():
        sys.exit(f"modelo não encontrado: {MODELO}")
    modelo = vosk.Model(str(MODELO))
    try:                                          # liga/desliga = systemctl --user start/stop giratina-voz
        while True:
            if MODO_JOGO.exists():
                time.sleep(2); continue
            ouvir(modelo)
            time.sleep(1)
    finally:
        ESTADO.unlink(missing_ok=True); waybar()


if __name__ == "__main__":
    main()
