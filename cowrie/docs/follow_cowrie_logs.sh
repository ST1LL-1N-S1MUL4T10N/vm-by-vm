#!/bin/bash

# Define log file path
LOGFILE="/var/log/cowrie_service_follow.log"

# Function to continuously follow the journalctl output and update the log file
follow_logs() {
  sudo journalctl -u "user@$(id -u cowrie).service" -f --no-pager | while IFS= read -r line
  do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" | tee -a "$LOGFILE"
  done
}

# Function to interactively accept commands while logs are being followed
interactive_shell() {
  echo "Type 'exit' to stop following logs."
  while true; do
    read -rp "> " cmd
    if [[ "$cmd" == "exit" ]]; then
      echo "Stopping log follow..."
      pkill -P $$ journalctl
      exit 0
    else
      echo "Running command: $cmd"
      eval "$cmd"
    fi
  done
}

# Run both follow_logs and interactive_shell in parallel
follow_logs &
interactive_shell
