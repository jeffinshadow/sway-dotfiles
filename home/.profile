# ~/.profile — sessão de login (greetd, TTY)
# Carrega as mesmas variáveis que o systemd --user lê de environment.d.
if [ -d "$HOME/.config/environment.d" ]; then
    set -a
    for _f in "$HOME"/.config/environment.d/*.conf; do
        [ -r "$_f" ] && . "$_f"
    done
    unset _f
    set +a
fi

# Sessão iniciada pelo greetd/TTY não traz o desktop definido
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-sway}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-sway}"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
