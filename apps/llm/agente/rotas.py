"""Camada rápida do giratina: comandos comuns reconhecidos por gramática, SEM LLM (~1 ms).
Funciona com o LLM desligado e no modo jogo — é o que a voz usa primeiro. Se nada casar de
forma inequívoca, devolve None e o pedido vai pro LLM (que respeita o modo jogo).

Normalização: minúsculas, sem acento, sem pontuação, sem gatilho ("ei/hey giratina") e sem
cortesia ("por favor", "ai"); números por extenso viram dígitos ("trinta" -> 30).
"""
import re, subprocess, time, unicodedata
from pathlib import Path
import ferramentas as F

GATILHO = r"^(e[iy]|hey|oi|o)?\s*(gira\s*tina|giratina|jiratina)\s*"
CORTESIA = r"\b(por favor|pf|ai|ae|pra mim|por gentileza)\b"
UNIDADES = {"zero": 0, "um": 1, "uma": 1, "dois": 2, "duas": 2, "tres": 3, "quatro": 4, "cinco": 5, "seis": 6,
            "sete": 7, "oito": 8, "nove": 9, "dez": 10, "onze": 11, "doze": 12, "treze": 13, "quatorze": 14,
            "catorze": 14, "quinze": 15, "dezesseis": 16, "dezessete": 17, "dezoito": 18, "dezenove": 19}
DEZENAS = {"vinte": 20, "trinta": 30, "quarenta": 40, "cinquenta": 50, "sessenta": 60, "setenta": 70,
           "oitenta": 80, "noventa": 90, "cem": 100}


def normaliza(t):
    t = unicodedata.normalize("NFKD", t.lower())
    t = "".join(c for c in t if not unicodedata.combining(c))
    t = re.sub(r"[^\w\s%]", " ", t)
    t = re.sub(GATILHO, "", t.strip())
    t = re.sub(CORTESIA, " ", t)
    # número por extenso: "setenta e cinco" -> 75
    def num(m):
        d = DEZENAS.get(m.group(1), 0); u = UNIDADES.get(m.group(3) or "", 0)
        return str(d + u)
    t = re.sub(r"\b(" + "|".join(DEZENAS) + r")\b( e (" + "|".join(UNIDADES) + r"))?", num, t)
    t = re.sub(r"\b(" + "|".join(UNIDADES) + r")\b", lambda m: str(UNIDADES[m.group(1)]), t)
    # formas faladas que o reconhecedor de voz devolve (o modelo não tem "tv", "hbo", "jbl")
    t = re.sub(r"\b(tv|teve|t v|te ve|tele ve|televisao|tevezinha)\b", "tv", t)
    t = re.sub(r"\b(aga be o|agabeo|a g b o|h b o)\b", "hbo", t)
    t = re.sub(r"\b(jota be ele|j b l)\b", "jbl", t)
    t = re.sub(r"\b(iu tubi|you tube|iutubi|iutube)\b", "youtube", t)
    return re.sub(r"\s+", " ", t).strip()


