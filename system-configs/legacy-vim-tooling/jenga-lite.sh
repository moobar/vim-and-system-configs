#!/usr/bin/env bash

# This script was tested on Debian stretch
# Prerequistis: inotify
# Debian: sudo apt-get install inotify-tools


# TODO(sagar): the only useful thing here is the inotify section at line :58
#     I should purge all this at some point in the near future.


# shutdown()
# {
#   echo ""
#   echo "Exiting... 'JENGA'"
#   exit 0
# }
#
#
# # TODO sagar: Maybe change this to take the amount of time, as a parameter,
# # else default to 1 second
# wait_1_second() {
#   now=$(date '+%s')
#   last=$1
#
#   diff=$(($now - $last))
#   [[ $diff -gt 1 ]] && return
# }
#
# # This apparently is a little brittle. Dune doesn't like exe files in
# # the bin (and maybe lib?) directory. Maybe I shouldn't copy the binaries and
# # just leave them in the _build/ directory
# copy_binaries_to_root() {
#   DEFAULT_BIN_DIR="_build/default/bin"
#
#   if [[ -d "$DEFAULT_BIN_DIR" ]]; then
#     cp "$DEFAULT_BIN_DIR"/*.exe .
#   fi
# }
#
# print_successful_compile() {
#   echo "$(date -I'seconds'): "
#   echo "Successfully built! HUZZAH! ;)"
# }
#
# function jenga-lite() {
#   echo "Starting 'JENGA' ;)"
#
#   trap shutdown 2
#   last_run=0
#
#   # Run dune immediately on startup.
#   dune build
#   if [[ $? == 0 ]]; then
#     print_successful_compile
#   fi
#
#   inotifywait -m -r -e create,modify,close_write --format '%w%f' . 2> /dev/null| while read FILE
#   do
#     if [[ $FILE == *".ml" || $FILE == *".mli" ||
#           $FILE == */"jbuild" || $FILE == "jbuild" ||
#           $FILE == */"dune" || $FILE == "dune" ]]; then
#       if wait_1_second $last_run; then
#         dune build
#         if [[ $? == 0 ]]; then
#           print_successful_compile
#           # 2018-11-04: Yeah, commenting this out, otherwise dune clean leaves artifacts
#           #copy_binaries_to_root
#         fi
#         last_run=$(date '+%s')
#       fi
#     fi
#   done
# }
