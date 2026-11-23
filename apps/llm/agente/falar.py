#!/usr/bin/env python3
"""falar.py "texto" — a Giratina fala em pt-BR pela saída padrão (CPU, ~1 s).
Voz: Kokoro (pf_dora, feminina pt-BR), opcionalmente misturada com uma voz mais suave/grave.
Reserva: Piper faber (masculina) se o Kokoro faltar. Venv: ~/.local/share/giratina-voz/venv
(pip install kokoro-onnx piper-tts). Escolha a variação em ~/.config/giratina/voz (A ou B).
Enquanto fala, cria $XDG_RUNTIME_DIR/giratina-falando (o voz.py não escuta a própria voz)."""
import io, os, re, subprocess, sys, wave
from pathlib import Path

BASE = Path.home() / ".local/share/giratina-voz/modelos"
FALANDO = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "giratina-falando")
CONF = Path.home() / ".config/giratina/voz"
# variações: (mistura de vozes {voz: peso}, velocidade)
VARIACOES = {
    "A": ({"pf_dora": 1.0}, 0.92),                              # dora pura, um pouco mais calma
    "B": ({"pf_dora": 0.7, "af_heart": 0.3}, 0.88),             # mais suave e grave, mais lenta
}


def limpar(t):
    t = re.sub(r"[`*_#>\[\]]", "", t)
    t = re.sub(r"https?://\S+", "um link", t)
    t = t.replace("%", " por cento").replace("°C", " graus").replace("/", " barra ")
    return re.sub(r"\s+", " ", t).strip()[:400]


def wav_kokoro(texto, variacao):
    import numpy as np
    from kokoro_onnx import Kokoro
    k = Kokoro(str(BASE / "kokoro/kokoro-v1.0.int8.onnx"), str(BASE / "kokoro/voices-v1.0.bin"))
    mistura, vel = VARIACOES.get(variacao, VARIACOES["A"])
    estilo = sum(k.get_voice_style(v) * p for v, p in mistura.items())
    amostras, taxa = k.create(texto, voice=estilo, speed=vel, lang="pt-br")
    pcm = (np.clip(amostras, -1, 1) * 32767).astype("<i2").tobytes()
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(taxa); w.writeframes(pcm)
    return buf.getvalue()


def wav_piper(texto):
    from piper import PiperVoice
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        PiperVoice.load(str(BASE / "piper/pt_BR-faber-medium.onnx")).synthesize_wav(texto, w)
    return buf.getvalue()


def falar(texto, variacao=None):
    texto = limpar(texto)
    if not texto:
        return
    variacao = variacao or (CONF.read_text().strip().upper() if CONF.exists() else "B")
    try:
        dados = wav_kokoro(texto, variacao)
    except Exception:
        dados = wav_piper(texto)
    FALANDO.touch()
    try:
        subprocess.run(["pw-play", "--media-role", "Notification", "-"], input=dados,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
    finally:
        FALANDO.unlink(missing_ok=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    var = None
    if args and args[0] in ("--voz", "-v") and len(args) > 1:
        var, args = args[1].upper(), args[2:]
    falar(" ".join(args) or sys.stdin.read(), var)
