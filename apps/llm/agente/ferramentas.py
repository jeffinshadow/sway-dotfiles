"""Ferramentas do assistente giratina, em 3 níveis (a regra é do código, não do modelo):

  AUTO        roda direto (só ações reversíveis/leitura): sway, mídia, volume, brilho, modos,
              ler/buscar configs nas pastas permitidas, status, diagnóstico só-leitura (bubblewrap,
              sem rede, sem escrita), celular (ping/tocar/link)
  CONFIRMAR   mostra o que vai fazer e só executa com "sim": editar/escrever arquivo (diff +
              backup), executar comando, rodar backup agora, subir/derrubar homologação
  NUNCA       sudo/su/doas, gravar fora das pastas permitidas (/etc etc.), rm -r, mkfs, dd, docker
              rm/prune, curl|sh... — recusado antes de perguntar

Cada ferramenta devolve texto curto (o modelo é pequeno: saída truncada em ~3 KB).
"""
import difflib, json, os, re, shlex, shutil, subprocess, time
from pathlib import Path

HOME = Path.home()
SCRIPTS = HOME / ".config/sway/scripts"
LLM_SH = HOME / ".dotfiles/apps/llm/llm.sh"
PREFIXO_AC = Path("/mnt/jogos/Steam/steamapps/compatdata/244210/pfx/drive_c/users/steamuser/Documents/Assetto Corsa")
AC = Path("/mnt/jogos/Steam/steamapps/common/assettocorsa")
ETS2 = HOME / ".local/share/Euro Truck Simulator 2"
# Pastas onde o assistente pode LER e (com confirmação) EDITAR
RAIZES = [HOME / ".config", HOME / ".dotfiles", HOME / ".local/share/applications", HOME / "Documentos",
          HOME / "Claudio", Path("/srv/docker"), PREFIXO_AC, AC / "extension/config", AC / "content/cars",
          AC / "cfg", ETS2, HOME / ".steam/steam/userdata"]
NAO_LER = [HOME / ".ssh", HOME / ".gnupg", HOME / ".config/restic", HOME / ".config/rclone",
           HOME / ".config/controle-tv", HOME / ".local/share/keyrings"]
MAX_SAIDA = 3000

APPS = {"firefox": "firefox", "chromium": "chromium", "telegram": "Telegram", "discord": "vesktop",
        "steam": "steam", "terminal": "ghostty", "arquivos": "nautilus", "calculadora": "gnome-calculator",
        "editor": "gnome-text-editor", "libreoffice": "libreoffice", "gimp": "gimp", "configuracoes-audio": "pavucontrol"}
JOGOS = {"assetto corsa": 244210, "ets2": 227300, "cyberpunk": 1091500}   # instalados (manifests em /mnt/jogos)
CELULAR = "bfc8a73d5f1b406f8706f8c2c1fce090"

PROIBIDO = re.compile(r"(^|[;&|`(\s])(sudo|su|doas|pkexec|mkfs\S*|dd|shred|wipefs|fdisk|parted|"
                      r"chmod\s+-R\s+777|rm\s+(-\w*r\w*|--recursive)|systemctl\s+(?!--user)\S+)"
                      r"|>\s*/(etc|usr|boot|dev|sys|proc)/|curl[^|]*\|\s*(ba|z)?sh|wget[^|]*\|\s*(ba|z)?sh"
                      r"|docker\s+(rm|rmi|system\s+prune|volume\s+(rm|prune))|:\(\)\s*\{")


def _corta(t, n=MAX_SAIDA):
    t = (t or "").strip()
    return t if len(t) <= n else t[:n] + f"\n…[+{len(t) - n} caracteres cortados]"


def _run(cmd, timeout=20, shell=False, env=None):
    try:
        r = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=timeout, env=env)
        out = (r.stdout or "") + (("\n" + r.stderr) if r.stderr.strip() else "")
        return _corta(out) or f"(ok, código {r.returncode})"
    except subprocess.TimeoutExpired:
        return f"(tempo esgotado: {timeout} s)"
    except FileNotFoundError as e:
        return f"(comando não encontrado: {e.filename})"


def _bg(cmd):
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return "ok"


def modo_jogo_ativo():
    return Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "modo-jogo").exists()


def _caminho(p, escrever=False):
    """Resolve e valida o caminho contra as raízes permitidas."""
    c = Path(os.path.expanduser(str(p))).resolve()
    if any(c == n or n in c.parents for n in NAO_LER):
        raise PermissionError(f"pasta protegida (segredos): {c}")
    if not any(c == r or r in c.parents for r in RAIZES):
        raise PermissionError(f"fora das pastas permitidas: {c}")
    return c


