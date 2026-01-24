# ---------------------- oh-my-zsh ----------------
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="ys"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions docker zsh-vi-mode)
HISTFILE="${ZSH}/cache/.zsh_history"
ZSH_COMPDUMP="${ZSH}/cache/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
DISABLE_MAGIC_FUNCTIONS=true
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
alias "fs"="fuzzy --search"
alias "fj"="fuzzy --jump"
alias "fe"="fuzzy --edit"
alias "hh"="fuzzy --history"

#-------------------- starship ---------------------
{ command -v starship 2>&1 >/dev/null } && { eval "$(starship init zsh)" }

#---------------------- neovim -----------------------
export NVIM_APPNAME="nvchad"
export EDITOR="nvim"

#---------------------- nvm -----------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#----------------------- bin -----------------------
export PATH="$PATH:/data/bin"
export PATH="$PATH:~/.root/bin"
export PATH="$PATH:$(go env GOPATH)/bin"

[[ -f "$HOME/.local/bin/env" ]] && { source "$HOME/.local/bin/env" }

# --------------------- env -----------------------
[[ -f "$HOME/.zsh.env" ]] && { source "$HOME/.zsh.env" }
[[ -f "$HOME/.zsh.alias" ]] && { source "$HOME/.zsh.alias" }

# --------------------- source -----------------------
[[ -f "$HOME/.albert-scripts/export.sh" ]] && { source "$HOME/.albert-scripts/export.sh" }

# # --------------------- cpp -----------------------
# ulimit -c unlimited
# # ccache
# export USE_CCACHE=1
# export CCACHE_SLOPPINESS=file_macro,include_file_mtime,time_macros
# export CCACHE_UMASK=002
# export CCACHE_DIR="/data/.ccache"
# export CC="ccache gcc"
# export CXX="ccache g++"
# ccache -M 150G
#
# export GCC_BASE=/opt/rh/gcc-toolset-10/root/bin
# export GCC=/opt/rh/gcc-toolset-10/root/usr/bin/gcc
# export CC=/opt/rh/gcc-toolset-10/root/usr/bin/gcc
# export CXX=/opt/rh/gcc-toolset-10/root/usr/bin/g++
# source /opt/rh/gcc-toolset-10/enable

# --------------------- homebrew -----------------------
export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"
