#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function _sbsSetFlag() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --sbs)
        echo "-c delta.side-by-side=true"
        return 0
        ;;
      *)
        shift # past argument
        ;;
    esac
  done

  echo ""
  return 0
}


function _removeSbsFlag() {
  local new_args=()
  for arg in "$@"; do
    if [ "$arg" != "--sbs" ]; then
      new_args+=("$arg")
    fi
  done
  echo "${new_args[@]}"
  return 0
}

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

## [vimgitconf]  ->  Shorthand
#  Edit the sourced git config file
# shellcheck disable=SC2002,SC2046
function vimgitconf() {
  local GITCONF=
  GITCONF="$(cat ~/.gitconfig | grep '^\s*path' | sed -E 's/^[^=]*= *//g')"
  vim "${GITCONF/#~/$HOME}"
}

## [gitpullmaster]
#  Pulls master from any branch. Useful for running before a merge with master
function gitpullmaster() {
  git fetch --all
  git fetch origin
  local PARENT_BRANCH=

  PARENT_BRANCH=$(gitparentbranch)
  if [[ $PARENT_BRANCH != "HEAD" ]]; then
    git fetch origin "$(gitparentbranch)":"$(gitparentbranch)"
  fi

  if git rev-parse --verify origin/master &> /dev/null; then
    git fetch origin master:master
  elif git rev-parse --verify origin/main &> /dev/null; then
    git fetch origin main:main
  else
      echo "Couldn't pull master/main"
  fi
}

### [gitparentbranchancestors]
##  Output the name of the branch that was branched off of
function gitparentancestors() {
  for branch in $(git branch -r | awk '{print $1}' | grep -v "$(gitbranch)"); do
    echo \
      "$branch" \
      "$(git log --oneline --pretty=format:"%cI %H %s" "$(git merge-base "$(git rev-parse --abbrev-ref HEAD)" "$branch")" -1)";
  done | sort -k 2
}

### [gitparentbranchcommit]
##  Output the name of the branch that was branched off of
function gitparentbranchcommit() {
  gitparentancestors | tail -1
}

### [gitparentbranch]
##  Output the name of the branch that was branched off of
function gitparentbranch() {
  local PARENT_BRANCH=
  #gitparentbranchcommit | awk '{print $1}' | cut -d/ -f2-

  PARENT_BRANCH=$(git show-branch \
    | grep -F '*' \
    | grep -v "$(git rev-parse --abbrev-ref HEAD)" \
    | grep --color=never -Eo '\[[^]]*\]' \
    | tr -d '][' \
    | head -1)

  if [[ -z $PARENT_BRANCH ]]; then
    PARENT_BRANCH="HEAD"
  fi

  echo "${PARENT_BRANCH}"
}

## [gitbranchlog] <git log ARGS>  ->  Alias
#  Show the git log, but only for the branch
#  [-p] is a useful ARG for showing the commit diff
function gitbranchlog() {
  local BRANCH_PARENT
  BRANCH_PARENT=$(gitparentbranch)
  git log "${BRANCH_PARENT}"..HEAD "$@"
}

## [gitbranchdiff <git diff -w ARGS>]  ->  Shorthand
#  Show the entire diff of the branch, relative to the last branch
function gitbranchdiff() {
  local BRANCH_PARENT=''
  BRANCH_PARENT=$(gitparentbranch)

  local SBS_FLAG='', NEW_ARGS=''
  SBS_FLAG=$(_sbsSetFlag "$@")
  NEW_ARGS=$(_removeSbsFlag "$@")

  if [[ -z ${NEW_ARGS} ]]; then
    set --
  else
    set -- "${NEW_ARGS[@]}"
  fi

  # shellcheck disable=SC2086
  git ${SBS_FLAG} diff -w "${BRANCH_PARENT}"..HEAD "$@"
}

## [gitbranchfiles <git diff -w ARGS>]  ->  Shorthand
#  Show all the files that have been changed in the branch
function gitbranchfiles() {
  gitbranchdiff --name-only "$@" | awk '{print $0}'
}

