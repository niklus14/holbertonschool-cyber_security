#!/bin/bash
LOG_FILE="auth.log"
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE" | grep "sshd" | awk '{for(i=5;i<=NF;i++) print $i}' | sort | uniq -c | sort -nr
else
    echo "Log file not found!"
    exit 1
fi
