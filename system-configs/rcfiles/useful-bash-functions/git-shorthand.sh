#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## [gitsbs <git ARGS>]  ->  Alias
#  git with the [delta.side-by-side] setting enabled
function gitsbs() {
  git -c delta.side-by-side=true "$@"
}

## [gitroot]  ->  Alias
#  Print the root of the repo
function gitroot() {
  git rev-parse --show-toplevel
}

## [gitbranch]  ->  Alias
#  Print the name of the current working branch
function gitbranch() {
  git rev-parse --abbrev-ref HEAD
}

## [gitroot]  ->  Shorthand
#  cd into the root of the git repo
function cdroot() {
  cd "$(gitroot)" || return
}

## [gitparentbranch]
#  Output the name of the branch that was branched off of
function gitparentbranch() {
  local PARENT=
  PARENT=$(git show-branch | grep -F '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | grep -m1 -Eo '\[(.*?)\]' | tr -d '][' | head -n1)
  if [[ -z $PARENT ]]; then
    PARENT=origin
  fi
  echo "${PARENT}"
}

## [gitbranchlog] <git log ARGS>  ->  Alias
#  Show the git log, but only for the branch
function gitbranchlog() {
  local BRANCH_PARENT
  BRANCH_PARENT=$(gitparentbranch)
  git log "${BRANCH_PARENT}"..HEAD "$@"
}

## [gitbranchdiff <git diff -w ARGS>]  ->  Shorthand
#  Show the entire diff of the branch, relative to the last branch
function gitbranchdiff() {
  local BRANCH_PARENT
  BRANCH_PARENT=$(gitparentbranch)
  git diff -w "${BRANCH_PARENT}"..HEAD "$@"
}

## [gitbranchfiles <git diff -w ARGS>]  ->  Shorthand
#  Show all the files that have been changed in the branch
function gitbranchfiles() {
  gitbranchdiff --name-only "$@" | awk '{print $0}'
}

## [gitbranchlog-origin] <git log ARGS>  ->  Alias
#  Show the git log, all the way to origin/main
function gitbranchlog-origin() {
  git log origin..HEAD "$@"
}

## [gitbranchdiff-origin <git diff -w ARGS>]  ->  Shorthand
#  Show the entire diff of the branch, relative to the parent/origin
function gitbranchdiff-origin() {
  # This is a nice way to get a commit, but it feels not necessary
  # local ORIGIN_COMMIT
  # ORIGIN_COMMIT=$(git log --reverse origin..HEAD --parents --pretty=oneline | head -1 | awk '{print $2}')
  # git diff -w "${ORIGIN_COMMIT}" HEAD "$@"

  git diff -w origin..HEAD "$@"
}

## [gitbranchfiles-origin <git diff -w ARGS>]  ->  Shorthand
#  Show all the files that have been changed in the branch
function gitbranchfiles-origin {
  gitbranchdiff-origin --name-only "$@" | awk '{print $0}'
}

## [fgitswitch]  ->  Shorthand
#  Fuzzy finder to switch branches
function fgitswitch() {
  git switch "$(_fzf_git_branches | sed 's/^origin\///')"
}

## [fgitadd]  ->  Shorthand
#  Fuzzy finder to add files to a commit
function fgitadd() {
  git add "$(_fzf_git_files)"
}

## [fgitdiff <git diff -w ARGS>]
#  Show each file individually and view its diff in a sbs fzf window
#
#  ARGS      = Can pass in any args supported by [git diff -w]
#  RETURNS  ->
#    A fzf window that shows the files populated by git diff -w
#    with the file on the left and the diff on the right.
#    CTRL-J/K and CTRL-D/U to navigated the diff
function fgitdiff() {
  if ! git status &>/dev/null; then
    echo "Only works in a git repo"
    return 1
  fi

  (
    local preview
    cd "$(git rev-parse --show-toplevel)" || return 1
    preview="git diff -w --no-ext-diff $* -- {-1} | delta --no-gitconfig -n --keep-plus-minus-markers --navigate"

    git diff -w "$@" --name-only \
    | fzf -m --ansi \
        --preview "${preview}" \
        --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
        --bind "ctrl-j:preview-down,ctrl-k:preview-up"
  )
}

## [fvimdiff <git diff -w ARGS>]
#  Show each file individually and view its diff in a sbs fzf window
#
#  ARGS      = Can pass in any args supported by [git diff -w]
#  RETURNS  ->
#    A fzf window that shows the files populated by git diff -w
#    with the file on the left and the diff on the right.
#    CTRL-J/K and CTRL-D/U to navigated the diff
#
#    The file selected will be opened in vim
function fvimdiff() {
  local FILE_TO_OPEN=
  local GIT_ROOT=
  GIT_ROOT="$(git rev-parse --show-toplevel)"

  FILE_TO_OPEN=$(
  (
  local preview=
  #preview="bat --style='${BAT_STYLE:-full}' --color=always --pager=never -- ${GIT_ROOT}/{-1}"
  preview="git diff -w --no-ext-diff $* -- ${GIT_ROOT}/{-1} | delta --no-gitconfig -n --keep-plus-minus-markers --navigate"

  git diff -w --name-only | awk '{print $1}' \
    | fzf -m --ansi \
    --preview "${preview}" \
    --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
    --bind "ctrl-j:preview-down,ctrl-k:preview-up"

  )
)

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    vim "${GIT_ROOT}/${FILE_TO_OPEN}"
  fi
}

## [fvimbranch <git diff -w ARGS>]
#  Show each file changed in a branch and view its diff in a sbs fzf window
#
#  ARGS      = Can pass in any args supported by [git diff -w]
#  RETURNS  ->
#    A fzf window that shows the files changed on the working branch
#    with the file on the left and the content (with sytnax highlighting) on the right.
#    CTRL-J/K and CTRL-D/U to navigated the file
#
#    The file selected will be opened in vim
function fvimbranch() {
  local FILE_TO_OPEN=
  local GIT_ROOT=
  GIT_ROOT="$(git rev-parse --show-toplevel)"

  FILE_TO_OPEN=$(
  (
  local preview=
  preview="bat --style='${BAT_STYLE:-full}' --color=always --pager=never -- ${GIT_ROOT}/{-1}"

  gitbranchfiles "$@" |
    fzf -m --ansi \
    --preview "${preview}" \
    --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
    --bind "ctrl-j:preview-down,ctrl-k:preview-up"
  )
)

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    vim "${GIT_ROOT}/${FILE_TO_OPEN}"
  fi
}

## [gh-download-all-repos]
#  Downloads every repo associated with an owner
#
#  Args:
#    -o|--owner [OWNER]        Repo owner name
#  Options:
#    -p|--parallel [MAX_JOBS]  Number of gh downloads to do simultanesously (Default: 20)
#    -s|--ssh                  Scheme is set to clone with ssh key (Default)
#    -h|--http                 Scheme is set to clone with http
#    -f|--filter-file [FILE]   Provide a [grep -f] compatible file for filtering which repos to get (case insensitive)
#  Example:
#    gh-download-all-repos -o moobar -h
function gh-download-all-repos() {
  local OWNER=
  local SCHEME="git@github.com:"
  local MAX_PARALLEL=20
  local FILTER_FILE=
  if [[ $# -eq 0 ]]; then
    echo "must supply -o or --owner [OWNER_NAME]"
    return 1
  fi


  while [[ $# -gt 0 ]]; do
    case $1 in
      -o|--owner)
        OWNER=$2
        shift
        shift
        ;;
      -p|--parallel)
        MAX_PARALLEL=$2
        shift
        shift
        ;;
      -s|--ssh)
        SCHEME="git@github.com:"
        shift
        ;;
      -h|--http)
        SCHEME="https://github.com/"
        shift
        ;;
      -f|--filter-file)
        FILTER_FILE=$2
        shift
        shift
        ;;
      *)
        echo "must supply -o or --owner [OWNER_NAME]"
        return 1
    esac
  done

  local repo_info=
  (
    while read -r repo_info; do
      local archive_status=, repo_name

      #printf "OWNER info: %s\n" "${owner}"
      repo_name=$(awk -F '\t' '{print $1}' <<< "${repo_info}")
      archive_status=$(awk -F '\t' '{print $3}' <<< "${repo_info}" | grep -o 'archived')
      if [[ $archive_status == "archived" ]]; then
        echo Skipping archived repo: "${SCHEME}${repo_name}"
        continue
      fi
      if [[ -n $FILTER_FILE ]]; then
        if ! echo "${repo_name}" | sed "s/${OWNER}\///" | grep -qf "${FILTER_FILE}"; then
          echo "${repo_name} was not in ${FILTER_FILE}. Skipping"
          continue
        fi
      fi
      echo Cloning repo with: git clone "${SCHEME}${repo_name}"
      git clone --quiet "${SCHEME}${repo_name}" &

      while true; do
        RUNNING=$(jobs | grep -c "Running")
        if [[ $RUNNING -le $MAX_PARALLEL ]]; then break; fi
        sleep 5
      done
    done < <( gh repo list "${OWNER}" --limit 1000 )
    echo "The vast majority of the repos were cloned. Still waiting for"
    echo Running: 'ps auxww | grep -v grep | grep "git clone --quiet"'
    # shellcheck disable=SC2009
    ps auxww | grep -v grep | grep "git clone --quiet"
    wait
    echo "Successfully cloned all repos for ${OWNER}"
  )
}

