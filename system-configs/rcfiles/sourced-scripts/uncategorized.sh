#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## [diff]  ->  Alias
#  Replace builtin diff with delta (https://github.com/dandavison/delta)
#
#  If you want to use the builtin diff
#    [$ command diff]
function diff() {
  command diff "$@" -u | delta
}

## [rg]  ->  Alias
#  Sane defaults for rg (smart-case and --no-ignore) and then pipes the output to less
#
#  use [rgcase] for case sensitive searches
function rg() {
  command rg --smart-case --color=always --no-ignore -p "$@" | less -XFR
}

## [rg-no-pager]  ->  Alias
#  same as [rg] without a pager
function rg-no-pager() {
  command rg --smart-case --color=always --no-ignore -p "$@"
}

## [rgcase]  ->  Alias
#  Sane defaults for rg (--no-ignore) and then pipes the output to less
function rgcase() {
  command rg --color=always --no-ignore -p "$@" | less -XFR
}

## [rgjava]  ->  Shorthand
#  calls [rg] on java files (--type java)
function rgjava() {
  rg -p --type java "$@" | less -XFR
}

## [rgjavasource]  ->  Shorthand
#  same as rgjava except ignores known [target] directory, which has generated sources
function rgjavasource() {
  rg -p --type java --iglob '!target' "$@" | less -XFR
}

## [rgsource]  ->  Shorthand
#  similar to rgjavasource except doesn't restrict type to java files
function rgsource() {
  rg -p --type java --iglob '!target' "$@" | less -XFR
}

## [rg-ips]  ->  Shorthand
#  Search recursively for anything that matches what an IP should look like, with
function rg-ips() {
  rg --pcre2 '\b(?!127\.0\.0\.1\b|0\.0\.0\.0\b)(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\b' "$@"
}


## [grep-urls STRING]
#  Try to grep through a [STRING] and find all the urls
#
#  STRING   = Aribtrary text
#  RETURN  ->
#    Returns all urls found in the text
function grep-urls() {
  local URL_RE='(http://|https://|www\.)[^/ )'"'"'"]+'
  if [[ -z $2 ]]; then
    grep -EIoir --no-filename "$URL_RE" "$1" | sort -u | less
  else
    grep -EIoi --no-filename "$URL_RE" "$1" | sort -u | less
  fi
}

## [seconds-to-date STRING]
#  Converts SECONDS to an ISO8601 date
#
#  STRING   = date in seconds
#  RETURN  ->
#    ISO8601 UTC date
function seconds-to-date() {
  if [[ -z $1 ]] && test -t 0 ; then
    echo "Must provide seconds"
    return 1
  fi
  local SECONDS=

  if [[ -n $1 ]]; then
    SECONDS=$1
  else
    SECONDS=$(cat)
  fi

  python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(${SECONDS}/1000).isoformat() + 'Z')"
}

## [mongo-compass-localhost STRING]
#  Given a PORT generate a url for mongo compass
#
#  STRING   = port
#  RETURN  ->
#    Compass url
function mongo-compass-localhost() {
  if [[ -z $1 ]] && test -t 0 ; then
    echo "Must provide port"
    return 1
  fi
  local PORT=

  if [[ -n $1 ]]; then
    PORT=$1
  else
    PORT=$(cat)
  fi

  echo "mongodb://localhost:${PORT}/?directConnection=true"
}

## [jq-to-csv JSON]
#  Take a [JSON] and reformat it as a CSV
#
#  JSON     = String formatted as json
#  RETURN  ->
#    The csv with the keys formatted as columns.
#    ** Only works with a flat json
function jq-to-csv ()
{
  if [[ -z $1 ]]; then
    jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv'
  else
    jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' <<< "$1"
  fi
}

function to-snake-case() {
  if test ! -t 0; then
    cat | jq '
    def camel_to_snake:
    gsub("(?<lower>[a-z])(?<upper>[A-Z])"; "\(.lower)_\(.upper|ascii_downcase)");

    walk(
    if type == "object" then
      with_entries(.key |= camel_to_snake)
    else
      .
    end
    )'
  else
    if [[ -z "${1}" ]]; then
      echo "Must pass json file name"
      return 1
    fi
    jq '
    def camel_to_snake:
    gsub("(?<lower>[a-z])(?<upper>[A-Z])"; "\(.lower)_\(.upper|ascii_downcase)");

    walk(
    if type == "object" then
      with_entries(.key |= camel_to_snake)
    else
      .
    end
    )' "$1"
  fi
}

