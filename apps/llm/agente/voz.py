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
import collections, difflib, json, os, re, subprocess, sys, time
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
FRASES = json.loads((AQUI / "frases_voz.json").read_text())            # comandos conhecidos
# vocabulário do reconhecedor de comando: as frases + palavras do gatilho (absorvem o "tina" que sobra)
VOCAB = FRASES + ["ei", "gira", "tina", "[unk]"]


def _rota(frase):
    fs = {f for rx, f in rotas._COMPILADAS if rx.search(rotas.normaliza(frase))}
    return next(iter(fs)) if len(fs) == 1 else None


CANDIDATAS = [(rotas.normaliza(f), f, _rota(f)) for f in FRASES]


def casar(g):
    """A Vosk monta qualquer sequência das palavras do vocabulário; aqui escolhe a frase conhecida
    mais parecida. Recusa se a semelhança for baixa ou se dois comandos diferentes empatarem
    (ex.: "liga" x "desliga")."""
    g = re.sub(r"^((ei|gira|tina)\s+)+", "", g).strip()
    if not g:
        return None
    if rotas.rotear_teste(g):
        return g
    n = rotas.normaliza(g)
    tem_num = bool(re.search(r"\d", n))          # "brilho" sozinho não vira "brilho zero"
    notas = sorted(((difflib.SequenceMatcher(None, n, c).ratio(), f, r) for c, f, r in CANDIDATAS
                    if tem_num or not re.search(r"\d", c)), reverse=True)
    nota, frase, rota = notas[0]
    rival = next((x for x in notas[1:] if x[2] is not rota), None)
    log(f"casar: {g!r} -> {frase!r} ({nota:.2f}; rival {rival[1]!r} {rival[0]:.2f})" if rival else "")
    if nota < 0.85 or len(n) < 0.75 * len(rotas.normaliza(frase)) or (rival and nota - rival[0] < 0.06):
        return None
    return frase
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


def midia_tocando():
    """Modo TV ligado ou algum player tocando: o som da JBL pode imitar o gatilho."""
    if (RUN / "modo-tv").exists():
        return True
    r = subprocess.run(["playerctl", "-a", "status"], capture_output=True, text=True)
    return "Playing" in r.stdout


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
    livre = cmd_g = None
    folga = collections.deque(maxlen=16)           # ~2 s antes do disparo (o começo do comando)
    ESTADO.touch(); waybar()
    log("ouvindo", src or "(fonte padrão)")
    ate = calma = 0.0
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
                exige = r"\b(ei|oi|hei) gira tina\b" if midia_tocando() else r"gira tina"
                if re.search(exige, txt) and time.time() > calma:
                    log("gatilho:", txt)
                    som("message-new-instant"); avisar("Giratina", "🎙 ouvindo…", 3000)
                    gat.Reset()
                    livre = vosk.KaldiRecognizer(modelo, TAXA)
                    cmd_g = vosk.KaldiRecognizer(modelo, TAXA, json.dumps(VOCAB, ensure_ascii=False))
                    for b in folga:
                        livre.AcceptWaveform(b); cmd_g.AcceptWaveform(b)
                    folga.clear()
                    partes = []
                    ate = time.time() + JANELA_COMANDO
                continue
            # comando: gramática fechada (precisa) + transcrição livre (pro LLM) em paralelo
            fim = cmd_g.AcceptWaveform(dados)
            if livre.AcceptWaveform(dados):
                partes.append(json.loads(livre.Result()).get("text", ""))
            if not fim and time.time() <= ate:
                continue
            g = json.loads(cmd_g.Result() if fim else cmd_g.FinalResult()).get("text", "").replace("[unk]", "").strip()
            if fim and not re.sub(r"\b(ei|gira|tina)\b", "", g).strip() and time.time() <= ate:
                continue                             # só pausa/resto do gatilho: segue esperando o comando
            t = " ".join(partes + [json.loads(livre.FinalResult()).get("text", "")]).strip()
            t = (t[GATILHO_RX.search(t).end():] if GATILHO_RX.search(t) else t).strip()
            log(f"comando: gramática={g!r} livre={t!r}")
            livre = cmd_g = None
            calma = time.time() + 2.0
            frase = casar(g)
            tocando = midia_tocando()
            if frase and tocando and len(t.split()) > len(frase.split()) + 4:
                log("descartado: fala demais pra um comando (provavelmente o áudio da TV)")
                frase = None; t = ""
            if frase:
                executar(frase)
            elif len(t.split()) >= 4 and not tocando:
                executar(t)                          # pergunta aberta -> agente/LLM
            else:
                som("dialog-warning"); avisar("Giratina", f"🎙 não entendi ({t or g or 'nada'})", 3000)
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
