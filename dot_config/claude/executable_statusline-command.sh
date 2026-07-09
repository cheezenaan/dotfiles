#!/usr/bin/env bash
# Claude Code Status Line - 3-line display with rate limit info
# Reads JSON from stdin, fetches usage API, outputs ANSI-colored status

set -euo pipefail

# ── Colors (ANSI 24-bit true color) ──────────────────────────────
GREEN='\033[38;2;151;201;195m'   # #97C9C3
YELLOW='\033[38;2;229;192;123m'  # #E5C07B
RED='\033[38;2;224;108;117m'     # #E06C75
GRAY='\033[38;2;74;88;92m'       # #4A585C
RESET='\033[0m'

# ── Read stdin JSON ──────────────────────────────────────────────
INPUT=$(cat)

MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Unknown"')
CONTEXT_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# ── Git info ─────────────────────────────────────────────────────
if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
  if [ -z "$BRANCH" ]; then
    BRANCH=$(git -C "$CWD" describe --always 2>/dev/null || echo "detached")
  fi
  DIFF_STAT=$(git -C "$CWD" diff --numstat HEAD 2>/dev/null | awk '{a+=$1;d+=$2}END{if(NR>0)printf "+%d/-%d",a,d; else print "+0/-0"}')
  [ -z "$DIFF_STAT" ] && DIFF_STAT="+0/-0"
  # Ahead/behind upstream
  UPSTREAM=""
  if AB=$(git -C "$CWD" rev-list --left-right --count HEAD...@{u} 2>/dev/null); then
    AHEAD=$(echo "$AB" | awk '{print $1}')
    BEHIND=$(echo "$AB" | awk '{print $2}')
    [ "$AHEAD" -gt 0 ] && UPSTREAM="⬆️ ${AHEAD}"
    [ "$BEHIND" -gt 0 ] && UPSTREAM="${UPSTREAM} ⬇️ ${BEHIND}"
  fi
else
  BRANCH="-"
  DIFF_STAT="+0/-0"
  UPSTREAM=""
fi

# ── Rate limit: fetch or use cache ───────────────────────────────
CACHE="/tmp/claude-usage-cache.json"
CACHE_TTL=360
NOW=$(date +%s)

