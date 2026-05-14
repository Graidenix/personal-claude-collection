#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  cwd=$(echo "$cwd" | sed "s|^$HOME/Developer/|Dev/|;s|^$HOME|~|")
fi

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

session_pct=$(echo "$input" | jq -r '.rate_limits.session.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
reset_str=" "
if [ -n "$five_reset" ]; then
  now=$(date +%s)
  reset_ts=$(date -d "$five_reset" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "${five_reset%%.*}" +%s 2>/dev/null || echo 0)
  if [ "$reset_ts" -gt "$now" ] 2>/dev/null; then
    diff=$((reset_ts - now))
    hours=$((diff / 3600))
    mins=$(( (diff % 3600) / 60 ))
    if [ "$hours" -gt 0 ]; then
      reset_str=" ⟳ ${hours}h${mins}m"
    else
      reset_str=" ⟳${mins}m"
    fi
  fi
fi

build_bar() {
  pct="$1"
  filled=$(printf "%.0f" "$(echo "$pct * 10 / 100" | bc -l 2>/dev/null || echo 0)")
  empty=$((10 - filled))

  # Pick color: green ≤50%, orange ≤90%, red >90%
  pct_int=$(printf "%.0f" "$pct")
  if [ "$pct_int" -le 50 ] 2>/dev/null; then
    color="\033[32m"
  elif [ "$pct_int" -le 90 ] 2>/dev/null; then
    color="\033[33m"
  else
    color="\033[31m"
  fi
  reset="\033[0m"

  bar=""
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$((i + 1))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$((i + 1))
  done
  printf "${color}%s${reset}" "$bar"
}

out=""

# Model name
out="${model}"

if [ -n "$cwd" ]; then
  out="${out}  ${cwd}"
fi

# Context window
if [ -n "$used_pct" ]; then
  bar=$(build_bar "$used_pct")
  used_fmt=$(printf "%.0f" "$used_pct")
  out="${out}  ctx ${bar} ${used_fmt}%"
fi

# Session rate limit
if [ -n "$session_pct" ]; then
  bar=$(build_bar "$session_pct")
  session_fmt=$(printf "%.0f" "$session_pct")
  out="${out}  sess ${bar} ${session_fmt}%"
fi

# 5-hour rate limit
if [ -n "$five_pct" ]; then
  bar=$(build_bar "$five_pct")
  five_fmt=$(printf "%.0f" "$five_pct")
  out="${out}  5h ${bar} ${five_fmt}%${reset_str}"
fi

# 7-day rate limit
if [ -n "$week_pct" ]; then
  bar=$(build_bar "$week_pct")
  week_fmt=$(printf "%.0f" "$week_pct")
  out="${out}  7d ${bar} ${week_fmt}%"
fi

printf "%s" "$out"
