#!/bin/sh
host=$(hostname 2>/dev/null)
user=$USER
machine=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
[ -z "$machine" ] && machine="Unknown"
kernel=$(uname -r)
if [ -f /etc/os-release ]; then
    distro=$(. /etc/os-release; echo "$PRETTY_NAME")
else
    distro="Unknown"
fi
if command -v dpkg >/dev/null 2>&1; then
    packages="$(dpkg -l 2>/dev/null | grep -c '^ii') (dpkg)"
elif command -v pacman >/dev/null 2>&1; then
    packages="$(pacman -Qq 2>/dev/null | wc -l) (pacman)"
elif command -v rpm >/dev/null 2>&1; then
    packages="$(rpm -qa 2>/dev/null | wc -l) (rpm)"
else
    packages="Unknown"
fi
shell_name="${SHELL##*/}"
term="${TERM_PROGRAM:-${TERM:-Unknown}}"
uptime_secs=$(awk '{print int($1)}' /proc/uptime)
up_h=$((uptime_secs / 3600))
up_m=$(((uptime_secs % 3600) / 60))
uptime_str="${up_h}h ${up_m}m"
cpu=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
[ -z "$cpu" ] && cpu="Unknown"
load_1m=$(awk '{print $1}' /proc/loadavg)
nproc_count=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
load_pct=$(awk -v l="$load_1m" -v n="$nproc_count" 'BEGIN {printf "%.0f", (l/n) * 100 }')
load="${load_pct}%"
mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used_kb=$((mem_total_kb - mem_avail_kb))
mem_total_mb=$((mem_total_kb / 1024))
mem_used_mb=$((mem_used_kb / 1024))
gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | head -n1 | sed 's/.*: //' | sed 's/\[.*\]//; s/(rev .*)$//' | xargs)
[ -z "$gpu" ] && gpu="Unknown"
draw_box() {
    local content="$1"
    local maxlen=0
    local line
    while IFS= read -r line; do
        [ ${#line} -gt "$maxlen" ] && maxlen=${#line}
    done <<< "$content"
    local pad=$((maxlen + 2))
    local border=$(printf -- '-%.0s' $(seq 1 "$pad"))
    printf "+%s+\n" "$border"
    while IFS= read -r line; do
        printf "| %-*s |\n" "$maxlen" "$line"
    done <<< "$content"
    printf "+%s+\n" "$border"
}
opener=$(printf "%s\n" \
    "You lazy bastard!" \
    "You couldn't be bothered to  look up this info yourself and used a script to do it for you?" \
    "Your mother would be ashamed of you"
)
info=$(printf "%-55s: %s\n" \
    "Here is your imbecilic self" "$user" \
    "Here is your bitch ass host" "$host" \
    "Here is the paperweight you call a machine" "$machine" \
    "Here is your kernel held together by hope" "$kernel" \
    "Here is the distro you picked to feel special" "$distro" \
    "Here is your embarassing amount of packages" "$packages" \
    "Here is the shell you don't know a single trick in" "$shell_name" \
    "Here is your basic ass terminal" "$term" \
    "Here is the uptime proving you have no life" "$uptime_str" \
    "Here is your chud of a cpu" "$cpu" \
    "Here is your chud of a cpu taking a load" "$load" \
    "Here is your ram, consider downloading more" "${mem_used_mb}MB/${mem_total_mb}MB" \
    "Here is the gpu that cant even run doom" "$gpu"
