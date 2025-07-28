#!/bin/bash

LOGFILE="/var/log/syslog"
OUTPUTFILE="dhcp_macs.txt"

update_entry() {
  local time="$1"
  local mac="$2"
  local ip="$3"

  # Check if the exact line already exists (time, mac, ip)
  if grep -Fxq "$time $mac $ip" "$OUTPUTFILE" 2>/dev/null; then
    # Line already exists, do nothing
    return
  fi

  # Check if an entry for this MAC exists with a different time or IP
  if grep -q " $mac " "$OUTPUTFILE" 2>/dev/null; then
    # Update the existing entry (replace whole line containing the MAC)
    sed -i "/ $mac /c\\$time $mac $ip" "$OUTPUTFILE"
  else
    # New entry, append to file
    echo "$time $mac $ip" >> "$OUTPUTFILE"
  fi
}

tail -Fn0 "$LOGFILE" | while read -r line; do
  if [[ "$line" == *"dnsmasq-dhcp"* ]]; then
    # Extract timestamp (fields 1 and 2)
    time=$(echo "$line" | awk '{print $1, $2}')

    # Extract MAC address (last match of MAC pattern)
    mac=$(echo "$line" | grep -oE '([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}' | tail -1)

    # Extract IP address (first IPv4)
    ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

    # Only process if valid MAC found
    if [[ "$mac" =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]]; then
      update_entry "$time" "$mac" "$ip"
    fi
  fi
done
