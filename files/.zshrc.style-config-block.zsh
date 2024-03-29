### aux functions
function plugin-compile {
  ZPLUGINDIR=${ZPLUGINDIR:-$HOME/.config/zsh/plugins}
  autoload -U zrecompile
  local f
  for f in $ZPLUGINDIR/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$f"
  done
}
##? Clone a plugin, identify its init file, source it, and add it to your fpath. See https://github.com/mattmc3/zsh_unplugged?tab=readme-ov-file
function plugin-load {
  local repo plugdir initfile initfiles=()
  : ${ZPLUGINDIR:=${ZDOTDIR:-~/.config/zsh}/plugins}
  for repo in $@; do
    plugdir=$ZPLUGINDIR/${repo:t}
    initfile=$plugdir/${repo:t}.plugin.zsh
    # git clone plugin
    if [[ ! -d $plugdir ]]; then
      echo "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules \
        https://github.com/$repo $plugdir
      echo "Compiling plugin $repo..."
      plugin-compile $plugdir
    fi
    # seach init files
    if [[ ! -e $initfile ]]; then
      initfiles=($plugdir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
      (( $#initfiles )) || { echo >&2 "No init file '$repo'." && continue }
      ln -sf $initfiles[1] $initfile
    fi
    fpath+=$plugdir
    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
  done
}


### prompt style

# define colors
# https://www.ditig.com/256-colors-cheat-sheet
function define_os_color {
    local os=$(uname)
    if [[ "$os" == "Darwin" ]]; then
        echo "%F{32}"
    elif [[ "$os" == "Linux" ]]; then
        echo "%F{208}"
    else
        echo "%f"
    fi
}
function define_os_color_darker {
    local os=$(uname)
    if [[ "$os" == "Darwin" ]]; then
        echo "%F{25}"
    elif [[ "$os" == "Linux" ]]; then
        echo "%F{202}"
    else
        echo "%f"
    fi
}
COLOR_SEP=$(define_os_color_darker)
COLOR_USR=$(define_os_color)
COLOR_MSN=$(define_os_color)
COLOR_DIR=$'%F{127}'
COLOR_GIT=$'%F{8}'
COLOR_PMT=$'%F{254}'

# setup git status badge
function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/ [\1]/p'
}

# enable env vars in prompt
setopt PROMPT_SUBST

# create prompt itself
#export PROMPT='${COLOR_USR}%n@${COLOR_MSN}%m:${COLOR_DIR}%~${COLOR_GIT}$(parse_git_branch)${COLOR_DEF} ${COLOR_PMT}%{%(#.#.$)%} '
export PROMPT='%{${COLOR_USR}%}%n@%{${COLOR_MSN}%}%m:%{${COLOR_DIR}%}%~%{${COLOR_GIT}%}$(parse_git_branch)%{${COLOR_DEF}%} %{${COLOR_PMT}%}%{%(#.#.$)%} '

### completions: list with highlighted item, not cased and additional completions
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zmodload -i zsh/complist


### setup plugins
repos=(
  # completions
  zsh-users/zsh-completions

  # plugins you want loaded last
  zsh-users/zsh-syntax-highlighting
#  zsh-users/zsh-history-substring-search  # seems some visual bug
  zsh-users/zsh-autosuggestions
)

plugin-load $repos

autoload -Uz promptinit && promptinit
autoload -U compinit && compinit -u
