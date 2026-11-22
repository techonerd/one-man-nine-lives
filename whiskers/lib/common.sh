# Whiskers plugin helpers. Sourced by every check in checks.d/.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Plugin contract (any language works, this file is only a convenience for bash):
#   <check> describe  -> one JSON object:
#        {"name": "...", "description": "...", "applies": true|false, "default_enabled": true,
#         "options": [{"key":"temp_warn","type":"int|bool|string|file","default":70,
#                      "label":"...","min":1,"max":100,"unit":"°C"}]}
#   <check> run       -> zero or more JSON lines, one per finding:
#        {"id":"disk:SERIAL","level":"ok|info|warn|error","title":"...","summary":"...",
#         "fix":"command or advice","detail":"..."}
# Options arrive as environment variables WHISKERS_OPT_<key>; private state dir is $WHISKERS_STATE.
# Write titles and summaries for a human: what happened, what it means for them, in plain words.

export LC_ALL=C
WHISKERS_STATE=${WHISKERS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/whiskers/plugins/$(basename "$0")}
mkdir -p "$WHISKERS_STATE"

emit() { # id level title summary [fix] [detail]
  jq -nc --arg id "$1" --arg level "$2" --arg title "$3" --arg summary "$4" \
         --arg fix "${5:-}" --arg detail "${6:-}" \
         '{id:$id, level:$level, title:$title, summary:$summary, fix:$fix, detail:$detail}'
}

opt() { # key default
  local v="WHISKERS_OPT_$1"
  printf '%s' "${!v:-$2}"
}

# Dispatch: call at the end of a plugin with its describe JSON in $DESCRIBE and a run() function.
plugin_main() {
  case ${1:-run} in
    describe) printf '%s\n' "$DESCRIBE" ;;
    run) run ;;
    *) echo "usage: $(basename "$0") describe|run" >&2; return 1 ;;
  esac
}

# Friendly name for a process: bundled lib/names.tsv, overridden by ~/.config/whiskers/names.tsv
_names_loaded=0
declare -A _FRIENDLY=() _MEANING=()
_load_names() {
  (( _names_loaded )) && return; _names_loaded=1
  local f k n m
  for f in "${WHISKERS_LIB:-}/names.tsv" "${WHISKERS_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/whiskers}/names.tsv"; do
    [[ -r $f ]] || continue
    while IFS=$'\t' read -r k n m; do
      [[ -z $k || $k == \#* ]] && continue
      _FRIENDLY[$k]=$n; [[ -n $m ]] && _MEANING[$k]=$m
    done < "$f"
  done
}
friendly_name() { _load_names; local k=${1:0:15}; printf '%s' "${_FRIENDLY[$1]:-${_FRIENDLY[$k]:-$1}}"; }
friendly_meaning() { _load_names; local k=${1:0:15}; printf '%s' "${_MEANING[$1]:-${_MEANING[$k]:-}}"; }
