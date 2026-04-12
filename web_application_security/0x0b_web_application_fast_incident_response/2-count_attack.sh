#!/bin/bash
LOGFILE="logs.txt"
attacker_ip=$(awk '{print $1}' "$LOGFILE" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')
count=$(grep -c "^$attacker_ip" "$LOGFILE")
echo "$count"