fetch_usage() {
  # Returns: JSON on stdout + return 0 on success, empty + return 1 on failure
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | xxd -r -p | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || true
  if [ -z "$token" ]; then
    return 1
  fi
  local resp
  resp=$(curl -s --fail --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || true
  # Validate response has expected structure
  if echo "$resp" | jq -e '.five_hour' >/dev/null 2>&1; then
    # Atomic write: tmpfile + mv
    local tmpfile
    tmpfile=$(mktemp "${CACHE}.XXXXXX" 2>/dev/null) || tmpfile="${CACHE}.tmp"
    echo "$resp" | jq -c "{five_hour,seven_day,fetched_at:$NOW}" > "$tmpfile" && mv -f "$tmpfile" "$CACHE"
    echo "$resp"
    return 0
  else
    return 1
  fi
}

# ── Load cache + stale-while-revalidate ──────────────────────────
USAGE=""
STALE=0

if [ -f "$CACHE" ]; then
  CACHED_AT=$(jq -r '.fetched_at // 0' "$CACHE" 2>/dev/null || echo 0)
  AGE=$((NOW - CACHED_AT))
  USAGE=$(cat "$CACHE")
  if [ "$AGE" -ge "$CACHE_TTL" ]; then
    # Cache is stale — try to refresh
    if FRESH=$(fetch_usage); then
      USAGE="$FRESH"
      STALE=0
    else
      # fetch failed — keep stale cache
      STALE=1
    fi
  fi
else
  # No cache at all — must fetch
  if FRESH=$(fetch_usage); then
    USAGE="$FRESH"
  else
    # No cache + fetch failed — signal N/A
    USAGE=""
  fi
fi

if [ -z "$USAGE" ]; then
  # Complete failure: no cache, no API
  FIVE_PCT="N/A"
  FIVE_RESET=""
  SEVEN_PCT="N/A"
  SEVEN_RESET=""
else
  FIVE_PCT=$(echo "$USAGE" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
  FIVE_RESET=$(echo "$USAGE" | jq -r '.five_hour.resets_at // ""')
  SEVEN_PCT=$(echo "$USAGE" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
  SEVEN_RESET=$(echo "$USAGE" | jq -r '.seven_day.resets_at // ""')
fi

# ── Helper: color by percentage ──────────────────────────────────
color_for_pct() {
  local pct=$1
  if [ "$pct" = "N/A" ]; then
    echo "$GRAY"
    return
  fi
  # clamp to 0-100
  if [ "$pct" -lt 0 ]; then pct=0; fi
  if [ "$pct" -gt 100 ]; then pct=100; fi
  if [ "$pct" -lt 50 ]; then
    echo "$GREEN"
  elif [ "$pct" -lt 80 ]; then
    echo "$YELLOW"
  else
    echo "$RED"
  fi
}

# ── Helper: progress bar (10 segments) ───────────────────────────
progress_bar() {
  local pct=$1
  if [ "$pct" = "N/A" ]; then
    echo "▱▱▱▱▱▱▱▱▱▱"
    return
  fi
  # clamp to 0-100
  if [ "$pct" -lt 0 ]; then pct=0; fi
  if [ "$pct" -gt 100 ]; then pct=100; fi
  local filled=$((pct / 10))
  local empty=$((10 - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="▰"; done
  for ((i=0; i<empty; i++)); do bar+="▱"; done
  echo "$bar"
}

# ── Helper: format reset time in Asia/Tokyo ──────────────────────
format_reset() {
  local iso_time=$1
  local label=$2
  if [ -z "$iso_time" ] || [ "$iso_time" = "null" ]; then
    echo ""
    return
  fi
  # Parse UTC ISO time to epoch, then format in Asia/Tokyo
  local stripped="${iso_time%%.*}"  # Remove fractional seconds
  local epoch
  epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$stripped" "+%s" 2>/dev/null || echo "")
  if [ -z "$epoch" ]; then
    echo "Resets ? (Asia/Tokyo)"
    return
  fi
  # Round up to next minute
  local remainder=$((epoch % 60))
  if [ "$remainder" -gt 0 ]; then
    epoch=$((epoch + 60 - remainder))
  fi
  if [ "$label" = "5h" ]; then
    # 24h format: "14:00"
    local formatted
    formatted=$(TZ=Asia/Tokyo date -r "$epoch" "+%H:%M" 2>/dev/null || echo "?")
    echo "${formatted} JST"
  else
    # "3/6 12:00"
    local formatted
    formatted=$(TZ=Asia/Tokyo date -r "$epoch" "+%-m/%-d %H:%M" 2>/dev/null || echo "?")
    echo "${formatted} JST"
  fi
}

# ── Build output ─────────────────────────────────────────────────
SEP="${GRAY}│${RESET}"
CTX_COLOR=$(color_for_pct "${CONTEXT_PCT%%.*}")
CTX_INT=$(printf "%.0f" "$CONTEXT_PCT" 2>/dev/null || echo "0")

# Line 1: Model │ Context % │ +added/-removed │ branch │ ahead/behind
UPSTREAM_FMT=""
[ -n "$UPSTREAM" ] && UPSTREAM_FMT=" ${SEP} ${UPSTREAM}"
LINE1="🦀 ${MODEL} ${SEP} 📊 ${CTX_COLOR}${CTX_INT}%${RESET} ${SEP} ✏️ ${DIFF_STAT} ${SEP} 🔀 ${BRANCH}${UPSTREAM_FMT}"

# Line 2: 5h rate limit
FIVE_COLOR=$(color_for_pct "$FIVE_PCT")
FIVE_BAR=$(progress_bar "$FIVE_PCT")
FIVE_RESET_FMT=$(format_reset "$FIVE_RESET" "5h")
STALE_MARK=""
if [ "$STALE" -eq 1 ]; then STALE_MARK=" ${GRAY}(stale)${RESET}"; fi
LINE2="⏱️ 5h  ${FIVE_COLOR}${FIVE_BAR}${RESET}  ${FIVE_COLOR}${FIVE_PCT}%${RESET}  ${FIVE_RESET_FMT}${STALE_MARK}"

# Line 3: 7d rate limit
SEVEN_COLOR=$(color_for_pct "$SEVEN_PCT")
SEVEN_BAR=$(progress_bar "$SEVEN_PCT")
SEVEN_RESET_FMT=$(format_reset "$SEVEN_RESET" "7d")
LINE3="📅 7d  ${SEVEN_COLOR}${SEVEN_BAR}${RESET}  ${SEVEN_COLOR}${SEVEN_PCT}%${RESET}  ${SEVEN_RESET_FMT}"

# Output
printf '%b\n%b\n%b' "$LINE1" "$LINE2" "$LINE3"
