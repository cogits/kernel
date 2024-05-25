# term
TERM=xterm-256color

# plugins {{{1
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_HISTORY_IGNORE="(cd|ls) *"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/fzf/completion.zsh 2>/dev/null
source /usr/share/zsh/plugins/fzf/key-bindings.zsh 2>/dev/null


# key bindings {{{1
bindkey '\eh' backward-char
bindkey '\el' forward-char              # accept the suggestion
bindkey '\ej' history-substring-search-down
bindkey '\ek' history-substring-search-up
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

bindkey '\en' backward-word
bindkey '\em' forward-word              # partially accept the suggestion

bindkey '^X' where-is
bindkey '^Z' undo


# options {{{1
# Keep 2000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=2000
SAVEHIST=2000
HISTORY_IGNORE='(cd *|l[sal] *|rm *|p[tl] *|echo *|print *)'
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_ALL_DUPS

# Disable correction
unsetopt correct_all
unsetopt correct
DISABLE_CORRECTION="true"

setopt EXTENDED_GLOB        # extended pattern matching
setopt AUTO_CD              # [cd] /home/ali
setopt AUTO_PUSHD           # dirs -v / ~<num>
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

# Use modern completion system {{{1
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select     #For autocompletion with an arrow-key driven interface

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'


# aliases {{{1
alias fd='fd -I'
alias rg='rg -M $COLUMNS' # max columns

alias pt='print'
alias pl='print -l'
alias ls='eza -s Name --group-directories-first'
alias ll='ls -lh --no-user'
alias la='ls -a'

alias tree='eza -T'
alias btop='btop --utf-force'
alias readelf='readelf -W'
alias apk='apk --allow-untrusted'


# set dotdot.. aliases
dot=.
ddot=..
cmd=$ddot
parents=$ddot

for i ({3..9}) {
    cmd=$cmd$dot
    parents=$parents/$ddot
    alias $cmd="cd $parents"
}

unset dot ddot cmd parents


# functions {{{1
now() {
    local str
    if [[ -z $1 ]] {
        str='%D{%H:%M:%S.%.}'
    } else {
        if [[ $1 == "-d" ]] {
            str='%D{%y%m%d}'
        } elif [[ $1 == "-t" ]] {
            str='%D{%H%M%S}'
        } else {
            str='%D{%y%m%d_%H%M%S}'
        }
    }
    print -P $str
}

pathshorten() {
    local arr=()
    local tail=${${(D)PWD}#${(%):-%-1~}}

    # 空字符串则替换成 '/'，因为之后要用 ':h' 处理。"/":h 为空，而 "":h 为 "." 。。。
    for i (${(s./.)${tail:-/}:h}) {
        arr+=/$i[1]
    }

    print "${(%):-%-1~}${(j..)arr}${tail:+/${PWD:t}}"
}

EDITOR=vim

vi() {
    local i=0
    local cmd=(${=*})
    local cmdidx=({1..$#cmd})

    for i str (${cmdidx:^cmd}) {
        if [[ $str =~ "^[^-].+:" ]] {
            cmd[$i]="${str[(ws.:.)1]} +${str[(ws.:.)2]}"
        }
    }
    eval "$EDITOR $cmd"
}

# prompt {{{1
setopt prompt_subst

_ps_sign_='%(!.#.$)'
_ps_sign_=${(%)_ps_sign_}
_ps_sign_='%(?.'$_ps_sign_'.×)'

_ps_directory_='%(4~|$(pathshorten)|%~)'
_ps_errcolor_='%(?.%F{white}.%U%F{red})'
_ps_stop_='%u%f'

PROMPT="${_ps_directory_} ${_ps_errcolor_}${_ps_sign_}${_ps_stop_} "
unset _ps_directory_ _ps_errcolor_ _ps_sign_ _ps_stop_

# dircolors {{{1
eval $(dircolors /etc/dircolors.256dark)

# Epilogue {{{1
# vim:set foldmethod=marker:
