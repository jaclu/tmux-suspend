#!/usr/bin/env bash

set -e

#
#  I use an env var TMUX_BIN to point at the used tmux, defined in my
#  tmux.conf, in order to pick the version matching the server running,
#  or when the tmux bin is in fact tmate :)
#  If not found, it is set to whatever is in PATH, so should have no negative
#  impact. In all calls to tmux I use $TMUX_BIN instead in the rest of this
#  plugin.
#
[ -z "$TMUX_BIN" ] && TMUX_BIN="tmux"

declare -r CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux_option() {
  local -r option=$($TMUX_BIN show-option -gqv "$1")
  local -r fallback="$2"
  echo "${option:-$fallback}"
}

declare -r key_config='@suspend_key'
declare -r suspended_options_config='@suspend_suspended_options'
declare -r on_resume_command_config='@suspend_on_resume_command'
declare -r on_suspend_command_config='@suspend_on_suspend_command'

declare -r default_suspended_options=" \
  @mode_indicator_custom_prompt:: ---- , \
  @mode_indicator_custom_mode_style::bg=brightblack\,fg=black \
"
declare -r default_on_resume_command=""
declare -r default_on_suspend_command=""

init_tmux_suspend() {
  local -r KEY=$(tmux_option "$key_config" "F12")
  local -r suspended_options=$(tmux_option "$suspended_options_config" "$default_suspended_options")
  local -r on_resume_command=$(tmux_option "$on_resume_command_config" "$default_on_resume_command")
  local -r on_suspend_command=$(tmux_option "$on_suspend_command_config" "$default_on_suspend_command")

  $TMUX_BIN bind -Troot "$KEY" run-shell "$CURRENT_DIR/scripts/suspend.sh \"$on_suspend_command\" \"$suspended_options\""
  $TMUX_BIN bind -Tsuspended "$KEY" run-shell "$CURRENT_DIR/scripts/resume.sh \"$on_resume_command\""
}

init_tmux_suspend
