#!/bin/sh
# One-shot sample. The QML service restarts this only while a stats widget is loaded.

read -r cpu_line < /proc/stat || exit 1
set -- $cpu_line
user=${2:-0}
nice=${3:-0}
system=${4:-0}
idle=${5:-0}
iowait=${6:-0}
irq=${7:-0}
softirq=${8:-0}
steal=${9:-0}

idle_all=$((idle + iowait))
total=$((user + nice + system + idle + iowait + irq + softirq + steal))

mem_total=0
mem_avail=0
while read -r key val _; do
    case $key in
        MemTotal:) mem_total=$val ;;
        MemAvailable:) mem_avail=$val ;;
    esac
done < /proc/meminfo

ram=0
if [ "$mem_total" -gt 0 ]; then
    ram=$(( (mem_total - mem_avail) * 100 / mem_total ))
fi

temp_c=-1

read_best() {
    best=0
    dir=$1
    for input in "$dir"/temp*_input; do
        [ -r "$input" ] || continue
        v=$(cat "$input" 2>/dev/null) || continue
        case $v in
            ''|*[!0-9]*) continue ;;
        esac
        if [ "$v" -gt "$best" ]; then
            best=$v
        fi
    done
    if [ "$best" -gt 1000 ] && [ "$best" -lt 125000 ]; then
        temp_c=$((best / 1000))
        return 0
    fi
    return 1
}

found=0
for dir in /sys/class/hwmon/hwmon*; do
    [ -r "$dir/name" ] || continue
    name=$(cat "$dir/name" 2>/dev/null) || continue
    case $name in
        coretemp|k10temp|zenpower|cpu_thermal) ;;
        *) continue ;;
    esac
    if read_best "$dir"; then
        found=1
        break
    fi
done

if [ "$found" -eq 0 ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        [ -r "$zone/type" ] || continue
        [ -r "$zone/temp" ] || continue
        type=$(cat "$zone/type" 2>/dev/null) || continue
        case $type in
            x86_pkg_temp|k10temp|cpu-thermal|acpitz) ;;
            *) continue ;;
        esac
        v=$(cat "$zone/temp" 2>/dev/null) || continue
        case $v in
            ''|*[!0-9]*) continue ;;
        esac
        if [ "$v" -gt 1000 ] && [ "$v" -lt 125000 ]; then
            temp_c=$((v / 1000))
            break
        fi
    done
fi

printf '%s %s %s %s\n' "$idle_all" "$total" "$ram" "$temp_c"