def _sh(*cmd):
    subprocess.Popen(list(cmd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


S = str(F.SCRIPTS)
LIGA = r"(liga|ativa|abre|bota|coloca|poe|entra|inicia|comeca)\w*"
DESLIGA = r"(desliga|fecha|sai|desativa|encerra|para)\w*"


def _boa_noite():
    _sh(f"{S}/modo-tv.sh", "desligar")
    subprocess.run(["playerctl", "-a", "pause"], capture_output=True)
    _sh(f"{S}/dnd.sh") if "do-not-disturb" not in subprocess.run(["makoctl", "mode"], capture_output=True, text=True).stdout else None
    time.sleep(1.5)
    _sh("swaymsg", "output * power off")
    return "boa noite: TV desligada, mídia pausada, telas apagadas"


def _relatorio():
    return F.status_sistema() + "\n" + F.atualizacoes()


def _reconecta_jbl():
    r = subprocess.run(["bluetoothctl", "connect", "90:F2:60:29:60:66"], capture_output=True, text=True, timeout=15)
    time.sleep(2)
    sink = subprocess.run("pactl list short sinks | awk '/90_F2_60_29_60_66/{print $2; exit}'", shell=True,
                          capture_output=True, text=True).stdout.strip()
    if sink:
        subprocess.run(["pactl", "set-default-sink", sink])
        return "JBL conectada e como saída padrão"
    return "não consegui conectar a JBL: " + (r.stdout.strip().splitlines() or ["?"])[-1]


def _vou_jogar(m):
    jogo = {"assetto": "assetto corsa", "ac": "assetto corsa", "ets": "ets2", "caminhao": "ets2",
            "truck": "ets2", "cyberpunk": "cyberpunk"}.get((m.group("jogo") or "").split()[0] if m.group("jogo") else "", None)
    _sh(str(F.LLM_SH), "parar")
    _sh(f"{S}/modo-jogo.sh", "ligar")
    if jogo:
        F.abrir_jogo(jogo)
        return f"modo jogo ligado, LLM fora, abrindo {jogo}"
    return "modo jogo ligado e LLM fora — bom jogo"


# (padrão, ação) — a ação recebe o match; devolve texto pro usuário
INTENCOES = [
    (rf"^{LIGA} (o )?modo tv( (com|e) (o )?(monitor )?vertical( ligado| aceso)?| vertical)$", lambda m: F.modo_tv("ligar vertical")),
    (rf"^{LIGA} (o )?modo tv$|^modo tv$", lambda m: F.modo_tv("ligar")),
    (rf"^{DESLIGA} (do |o )?modo tv$|^desliga (a )?tv$", lambda m: F.modo_tv("desligar")),
    (rf"^({LIGA} |toca |quero ver )?(o )?youtube( na tv)?$", lambda m: F.modo_tv("youtube")),
    (rf"^({LIGA} |toca )?(o )?(youtube music|musica|music)( na tv)?$", lambda m: F.modo_tv("music")),
    (rf"^({LIGA} |quero ver )?(o )?(hbo|max|hbo max)( na tv)?$", lambda m: F.modo_tv("max")),
    (r"^(pausa|pause|para a musica|para o video|pausar)$", lambda m: F.midia("pause")),
    (r"^(continua|play|toca|despausa|volta a tocar)$", lambda m: F.midia("play")),
    (r"^(proxima|proximo|pula|passa)( musica| video)?$", lambda m: F.midia("next")),
    (r"^(anterior|volta( a musica)?|musica anterior)$", lambda m: F.midia("previous")),
    (r"^(o que ta|o que esta) tocando$", lambda m: F.midia("status")),
    (r"^(volume|som) (em |no |pra |para )?(?P<v>\d{1,3})( ?%| por cento)?$", lambda m: F.volume("definir", int(m.group("v")))),
    (r"^(aumenta|sobe|mais alto)( o)?( volume| som)?$", lambda m: F.volume("aumentar")),
    (r"^(abaixa|diminui|desce|mais baixo)( o)?( volume| som)?$", lambda m: F.volume("diminuir")),
    (r"^(muta|mudo|silencio|tira o som)$", lambda m: F.volume("mudo")),
    (r"^brilho (em |no |pra |para )?(?P<v>\d{1,3})( ?%| por cento)?$", lambda m: F.brilho("definir", int(m.group("v")))),
    (r"^brilho (no )?maximo$", lambda m: F.brilho("definir", 100)),
    (r"^(aumenta|sobe|mais)( o)? brilho$", lambda m: F.brilho("mais")),
    (r"^(abaixa|diminui|menos)( o)? brilho$", lambda m: F.brilho("menos")),
    (rf"^{LIGA} (o )?modo jogo$", lambda m: F.modo_jogo("ligar")),
    (rf"^{DESLIGA} (o )?modo jogo$", lambda m: F.modo_jogo("desligar")),
    (rf"^{LIGA} (o )?nao perturbe$", lambda m: F.nao_perturbe(True)),
    (rf"^{DESLIGA} (o )?nao perturbe$", lambda m: F.nao_perturbe(False)),
    (r"^(salva|grava|guarda)( o)? replay$", lambda m: F.captura("salvar_replay")),
    (r"^(tira|bate)( um)? (print|captura)( da tela)?$", lambda m: F.captura("tela")),
    (r"^(cade|onde ta|acha|toca)( o)? (meu )?celular$", lambda m: F.celular("tocar")),
    (r"^(bateria do celular|quanto de bateria( tem)? no celular)$", lambda m: F.celular("bateria") + "%"),
    (r"^(reconecta|conecta|liga)( a)? (caixinha|caixa|jbl|caixa de som)$", lambda m: _reconecta_jbl()),
    (r"^boa noite( giratina)?$", lambda m: _boa_noite()),
    (r"^(apaga|desliga)( as)? telas?$", lambda m: (_sh("swaymsg", "output * power off"), "telas apagadas")[1]),
    (r"^(relatorio|status|como ta|como esta)( da| a)? (maquina|pc|sistema)$", lambda m: _relatorio()),
    (r"^tem atualiza\w*$|^(ha|tem) (alguma )?atualiza\w*$", lambda m: F.atualizacoes()),
    (r"^(que horas sao|que hora e|horas)$", lambda m: time.strftime("São %H:%M.")),
    (r"^(que dia e hoje|que dia e|data de hoje)$", lambda m: time.strftime("Hoje é %d/%m/%Y.")),
    (r"^vou jogar( (?P<jogo>assetto( corsa)?|ac|ets\w*|caminhao|truck|cyberpunk))?$", _vou_jogar),
]
_COMPILADAS = [(re.compile(p), f) for p, f in INTENCOES]


def rotear(texto):
    """Devolve (resposta, intenção) se casar inequivocamente; senão None."""
    t = normaliza(texto)
    if not t:
        return None
    casos = [(rx, f) for rx, f in _COMPILADAS if rx.search(t)]
    if len(casos) != 1:
        # "liga o modo tv vertical" casa só no primeiro graças à âncora; se ambíguo, deixa pro LLM
        casos = casos[:1] if casos and all(c[1] is casos[0][1] for c in casos) else casos
    if len(casos) != 1:
        return None
    rx, f = casos[0]
    return f(rx.search(t)), rx.pattern
