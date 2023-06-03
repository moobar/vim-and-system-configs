#!/bin/bash


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
