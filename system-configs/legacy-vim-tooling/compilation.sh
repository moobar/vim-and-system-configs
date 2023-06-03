#!/bin/bash

## Splits your windows into three panes. One large vertical pane on the left and two smaller panes
#  on the right. The left side is meant for code development and the right is for terminal usage and
#  compilation. [compile-workspace] will generate a jbuid for you based on the name of the feature or
#  what files have been checked in to the feature, or locally being worked on. see [create-jbuild]
#
#  left pane         : Meant for writing your ocaml code
#  upper right pane  : Quick access to a terminal
#  bottom right pane : Jenga/compilation status.
function compile-workspace() {
  if [[ -z "$TMUX" ]]; then
    echo "This command only works in tmux"
    return 1
  fi

  BOTTOM_RIGHT_HEIGHT=$(( "$(tmux display -p '#{window_height}')" / 5 ))
  # BOTTOM_RIGHT_WIDTH=$(expr $(tmux display -p '#{window_width}') / 2)

  tmux split-window -h
  tmux split-window -v

  tmux select-pane -t 0
  tmux resize-pan -t 2 -y "$BOTTOM_RIGHT_HEIGHT"
  tmux send-keys -t 1 "cd ${PWD}" C-m
  tmux send-keys -t 2 "cd ${PWD}" C-m
  # tmux send-keys -t 2 "dune build --watch" C-m
}

# ## Runs dune clean, but also removes all .merlin files. This is useful for situations where for
# #  some reason dune has built old .merlin artifacts and the newer style artifacts
# function clean-workspaces() {
#   dune clean && find . | grep \.merlin | xargs -n1 rm
# }

alias cw='compile-workspace'
