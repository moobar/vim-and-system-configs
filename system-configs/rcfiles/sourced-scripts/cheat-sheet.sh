#!/bin/env bash

## WIP
function cheat-sheet-sh() {
  # This is kinda garbage, but i like what they were going for
  local cheat='curl -s https://cheat.sh'
  local menu='fzf'
  local pager='less -R'
  local cachefile_max_age_hours=6
  local cachefile=''

  case "$(uname -o)" in
    GNU/Linux)  cachefile='/dev/shm/cheatlist'  ;;
    Darwin)     cachefile="$TMPDIR/cheatlist" ;;
    *)          echo "Unsupported OS"; exit 1 ;;
  esac

  # Download list file and cache it.
  function listing () {
    if [ -f "${cachefile}" ]
    then
      local filedate='' now='' age_hours=''
      filedate=$(stat -f "%m" -- "${cachefile}")
      now=$(date +%s)
      age_hours=$(( (now - filedate) / 60 / 60 ))
      if [[ "${age_hours}" -gt "${cachefile_max_age_hours}" ]]
      then
        eval "${cheat}/:list" > "${cachefile}"
      fi
    else
      eval "${cheat}/:list" > "${cachefile}"
    fi
    cat -- "${cachefile}"
  }

  case "${1}" in
    '')
      if selection=$(listing | fzf)
      then
        eval "${cheat}/${selection}" | less -R
      fi
      ;;
    '-h')
      eval "${cheat}/:help" | less -R
      ;;
    '-l')
      listing
      ;;
    *)
      eval "${cheat}/${*}" | less -R
      ;;
  esac
}
