
#!/usr/bin/env bash
# Claude Code status line: model name + context usage bar + daily token/cost usage.
# Reads the status line JSON payload from stdin. Requires `jq`; degrades
# gracefully (fixed defaults, no crash) if jq or expected fields are missing.

input=$(cat)

# ---- Parse everything needed from the payload in one jq call ----
IFS=$'\t' read -r model used_pct session_id session_cost \
  call_input call_output call_cache_w call_cache_r <<<"$(echo "$input" | jq -r '
    (.model.display_name // .model.id // "Claude") as $model |
    (.context_window.total_input_tokens // 0) as $tin |
    (.context_window.context_window_size // 0) as $cws |
    (.context_window.used_percentage //
      (if $cws > 0 then ($tin / $cws * 100) else 0 end)) as $pct |
    (.session_id // "unknown") as $sid |
    (.cost.total_cost_usd // null) as $scost |
    (.context_window.current_usage.input_tokens // 0) as $ci |
    (.context_window.current_usage.output_tokens // 0) as $co |
    (.context_window.current_usage.cache_creation_input_tokens // 0) as $ccw |
    (.context_window.current_usage.cache_read_input_tokens // 0) as $ccr |
    [$model, $pct, $sid, $scost, $ci, $co, $ccw, $ccr] | @tsv
  ' 2>/dev/null)"

[ -z "$model" ] && model="Claude"
[ -z "$session_id" ] && session_id="unknown"

# ---- Numeric sanitizer: validate/clamp a value, falling back to a default ----
to_int() {
  awk -v v="$1" -v d="$2" -v lo="$3" -v hi="$4" '
    BEGIN {
      if (v !~ /^-?[0-9]+([.][0-9]+)?$/) v = d
      v = int(v)
      if (v < lo) v = lo
      if (v > hi) v = hi
      printf "%d", v
    }'
}

used_pct_int=$(to_int "$used_pct" 0 0 100)
call_input=$(to_int "$call_input" 0 0 999999999)
call_output=$(to_int "$call_output" 0 0 999999999)
call_cache_w=$(to_int "$call_cache_w" 0 0 999999999)
call_cache_r=$(to_int "$call_cache_r" 0 0 999999999)
call_tokens=$(( call_input + call_output + call_cache_w + call_cache_r ))

bar_width=10
filled=$(( used_pct_int * bar_width / 100 ))
empty=$(( bar_width - filled ))
bar="$(printf '%.0s█' $(seq 1 "$filled" 2>/dev/null))$(printf '%.0s░' $(seq 1 "$empty" 2>/dev/null))"

# ---- Daily token/cost usage (persisted across invocations, resets per day) ----
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_file="$script_dir/statusline-daily-usage.json"
today=$(date +%Y-%m-%d)

# --slurpfile requires the file to exist before jq runs; jq's own try/catch
# only covers parse errors, not a missing file.
[ -f "$state_file" ] || echo '{}' > "$state_file" 2>/dev/null

new_state=$(jq -n \
  --slurpfile old "$state_file" \
  --arg today "$today" \
  --arg session "$session_id" \
  --arg session_cost_raw "$session_cost" \
  --argjson call_tokens "$call_tokens" \
  '
  (try ($old[0]) catch {}) as $o0 |
  ($o0 // {}) as $o |
  (if $session_cost_raw != "" then ($session_cost_raw | tonumber) else null end) as $session_cost |
  (if $o.date == $today then $o else {date: $today, total_cost: 0, total_tokens: 0, sessions: {}} end) as $base |
  (($base.sessions[$session].last_cost) // 0) as $last_cost |
  (if $session_cost != null then ($session_cost - $last_cost) else 0 end) as $delta_raw |
  (if $delta_raw < 0 then 0 else $delta_raw end) as $delta_cost |
  {
    date: $base.date,
    total_cost: (($base.total_cost // 0) + $delta_cost),
    total_tokens: (($base.total_tokens // 0) + $call_tokens),
    sessions: (($base.sessions // {}) + { ($session): { last_cost: (if $session_cost != null then $session_cost else $last_cost end) } })
  }
  ' 2>/dev/null)

if [ -n "$new_state" ]; then
  echo "$new_state" > "$state_file" 2>/dev/null
fi

IFS=$'\t' read -r daily_cost daily_tokens <<<"$(echo "${new_state:-{\}}" | jq -r '[(.total_cost // 0), (.total_tokens // 0)] | @tsv' 2>/dev/null)"
[ -z "$daily_cost" ] && daily_cost=0
[ -z "$daily_tokens" ] && daily_tokens=0

fmt_tokens() {
  local n
  n=$(to_int "$1" 0 0 999999999999)
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN{printf "%.1fM", n/1000000}'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN{printf "%.1fk", n/1000}'
  else
    echo "$n"
  fi
}

tokens_fmt=$(fmt_tokens "$daily_tokens")
cost_fmt=$(awk -v c="$daily_cost" 'BEGIN{printf "%.2f", c+0}' 2>/dev/null)
[ -z "$cost_fmt" ] && cost_fmt="0.00"

printf '\033[2m%s\033[0m \033[2m|\033[0m \033[2m[%s] %s%%\033[0m \033[2m|\033[0m \033[2mToday: %s tok, $%s\033[0m' \
  "$model" "$bar" "$used_pct_int" "$tokens_fmt" "$cost_fmt"
