# ---------------------- function -----------------
add_to_path() {
    if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$PATH:$1"
    fi
}

# ----------------------- PATH --------------------
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
export DISABLE_AUTO_TITLE='true'

# --------------------- general -------------------
export TERM="xterm-256color"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LS_COLORS=${LS_COLORS}:'di=01;35'

#---------------------- neovim -----------------------
export NVIM_APPNAME="dojo"
export EDITOR="nvim"
export VISUAL="nvim"

#---------------------- nvm -----------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --------------------- source -----------------------
[[ -f "$HOME/.albert-scripts/export.sh" ]] && { source "$HOME/.albert-scripts/export.sh" }

# --------------------- cargo -----------------------
[[ -f "$HOME/.cargo/env" ]] && { source "$HOME/.cargo/env" }

# --------------------- nix -------------------------
[[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]] && { source "$HOME/.nix-profile/etc/profile.d/nix.sh" }

# --------------------- bun -----------------------
[ -s "$HOME/.bun/_bun" ] && { source "$HOME/.bun/_bun" }

#---------------------- tdsql -----------------------
[[ -f "/data/ws-shared/tdsql-dev-utils/scripts/export.sh" ]] && { source "/data/ws-shared/tdsql-dev-utils/scripts/export.sh" }

# ----------------------- PATH --------------------
export BUN_INSTALL="$HOME/.bun"
add_to_path "$BUN_INSTALL/bin:$PATH"
add_to_path "/data/bin"
add_to_path "/usr/local/go/bin"
add_to_path "/home/linuxbrew/.linuxbrew/bin"

{ command -v go 2>&1 >/dev/null } && { add_to_path "$(go env GOPATH)/bin" }
[[ -f "$HOME/.local/bin/env" ]] && { source "$HOME/.local/bin/env" }

#---------------------- mise -----------------------
{ command -v mise 2>&1 >/dev/null } && { eval "$(mise activate zsh)" }

#--------------------- zoxide ----------------------
{ command -v zoxide 2>&1 >/dev/null } && { eval "$(zoxide init zsh)" }

#-------------------- starship ---------------------
{ command -v starship 2>&1 >/dev/null } && { eval "$(starship init zsh)" }

# --------------------- env -----------------------
[[ -f "$HOME/.zsh.env" ]] && { source "$HOME/.zsh.env" }
[[ -f "$HOME/.zsh.envs" ]] && { source "$HOME/.zsh.envs" }
[[ -f "$HOME/.zsh.alias" ]] && { source "$HOME/.zsh.alias" }
[[ -f "$HOME/.zsh.keybindings" ]] && { source "$HOME/.zsh.keybindings" }
[[ -f "$HOME/.misc.env" ]] && { source "$HOME/.misc.env" }