# ---------------------------------------------------------------- ferramentas AUTO
def sway(acao, alvo=""):
    alvo = str(alvo).strip()
    mapa = {"workspace": f"workspace number {alvo}", "focar": f"focus {alvo}",
            "mover_para_workspace": f"move container to workspace number {alvo}",
            "layout": f"layout {alvo}", "tela_cheia": "fullscreen toggle", "flutuar": "floating toggle",
            "fechar_janela": "kill", "focar_app": f'[app_id="(?i){re.escape(alvo)}"] focus'}
    if acao not in mapa:
        return f"ação inválida: {acao}"
    if acao in ("workspace", "mover_para_workspace") and not alvo.isdigit():
        return "alvo precisa ser o número do workspace"
    if acao == "focar" and alvo not in ("left", "right", "up", "down", "parent"):
        return "alvo: left|right|up|down|parent"
    if acao == "layout" and alvo not in ("tabbed", "stacking", "splith", "splitv", "toggle split"):
        return "alvo: tabbed|stacking|splith|splitv"
    return _run(["swaymsg", mapa[acao]])


def janelas():
    tree = json.loads(subprocess.run(["swaymsg", "-t", "get_tree"], capture_output=True, text=True).stdout)
    res = []
    def anda(n, ws=None):
        if n.get("type") == "workspace":
            ws = n.get("name")
        if n.get("pid") and n.get("type") in ("con", "floating_con"):
            app = n.get("app_id") or (n.get("window_properties") or {}).get("class")
            res.append(f"ws {ws}: {app} — {(n.get('name') or '')[:60]}{' (foco)' if n.get('focused') else ''}")
        for k in n.get("nodes", []) + n.get("floating_nodes", []):
            anda(k, ws)
    anda(tree)
    return "\n".join(res) or "nenhuma janela"


def abrir_app(app):
    if app not in APPS:
        return f"app desconhecido; opções: {', '.join(APPS)}"
    return _bg([APPS[app]]) and f"abrindo {app}"


def abrir_jogo(jogo):
    j = JOGOS.get(jogo.lower())
    if not j:
        return f"jogo desconhecido; opções: {', '.join(JOGOS)}"
    return _bg(["steam", f"steam://rungameid/{j}"]) and f"abrindo {jogo} pelo Steam"


def midia(acao):
    if acao not in ("play-pause", "play", "pause", "next", "previous", "stop", "status"):
        return "ação: play-pause|play|pause|next|previous|stop|status"
    if acao == "status":
        return _run(["playerctl", "metadata", "--format", "{{status}}: {{artist}} - {{title}} ({{playerName}})"])
    return _run(["playerctl", acao])


def volume(acao, valor=None):
    if acao == "definir" and valor is not None:
        v = max(0, min(100, int(valor)))
        _run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{v}%"])
        return f"volume em {v}%"
    m = {"aumentar": "raise", "diminuir": "lower", "mudo": "mute-toggle"}
    if acao not in m:
        if acao == "consultar":
            return _run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
        return "ação: aumentar|diminuir|mudo|definir|consultar"
    return _run(["swayosd-client", "--output-volume", m[acao]])


