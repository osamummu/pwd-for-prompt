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


(( ${+ZSH_PWD4PROMPT} )) || typeset -gA ZSH_PWD4PROMPT
# ディレクトリ名を短くするときの長さ
# Ex) if this option is "2": /foo/bar/ → /fo/ba/
: ${ZSH_PWD4PROMPT[len_if_shortening]="1"}
# ZSH_PWD4PROMPT[len_if_shortening]で、1文字として扱う文字。
# 「[[  ]]」による正規表現の[]の中に入れる
# TODO:
# : ${ZSH_PWD4PROMPT[singlewidth_characters_pattern]=" -"}
# 隠しディレクトリを短縮するときに特別なあつかいをするか
# Ex) if this option is "1": /.foo/ → /.f/
#     if this option is "0": /.foo/ → /./
: ${ZSH_PWD4PROMPT[enable_special_shortening_of_hidden_dirs]="1"}
# pwd-for-promptの出力の最大幅。数字のみで絶対値、%を末尾に付けると画面幅に対する相対値
# これを超えるとpathの省略が行われる。空や0, 0%なら省略を行わない
: ${ZSH_PWD4PROMPT[max_width]="33%"}
# ZSH_PWD4PROMPT[max_width]を超えるpathを省略するときに代わりに出力する文字列
# "\0"が省略したディレクトリ数に置き換えられる
: ${ZSH_PWD4PROMPT[str_replacing_multiple_omitted_dirs]="…\0"}
# cwdの親ディレクトリの短縮しない個数
# Ex) if this option is "2": /abcd/efgh/ijkl/mnop/qrst/CWD → /a/e/i/mnop/qrst/CWD
: ${ZSH_PWD4PROMPT[num_of_parent_dirs_of_cwd_unshortened]="3"}
# 置き換えするパターン（Ex: ^$HOME → ~, ~/Downloads/ → ~// など）
# 「対象のパターン\0置き換える文字列」の形式で'\n'区切りのリスト
# ※先頭から順に適応される
: ${ZSH_PWD4PROMPT[patterns_to_replace]="${HOME}\0~\n~/Downloads\0~/DL"}
# 短縮しないディレクトリでも、この文字数を超えるなら短縮する（この文字数以降を出力しない）
# max_widthと同じ指定法
: ${ZSH_PWD4PROMPT[upper_limit_on_dirname_len]="8"}

# CWD直下のファイルの個数表示のfmt
# \nが通常ファイル数、\rが隠しファイル数、\0が合計
: ${ZSH_PWD4PROMPT[fmt_to_count_files_in_cwd]="\n+\r"}

function _zsh_pwd4prompt_print() {
    local cwd="$PWD"
    local sep="\n"
    local rule_sep="\0"
    for rule in ${(ps.$sep.)ZSH_PWD4PROMPT[patterns_to_replace]}; do
        local tmp=(${(ps.$rule_sep.)rule})
        local pattern="$tmp[1]"
        local replacement="$tmp[2]"
        local cwd="${cwd/${pattern}/${replacement}}"
    done
    echo "$cwd"
}


function _zsh_pwd4prompt_print_short_path() {
    local path="$1"
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

