#!/bin/bash

metrics_file="/var/lib/nginx/html/metrics/metrics.prom"
mountpoint="/"   

ensure_dir() {
    local d; d="$(dirname "$metrics_file")"
    mkdir -p "$d"
}

# считываем необходимые строки о cpu в /proc/stat
cpu_usage_percent() {
    # u1 - user time, n1 - nice time, s1 - system time, i1 - idle time, w1 - IOWait time, irq1 - IRQ time, sirq1 - SoftIRQ time, st1 - steal time, _ _ ignore
    read -r u1 n1 s1 i1 w1 irq1 sirq1 st1 _ _ < <(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' /proc/stat)
    sleep 1
    read -r u2 n2 s2 i2 w2 irq2 sirq2 st2 _ _ < <(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' /proc/stat)
    # idle1, idle2 - общее время простоя
    idle1=$((i1 + w1));   idle2=$((i2 + w2))
    # non1, non2 - общее время работы CPU
    non1=$((u1 + n1 + s1 + irq1 + sirq1 + st1))
    non2=$((u2 + n2 + s2 + irq2 + sirq2 + st2))
    # простой + работа
    tot1=$((idle1 + non1)); tot2=$((idle2 + non2))
    # разница между измерениями
    totd=$((tot2 - tot1));  idld=$((idle2 - idle1))
    # (общее время - время простоя)/общее время * 100%
    awk -v t="$totd" -v i="$idld" 'BEGIN{ printf("%.2f\n", (t>0)?(100*(t-i)/t):0) }'
}

mem_bytes() {
    # /:/ -  регулярка
    awk 'BEGIN{t=a=0}
         /MemTotal:/     {t=$2*1024} 
         /MemAvailable:/ {a=$2*1024}
         END{print t, a}' /proc/meminfo
}

disk_bytes() {
    # в байтах все и доступная память
    df -B1 --output=size,avail "$1" | awk 'NR==2{print $1, $2}'
}

write_metrics_once() {
    local tmp; tmp="$(mktemp)"
    local cpu mem_t mem_a d_tot d_free

    cpu="$(cpu_usage_percent)"
    read -r mem_t mem_a < <(mem_bytes)
    read -r d_tot d_free < <(disk_bytes "$mountpoint")

    {
        echo "# HELP my_cpu_usage_percent CPU usage in percent"
        echo "# TYPE my_cpu_usage_percent gauge"
        echo "my_cpu_usage_percent ${cpu}"

        echo
        echo "# HELP my_mem_total_bytes Total memory in bytes"
        echo "# TYPE my_mem_total_bytes gauge"
        echo "my_mem_total_bytes ${mem_t}"

        echo
        echo "# HELP my_mem_available_bytes Available memory in bytes"
        echo "# TYPE my_mem_available_bytes gauge"
        echo "my_mem_available_bytes ${mem_a}"

        echo
        echo "# HELP my_disk_total_bytes Total disk space in bytes"
        echo "# TYPE my_disk_total_bytes gauge"
        echo "my_disk_total_bytes{mount=\"${mountpoint}\"} ${d_tot}"

        echo
        echo "# HELP my_disk_free_bytes Free disk space in bytes"
        echo "# TYPE my_disk_free_bytes gauge"
        echo "my_disk_free_bytes{mount=\"${mountpoint}\"} ${d_free}"
    } >"$tmp"

    mv -f "$tmp" "$metrics_file"
    chmod 644 "$metrics_file"
}