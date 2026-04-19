#!/bin/bash
LOG_FILE="dmesg"
if [ -f "$LOG_FILE" ]; then
    grep "Linux version" "$LOG_FILE"
else
    echo "dmesg file not found!"
    exit 1
fi
