# Enable colors and change prompt:
autoload -U colors && colors
PS1="%F{yellow}%n%f%F{magenta}@%f%F{blue}%m%f %~ %F{green}❯%f "


# History:
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

#Load zsh autosuggestion
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

#Load zsh history-substring-search
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

#load zsh-system-clipboard
source /usr/share/zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh

#Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)   # Include hidden files.

# VI mode:
bindkey -v
export KEYTIMEOUT=1

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes:
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Edit line in vim:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

bindkey -M vicmd Y zsh-system-clipboard-vicmd-vi-yank-eol


# Archive extraction:
ex () {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjvf "$1" ;;    
      *.tar.gz)    tar xzvf "$1" ;;
      *.bz2)       bunzip2 -v "$1" ;;
      *.rar)       unrar x -y "$1" ;;   
      *.gz)        gunzip -v "$1" ;;
      *.tar)       tar xvf "$1" ;;
      *.tbz2)      tar xjvf "$1" ;;
      *.tgz)       tar xzvf "$1" ;;
      *.zip)       unzip "$1" ;;     
      *.Z)         uncompress -v "$1" ;;
      *.7z)        7z x "$1" ;;         
      *.deb)       ar x "$1" ;;         
      *.tar.xz)    tar xvJf "$1" ;;     
      *.tar.zst)   tar --zstd -xvf "$1" ;;
      *)           echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

bindkey -s '^f' 'yy\n'

# Open ranger in current directory:
#run_ranger () {
#    echo
#    ranger --choosedir=$HOME/.rangerdir < $TTY
#    LASTDIR=`cat $HOME/.rangerdir`
#    cd "$LASTDIR"
#    zle reset-prompt
#}
#zle -N run_ranger
#bindkey '^f' run_ranger


## Options section
setopt correct                                                  # Auto correct mistakes
setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
setopt nocaseglob                                               # Case insensitive globbing
setopt rcexpandparam                                            # Array expension with parameters
setopt nocheckjobs                                              # Don't warn about running processes when exiting
setopt numericglobsort                                          # Sort filenames numerically when it makes sense
setopt nobeep                                                   # No beep
setopt appendhistory                                            # Immediately append history instead of overwriting
setopt histignorealldups                                        # If a new command is a duplicate, remove the older one
setopt autocd                                                   # if only directory path is entered, cd there.
setopt inc_append_history                                       # save commands are added to the history immediately, otherwise only when shell exits.
setopt histignorespace                                          # Don't save commands that start with space


zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"         # Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' rehash true                              # automatically find new executables in path 
# Speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path  ~/.cache/zcache


# bind UP and DOWN arrow keys to history substring search
bindkey '^[[A' history-substring-search-up			
bindkey '^[[B' history-substring-search-down

# Resizing issue fix
unset LINES
unset COLUMNS

# EXPORTS
export FZF_COMPLETION_OPTS="--multi"
# Default Apps
export EDITOR="nvim"
export READER="zathura"
export VISUAL="nvim"
export TERMINAL="kitty"
export BROWSER="brave"
export VIDEO="mpv"
export IMAGE="imv"
export COLORTERM="truecolor"
export OPENER="mimeopen"
export LANG=en_US.UTF-8
export MANPAGER='nvim +Man!'
export TRUEBROWSER='brave'
export BAT_THEME='base16-256'



# export JAVA_HOME='/usr/lib/jvm/java-17-openjdk'
export ANDROID_SDK_ROOT='$HOME/Android/Sdk/'
export CHROME_EXECUTABLE='/usr/bin/google-chrome-stable'
# export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/
# export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools/
# export PATH=$PATH:$ANDROID_SDK_ROOT/tools/bin/
# export PATH=$PATH:$ANDROID_ROOT/emulator
# export PATH=$PATH:$ANDROID_SDK_ROOT/tools/


#export paths
export PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH=/home/adharsh/.cargo/bin:$PATH
export PATH=$JAVA_HOME/bin:$PATH 
export PATH="$PATH":"$HOME/.pub-cache/bin"
export XDG_CACHE_HOME="$HOME/.cache"

# aliases
alias neofetch='fastfetch'
alias scrcpy='SDL_VIDEODRIVER=wayland scrcpy'
alias ls='ls -Gh --color=auto'
alias ll='ls -alF'
# alias code='GTK_USE_PORTAL=1 code'
alias la='ls -A'
alias ta='tmux attach-session'
alias l='ls -CF'
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
alias zshrc="nvim ~/.zshrc"
alias wttr="curl wttr.in"
alias bkup="/media/windows/stuff/dotfiles"
alias cava="TERM=st-256color cava"
alias code="codium"
alias deck="STEAM_MULTIPLE_XWAYLANDS=1 gamescope -W 1920 -H 1080 -f --xwayland-count 2 -r 60 -e --prefer-vk-device 8086:9a60 --adaptive-sync -- steam -gamepadui -steamdeck --pipewire-dmabuf"


# alias fzf='fzfub'
# alias hyprcrash="cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -n 2 | tail -n 1)/hyprland.log >> sed && paste.sh sed && rm sed"
# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_COMMAND='ag --hidden -p .gitignore -g ""'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --info=inline --preview "bat --color=always --style=numbers --line-range=:500 {}"'
export XCURSOR_PATH=${XCURSOR_PATH}:~/.local/share/icons


#youtube-dl
mp3 () {
	yt-dlp --ignore-errors -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 -o '~/Music/yt/%(title)s.%(ext)s' "$1"
}


# Startup
eval "$(starship init zsh)"


# Load zsh-syntax-highlighting; should be last.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/adharsh/.dart-cli-completion/zsh-config.zsh ]] && . /home/adharsh/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

