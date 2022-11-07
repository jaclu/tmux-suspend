#!/usr/bin/env bash

set -eu

#
#  I use an env var TMUX_BIN to point at the used tmux, defined in my
#  tmux.conf, in order to pick the version matching the server running,
#  or when the tmux bin is in fact tmate :)
#  If not found, it is set to whatever is in PATH, so should have no negative
#  impact. In all calls to tmux I use $TMUX_BIN instead in the rest of this
#  plugin.
#
[ -z "$TMUX_BIN" ] && TMUX_BIN="tmux"

set_options_for_resumed_state() {
  local -r escaped_delim="${RANDOM}${RANDOM}${RANDOM}"

  local _options="${1#,}"
  _options="${_options//\\,/${escaped_delim}}"
  IFS=, read -ra options <<< "${_options}"

  local flags=""
  local name=""
  local value=""

  for item in "${options[@]}"; do
    name="$(echo "${item%%:*}" | xargs)"
    item="${item#*:}"
    flags="${item%%:*}"
    value="${item#*:}"
    value="${value//${escaped_delim}/,}"

    $TMUX_BIN set-option -q${flags} "${name}" "${value}"
  done
}

declare -r on_resume_command="${1}"
declare -r resumed_options="$($TMUX_BIN show-option -qv '@suspend_resumed_options')"

declare -r prefix="$($TMUX_BIN show-option -qv '@suspend_prefix')"
declare prefix_flags=""
if [[ -z ${prefix} ]]; then
  prefix_flags="u"
fi

eval "${on_resume_command}"

set_options_for_resumed_state "${resumed_options}"

$TMUX_BIN set-option -q${prefix_flags} prefix "${prefix}" \; set-option -u key-table

$TMUX_BIN refresh-client -S
