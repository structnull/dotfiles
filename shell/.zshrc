# Cache and helper setup
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

typeset -U path PATH

command_exists() {
  (( $+commands[$1] ))
}

safe_source() {
  [[ -r "$1" ]] && source "$1"
}

add_path_front() {
  [[ -d "$1" ]] && path=("$1" $path)
}

add_path_back() {
  [[ -d "$1" ]] && path+=("$1")
}

mkdir -p "$XDG_CACHE_HOME/zsh" >/dev/null 2>&1


# Prompt
autoload -Uz colors compinit edit-command-line
colors

if command_exists starship; then
  [[ -t 1 ]] && eval "$(starship init zsh)"
else
  PROMPT='%F{yellow}%n%f%F{magenta}@%f%F{blue}%m%f %~ %F{green}❯%f '
fi


# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

setopt appendhistory
setopt autocd
setopt correct
setopt extendedglob
setopt histignorealldups
setopt histignorespace
setopt inc_append_history
setopt nocaseglob
setopt nocheckjobs
setopt nobeep
setopt numericglobsort
setopt rcexpandparam


# Plugins
safe_source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
safe_source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
safe_source /usr/share/zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh


# Completion
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

_comp_options+=(globdots)
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-${ZSH_VERSION}"


# Vi mode and key bindings
bindkey -v
export KEYTIMEOUT=1

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey '^?' backward-delete-char
bindkey '^e' edit-command-line
bindkey -s '^f' 'yy\n'

if (( $+widgets[history-substring-search-up] && $+widgets[history-substring-search-down] )); then
  [[ -n ${terminfo[kcuu1]-} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [[ -n ${terminfo[kcud1]-} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

if (( $+widgets[zsh-system-clipboard-vicmd-vi-yank-eol] )); then
  bindkey -M vicmd Y zsh-system-clipboard-vicmd-vi-yank-eol
fi

zle-keymap-select() {
  if [[ $KEYMAP == vicmd || $1 == block ]]; then
    [[ -t 1 ]] && printf '\e[1 q'
  elif [[ $KEYMAP == main || $KEYMAP == viins || -z $KEYMAP || $1 == beam ]]; then
    [[ -t 1 ]] && printf '\e[5 q'
  fi
}
zle -N zle-keymap-select

zle-line-init() {
  zle -K viins
  [[ -t 1 ]] && printf '\e[5 q'
}
zle -N zle-line-init

precmd() {
  [[ -t 1 ]] && printf '\e[5 q'
}

preexec() {
  [[ -t 1 ]] && printf '\e[5 q'
}

[[ -t 1 ]] && printf '\e[5 q'


# Helpers
ex() {
  [[ -n "$1" ]] || {
    echo "usage: ex <archive>"
    return 1
  }

  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjvf "$1" ;;
      *.tar.gz) tar xzvf "$1" ;;
      *.bz2) bunzip2 -v "$1" ;;
      *.rar) unrar x -y "$1" ;;
      *.gz) gunzip -v "$1" ;;
      *.tar) tar xvf "$1" ;;
      *.tbz2) tar xjvf "$1" ;;
      *.tgz) tar xzvf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress -v "$1" ;;
      *.7z) 7z x "$1" ;;
      *.deb) ar x "$1" ;;
      *.tar.xz) tar xvJf "$1" ;;
      *.tar.zst) tar --zstd -xvf "$1" ;;
      *) echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

yy() {
  local tmp cwd

  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
  yazi "$@" --cwd-file="$tmp"

  if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    cd -- "$cwd" || return
  fi

  rm -f -- "$tmp"
}

mp3() {
  mkdir -p "$HOME/Music/yt" || return 1
  yt-dlp \
    --ignore-errors \
    -f bestaudio \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 0 \
    -o "$HOME/Music/yt/%(title)s.%(ext)s" \
    "$1"
}


# Environment
unset LINES
unset COLUMNS

export FZF_COMPLETION_OPTS="--multi"
export EDITOR="nvim"
export VISUAL="nvim"
export READER="zathura"
export TERMINAL="kitty"
export BROWSER="brave"
export TRUEBROWSER="brave"
export VIDEO="mpv"
export IMAGE="imv"
export OPENER="mimeopen"
export LANG="en_US.UTF-8"
export COLORTERM="truecolor"
export MANPAGER='nvim +Man!'
export BAT_THEME='base16-256'

# export JAVA_HOME='/usr/lib/jvm/java-17-openjdk'
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export CHROME_EXECUTABLE="/usr/bin/google-chrome-stable"

add_path_front "$HOME/.local/bin"
add_path_front "$HOME/.cargo/bin"
[[ -n ${JAVA_HOME-} ]] && add_path_front "$JAVA_HOME/bin"
add_path_back "$HOME/.pub-cache/bin"
add_path_front "$HOME/.openfang/bin"
export PATH

# Android SDK tools if you need them:
# add_path_back "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
# add_path_back "$ANDROID_SDK_ROOT/platform-tools"
# add_path_back "$ANDROID_SDK_ROOT/tools/bin"
# add_path_back "$ANDROID_SDK_ROOT/emulator"

export XCURSOR_PATH="${XCURSOR_PATH:+$XCURSOR_PATH:}$HOME/.local/share/icons"


# Aliases
alias neofetch='fastfetch'
alias scrcpy='SDL_VIDEODRIVER=wayland scrcpy'
alias ls='ls -Gh --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ta='tmux attach-session'
alias v='nvim'
alias vim='nvim'
alias win='/media/windows/'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias py='python3'
alias paclist="pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'"
alias zshrc='nvim ~/.zshrc'
alias wttr='curl wttr.in'
alias bkup='/media/windows/stuff/dotfiles'
alias cava='TERM=st-256color cava'
alias code='codium'
alias deck='STEAM_MULTIPLE_XWAYLANDS=1 gamescope -W 1920 -H 1080 -f --xwayland-count 2 -r 60 -e --prefer-vk-device 8086:9a60 --adaptive-sync -- steam -gamepadui -steamdeck --pipewire-dmabuf'


# FZF
if [[ -t 0 && -t 1 ]]; then
  safe_source /usr/share/fzf/key-bindings.zsh
  safe_source /usr/share/fzf/completion.zsh
fi

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --info=inline --preview "bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || sed -n '\''1,500p'\'' {}"'


# Extra completions
safe_source /home/adharsh/.dart-cli-completion/zsh-config.zsh


# Load last
safe_source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
