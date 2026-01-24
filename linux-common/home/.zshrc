# ---------------------- oh-my-zsh ----------------
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="ys"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions docker zsh-vi-mode gitfast)
HISTFILE="${ZSH}/cache/.zsh_history"
ZSH_COMPDUMP="${ZSH}/cache/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
DISABLE_MAGIC_FUNCTIONS=true
autoload -Uz compinit && compinit
source $ZSH/oh-my-zsh.sh

# --------------------- zsh -----------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=blue'

# --------------------- general -------------------
export TERM="xterm-256color"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LS_COLORS=${LS_COLORS}:'di=01;35'

#------------------- fuzzy-shell -------------------
source "${HOME}/.fuzzy_shell/scripts/export.sh"

#--------------------- zoxide ----------------------
{ command -v zoxide 2>&1 >/dev/null } && { eval "$(zoxide init zsh)" }

#-------------------- starship ---------------------
{ command -v starship 2>&1 >/dev/null } && { eval "$(starship init zsh)" }

#---------------------- neovim -----------------------
export NVIM_APPNAME="dojo"
export EDITOR="nvim"
export VISUAL="nvim"
# support c-x c-e
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

#---------------------- nvm -----------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#----------------------- bin -----------------------
export PATH="$PATH:/data/bin"
export PATH="$PATH:~/.root/bin"
export PATH="$PATH:$(go env GOPATH)/bin"
[[ -f "$HOME/.local/bin/env" ]] && { source "$HOME/.local/bin/env" }

# --------------------- source -----------------------
[[ -f "$HOME/.albert-scripts/export.sh" ]] && { source "$HOME/.albert-scripts/export.sh" }

# --------------------- cpp -----------------------
ulimit -c unlimited

# --------------------- homebrew -----------------------
export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"

# --------------------- env -----------------------
[[ -f "$HOME/.zsh.env" ]] && { source "$HOME/.zsh.env" }
[[ -f "$HOME/.zsh.alias" ]] && { source "$HOME/.zsh.alias" }
