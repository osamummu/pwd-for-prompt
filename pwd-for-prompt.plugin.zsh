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


(( ${+ZSH_PWD4PROMPT} )) || typeset -A ZSH_PWD4PROMPT
# ディレクトリ名を短くするときの長さ
# Ex) if this option is "2": /foo/bar/ → /fo/ba/
: ${ZSH_PWD4PROMPT[length_if_shortening]="1"}
# 隠しディレクトリを短縮するときに特別なあつかいをするか
# Ex) if this option is "1": /.foo/ → /.f/
#     if this option is "0": /.foo/ → /./
: ${ZSH_PWD4PROMPT[enable_special_shortening_of_hidden_dirs]="1"}
# pwd-for-promptの出力の最大幅。数字のみで絶対値、%を末尾に付けると画面幅に対する相対値
: ${ZSH_PWD4PROMPT[max_width]="33%"}
# ZSH_PWD4PROMPT[max_width]を超えるときに
: ${ZSH_PWD4PROMPT[enable_multiple_dirs_omission_with_forcing]="1"}
# 長過ぎるpathを省略するときに代わりに出力する文字列（"#"が省略したディレクトリ数に置き換えられる。"##"は"#"に）
: ${ZSH_PWD4PROMPT[str_replacing_multiple_omitted_dirs]="…#"}
# cwdの親ディレクトリの短縮しない個数
# Ex) if this option is "2": /abcd/efgh/ijkl/mnop/qrst/CWD → /a/e/i/mnop/qrst/CWD
: ${ZSH_PWD4PROMPT[num_of_parent_dirs_of_cwd_unshortened]="3"}


function _zsh_pwd4prompt_print_short_path() {
    local path="$1"
    # ディレクトリ名の省略の仕方
        # 最初のN文字だけ表示
        # 隠しファイルは「.」の次の文字も含む
        # 横幅が一定以上（絶対サイズ・%での画面横幅に対する相対サイズ）になるときは、
            # 重要でない部分を「...」や「…5」のように省略。
                # → $_ZSH_PWD4PROMPT_OMISSION_COUNTが省略したディレクトリ数に変換される
    # 特定のディレクトリは省略しない
        # $HOMEや.gitのあるディレクトリと、その直下N個は省略しない
        # カレントとその上N個は省略しない
        # 省略しないディレクトリでも、あまりに長い名前のものは名前を省略
}

function _zsh_pwd4prompt_short_path() {
    local TARGET_PATH="$1"
    local NUM_NOT_TO_BE_OMITTED="$2"
    local TOPATH="${3-"^$HOME\$|^/\$"}"

    local retval="$TARGET_PATH"

    [[ "$TARGET_PATH" = "/" ]] && {echo "/";return}

    for _ in {0..${NUM_NOT_TO_BE_OMITTED}}; do
        local retval="${TARGET_PATH%/*}"
        [[ "$retval" =~ "$TOPATH" ]] && break
    done
    echo "${retval/"$HOME"/"~"}"
    # TODO:
    return

    (
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
}


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