def brilho(acao, valor=None):
    if acao in ("mais", "menos"):
        return _run([str(SCRIPTS / "brilho.sh"), acao], timeout=30)
    if acao == "definir" and valor is not None:
        v = max(0, min(100, int(valor)))
        buses = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ddc-buses")
        lista = buses.read_text().split() if buses.exists() else ["6", "4"]
        for b in lista:
            subprocess.Popen(["ddcutil", "--bus", b, "--noverify", "setvcp", "10", str(v)],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return f"brilho em {v}%"
    return "ação: mais|menos|definir"


def modo_tv(acao):
    ok = ("ligar", "ligar vertical", "desligar", "youtube", "music", "max", "fechar", "estado")
    if acao not in ok:
        return f"ação: {'|'.join(ok)}"
    if acao == "estado":
        return _run([str(SCRIPTS / "modo-tv.sh"), "estado"]) + " / app: " + _run([str(SCRIPTS / "modo-tv.sh"), "app"])
    return _bg([str(SCRIPTS / "modo-tv.sh"), *acao.split()]) and f"modo TV: {acao}"


def modo_jogo(acao):
    if acao not in ("ligar", "desligar", "estado"):
        return "ação: ligar|desligar|estado"
    if acao == "estado":
        return "ligado" if modo_jogo_ativo() else "desligado"
    return _bg([str(SCRIPTS / "modo-jogo.sh"), acao]) and f"modo jogo: {acao}"


def nao_perturbe(ligar):
    ativo = "do-not-disturb" in subprocess.run(["makoctl", "mode"], capture_output=True, text=True).stdout
    if bool(ligar) != ativo:
        _bg([str(SCRIPTS / "dnd.sh")])
    return "não perturbe " + ("ligado" if ligar else "desligado")


def notificar(titulo, texto=""):
    return _run(["notify-send", "-a", "giratina", titulo, texto])


def captura(tipo):
    m = {"tela": ["screenshot.sh", "full"], "area": ["screenshot.sh", "area"], "ocr": ["ocr.sh"],
         "gravar_tela": ["record.sh", "tela"], "salvar_replay": ["replay.sh", "salvar"]}
    if tipo not in m:
        return f"tipo: {'|'.join(m)}"
    return _bg([str(SCRIPTS / m[tipo][0]), *m[tipo][1:]]) and f"{tipo}: ok"


def celular(acao, conteudo=""):
    if acao == "tocar":
        return _run(["kdeconnect-cli", "-d", CELULAR, "--ring"])
    if acao == "ping":
        return _run(["kdeconnect-cli", "-d", CELULAR, "--ping-msg", conteudo or "giratina"])
    if acao == "enviar":
        if not conteudo:
            return "informe o link ou o caminho do arquivo"
        if not re.match(r"https?://", conteudo):
            return "pelo celular só vão links (arquivo use: enviar_arquivo_celular, que pede confirmação)"
        return _run(["kdeconnect-cli", "-d", CELULAR, "--share", conteudo])
    if acao == "bateria":
        return _run(["qdbus6", "org.kde.kdeconnect", f"/modules/kdeconnect/devices/{CELULAR}/battery",
                     "org.kde.kdeconnect.device.battery.charge"])
    return "ação: tocar|ping|enviar|bateria"


def status_sistema():
    partes = []
    partes.append(_run("uptime -p; cat /proc/loadavg | cut -d' ' -f1-3", shell=True))
    partes.append(_run("free -h | awk 'NR==2{print \"RAM: \"$3\" de \"$2}'", shell=True))
    partes.append(_run("df -h / /mnt/jogos | awk 'NR>1{print $6\": \"$3\" de \"$2\" (\"$5\")\"}'", shell=True))
    partes.append(_run("cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | awk '{print \"GPU: \"$1/1000\"°C\"}'; "
                       "echo \"VRAM: $(( $(cat /sys/class/drm/card1/device/mem_info_vram_used) / 1048576 )) MiB\"", shell=True))
    f1 = _run("systemctl --failed --no-legend --plain | awk '{print $1}'", shell=True)
    f2 = _run("systemctl --user --failed --no-legend --plain | awk '{print $1}'", shell=True)
    falhas = " ".join(x for x in (f1, f2) if x and not x.startswith("(ok"))
    partes.append("serviços com falha: " + (falhas or "nenhum"))
    partes.append("último backup Drive: " + _run("tail -1 ~/backups/backup-drive.log", shell=True))
    partes.append("LLM: " + _run([str(LLM_SH), "estado"]) + " | modo jogo: " + ("ligado" if modo_jogo_ativo() else "desligado"))
    return _corta("\n".join(partes))


def atualizacoes():
    oficiais = _run("checkupdates 2>/dev/null | wc -l", shell=True, timeout=60)
    aur = _run("paru -Qua 2>/dev/null | wc -l", shell=True, timeout=60)
    lista = _run("checkupdates 2>/dev/null | head -15", shell=True, timeout=60)
    return f"repositórios: {oficiais} pacotes | AUR: {aur}\n{lista}"


def servico(unidade, usuario=True):
    if not re.fullmatch(r"[\w@.\-]+", unidade):
        return "nome de unidade inválido"
    base = ["systemctl", "--user"] if usuario else ["systemctl"]
    return _run(base + ["status", "--no-pager", "-n", "8", unidade])


def ler_arquivo(caminho, inicio=1, linhas=200):
    try:
        c = _caminho(caminho)
    except PermissionError as e:
        return str(e)
    if not c.is_file():
        return f"não é um arquivo: {c}"
    txt = c.read_text(errors="replace").splitlines()
    i = max(1, int(inicio)); f = i + int(linhas) - 1
    corpo = "\n".join(f"{n}: {l}" for n, l in enumerate(txt[i - 1:f], i))
    return _corta(f"{c} ({len(txt)} linhas)\n{corpo}", 6000)


def buscar(padrao, pasta):
    try:
        c = _caminho(pasta)
    except PermissionError as e:
        return str(e)
    rg = shutil.which("rg")
    cmd = [rg, "-n", "-i", "--max-count", "5", "-g", "!*.dds", padrao, str(c)] if rg else \
          ["grep", "-rniI", "-m", "5", "--exclude=*.dds", padrao, str(c)]
    return _run(cmd, timeout=20)


def listar(pasta):
    try:
        c = _caminho(pasta)
    except PermissionError as e:
        return str(e)
    if not c.is_dir():
        return f"não é uma pasta: {c}"
    itens = sorted(c.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))[:80]
    return "\n".join(f"{p.name}{'/' if p.is_dir() else ''}" for p in itens)


