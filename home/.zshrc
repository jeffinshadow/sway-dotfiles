# SSH interativo → entra (ou volta) na sessão "main" do tmux: se a conexão
# cair, o que estava rodando continua lá. Ctrl+b d sai pro shell comum.
if [[ -n $SSH_CONNECTION && -z $TMUX && -o interactive ]] && command -v tmux &>/dev/null; then
    tmux new-session -A -s main
fi

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups autocd

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

eval "$(starship init zsh)"

# fzf: Ctrl+R busca no histórico, Ctrl+T insere arquivo, Alt+C entra em pasta
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --info=inline \
--color=bg:#131314,bg+:#183A61,fg:#ACABAD,fg+:#F0EDEE,hl:#8AB8F0,hl+:#8AB8F0 \
--color=border:#323235,prompt:#5294E2,pointer:#5294E2,marker:#78CA9F,info:#919093,header:#919093,spinner:#B98EFF"
    source <(fzf --zsh)
fi
# zoxide: "z proj" pula pra pasta mais usada que bate; "zi" escolhe no fzf
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fastfetch com os ajustes da máquina (tamanho da logo etc.), se houver:
# ~/.config/fastfetch/host.args ← hosts/<hostname>/fastfetch.args
fastfetch() {
    local -a extra
    [[ -r ~/.config/fastfetch/host.args ]] &&
        extra=(${(z)"$(grep -v '^[[:space:]]*#' ~/.config/fastfetch/host.args)"})
    echo; command fastfetch "${extra[@]}" "$@"
}

alias ls='ls --color=auto'
alias ll='ls -lh --group-directories-first'
alias la='ll -A'
alias ip='ip -color=auto'
alias grep='grep --color=auto'

# ultima linha SEMPRE:
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
