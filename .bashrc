# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
# EXPORTS
export LANG=en_US.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'
export MANPAGER='nvim +Man!'
export BROWSER='firefox'
export TRUEBROWSER='firefox'
export BAT_THEME='base16-256'
export PATH

function fgtab {
  echo "tput setf/setb - Foreground/Background table"
  for f in {0..7}; do
    for b in {0..7}; do
      echo -en "$(tput setf $f)$(tput setb $b) $f/$b "
    done
    echo -e "$(tput sgr 0)"
  done
}
# The prompt in a somewhat Terminal -type independent manner:
cname="$(tput setf 3)"
csgn="$(tput setf 4)"
chost="$(tput setf 2)"
cw="$(tput setf 6)"
crst="$(tput sgr 0)"
PS1="\[${cname}\]\u\[${csgn}\]@\[${chost}\]\h:\[${cw}\]\w\[${csgn}\]\$\[${crst}\] "


#file extraction
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *)           echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# Alias's for multiple directory listing commands
alias ll='ls -Alh' # show hidden files
alias la='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh' # sort by extension
alias lk='ls -lSrh' # sort by size
alias lc='ls -lcrh' # sort by change time
alias lu='ls -lurh' # sort by access time
alias lr='ls -lRh' # recursive ls
alias lt='ls -ltrh' # sort by date
alias vim="nvim"
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
unset rc

eval "$(starship init bash)"


# BEGIN_KITTY_SHELL_INTEGRATION
if test -n "$KITTY_INSTALLATION_DIR" -a -e "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; then source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; fi
# END_KITTY_SHELL_INTEGRATION
export PATH="$HOME/bin:$PATH"
alias nvim="$HOME/bin/nvim"
