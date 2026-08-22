#!/bin/sh
set -eu

apk add --no-cache curl >/dev/null

URL="https://pihole.morrisons.site/admin/"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" != "200" ]; then
  echo "FAIL: expected status 200 from $URL, got $STATUS"
  exit 1
fi

echo "PASS: $URL returned 200"

# doubleclick.net is on virtually every default Pi-hole blocklist -- query
# Pi-hole directly (it's hostNetwork, no DNS Service exists) and confirm it
# comes back blocked rather than resolving normally. Tolerant of either
# common blocking mode: NULL (0.0.0.0) or NXDOMAIN.
AD_DOMAIN="doubleclick.net"
RESULT=$(nslookup "$AD_DOMAIN" "$PIHOLE_ADDR" 2>&1 || true)

if echo "$RESULT" | grep -q "0\.0\.0\.0"; then
  echo "PASS: $AD_DOMAIN blocked (0.0.0.0) by Pi-hole"
elif echo "$RESULT" | grep -qi "NXDOMAIN\|can't find"; then
  echo "PASS: $AD_DOMAIN blocked (NXDOMAIN) by Pi-hole"
else
  echo "FAIL: $AD_DOMAIN was not blocked by Pi-hole ($PIHOLE_ADDR):"
  echo "$RESULT"
  exit 1
fi