## [gitbranchlog-origin] <git log ARGS>  ->  Alias
#  Show the git log, all the way to origin/main
#  [-p] is a useful ARG for showing the commit diff
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

  local SBS_FLAG='', NEW_ARGS=''
  SBS_FLAG=$(_sbsSetFlag "$@")
  NEW_ARGS=$(_removeSbsFlag "$@")

  if [[ -z ${NEW_ARGS} ]]; then
    set --
  else
    set -- "${NEW_ARGS[@]}"
  fi

  # shellcheck disable=SC2086
  git ${SBS_FLAG} diff -w origin..HEAD "$@"
}

## [gitbranchlog-unpushed <git log @{upstream} ARGS>]  ->  Shorthand
#  Show logs for committed changes that haven't been pushed
#  [-p] is a useful ARG for showing the commit diff
function gitbranchlog-unpushed() {
  ## I think these two are the same thing
  # git log --branches --not --remotes
  # git log @{upstream}..
  ## I slightly prefer the upstream because it's clearer

  git log @{upstream}.. "$@"
}

## [git-checkout-repo-to-previous-state]  ->  Shorthand
#  Use this to stage changes from HEAD to <previous-state>, which can be a branch or commit
#  Unilike git reset, this doesn't move tip of the branch
function git-checkout-repo-to-previous-state() {
  if [[ -z $1 ]]; then
    echo "No commit/branch specified"
    return 1
  fi
  local STATE="$1"
  git checkout --no-overlay "${STATE}" "$(git rev-parse --show-toplevel)"
}

## [git-restore-repo-to-previous-state]  ->  Shorthand
#  Use this to stage changes from HEAD to <previous-state>, which can be a branch or commit
#  Unilike git reset, this doesn't move tip of the branch
#
#  This is identical to git-checkout-repo-to-previous-state, using modern git syntax
function git-restore-repo-to-previous-state() {
  if [[ -z $1 ]]; then
    echo "No commit/branch specified"
    return 1
  fi
  local STATE="$1"
  git restore --source="${STATE}" --staged --worktree "$(git rev-parse --show-toplevel)"
}

function git-restore-staged-files-all() {
  git restore --staged "$(git rev-parse --show-toplevel)"
}

## [gitpush-upstream]  ->  Shorthand
#  First time pushing a branch, use this to set the upstream
function gitpush-upstream() {
  git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)"
}

## [gitbranchfiles-origin <git diff -w ARGS>]  ->  Shorthand
#  Show all the files that have been changed in the branch
function gitbranchfiles-origin() {
  gitbranchdiff-origin --name-only "$@" | awk '{print $0}'
}

function gh-search-authored-prs() {
  gh search prs --limit=200 --state=open --author="@me"
}

function gh-search-authored-prs-json() {
  gh search prs --limit=200 --state=open --author="@me" --json assignees,author,authorAssociation,body,closedAt,commentsCount,createdAt,id,isDraft,isLocked,isPullRequest,labels,number,repository,state,title,updatedAt,url "$@" | jq -c .[]
}

function gh-search-assigned-prs() {
  gh search prs --limit=200 --state=open --assignee="@me" "$@"
}

function gh-search-assigned-prs-json() {
  gh search prs --limit=200 --state=open --assignee="@me" --json assignees,author,authorAssociation,body,closedAt,commentsCount,createdAt,id,isDraft,isLocked,isPullRequest,labels,number,repository,state,title,updatedAt,url "$@" | jq -c .[]
}

function gh-search-merged-prs() {
  gh search prs --author=@me --state closed --merged "$@"
}

function repo-name() {
  basename -s .git "$(git config --get remote.origin.url)"
}

