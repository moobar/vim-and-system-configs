#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## TODO: This is still a wip
function mvn-watch() {

  (
    # Define the directory to watch
    local watch_directory=""
    local project_name=""
    local batch_time_period=5
    local last_change=0
    local lock=false

    if [[ -z "$1" ]]; then
      watch_directory="$(pwd)"
    else
      if [[ ${1:0:1} == "/" ]]; then
        watch_directory="$1"
      else
        watch_directory="$(pwd)/$1"
      fi
    fi

    if [[ -n "$2" ]]; then
      project_name="$2"
    fi

    cd "$(git rev-parse --show-toplevel)" || true

    function clean_compile() {
      if [[ -n "$project_name" ]]; then
        echo "Compiling project: $project_name"
        mvn clean compile -pl ":$project_name" -am
      else
        echo "Compiling project"
        mvn clean compile
      fi
    }

    # Define the command to run when a change is detected
    function on_change_command() {
      echo "Batched events, recompiling"
      # Add your custom commands here
      if [[ -n "$project_name" ]]; then
        echo "Compiling project: $project_name"
        mvn compile -pl ":$project_name" -am
      else
        echo "Compiling project"
        mvn compile
      fi
    }

    #echo "Running mvn clean compile on project"
    #clean_compile

    echo ""
    echo ""
    echo "Watching directory: $watch_directory"
    if [[ -n "$project_name" ]]; then
      echo "Compiling sub project: $project_name"
    fi
    # Use fswatch to monitor changes in Java and XML files
    fswatch -0 -l 1 -e ".*" -i "\\.java$" -i "pom\\.xml$" -e ".*generated-sources.*" "$watch_directory" |
      while read -r -d "" event; do
        echo "Change detected in file: $event"
        if ! $lock; then
          lock=true
          on_change_command
          last_change="$(date +%s)"
        else
          local current_time="", time_since_last_change=""
          current_time="$(date +%s)"
          time_since_last_change="$((current_time - last_change))"
          if [[ "$time_since_last_change" -gt "$batch_time_period" ]]; then
            lock=false
          fi
        fi
      done
  )
}

function generate-class-path() {
  function _generate-class-path() {
    if test ! -t 0; then
      cat \
        | grep -Eo "\.m2.*" | cut -d/ -f3- | xargs dirname | rev | sed 's/\//-/' | rev | tr '/' '.' | xargs -n1 -IJARNAME echo JARNAME.jar | grep -f <(ls server/target/lib | xargs -n1) | xargs -n1 -IJAR echo ./server/target/lib/JAR | paste -sd: -
    else
      grep -Eo "\.m2.*" "${1}" | cut -d/ -f3- | xargs dirname | rev | sed 's/\//-/' | rev | tr '/' '.' | xargs -n1 -IJARNAME echo JARNAME.jar | grep -f <(ls server/target/lib | xargs -n1) | xargs -n1 -IJAR echo ./server/target/lib/JAR | paste -sd: -
    fi
  }
  if test ! -t 0; then
    echo "$(cat | _generate-class-path):./server/target/*"
  else
    echo "$(_generate-class-path "$@"):./server/target/*"
  fi
}

#function run-jar-locally


function mvn-clean-install-quick() {
  mvn clean install -DskipTests -Ddockerfile.skip=true "$@"
}

function mvn-test() {
  mvn test -DtrimStackTrace=false -Dstdout=F "$@"
}

function mvn-classpath() {
  mvn dependency:build-classpath -pl :server \
    | grep -Fv '[INFO]' \
    | tr ':' '\n' \
    | xargs -IJAR dirname JAR \
    | sed "s|${HOME}/\.m2/repository/||g" \
    | rev \
    | sed 's|/|-|' \
    | tr '/' '.' \
    | rev \
    | xargs -IJAR echo JAR.jar
}

function jar-find-clients() {
  (
    cd "$(git rev-parse --show-toplevel)" || true

    # shellcheck disable=SC2010
    for jar in $(ls server/target/lib/com.current.*.jar | grep -v -- '\client-.*\.jar'); do
      echo JAR: "$jar"
      jar -tvf "$jar" | grep Client.class;
    done
  )
}


function ffjava() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

