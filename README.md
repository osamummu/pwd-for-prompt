# Abbreviated current working directory for zsh prompt
This program provides a command `pwd-for-prompt` that abbreviates and outputs the current working directory.

## Example
```shell
$ pwd
/home/user/foo/bar/baz/qux
$ ls -a ../..
./ ../ .git/ baz/
$ pwd-for-prompt
%{%}~/f/%{%}bar%{%}%{%}/baz/qux%{%}
```

## Usage
Add the following setting to your .zshrc:
```zsh
source path-where-this-plugin-was-installed/pwd-for-prompt.plugin.zsh
PROMPT='$(pwd-for-prompt)
$ '
```

## Options
You can use the following options in your .zshrc.

- `ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY`

Set the depth of directories which is does not abbreviate from the current directory.

```zsh
# Ex: Set to not abbreviate 3-depth from the current directory.
ZSH_PWD4PROMPT_NUMBER_OF_DIRECTORIES_TO_DISPLAY="3"
```

- `ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS`

Set list of directories which is ignored when searching git root.

```zsh
# Ex: Set to ignore `~/foo` directory.
ZSH_PWD4PROMPT_GITROOT_SEARCH_EXCLUSIONS=( "^${HOME}/foo\$" )
```

- `ZSH_PWD4PROMPT_STYLE`

Set color of output.

```zsh
# Ex: Set cyan.
ZSH_PWD4PROMPT_STYLE="%{$fg_bold[cyan]%}"
```

- `ZSH_PWD4PROMPT_RESET_STYLE`

Set escape sequences for resetting colors after output.

```zsh
# Ex:
ZSH_PWD4PROMPT_RESET_STYLE="%{${reset_color}%}"
```

- `ZSH_PWD4PROMPT_GITROOT_PREFIX`

Set the prefix of the directory containing `.git`.

```zsh
Ex: Set color yellow and add a flag `Git:`
ZSH_PWD4PROMPT_GITROOT_PREFIX="%{$fg_bold[yellow]%} Git:"
```

- `ZSH_PWD4PROMPT_GITROOT_SUFFIX`

Set the suffix of the directory containing `.git`.

```zsh
Ex: Reset color.
ZSH_PWD4PROMPT_GITROOT_SUFFIX="%{${reset_color}%}${ZSH_PWD4PROMPT_STYLE}"
```