def diagnostico(comando):
    """Comando só-leitura: bubblewrap com / somente leitura, sem rede, /tmp vazio, 20 s."""
    if PROIBIDO.search(comando):
        return "comando bloqueado (lista de proibidos)"
    bw = ["bwrap", "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc", "--tmpfs", "/tmp",
          "--unshare-net", "--unshare-pid", "--die-with-parent", "--new-session",
          "--tmpfs", str(HOME / ".ssh"), "--tmpfs", str(HOME / ".gnupg"), "--tmpfs", str(HOME / ".config/restic"),
          "--tmpfs", str(HOME / ".config/rclone"), "bash", "-c", comando]
    return _run(bw, timeout=20)


# ---------------------------------------------------------------- ferramentas CONFIRMAR
def _gravar(c, novo, confirmar):
    antigo = c.read_text(errors="replace") if c.exists() else ""
    if antigo == novo:
        return "nada mudou"
    diff = "".join(difflib.unified_diff(antigo.splitlines(True), novo.splitlines(True),
                                        fromfile=str(c), tofile=str(c) + " (novo)", n=2))
    if not confirmar(f"Editar {c}", diff):
        return "edição recusada pelo usuário"
    if c.exists():
        bak = c.with_name(c.name + time.strftime(".bak-%Y%m%d-%H%M%S"))
        shutil.copy2(c, bak)
    c.parent.mkdir(parents=True, exist_ok=True)
    c.write_text(novo)
    return f"gravado {c}" + (f" (backup: {bak.name})" if antigo else "")


def substituir_trecho(caminho, trecho_antigo, trecho_novo, *, confirmar):
    try:
        c = _caminho(caminho, escrever=True)
    except PermissionError as e:
        return str(e)
    if not c.is_file():
        return f"arquivo não existe: {c}"
    txt = c.read_text(errors="replace")
    n = txt.count(trecho_antigo)
    if n != 1:
        return f"o trecho antigo aparece {n} vezes (precisa ser exatamente 1); leia o arquivo e copie o trecho exato"
    return _gravar(c, txt.replace(trecho_antigo, trecho_novo), confirmar)


def escrever_arquivo(caminho, conteudo, *, confirmar):
    try:
        c = _caminho(caminho, escrever=True)
    except PermissionError as e:
        return str(e)
    return _gravar(c, conteudo, confirmar)


def executar(comando, *, confirmar):
    if PROIBIDO.search(comando):
        return "comando bloqueado (proibido: sudo, rm -r, systemctl de sistema, gravar em /etc, etc.)"
    if not confirmar("Executar comando", comando):
        return "execução recusada pelo usuário"
    return _run(["bash", "-lc", comando], timeout=120)


def enviar_arquivo_celular(caminho, *, confirmar):
    try:
        c = _caminho(caminho)
    except PermissionError as e:
        return str(e)
    if not confirmar("Mandar arquivo pro celular", str(c)):
        return "recusado"
    return _run(["kdeconnect-cli", "-d", CELULAR, "--share", str(c)])


def backup_agora(*, confirmar):
    if not confirmar("Rodar o backup no Google Drive agora", "systemctl --user start backup-drive.service"):
        return "recusado"
    return _bg(["systemctl", "--user", "start", "backup-drive.service"]) and "backup iniciado (log: ~/backups/backup-drive.log)"


def homologacao(projeto, acao, *, confirmar):
    if not re.fullmatch(r"[\w.\-]+", projeto) or not Path("/srv/docker", projeto).is_dir():
        return f"projeto inexistente em /srv/docker: {', '.join(p.name for p in Path('/srv/docker').iterdir())}"
    if acao == "status":
        return _run(["docker", "compose", "--project-directory", f"/srv/docker/{projeto}", "ps"])
    if acao == "logs":
        return _run(["docker", "compose", "--project-directory", f"/srv/docker/{projeto}", "logs", "--tail", "40"])
    if acao not in ("subir", "derrubar"):
        return "ação: status|logs|subir|derrubar"
    cmd = ["docker", "compose", "--project-directory", f"/srv/docker/{projeto}"] + (["up", "-d"] if acao == "subir" else ["down"])
    if not confirmar(f"Homologação {projeto}: {acao}", " ".join(cmd)):
        return "recusado"
    return _run(cmd, timeout=180)


# ---------------------------------------------------------------- catálogo (esquemas pro modelo)
def _f(nome, desc, props=None, req=None):
    return {"type": "function", "function": {"name": nome, "description": desc,
            "parameters": {"type": "object", "properties": props or {}, "required": req or []}}}

def _e(*ops, d=""):
    return {"type": "string", "enum": list(ops), "description": d}

S = {"type": "string"}
CATALOGO = [
    _f("sway", "Controla janelas/workspaces do Sway.", {"acao": _e("workspace", "focar", "mover_para_workspace", "layout",
       "tela_cheia", "flutuar", "fechar_janela", "focar_app"), "alvo": {"type": "string", "description":
       "número do workspace, direção (left/right/up/down), layout (tabbed/stacking/splith/splitv) ou app_id"}}, ["acao"]),
    _f("janelas", "Lista as janelas abertas e em qual workspace estão."),
    _f("abrir_app", "Abre um aplicativo.", {"app": _e(*APPS)}, ["app"]),
    _f("abrir_jogo", "Abre um jogo pelo Steam.", {"jogo": _e(*JOGOS)}, ["jogo"]),
    _f("midia", "Controla o player de mídia (música/vídeo).", {"acao": _e("play-pause", "play", "pause", "next", "previous", "stop", "status")}, ["acao"]),
    _f("volume", "Volume da saída de áudio (JBL).", {"acao": _e("aumentar", "diminuir", "mudo", "definir", "consultar"),
       "valor": {"type": "integer", "description": "0-100, só com definir"}}, ["acao"]),
    _f("brilho", "Brilho dos dois monitores.", {"acao": _e("mais", "menos", "definir"), "valor": {"type": "integer"}}, ["acao"]),
    _f("modo_tv", "Modo Smart TV no monitor de 32\" (YouTube na TV, YouTube Music, HBO Max).",
       {"acao": _e("ligar", "ligar vertical", "desligar", "youtube", "music", "max", "fechar", "estado",
                   d="'ligar vertical' mantém o monitor vertical aceso")}, ["acao"]),
    _f("modo_jogo", "Modo jogo (foco preso, não perturbe, replay, escalonador LAVD).", {"acao": _e("ligar", "desligar", "estado")}, ["acao"]),
    _f("nao_perturbe", "Liga/desliga o não perturbe das notificações.", {"ligar": {"type": "boolean"}}, ["ligar"]),
    _f("captura", "Captura de tela, OCR, gravação ou salvar replay.", {"tipo": _e("tela", "area", "ocr", "gravar_tela", "salvar_replay")}, ["tipo"]),
    _f("celular", "Celular Android via KDE Connect.", {"acao": _e("tocar", "ping", "enviar", "bateria"),
       "conteudo": {"type": "string", "description": "mensagem do ping, ou link/caminho pra enviar"}}, ["acao"]),
    _f("status_sistema", "Resumo da máquina: carga, RAM, discos, GPU, serviços com falha, backup, LLM."),
    _f("atualizacoes", "Consulta atualizações de pacotes disponíveis (não instala)."),
    _f("servico", "Status de um serviço systemd.", {"unidade": S, "usuario": {"type": "boolean", "description": "true = serviço do usuário"}}, ["unidade"]),
    _f("ler_arquivo", "Lê um arquivo de configuração (pastas permitidas).", {"caminho": S, "inicio": {"type": "integer"}, "linhas": {"type": "integer"}}, ["caminho"]),
    _f("buscar", "Procura um texto dentro de uma pasta permitida.", {"padrao": S, "pasta": S}, ["padrao", "pasta"]),
    _f("listar", "Lista uma pasta permitida.", {"pasta": S}, ["pasta"]),
    _f("diagnostico", "Roda um comando SÓ DE LEITURA (sem rede, sem gravar), ex.: journalctl --user -n 50, ls, cat, ps, df.", {"comando": S}, ["comando"]),
    _f("substituir_trecho", "Edita um arquivo trocando um trecho exato por outro (pede confirmação, faz backup).",
       {"caminho": S, "trecho_antigo": S, "trecho_novo": S}, ["caminho", "trecho_antigo", "trecho_novo"]),
    _f("escrever_arquivo", "Cria/reescreve um arquivo inteiro (pede confirmação, faz backup).", {"caminho": S, "conteudo": S}, ["caminho", "conteudo"]),
    _f("executar", "Executa um comando de shell que ALTERA algo (pede confirmação ao usuário).", {"comando": S}, ["comando"]),
    _f("backup_agora", "Roda o backup no Google Drive agora (pede confirmação)."),
    _f("enviar_arquivo_celular", "Manda um arquivo pro celular (pede confirmação).", {"caminho": S}, ["caminho"]),
    _f("homologacao", "Containers de homologação em /srv/docker.", {"projeto": S, "acao": _e("status", "logs", "subir", "derrubar")}, ["projeto", "acao"]),
]
CONFIRMA = {"substituir_trecho", "escrever_arquivo", "executar", "backup_agora", "homologacao", "enviar_arquivo_celular"}
LEITURA_EXTERNA = {"ler_arquivo", "buscar", "diagnostico", "homologacao"}   # depois delas, tudo pede confirmação

