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
    #function clean_compile() {
    #  if [[ -n "$project_name" ]]; then
    #    echo "Compiling project: $project_name"
    #    mvn clean compile -pl ":$project_name" -am
    #  else
    #    echo "Compiling project"
    #    mvn clean compile
    #  fi
    #}
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

function mvn-clean-install-skipTests() {
  mvn clean install -DskipTests "$@"
}

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

function mvn-find-runtime-dependencies() {
  if test ! -t 0; then
    cat | grep -F ':jar' | grep runtime | awk '{print $NF}' | sort | uniq -c
  else
    mvn dependency:tree "$@" | grep -F ':jar' | grep -F ':runtime' | awk '{print $NF}' | sort | uniq -c
  fi
}

function get-app-version() {
  xq -x '/project/version' "$(git rev-parse --show-toplevel)/pom.xml"
}

function rc-generate() {
  local RC_NUMBER=
  local APP_SNAPSHOT_VERSION=
  local APP_VERSION=
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--rc)
        local RC_NUMBER="$2"
        shift
        shift
        ;;
      *)
        echo "Invalid argument: $1"
        return 1
        ;;
    esac
  done

  if [[ -z "$RC_NUMBER" ]]; then
    echo "Must provide a release candidate number as rcNUMBER"
    echo "use flag [-r|--rc] to provide the release candidate number"
    return 1
  fi
  APP_SNAPSHOT_VERSION="$(get-app-version)"
  APP_VERSION="${APP_SNAPSHOT_VERSION//-SNAPSHOT/}"

  echo "About to run:"
  cat <<EOM
  mvn -Dcheckstyle.skip -Dfindbugs.skip=true -Dmaven.test.skip=true -DskipTests -Darguments="-DskipTests -Dcheckstyle.skip -DgenerateClientJs" release:prepare  -DreleaseVersion="${APP_VERSION}.${RC_NUMBER}" -DdevelopmentVersion="${APP_SNAPSHOT_VERSION}"
EOM

  read -r -p "Are you sure you want to continue? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 1
  fi

  mvn -Dcheckstyle.skip -Dfindbugs.skip=true -Dmaven.test.skip=true -DskipTests -Darguments="-DskipTests -Dcheckstyle.skip -DgenerateClientJs" release:prepare  -DreleaseVersion="${APP_VERSION}.${RC_NUMBER}" -DdevelopmentVersion="${APP_SNAPSHOT_VERSION}"
}

function rc-release() {
  echo "About to run:"
  cat <<EOM
  mvn -Darguments="-Dfindbugs.skip=true -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip -DgenerateClientJs" -Dmaven.javadoc.skip=true -DskipTests -Dcheckstyle.skip release:perform
EOM

  read -r -p "Are you sure you want to continue? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 1
  fi
  mvn -Darguments="-Dfindbugs.skip=true -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip -DgenerateClientJs" -Dmaven.javadoc.skip=true -DskipTests -Dcheckstyle.skip release:perform
}

function load () {
	open -na "IntelliJ IDEA.app" --args ~/forge/all-repos/"${1}"
}

function intellij() {
  (
    if [[ -n $1 ]]; then
      open -na "IntelliJ IDEA.app" --args ~/forge/all-repos/"$1"
    else
      if cd "$(git rev-parse --show-toplevel)"; then
        if [[ -f pom.xml ]]; then
          open -na "IntelliJ IDEA.app" --args .
        else
          echo "Not a java repo. Not opening IntelliJ"
        fi
      fi
    fi
  )
}

function generate-dto-from-proto() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: generate-dto-from-proto <proto-file> <output-directory>"
    return 1
  fi
  local PROTO_FILE="$1"
  local OUTPUT_DIRECTORY="$2"

  ~/.vim/system-configs/python-scripts/java-generator-code/proto_to_java_dto.py \
    "${PROTO_FILE}" \
    "${OUTPUT_DIRECTORY}"
}



function ffjava() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

