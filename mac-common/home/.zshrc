# --------------------- oh-my-zsh ---------------
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="ys"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode colored-man-pages)
HISTFILE="${ZSH}/.zsh_history"
ZSH_COMPDUMP="${ZSH}/cache/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
source $ZSH/oh-my-zsh.sh

# --------------------- zsh --------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=blue'

# --------------------- general --------------------
export TERM="xterm-256color"
echo "\e[35m keep simple, keep stupid \e[0m"
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LS_COLORS=${LS_COLORS}:'di=01;35'

# ---------------------- brew ------------------
export PATH=/opt/homebrew/bin:$PATH
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.cloud.tencent.com/homebrew-bottles"

#------------------- nvm  -------------------
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ---------------------- starship ------------------
eval "$(starship init zsh)"

#--------------------- zoxide ----------------------
{ command -v zoxide 2>&1 >/dev/null } && { eval "$(zoxide init zsh)" }

# ---------------------- RIME ------------------
export RIME_DIR="$HOME/Library/Rime"

# -----------------------  go ------------------
{ command -v go 2>&1 >/dev/null } && { export PATH="$PATH:$(go env GOPATH)/bin" }

#------------------- scripts  -------------------
source ${HOME}/.albert-scripts/export.sh

#------------------- nvim  -------------------
export NVIM_APPNAME=dojo
export EDITOR="nvim"
export VISUAL="nvim"

# --------------------- bin -----------------------
add_to_path() {
    if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$PATH:$1"
    fi
}
add_to_path "~/.local/bin"
[[ -f "$HOME/.local/bin/env" ]] && { source "$HOME/.local/bin/env" }

#------------------- nvm  -------------------
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# --------------------- env -----------------------
[[ -f "$HOME/.zsh.env" ]] && { source "$HOME/.zsh.env" }
[[ -f "$HOME/.zsh.envs" ]] && { source "$HOME/.zsh.envs" }
[[ -f "$HOME/.zsh.alias" ]] && { source "$HOME/.zsh.alias" }
[[ -f "$HOME/.zsh.keybindings" ]] && { source "$HOME/.zsh.keybindings" }
[[ -f "$HOME/.misc.env" ]] && { source "$HOME/.misc.env" }