## Taken from junegunn's rcfiles ##

## [gitzip]  ->  Alias
#  archive the current HEAD as a zip
function gitzip() {
  git archive -o "$(basename "$PWD")".zip HEAD
}

## [gittgz]  ->  Alias
#  archive the current HEAD as a tgz
function gittgz() {
  git archive -o "$(basename "$PWD")".tgz HEAD
}

## [gitdiffb BRANCH1 BRANCH2]
#  Show the diff relative to two branches
function gitdiffb() {
  if [ $# -ne 2 ]; then
    echo two branch names required
    return
  fi
  git log --graph \
  --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' \
  --abbrev-commit --date=relative "$1".."$2"
}

alias gitv='git log --graph --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

## [fco]  ->  Shorthand
#  Show all refs and switch to that branch or tag
function fco() {
  local selected=
  selected=$(_fzf_git_each_ref --no-multi)
  [ -n "$selected" ] && git checkout "$selected"
}

# prco - checkout github pull request
## [prco]
#  Show all pr's for a repo and view them in a fzf window
#
#  RETURNS  ->
#    Checksout the chosen pr with [gh pr checkout]
function prco() {
  # shellcheck disable=SC2016
  FZF_DEFAULT_COMMAND='GH_FORCE_TTY=95% gh pr list --limit=1000' \
    fzf-tmux -p 80%,100% --exit-0 --ansi \
        --border vertical --info inline --reverse --header-lines 3 \
        --preview 'GH_FORCE_TTY=$FZF_PREVIEW_COLUMNS gh pr view --comments {1}' \
        --preview-window up:border-down \
        --bind 'ctrl-o:execute-silent:gh pr view --web {1}' |
    grep -o '[0-9]*' | head -1 | xargs gh pr checkout
}

function ffgit() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

