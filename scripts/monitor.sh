#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./monitor.sh <service_name>"
    exit
fi

SERVICE=$1

echo "Checking $SERVICE"

STATE=$(systemctl is-active "$SERVICE")

if [ "$STATE" = "active" ]; then
    echo "Service $SERVICE is running"
else
    echo "Service $SERVICE isn't running"
    echo "The last 10 lines of the log for $SERVICE"
    journalctl -u "$SERVICE" -n 10 --no-pager
fi

echo "Checking the number of errors"

if [ -f /var/log/syslog ]; then
    TIME_HOUR_AGO=$(date -d "-1 hour" '+%Y-%m-%dT%H:%M:%S')
    ERRORS=$(grep -i "error" /var/log/syslog | awk -v iso="$TIME_HOUR_AGO" '$1 >= iso {count++} END {print count+0}')
    echo "Found $ERRORS error(s) in /var/log/syslog in the last hour"
else
    echo "Couldn't find file /var/log/syslog"
fi
