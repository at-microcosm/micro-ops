#!/bin/sh
# Managed by Ansible (roles/cert_check)
#
# check tls certs, report to healtchecks.io. fail if they expire soon.
#
# /etc/cert-check.env: CERT_CHECK_NAMES (space-separated),
# CERT_CHECK_MIN_DAYS, CERT_CHECK_CONNECT (host:port), CERT_CHECK_PING_URL
set -u

min_secs=$((CERT_CHECK_MIN_DAYS * 86400))
report=""
failed=0

for name in $CERT_CHECK_NAMES; do
    cert=$(timeout 10 openssl s_client -connect "$CERT_CHECK_CONNECT" -servername "$name" </dev/null 2>/dev/null \
        | openssl x509 2>/dev/null)
    if [ -z "$cert" ]; then
        report="${report}${name}: no certificate served\n"
        failed=1
        continue
    fi
    end=$(printf '%s\n' "$cert" | openssl x509 -noout -enddate | cut -d= -f2)
    if printf '%s\n' "$cert" | openssl x509 -noout -checkend "$min_secs" >/dev/null; then
        report="${report}${name}: ok, expires ${end}\n"
    else
        report="${report}${name}: EXPIRES SOON, ${end}\n"
        failed=1
    fi
done

url="$CERT_CHECK_PING_URL"
if [ "$failed" -ne 0 ]; then
    url="$url/fail"
fi

printf '%b' "$report"

# try to report (with a couple retries on the actual request)
if ! printf '%b' "$report" | curl -fsS -m 10 --retry 3 --data-binary @- -o /dev/null "$url?create=1"; then
    echo "failed to ping healthchecks.io" >&2
    exit 2
fi

exit "$failed"