function gh-search-prs() {
  local SEARCH_TERMS=''
  if [[ $# -eq 0 ]]; then
    SEARCH_TERMS+="author=@me is:open"
  else
    SEARCH_TERMS="$*"
  fi
  gh search prs --limit=200 "${SEARCH_TERMS}"
}

function gh-search-prs-json() {
  gh search prs --limit=200 --json assignees,author,authorAssociation,body,closedAt,commentsCount,createdAt,id,isDraft,isLocked,isPullRequest,labels,number,repository,state,title,updatedAt,url "$@" | jq -c .[]
}

function fgit-switch-localbranch() {
  git switch "$(git branch | tail -n +2 | tr -d '[:blank:]' | fzf)"
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
      local archive_status='' repo_name=''

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
    done 3< <( gh repo list "${OWNER}" --limit 1000 ) <&3

    echo "The vast majority of the repos were cloned. Still waiting for"
    echo Running: 'ps auxww | grep -v grep | grep "git clone --quiet"'
    # shellcheck disable=SC2009
    ps auxww | grep -v grep | grep "git clone --quiet"
    wait
    echo "Successfully cloned all repos for ${OWNER}"
  )
}

## [gh-pr-create]  ->  Alias
#  Runs gh pr create --fill
function gh-pr-create() {
  gh pr create --fill "$@"
}

function git-branch-jira() {
  if [[ -z $1 ]]; then
    echo "Must enter a branch name"
    return 1
  fi
  local BRANCH_NAME=$1
  local TICKET=""

  TICKET="$(acli jira workitem search --limit 100 --jql "assignee = currentUser() AND status NOT IN (Completed, \"Won't Do\", Resolved) AND sprint IN openSprints()" --json | jq -r '.[] | .key + " " + .fields.summary' | fzf --prompt="Select ticket" | cut -d' ' -f1)"
  if yn_prompt "Checkout branch ${TICKET}-${BRANCH_NAME}?"; then
    git checkout -b "${TICKET}-${BRANCH_NAME}"
  else
    echo "Manually run: git checkout -b ${TICKET}-${BRANCH_NAME}"
  fi
}

### All of these git-branch ones should be correct. But I'm not 100% familiar with git rev-list

## [git-branch-commit-history-reverse]  ->  Alias
#  Show the branch commit history in chronological order
function git-branch-commit-history-reverse() {
  # git rev-list main..HEAD, means “commits in HEAD not in main.”
  git rev-list --reverse main..HEAD
}

## [git-branch-print-history-reverse]  ->  Alias
#  Show the branch commit history in chronological order
function git-branch-print-history-reverse() {
  git rev-list --reverse main..HEAD | xargs -n1 git show -s --format='%h %ad %an %s' --date=short
}

## [git-branch-show-commit]  ->  Alias
#  Git the first commit in the branch, then find the ancestor from main
#  Probably doesnt work right when you branch off a branch, but thats okay for now
function git-branch-show-first-commit() {
  git rev-list --reverse main..HEAD | head -1
}

## [git-branch-show-first-main-ancestor]  ->  Alias
#  Git the first commit in the branch, then find the ancestor from main
#  Probably doesnt work right when you branch off a branch, but thats okay for now
function git-branch-show-first-main-ancestor() {
  git merge-base main "$(git rev-list --reverse main..HEAD | head -1)"
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

## [git-squash-branch <BRNACH-TO-SQUASH>]
#  Prints commands to squash all commits on the branch
#  CAUTION. This is a destructive operation
#
#  Positional Args:
#    [BRANCH-TO-SQUASH] -- Branch Name
#
#  RETURNS  ->
#    Commands to run if you want to rename main/master branch
function git-squash-branch() {
  if [[ -z $1 ]]; then
    echo "Must supply branch"
    return 1
  fi
  local BRANCH=$1

  # Taken from
  # https://stackoverflow.com/questions/9683279/make-the-current-commit-the-only-initial-commit-in-a-git-repository
  echo "# CAUTION. These commands will completely destroy your branch and its hitory. Proceed with caution"
  echo git checkout --orphan "${BRANCH}-squashed"
  echo git add -A                       # Add all files and commit them
  echo git commit
  echo git branch -D "${BRANCH}"        # Deletes the supplied branch
  echo git branch -m "${BRANCH}"        # Rename the current branch to the supplied branch
  echo git push -f origin "${BRANCH}"   # Force push branch to github
  echo git gc --aggressive --prune=all  # remove the old files
}

function ffgit() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

