############################################
# Initializations
############################################

# Define variables used within this program
builtin unset _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED

for opt in $(builtin setopt); do
  if [[ "$opt" = "ksharrays" ]]; then
    _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED="1"
  fi
done


builtin autoload -U colors && colors
builtin setopt prompt_subst



############################################
# Functions
############################################

# In GUI, outputs the first argument, and if not, outputs the second argument.
function _zsh_pwd4prompt_gui_cui() {
  [[ "${DISPLAY}" ]] && builtin echo "$1" || builtin echo "$2"
}

# Returns the path of the directory where the first ".git" between the current
# directory and "$HOME" or "/" exists.
# Returns blank if not found.
function _zsh_pwd4prompt_search_gitroot_path() {
  local res=""

  builtin type git &>/dev/null \
    && local res="$(command git rev-parse --show-toplevel 2>/dev/null)" \
    || local res="$(
      while builtin true; do
        [[ -d "$PWD/${GIT_DIR-.git}" ]] && { builtin echo "$PWD"; break }
        builtin cd ..
        [[ "$PWD" =~ "^/\$" ]] && return
      done
    )"
  builtin echo "$res"
}


function _zsh_pwd4prompt_short_path() (
  local target_path="$1"
  local num_not_to_be_omitted="$2"
  local topath="${3-"^$HOME\$|^/\$"}"
  local retval
  local basename

  [[ "$target_path" = "/" ]] && { builtin echo "/"; return }

  (( "${_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED}" )) && builtin unsetopt ksharrays

  builtin cd "$target_path"

  local i=0
  while [[ ! "$PWD" =~ "$topath" ]] \
    && [[ "$i" -lt "$num_not_to_be_omitted" ]];
  do
    basename="${PWD##*/}"
    retval="/${basename}${retval}"
    builtin cd ..
    let i++
  done

  if [[ "$i" -ge "$num_not_to_be_omitted" ]]; then
    while [[ ! "$PWD" =~ "$topath" ]]; do
      basename="${PWD##*/}"
      # If it is a hidden file, include the next character of the first dot.
      if [ "${basename[1]}" = "." ]; then
        retval="/.${basename[2]}${retval}"
      else
        retval="/${basename[1]}${retval}"
      fi

      builtin cd ..
    done
  fi

  if [[ "$PWD" = "$HOME" ]]; then
    retval="~${retval}"
  fi

  (( "${_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED}" )) && builtin setopt ksharrays

  builtin echo "${retval}"
)


function _zsh_pwd4prompt_path_depth_difference() (
  local deeper="$1"
  local shallower="$2"
  local i=0
  builtin cd "$deeper"
  while [[ "$PWD" != "$shallower" ]] && [[ "$i" -lt "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY" ]]; do
    builtin cd ..
    builtin let i++
  done

  builtin echo "$i"
)


function pwd-for-prompt() (
  {
    local depth
    local gitroot_short_path
    local gitroot_basename
    local path_after_gitroot
    local gitroot="$(_zsh_pwd4prompt_search_gitroot_path)"
    local out="${ZSH_PWD4PROMPT_STYLE}"

    # Ignore ".git" directory in the directories that match the pattern written in
    # ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS.
    for exclude_path in $ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS; do
      [[ "$gitroot" =~ "$exclude_path" ]] && gitroot=""
    done

    if [[ -n "$gitroot" ]]; then
      # .git found
      gitroot_parent_path="$(builtin cd "$gitroot/.."; builtin echo "$PWD")"
      depth="$(_zsh_pwd4prompt_path_depth_difference "$PWD" "$gitroot_parent_path")"
      depth="$(( ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY - depth ))"
      [[ "$depth" -lt "0" ]] && depth="0"
      gitroot_short_path="$(_zsh_pwd4prompt_short_path "$gitroot_parent_path" "$depth")/"
      gitroot_basename="$(basename "$gitroot")"

      if [[ "$gitroot" != "$PWD" ]]; then
        path_after_gitroot="/$(_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY" "^${gitroot}\$")"
        path_after_gitroot="${path_after_gitroot#/}"
      fi

      # TODO: out+="${ZSH_PWD4PROMPT_PATH_STYLE}"
      out+="${gitroot_short_path}"
      out+="${ZSH_PWD4PROMPT_GITROOT_PREFIX}${gitroot_basename}${ZSH_PWD4PROMPT_GITROOT_SUFFIX}"
      out+="${path_after_gitroot}"
    else
      out+="$(_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY")"
    fi

    out+="${ZSH_PWD4PROMPT_RESET_STYLE}"

    builtin echo "$out"
  } 2>/dev/null
)



############################################
# Settings
############################################

# The number of parent directories to display
ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY="2"

# The array of directory pattern to ignore when searching for ".git".
# The pattern is such that "[[ "$PWD" =~ "PATTERN" ]]" is true
ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS=( "^${HOME}\$" )



############################################
# Theme
############################################

# TODO: delimiter
# ZSH_PWD4PROMPT_DELIMITER="/"
# TODO: directory style
# ZSH_PWD4PROMPT_PATH_STYLE="%{$fg_bold[cyan]%}"

# color for output
ZSH_PWD4PROMPT_STYLE="%{$fg_bold[cyan]%}"
# escape sequences for reseting colors
ZSH_PWD4PROMPT_RESET_STYLE="%{${reset_color}%}"

# The prefix and suffix of the directory containing ".git".
ZSH_PWD4PROMPT_GITROOT_PREFIX="%{$fg_bold[yellow]%}$(_zsh_pwd4prompt_gui_cui '' 'G:')"
ZSH_PWD4PROMPT_GITROOT_SUFFIX="%{${reset_color}%}${ZSH_PWD4PROMPT_STYLE}"



############################################
# Clean temporary variables
############################################

# unset variables used within this program
for var in $(builtin set); do
  [[ "$var" =~ "_ZSH_PWD4PROMPT_*" ]] && { unset "${var:0:((${(N)var#*=} - 1))}"; echo "ok"; }
done

# vim:ts=2:sw=2:sts=2:
