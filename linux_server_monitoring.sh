#!/usr/bin/env bash
#
# Logs system performance using sar + disk space (df -h) + top processes
#

# === Configuration ===
LOG_DIR="/var/log"                    # or use "./logs" if you prefer local directory
SAMPLE_INTERVAL=5                     # seconds between samples
DURATION=60                           # total run time in seconds
TOP_PROCESSES=5                       # how many top CPU/MEM processes to show
SAR_SAMPLE_SECS=1                     # seconds each sar snapshot should run
# =====================

# create timestamped log filename
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="${LOG_DIR}/simple_monitor_${TIMESTAMP}.log"

HOSTNAME=$(hostname)
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Banner
{
  echo "==============================="
  echo "Monitoring started at $START_TIME on $HOSTNAME"
  echo "Interval: ${SAMPLE_INTERVAL}s, Duration: ${DURATION}s"
  echo "Using: sar, df -h, ps"
  echo "==============================="
} >> "$LOG_FILE"

ITERATIONS=$(( DURATION / SAMPLE_INTERVAL ))

# --- Functions ---

append_sar() {
  if ! command -v sar >/dev/null 2>&1; then
    echo "sar not installed (sysstat). Skipping sar section." >> "$LOG_FILE"
    return
  fi

  {
    echo
    echo ">>> SAR snapshots (${SAR_SAMPLE_SECS}s each)"
    echo "[CPU]"
    sar -u "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Memory]"
    sar -r "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Swap]"
    sar -S "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Run queue / Load]"
    sar -q "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Block I/O]"
    sar -b "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Per-disk I/O] (first 20 lines)"
    sar -d "$SAR_SAMPLE_SECS" 1 | head -n 20
    echo
    echo "[Network per interface]"
    sar -n DEV "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Network errors]"
    sar -n EDEV "$SAR_SAMPLE_SECS" 1
    echo
    echo "[Sockets]"
    sar -n SOCK "$SAR_SAMPLE_SECS" 1
  } >> "$LOG_FILE" 2>&1
}

append_disk_space() {
  {
    echo
    echo ">>> Disk space (df -h)"
    df -h -x tmpfs -x devtmpfs | awk 'NR==1{print;next} {print | "sort -k5 -hr"}'
  } >> "$LOG_FILE" 2>&1
}

append_top_processes() {
  {
    echo
    echo ">>> Top ${TOP_PROCESSES} CPU-consuming processes"
    ps -eo pid,ppid,comm,%cpu,%mem --sort=-%cpu | head -n $((TOP_PROCESSES + 1))
    echo
    echo ">>> Top ${TOP_PROCESSES} Memory-consuming processes"
    ps -eo pid,ppid,comm,%mem,%cpu --sort=-%mem | head -n $((TOP_PROCESSES + 1))
  } >> "$LOG_FILE" 2>&1
}

# --- Main Loop ---

for ((i=1; i<=ITERATIONS; i++)); do
  SAMPLE_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "\n--- Sample $i @ $SAMPLE_TIME ---" >> "$LOG_FILE"

  append_sar
  append_disk_space
  append_top_processes

  echo "-------------------------------" >> "$LOG_FILE"
  sleep "$SAMPLE_INTERVAL"
done

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
{
  echo
  echo "Monitoring ended at $END_TIME"
  echo
} >> "$LOG_FILE"

echo "Log saved to $LOG_FILE"
