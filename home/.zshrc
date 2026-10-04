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

fastfetch() { echo; command fastfetch "$@"; }

alias ls='ls --color=auto'
alias ll='ls -lh --group-directories-first'
alias la='ll -A'
alias ip='ip -color=auto'
alias grep='grep --color=auto'

# ultima linha SEMPRE:
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
