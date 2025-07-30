#!/bin/bash

# Set base log directory
LOG_DIR="/var/log/cowrie_logs"
mkdir -p "$LOG_DIR"

# Get current date for daily log rotation
DATE=$(date '+%Y-%m-%d')
LOGFILE="$LOG_DIR/cowrie_$DATE.log"

# Get user ID dynamically
COWRIE_UID=$(id -u cowrie)

# Daemon log follower function
follow_logs() {
  while true; do
    CURRENT_DATE=$(date '+%Y-%m-%d')
    LOGFILE="$LOG_DIR/cowrie_$CURRENT_DATE.log"
    sudo journalctl -u "user@${COWRIE_UID}.service" -f --no-pager | \
      while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" >> "$LOGFILE"
      done
    sleep 5
  done
}

# Check if already running
if pgrep -f "follow_logs" > /dev/null; then
  echo "Daemon is already running."
  exit 1
fi

# Start in background (detached mode)
nohup bash -c follow_logs >/dev/null 2>&1 &

echo "Cowrie log follower started in background. Logs are stored in $LOG_DIR"
