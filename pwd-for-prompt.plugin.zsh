############################################
# Define variables used within this program
############################################

[[ "`setopt`" =~ "ksharrays" ]] \
    && _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED="1" \
    || unset _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED





############################################
#                Functions
############################################

autoload -U colors && colors
setopt prompt_subst

# disable promptinit
(( $+functions[promptinit] )) && {promptinit; prompt off}

function _zsh_pwd4prompt_gui_cui() {
    (( ${+DISPLAY} )) && echo "$1" || echo "$2"
}

# Echo the path of the directory where the first ".git" between the current
# directory and "/" exists. Echo blank if not found.
# ".git" in directories that match the pattern written in
# ZSH_PWD4PROMPT_GITTOP_SEARCH_EXCLUSION_PATTERN will be ignored.
function _zsh_pwd4prompt_search_gitroot_path() {
    local res=""
    type git &>/dev/null \
        && local res="$(command git rev-parse --show-toplevel 2>/dev/null)" \
        || local res="$(
            while builtin true; do
                [[ -d "$PWD/${GIT_DIR-.git}" ]] && { builtin echo "$PWD"; break }
                cd ..
                [[ "$PWD" =~ "^/\$" ]] && return
            done
        )"
    [[ "$res" =~ "$ZSH_PWD4PROMPT_GITTOP_SEARCH_EXCLUSION_PATTERN" ]] \
        || builtin echo "$res"
}


function _zsh_pwd4prompt_short_path() (
    TARGET_PATH="$1"
    NUM_NOT_TO_BE_OMITTED="$2"
    TOPATH="${3-"^$HOME\$|^/\$"}"
    retval=""

    [[ "$TARGET_PATH" = "/" ]] && {echo "/";return}

    (( ${+_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED} )) && unsetopt ksharrays

    cd "$TARGET_PATH"

    i=0
    while [[ ! "$PWD" =~ "$TOPATH" && "$i" -lt "$NUM_NOT_TO_BE_OMITTED" ]]; do
        basename="${PWD##*/}"
        retval="/${basename}${retval}"
        cd ..
        let i++
    done

    if [[ "$i" -ge "$NUM_NOT_TO_BE_OMITTED" ]]; then
        while [[ ! "$PWD" =~ "$TOPATH" ]]; do
            basename="${PWD##*/}"
            if [ "${basename[1]}" = "." ]; then
                retval="/.${basename[2]}${retval}"
            else
                retval="/${basename[1]}${retval}"
            fi
            cd ..
        done
    fi

    if [[ "$PWD" = "$HOME" ]]; then
        retval="~${retval}"
    fi

    (( ${+_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED} )) && setopt ksharrays

    echo "${retval}"
)


function _zsh_pwd4prompt_path_depth_difference() (
    deeper="$1"
    shallower="$2"
    i=0
    cd "$deeper"
    while [[ "$PWD" != "$shallower" && "$i" -lt "$ZSH_PWD4PROMPT_NUM_OF_DIRS_TO_DISPLAY" ]]; do
        cd ..
        let i++
    done

    echo "$i"
)


function pwd-for-prompt() {
    res="`_zsh_pwd4prompt_search_gitroot_path`"
    [[ -n "$res" ]] \
        && {
            # ".git" found
            gitroot_parent_path="${PWD%/*}" # " ← Without this comment, my Vim's highlighting breaks.
            depth="`_zsh_pwd4prompt_path_depth_difference "$PWD" "$gitroot_parent_path"`"
            depth="$(( ZSH_PWD4PROMPT_NUM_OF_DIRS_TO_DISPLAY - depth ))"
            [[ "$depth" -lt "0" ]] && depth="0"
            gitroot_short_path="`_zsh_pwd4prompt_short_path "$gitroot_parent_path" "$depth"`/"
            gitroot_basename="${res##*/}"
            [[ "$res" != "$PWD" ]] && {
                path_after_gitroot="/`_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUM_OF_DIRS_TO_DISPLAY" "^${res}\$"`"
                path_after_gitroot="${path_after_gitroot#/}"
            }

            echo "${ZSH_PWD4PROMPT_PREFIX_TO_WHOLE}${gitroot_short_path}${ZSH_PWD4PROMPT_GITTOP_PREFIX}${gitroot_basename}${ZSH_PWD4PROMPT_GITTOP_SUFFIX}${path_after_gitroot-""}${ZSH_PWD4PROMPT_SUFFIX_TO_WHOLE}" # "
        } \
        || \
            echo "${ZSH_PWD4PROMPT_PREFIX_TO_WHOLE}`_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUM_OF_DIRS_TO_DISPLAY"`${ZSH_PWD4PROMPT_SUFFIX_TO_WHOLE}"
}





############################################
#            Default  Settings
############################################

# The number of parent directories to display
ZSH_PWD4PROMPT_DEFAULT_NUM_OF_DIRS_TO_DISPLAY="3"

# The list of directory pattern to ignore when searching for ".git".
# The pattern is such that "[[ "$PWD" =~ "PATTERN" ]]" is true
ZSH_PWD4PROMPT_DEFAULT_GITTOP_SEARCH_EXCLUSION_PATTERN="^${HOME}\$"





############################################
#              Default Theme
############################################

# prefix and suffix to whole
ZSH_PWD4PROMPT_DEFAULT_PREFIX_TO_WHOLE="%{$fg_bold[cyan]%}"
ZSH_PWD4PROMPT_DEFAULT_SUFFIX_TO_WHOLE="%{${reset_color}%}"

# The prefix and suffix of the directory containing ".git".
ZSH_PWD4PROMPT_DEFAULT_GITTOP_PREFIX="%{$fg_bold[yellow]%}`_zsh_pwd4prompt_gui_cui '' 'Git:'`"
ZSH_PWD4PROMPT_DEFAULT_GITTOP_SUFFIX="%{${reset_color}%}${ZSH_PWD4PROMPT_DEFAULT_PREFIX_TO_WHOLE}"





############################################
#           Initalize variables
############################################

: ${ZSH_PWD4PROMPT_NUM_OF_DIRS_TO_DISPLAY="$ZSH_PWD4PROMPT_DEFAULT_NUM_OF_DIRS_TO_DISPLAY"}
: ${ZSH_PWD4PROMPT_GITTOP_SEARCH_EXCLUSION_PATTERN="$ZSH_PWD4PROMPT_DEFAULT_GITTOP_SEARCH_EXCLUSION_PATTERN"}
: ${ZSH_PWD4PROMPT_PREFIX_TO_WHOLE="$ZSH_PWD4PROMPT_DEFAULT_PREFIX_TO_WHOLE"}
: ${ZSH_PWD4PROMPT_SUFFIX_TO_WHOLE="$ZSH_PWD4PROMPT_DEFAULT_SUFFIX_TO_WHOLE"}
: ${ZSH_PWD4PROMPT_GITTOP_PREFIX="$ZSH_PWD4PROMPT_DEFAULT_GITTOP_PREFIX"}
: ${ZSH_PWD4PROMPT_GITTOP_SUFFIX="$ZSH_PWD4PROMPT_DEFAULT_GITTOP_SUFFIX"}





############################################
# Delete variables used within this program
############################################

for var in `builtin set`; do
    [[ "$var" =~ "^_ZSH_PWD4PROMPT_*" ]] && unset "${var:0:((${(N)var#*=}-1))}"
done

