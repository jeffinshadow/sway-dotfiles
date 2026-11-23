#!/usr/bin/env python3
"""Controle remoto do modo TV — servidor HTTPS só da rede de casa (porta 8443).

O celular abre https://shadowtec-giratina.local:8443 (PWA instalável). Cada toque vira
um POST /api com JSON; o servidor injeta no Sway pelos protocolos do wlroots:
  ponteiro: wlrctl (virtual pointer)  |  teclado: wtype (virtual keyboard)
  mídia: playerctl  |  volume: swayosd-client (mostra o OSD)  |  apps: modo-tv.sh
Sem dependências fora da biblioteca padrão. Roda pela sessão do Sway (50-autostart),
pra herdar WAYLAND_DISPLAY/SWAYSOCK.

Segurança: só responde com o token certo (header X-Token; o token vai na 1ª abertura
como ?k=... e fica no localStorage do celular). Certificados e token ficam fora do git:
  ~/.local/share/controle-tv/certs/{server.crt,server.key,ca.crt}  (gerar-certs.sh)
  ~/.config/controle-tv/token
"""
import json, os, secrets, ssl, subprocess, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path

HOME = Path.home()
WEB = Path(__file__).resolve().parent / "web"
CERTS = HOME / ".local/share/controle-tv/certs"
TOKEN_FILE = HOME / ".config/controle-tv/token"
MODO_TV = HOME / ".config/sway/scripts/modo-tv.sh"
PORT = int(os.environ.get("CONTROLE_TV_PORT", "8443"))

TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
if not TOKEN_FILE.exists():
    TOKEN_FILE.write_text(secrets.token_urlsafe(24))
    TOKEN_FILE.chmod(0o600)
TOKEN = TOKEN_FILE.read_text().strip()

TYPES = {".html": "text/html; charset=utf-8", ".js": "text/javascript", ".css": "text/css",
         ".webmanifest": "application/manifest+json", ".png": "image/png", ".svg": "image/svg+xml",
         ".crt": "application/x-x509-ca-cert"}
KEYS = {"up": "Up", "down": "Down", "left": "Left", "right": "Right", "ok": "Return",
        "back": "Escape", "backspace": "BackSpace", "space": "space", "tab": "Tab", "f": "f"}


def run(*cmd):
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        pass


class Pointer:
    """Junta os movimentos do touchpad e manda no máximo ~60 por segundo pro wlrctl."""
    def __init__(self):
        self.dx = self.dy = 0.0
        self.lock = threading.Lock()
        threading.Thread(target=self.loop, daemon=True).start()

    def add(self, dx, dy):
        with self.lock:
            self.dx += dx; self.dy += dy

    def loop(self):
        while True:
            time.sleep(1 / 60)
            with self.lock:
                dx, dy = int(self.dx), int(self.dy)
                self.dx -= dx; self.dy -= dy
            if dx or dy:
                subprocess.run(["wlrctl", "pointer", "move", str(dx), str(dy)],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


POINTER = Pointer()


def status():
    tv = subprocess.run([str(MODO_TV), "estado"], capture_output=True, text=True).stdout.strip()
    tocando = subprocess.run(["playerctl", "metadata", "--format", "{{status}}|{{title}}"],
                             capture_output=True, text=True).stdout.strip()
    st, _, titulo = tocando.partition("|")
    app = subprocess.run([str(MODO_TV), "app"], capture_output=True, text=True).stdout.strip()
    return {"tv": tv == "ligado", "status": st, "titulo": titulo, "app": app}


def acao(d):
    t = d.get("t")
    if t == "move":
        POINTER.add(float(d.get("dx", 0)), float(d.get("dy", 0)))
    elif t == "click":
        run("wlrctl", "pointer", "click", "right" if d.get("b") == "right" else "left")
    elif t == "scroll":
        run("wlrctl", "pointer", "scroll", str(int(d.get("dy", 0))), str(int(d.get("dx", 0))))
    elif t == "key" and d.get("k") in KEYS:
        run("wtype", "-k", KEYS[d["k"]])
    elif t == "text" and isinstance(d.get("s"), str) and 0 < len(d["s"]) <= 500:
        run("wtype", "--", d["s"])
    elif t == "media" and d.get("a") in ("play-pause", "next", "previous"):
        run("playerctl", d["a"])
    elif t == "vol":
        a = {"up": "raise", "down": "lower", "mute": "mute-toggle"}.get(d.get("a"))
        if a:
            run("swayosd-client", "--output-volume", a)
    elif t == "tv" and d.get("a") in ("ligar", "desligar", "youtube", "music", "max", "fechar"):
        run(str(MODO_TV), d["a"])
    elif t == "zoom" and d.get("a") in ("in", "out", "reset"):   # modo-tv.sh decide: escala ou Ctrl+/-
        run(str(MODO_TV), "zoom", d["a"])
    elif t == "power" and d.get("a") in ("telas-off", "telas-on", "reboot", "poweroff"):
        a = d["a"]
        if a == "telas-off":
            run("swaymsg", "output * power off")
        elif a == "telas-on":
            run("swaymsg", "output * power on")
        else:   # espera 2 s pra resposta chegar no celular antes de desligar
            run("sh", "-c", f"sleep 2; systemctl {a}")
    elif t == "fullscreen":
        run("swaymsg", "fullscreen", "toggle")
    else:
        return False
    return True


class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def send(self, code, body=b"", ctype="text/plain", extra=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def authed(self):
        return secrets.compare_digest(self.headers.get("X-Token", ""), TOKEN)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/api/status":
            if not self.authed():
                return self.send(403, b"token")
            return self.send(200, json.dumps(status()).encode(), "application/json")
        if path == "/ca.crt":      # pra instalar no celular (é público: não dá acesso a nada)
            f = CERTS / "ca.crt"
            return self.send(200, f.read_bytes(), TYPES[".crt"]) if f.exists() else self.send(404)
        name = "index.html" if path in ("/", "") else path.lstrip("/")
        f = (WEB / name).resolve()
        if WEB not in f.parents or not f.is_file():
            return self.send(404, b"404")
        extra = {"Service-Worker-Allowed": "/"} if name == "sw.js" else None
        self.send(200, f.read_bytes(), TYPES.get(f.suffix, "application/octet-stream"), extra)

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0) or 0)
        corpo = self.rfile.read(min(n, 4096)) if n else b""   # lê sempre (keep-alive)
        if self.path != "/api":
            return self.send(404)
        if not self.authed():
            return self.send(403, b"token")
        try:
            d = json.loads(corpo or b"{}")
            ok = acao(d) if isinstance(d, dict) else False
        except (ValueError, TypeError):
            ok = False
        self.send(204 if ok else 400)


class Server(ThreadingHTTPServer):
    daemon_threads = True

    def handle_error(self, request, client_address):   # celular que fecha a conexão no meio: ignora
        pass


def main():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERTS / "server.crt", CERTS / "server.key")
    srv = Server(("0.0.0.0", PORT), H)
    srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
    print(f"controle-tv em https://0.0.0.0:{PORT}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
