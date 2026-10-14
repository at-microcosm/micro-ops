#!/bin/sh
# Managed by Ansible (roles/plc_health)
#
# healthchecks.io ping (or /fail): checks time since most recent op
#
# /etc/plc-health.env: PLC_HEALTH_URL, PLC_HEALTH_MAX_LAG (seconds),
# PLC_HEALTH_PING_URL
set -u

failed=1
if ! health=$(curl -fsS -m 10 "$PLC_HEALTH_URL" 2>&1); then
    report="no answer from $PLC_HEALTH_URL: $health"
else
    ts=$(printf '%s' "$health" | jq -r '.lastCommittedOpTime // empty')
    if [ -z "$ts" ]; then
        report="no lastCommittedOpTime (nothing committed yet?): $health"
    elif ! op_s=$(date -d "$ts" +%s); then
        report="can't parse lastCommittedOpTime: $ts"
    else
        lag=$(( $(date +%s) - op_s ))
        if [ "$lag" -gt "$PLC_HEALTH_MAX_LAG" ]; then
            report="lagging: last op $ts, ${lag}s ago (max ${PLC_HEALTH_MAX_LAG}s)"
        else
            report="ok: last op $ts, ${lag}s ago"
            failed=0
        fi
    fi
fi

url="$PLC_HEALTH_PING_URL"
if [ "$failed" -ne 0 ]; then
    url="$url/fail"
fi

printf '%s\n' "$report"

# try to report (with a couple retries on the actual request)
if ! printf '%s\n' "$report" | curl -fsS -m 10 --retry 3 --data-binary @- -o /dev/null "$url?create=1"; then
    echo "failed to ping healthchecks.io" >&2
    exit 2
fi

# script's own success is just whether it could report to healtchecks.io.
# (systemd faild unit monitor finds error exits, avoid duplicate alerts)
exit 0
