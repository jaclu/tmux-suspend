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

set_options_for_suspended_state() {
  local -r escaped_delim="${RANDOM}${RANDOM}${RANDOM}"

  local _options="${1#,}"
  _options="${_options//\\,/${escaped_delim}}"
  IFS=, read -ra options <<< "${_options}"

  local flags=""
  local name=""
  local value=""

  local resumed_options=""
  for item in "${options[@]}"; do
    if [[ -z "$(echo "${item}" | xargs)" ]]; then
      continue
    fi

    name="$(echo "${item%%:*}" | xargs)"
    item="${item#*:}"
    flags="${item%%:*}"
    value="${item#*:}"
    value="${value//${escaped_delim}/,}"

    has_value="$($TMUX_BIN show-options -qv${flags} "${name}" | wc -l | xargs)"
    preserved_flags="${flags}"
    if [[ "${has_value}" = "0" ]]; then
      preserved_flags="${preserved_flags}u"
    fi
    preserved_value="$($TMUX_BIN show-options -qv${flags} "${name}")"
    resumed_options="${resumed_options},${name}:${preserved_flags}:${preserved_value//,/\\,}"

    $TMUX_BIN set-option -q${flags} "${name}" "${value}"
  done

  $TMUX_BIN set-option -q '@suspend_resumed_options' "${resumed_options}"
}

declare -r on_suspend_command="${1}"
declare -r suspended_options="${2}"

$TMUX_BIN set-option -q '@suspend_prefix' "$($TMUX_BIN show-option -qv prefix)"

$TMUX_BIN set-option -q prefix none \; set-option key-table suspended \; \
  if-shell -F '#{pane_in_mode}' 'send-keys -X cancel' \; \
  if-shell -F '#{pane_synchronized}' 'set synchronize-panes off'

set_options_for_suspended_state "${suspended_options}"

eval "${on_suspend_command}"

$TMUX_BIN refresh-client -S