# Categorias (≤ ~10 ferramentas por pedido: modelo de 9B erra com o catálogo inteiro)
CATEGORIAS = {
    "desktop": ["sway", "janelas", "abrir_app", "captura", "nao_perturbe", "brilho", "notificar"],
    "midia": ["midia", "volume", "modo_tv", "abrir_app"],
    "modos": ["modo_tv", "modo_jogo", "abrir_jogo", "nao_perturbe", "volume", "brilho"],
    "arquivos": ["ler_arquivo", "listar", "buscar", "substituir_trecho", "escrever_arquivo", "diagnostico"],
    "sistema": ["status_sistema", "atualizacoes", "servico", "diagnostico", "backup_agora", "homologacao", "executar"],
    "celular": ["celular", "enviar_arquivo_celular", "notificar"],
}
PALAVRAS = {
    "arquivos": r"arquivo|config|\.ini|\.cfg|\.conf|ler |le o|mostra o|edita|muda .* no|troca|chave|mod\b|ext_config|pasta|onde fica",
    "sistema": r"atualiza|backup|servi[cç]o|log|erro|falh|disco|ram|mem[oó]ria|cpu|gpu|vram|temperatura|docker|container|homolog|status|rodou|comando|processo",
    "celular": r"celular|telefone|kde ?connect|manda .* pro|envia .* pro",
    "midia": r"m[uú]sica|toca|pausa|volume|som|youtube|video|v[ií]deo|player|pr[oó]xima|anterior",
    "modos": r"modo|tv|televis|jogo|jogar|steam|assetto|ets2|cyberpunk",
    "desktop": r"janela|workspace|[aá]rea de trabalho|abre|abrir|tela|print|captura|ocr|brilho|monitor|n[aã]o perturbe|notifica",
}


def selecionar(texto):
    """Escolhe as categorias pelo texto e devolve os esquemas (no máximo ~11 ferramentas)."""
    t = texto.lower()
    cats = [c for c, rx in PALAVRAS.items() if re.search(rx, t)] or ["desktop", "sistema"]
    nomes = []
    for c in cats:
        for n in CATEGORIAS[c]:
            if n not in nomes:
                nomes.append(n)
    nomes = nomes[:11]
    return [c for c in CATALOGO if c["function"]["name"] in nomes]
FUNCOES = {k: v for k, v in globals().items() if callable(v) and k in {c["function"]["name"] for c in CATALOGO}}


def chamar(nome, args, confirmar):
    f = FUNCOES.get(nome)
    if not f:
        return f"ferramenta inexistente: {nome}"
    try:
        if nome in CONFIRMA:
            return f(**args, confirmar=confirmar)
        return f(**args)
    except TypeError as e:
        return f"argumentos inválidos: {e}"
    except Exception as e:  # nunca derruba o agente
        return f"erro: {type(e).__name__}: {e}"
