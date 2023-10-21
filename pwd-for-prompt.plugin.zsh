############################################
# Define variables used within this program
############################################

[[ "`setopt`" =~ "ksharrays" ]] \
    && _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED="1" \
    || unset _ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED





############################################
#                Functions
############################################

function _zsh_pwd4prompt_gui_cui() (
    [ "${DISPLAY}" ] && echo "$1" || echo "$2"
)

# Returns the path of the directory where the first ".git" between the current
# directory and "$HOME" or "/" exists. Returns blank if not found.
# ".git" in directories that match the pattern written in
# ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS will be ignored.
function _zsh_pwd4prompt_search_gitroot_path() (
    retval=""
    while true ; do
        unset docontinue
        for pattern in ${ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS}; do
            if [[ "${PWD}" =~ "${pattern}" ]]; then docontinue="1"; break; fi
        done

        if [ ! "${docontinue}" ]; then
            if [ -d "$PWD/.git" ]; then
                retval="$PWD"
                break 
            fi
        fi

        [[ "$PWD" =~ "^$HOME\$|^/\$" ]] \
            && break \
            || cd ..
    done

    echo ${retval}
)


function _zsh_pwd4prompt_short_path() (
    TARGET_PATH="$1"
    NUM_NOT_TO_BE_OMITTED="$2"
    TOPATH="${3-"^$HOME\$|^/\$"}"
    retval=""

    [ "$TARGET_PATH" = "/" ] && {echo "/";return}

    [ "${_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED}" ] && unsetopt ksharrays

    cd "$TARGET_PATH"

    i=0
    while [[ ! "$PWD" =~ "$TOPATH" ]] \
        && [ "$i" -lt "$NUM_NOT_TO_BE_OMITTED" ];
    do
        basename="`basename "$PWD"`"
        retval="/${basename}${retval}"
        cd ..
        let i++
    done

    if [ "$i" -ge "$NUM_NOT_TO_BE_OMITTED" ]; then
        while [[ ! "$PWD" =~ "$TOPATH" ]]; do
            basename="`basename "$PWD"`"
            if [ "${basename[1]}" = "." ]; then
                retval="/.${basename[2]}${retval}"
            else
                retval="/${basename[1]}${retval}"
            fi
            cd ..
        done
    fi

    if [ "$PWD" = "$HOME" ]; then
        retval="~${retval}"
    fi

    [ "${_ZSH_PWD4PROMPT_KSHARRAYS_IS_ENABLED}" ] && setopt ksharrays

    echo "${retval}"
)


function _zsh_pwd4prompt_path_depth_difference() (
    deeper="$1"
    shallower="$2"
    i=0
    cd "$deeper"
    while [ "$PWD" != "$shallower" ] && [ "$i" -lt "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY" ]; do
        cd ..
        let i++
    done

    echo "$i"
)


function pwd-for-prompt() (
    res="`_zsh_pwd4prompt_search_gitroot_path`"
    if [ -n "$res" ]; then
        # .git found
        gitroot_parent_path="`(cd "$res/.."; echo "$PWD")`" # "
        # NOTE: I added the comment at the end of the above line because my
        # Vim's highlighting causes a problem with the line.
        gitroot_basename="`basename "$res"`"
        depth="`_zsh_pwd4prompt_path_depth_difference "$PWD" "$gitroot_parent_path"`"
        echo "$depth"
        depth="$(( ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY - depth ))"
        [ "$depth" -gt "0" ] || depth="0"
        gitroot_short_path="`_zsh_pwd4prompt_short_path "$gitroot_parent_path" "$depth"`"
        path_after_gitroot="`_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY" "^${res}\$"`"

        echo "${ZSH_PWD4PROMPT_GITROOT_PREFIX}${ZSH_PWD4PROMPT_PATH_STYLE}${gitroot_short_path}/${ZSH_PWD4PROMPT_GITROOT_PREFIX}${gitroot_basename}${ZSH_PWD4PROMPT_GITROOT_SUFFIX}/${path_after_gitroot#/}${ZSH_PWD4PROMPT_GITROOT_SUFFIX}"
    else
        echo "${ZSH_PWD4PROMPT_GITROOT_PREFIX}`_zsh_pwd4prompt_short_path "$PWD" "$ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY"`${ZSH_PWD4PROMPT_GITROOT_SUFFIX}"
    fi
)





############################################
#                Settings
############################################

# The number of parent directories to display
ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY="3"

# The array of directory pattern to ignore when searching for ".git".
# The pattern is such that "[[ "$PWD" =~ "PATTERN" ]]" is true
ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS=( "^${HOME}\$" )





############################################
#                 Theme
############################################

# TODO: delimiter
# ZSH_PWD4PROMPT_DELIMITER="/"
# TODO: directory style
# ZSH_PWD4PROMPT_PATH_STYLE="%{$fg_bold[cyan]%}"

# prefix and suffix to whole
ZSH_PWD4PROMPT_PREFIX_TO_WHOLE="%{$fg_bold[cyan]%}"
ZSH_PWD4PROMPT_SUFFIX_TO_WHOLE="%{${reset_color}%}"

# The prefix and suffix of the directory containing ".git".
ZSH_PWD4PROMPT_GITROOT_PREFIX="%{$fg_bold[yellow]%}`_zsh_pwd4prompt_gui_cui '' 'Git:'`"
ZSH_PWD4PROMPT_GITROOT_SUFFIX="%{${reset_color}%}"





############################################
# Delete variables used within this program
############################################

for variable in `set|grep "_ZSH_PWD4PROMPT_"`; do
    unset "$variable"
done

