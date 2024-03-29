# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# == THIS PART IS LOADED BEFORE SWAY ==
# These environment variables will be available to sway and other graphical apps that don't go through bash beforehand

# Make sure ~/bin is in path
case ":$PATH:" in
	*:$HOME/bin:*) ;;
	*) export PATH=$HOME/bin:$PATH ;;
esac

# ssh-agent
if [ -n "$XDG_RUNTIME_DIR" ]; then
	if [ -z "$SSH_AUTH_SOCK" ]; then
		if [ ! -f "$XDG_RUNTIME_DIR/ssh-agent.sh" ]; then
			ssh-agent | grep -v "echo" > "$XDG_RUNTIME_DIR/ssh-agent.sh"
			chmod 600 "$XDG_RUNTIME_DIR/ssh-agent.sh"
		fi
		[ -f "$XDG_RUNTIME_DIR/ssh-agent.sh" ] && . $XDG_RUNTIME_DIR/ssh-agent.sh
	fi
else
	echo "WARNING : No \$XDG_RUNTIME_DIR" >&2
fi

# Force firefox to use wayland
export MOZ_ENABLE_WAYLAND=1

# MPD socket is in XDG_RUNTIME_DIR
export MPD_HOST="$XDG_RUNTIME_DIR/mpd"

# Prevent wine from messing with XDG
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# Microsoft
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# == END OF THE PRE-GUI PART ==
# We use tty1 for sway
if [[ -z $DISPLAY ]] && [[ -z $WAYLAND_DISPLAY ]] && [[ "$(tty)" = "/dev/tty1" ]]; then
	exec dbus-launch --exit-with-session sway -V 2>>$XDG_RUNTIME_DIR/sway.log.err >>$XDG_RUNTIME_DIR/sway.log.out
fi

# This should not be committed
. $HOME/.bashrc_secret
notes_address="${notes_address:-"https://localhost/missing_notes_address"}"

# vim mode
# this should precede every `bind` commands
set -o vi
bind 'set vi-ins-mode-string \1\e[5 q\033[32m\2I'
bind 'set vi-cmd-mode-string \1\e[1 q\033[31m\2N'
bind 'set show-mode-in-prompt on'
bind 'set keyseq-timeout 50'
# for some reason this broke clear
bind -x '"\C-l": clear'

# Case insensitive TAB
bind 'set completion-ignore-case on'

# Colored completion
bind 'set colored-stats on'

# Disable less history and enable its raw mode (colors)
export LESS="-R"
export LESSHISTFILE="-"

export EDITOR="/usr/bin/vim"
export PAGER="/usr/bin/less"

# Use man with neovim
export MANPAGER="nvim +Man!"

# Do not fill XDG_RUNTIME_DIR with coc logs
export NVIM_COC_LOG_LEVEL=off
export NVIM_COC_LOG_FILE="$XDG_RUNTIME_DIR/coc-nvim.log"

# foot integration
# https://codeberg.org/dnkl/foot/wiki#user-content-spawning-new-terminal-instances-in-the-current-working-directory
osc7_cwd() {
    local strlen=${#PWD}
    local encoded=""
    local pos c o
    for (( pos=0; pos<strlen; pos++ )); do
        c=${PWD:$pos:1}
        case "$c" in
            [-/:_.!\'\(\)~[:alnum:]] ) o="${c}" ;;
            * ) printf -v o '%%%02X' "'${c}" ;;
        esac
        encoded+="${o}"
    done
    printf '\e]7;file://%s%s\e\\' "${HOSTNAME}" "${encoded}"
}

# Do not save dupplicates in the history and lines starting with a space
export HISTCONTROL="ignoreboth"
# Better sync of histories : append instead of overwrite and sync at each prompt
shopt -s histappend
export PROMPT_COMMAND="osc7_cwd; history -a"
# Bigger history
export HISTFILESIZE=10000
export HISTSIZE=${HISTFILESIZE}

# Colors
alias ip='ip -c'
alias sip='sudo ip -c'
alias grep='grep --color'
alias ls='ls --color=auto'
alias sls='sudo ls --color=auto'

# Frequently used options
alias ll='ls -lAh --time-style=long-iso'
alias l='ll'
alias sll='sls -lAh --time-style=long-iso'
alias hd='hexdump -C'
alias feh='feh -.Z'
alias wpa_cli='wpa_cli -iwlan0'
alias readelf='readelf -W'
alias xcp='wl-copy -n'
alias xpa='wl-paste -n'
alias pvim='nvim -i NONE -u NONE --cmd "set noswapfile" --cmd "set nobackup" --cmd "set linebreak" --cmd "set clipboard+=unnamedplus" --noplugin'
alias ptar='tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner'
alias pgzip='gzip -n'
function oi() {
	offlineimap -u basic $* | grep -Ev "^Syncing" | grep -Ev "^Skipping"
}
function oiq() {
	offlineimap -qu basic $* | grep -Ev "^Syncing" | grep -Ev "^Skipping"
}
function jqless() {
	jq . "$1" -C | less
}
function ytdl-mpv-audio() {
	mpv ytdl://ytsearch:"$*" --ytdl-format=bestaudio
}
function chrono() {
	local now="$(date +%s)sec"
	watch -n0.1 -p TZ=UTC date --date now-"$now" +%H:%M:%S.%N
	TZ=UTC date --date now-"$now" +%H:%M:%S.%N
}

# Quick folders
alias tmp='cd /tmp/tmp'
alias cn="cadaver $notes_address"
function lyc() {
	cd "$HOME/lyc"
	[ -d "$1" ] && cd "$1"
}
function dev() {
	cd "$HOME/dev"
	[ -d "$1" ] && cd "$1"
}
function ctf() {
	cd "$HOME/ctf"
	if [ -d "$1" ]; then
		cd "$1"
	else
		cd "$(readlink current)"
	fi
}
function ctfset() {
	if [ -d "$HOME/ctf/$1" ]; then
		unlink $HOME/ctf/current && \
		ln -s $1 $HOME/ctf/current
	else
		printf "ctfset : %s : " "$1" >&2
		errno ENOENT | cut -d " " -f 3- >&2
	fi
}

# Open new gui app and send the term to the scratchpad
function g() {
	local terminal_id="$(swaymsg -t get_tree | jq '..| select(.type?) | select(.focused==true) | .id')"
	swaymsg "move scratchpad"
	"$@"
	swaymsg "[con_id=$terminal_id] focus; floating disable"
}

# Disable copyright warnings
alias gdb='gdb -q'
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias ffplay='ffplay -hide_banner'

alias :q='exit'
alias :qa='exit'
alias :q!='exit'
alias :qa!='exit'

# Title bar
PS1='\[\033]0;\u@\h:\w\007\]'
# Date
PS1+='\[\033[31m\][\D{%H:%M:%S%z}] '
# Prompt
PS1+='\[\033[01;92m\]\u@\h\[\033[01;94m\] \W \$\[\033[00m\] '