## [tmux-new-share]
#  Makes a new tmux socket that's world readable. Useful for two people sshing onto one box
#
#  JSON     = String formatted as json
#  RETURN  ->
#    The csv with the keys formatted as columns.
#    ** Only works with a flat json
function tmux-new-share ()
{
  if [[ $# -ne 1 ]]; then
    echo "[usage] tmux-new-share <name-of-socket-stored-in-/tmp> <name-of-session>"
  else
    local shared_socket=$1
    local session_name=$1
    tmux -S /tmp/"${shared_socket}" new -s "${session_name}"
  fi
}

## [tmux-attach-share NAME]
#  Attaches to [NAME] tmux shared session
#
#  NAME     = Name of the shared session
#  RETURN  ->
#    Attaches to the shared session
function tmux-attach-share ()
{
  if [[ $# -ne 1 ]]; then
    echo "[usage] tmux-attach-share <name>"
  else
    local shared_socket=$1
    local session_name=$1
    echo Running: tmux -S "/tmp/${shared_socket}" attach -t "${session_name}"
    tmux -S "/tmp/${shared_socket}" attach -t "${session_name}"
  fi
}

## [cd]
#  Fuzzy cding into directories
#
#  RETURN  ->
#    cd's into the directory chosen
function cd() {
  if [[ $# -eq 0 ]]; then
    local dir=
    dir=$(find . -type d 2>/dev/null | fzf)
    if [[ "$dir" ]]; then
      command cd "$dir" || return 1
    fi
  else
    command cd "$@" || return 1
  fi
}

## [cdd]
#  Given a file, cd into the directory that contains it
#
#  RETURN  ->
#    cd's into the directory of the file supplied
function cdd() {
  if [[ $# -eq 0 ]]; then
    echo "Must supply a file"
    return 1
  else
    command cd "$(dirname "$*")" || return 1
  fi
}

## [moo]
#  You won't be disapointed
#
#  RETURN  ->
#    :)
# shellcheck disable=SC1003
function moo() {
  echo ' _____'
  echo '/ Moo \'
  echo ' -----'
  echo '     \   ^__^'
  echo '      \  (oo)\_______'
  echo '         (__)\       )\/\'
  echo '             ||----w |'
  echo '             ||     ||'
}

## [print-tmux-colours]
#  Prints all the what all colors usable by tmux.conf look like
#
#  RETURN  ->
#    color name -> color
# shellcheck disable=SC1003
function print-tmux-colours() {
  for i in {0..255}; do
    echo -en "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
  done
}

## [fvimfind REGEX_SEARCH_TERM]
#  Find all files that match the [REGEX_SEARCH_TERM]
#
#  REGEX_SEARCH_TERM  = A regex of files to match
#  RETURN  ->
#    Opens the file selected in vim
function fvimfind() {
  if [[ -z $1 ]]; then
    echo "Must provide search term"
    return 1
  fi

  local FILE_TO_OPEN
  FILE_TO_OPEN=$(
  (
  local preview=
  preview="bat --style='${BAT_STYLE:-full}' --color=always --pager=never -- {-1}"

  find . -iname "$1" 2>/dev/null \
    | fzf -m --ansi \
    --preview "${preview}" \
    --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
    --bind "ctrl-j:preview-down,ctrl-k:preview-up"

  )
)

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    vim "$FILE_TO_OPEN"
  fi
}

## [fjq < FILE]
#  Opens a json file and acts as an interactive jq repl.
#  Works when piping the contents as well
#
#  REGEX_SEARCH_TERM  = A regex of files to match
#  RETURN  ->
#    An interactive query that returns whatever your query specifies
function fjq() {
  local TEMP=
  local QUERY=
  TEMP=$(mktemp -t fjq)
  cat > "$TEMP"
  QUERY=$(
  jq -C . "$TEMP" |
    fzf --reverse --ansi --disabled \
    --prompt 'jq> ' --query '.' \
    --preview "set -x; jq -C {q} \"$TEMP\"" \
    --header 'Press CTRL-Y to copy expression to the clipboard and quit' \
    --bind 'ctrl-y:execute-silent(echo -n {q} | pbcopy)+abort' \
    --bind "shift-down:page-down,shift-up:page-up" \
    --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
    --bind "ctrl-j:preview-down,ctrl-k:preview-up" \
    --print-query | head -1
  )
  [ -n "$QUERY" ] && jq "$QUERY" "$TEMP"
}

## [frg]  ->  Shorthand
#  [rg] with the files shown at the bottom of the screen
function frg() {
  rg --line-number --no-heading --color=always --smart-case "$@" |
    fzf -d ':' -n 2.. \
        --ansi \
        --no-sort \
        --preview-window 'down:20%:+{2}' \
        --preview 'bat \
        --style=numbers \
        --color=always \
        --highlight-line {2} {1}'
}

## [fps]  ->  Shorthand
#  [ps auxww] in a fuzzy finder
function fps() {
  ps auxwww | fzf --tac --header-lines=1 --header "Process List"

}

## [Rg]  ->  Shorthand
#  [rg] with the files shown to the right of the screen
function Rg() {
  local selected
  selected=$(
    rg --column --line-number --no-heading --color=always --smart-case "$1" |
      fzf --ansi \
          --delimiter : \
          --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
          --preview-window '~3:+{2}+3/2'
  )
  [ -n "$selected" ] && $EDITOR "$selected"
}

## [RG]  ->  Shorthand
#  [rg] with the files shown to the right of the screen, and the ability to change query
function RG() {
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  INITIAL_QUERY="$1"
  local selected=
  selected=$(
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY' || true" \
      fzf --bind "change:reload:$RG_PREFIX {q} || true" \
          --ansi --disabled --query "$INITIAL_QUERY" \
          --delimiter : \
          --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
          --preview-window '~3,+{2}+3/3'
  )
  [ -n "$selected" ] && $EDITOR "$selected"
}

## [chrome_history]
#  Brings up a fuzzy finder for searching your chrome history
#
#  RETURN  ->
#    An interactive fuzzy finder that searches all your chrome history
# shellcheck disable=SC2016
function chrome_history() {
  local cols=
  local sep=
  export cols=$(( COLUMNS / 3 ))
  export sep='{::}'

  if [[ "$(uname -s)" != "Darwin" ]]; then
    # Only works on OSX at the moment
    return 1
  fi
  # TODO: OSX Specific
  cp -f ~/Library/Application\ Support/Google/Chrome/Default/History /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select title, url from urls order by last_visit_time desc" |
  ruby -ne '
    cols = ENV["cols"].to_i
    title, url = $_.split(ENV["sep"])
    len = 0
    puts "\x1b[36m" + title.each_char.take_while { |e|
      if len < cols
        len += e =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/ ? 2 : 1
      end
    }.join + " " * (2 + cols - len) + "\x1b[m" + url' |
  fzf --ansi --multi --no-hscroll --tiebreak=index |
  sed 's#.*\(https*://\)#\1#' | xargs open
}

## [explain-shell]
#  Hits the explain shell website with the command you pass in
function explain-shell() {
  local URL_QUERY='' URL_QUERY_CMD=''
  URL_QUERY_CMD=$(cat <<EOM
python -c "import urllib.parse; q=urllib.parse.quote('$@'); print(q)"
EOM
)
  URL_QUERY=$(eval "${URL_QUERY_CMD}")
  local LINK="http://explainshell.com/explain?cmd=${URL_QUERY}"

  w3m -dump "${LINK}" | sed '1,9d' | sed '2,8d' | awk 'NR<=2{printf "%s%s",$0,(NR==1?" ":"\n"); next} 1'
}
## [date-utc]
#  Returns the current date in UTC
function date-utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

## [body]
# print the header (the first line of input)
# and then run the specified command on the body (the rest of the input)
# Source: https://unix.stackexchange.com/questions/11856/sort-but-keep-header-line-at-the-top
#
# Example use: [gcloud beta builds list --page-size=40 --limit=40 | body sort -k6 -k2]
function body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

## [curl-time]
# Provide timing information when curling a resource
function curl-time() {
  time curl -s -w @"$HOME/.vim/system-configs/curl-format/timing.txt" "$@"
}

## [mkdir-today]
#  Makes a directory named the current date in YYYY-MM-DD formate
function mkdir-today() {
  mkdir "$(date '+%Y-%m-%d')"
}

function ffb() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

