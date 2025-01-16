#!/bin/sh
#
# netcheck.sh - Connectivity checker & SLTE/Modem reset logic for OpenWrt
#
# Place in /usr/local/bin or /root (as you prefer), make it executable (chmod +x),
# and add to /etc/crontab or /etc/crontabs/root:
#
#   * * * * * /path/to/netcheck.sh
#
# This ensures it runs every minute.

#sleep after slte_reconnect
SLEEP1=140
#sleep after modem hardware reset
SLEEP2=60

##################################
# Helper functions
##################################

reset_usb_1() {
  logger -t netcheck "Resetting USB 1 power..."
  echo 0 > /sys/class/gpio/tp-link:power:usb1/value
  sleep 1
  echo 1 > /sys/class/gpio/tp-link:power:usb1/value
}

reset_usb_2() {
  logger -t netcheck "Resetting USB 2 power..."
  echo 0 > /sys/class/gpio/tp-link:power:usb2/value
  sleep 1
  echo 1 > /sys/class/gpio/tp-link:power:usb2/value
}

check_ipv4_pingable() {
  local IPV4_ADDRESS="$1"
  if ping -c 1 -W 1 "$IPV4_ADDRESS" >/dev/null 2>&1; then
    echo 1
  else
    echo 0
  fi
}

check_ipv6_pingable() {
  local IPV6_ADDRESS="$1"
  if ping6 -c 1 -W 1 "$IPV6_ADDRESS" >/dev/null 2>&1; then
    echo 1
  else
    echo 0
  fi
}

reconnect_slte() {
  logger -t netcheck "Stopping SLTE interface..."
  ifdown slte
  sleep 2
  logger -t netcheck "Starting SLTE interface..."
  ifup slte
}

##################################
# Main logic
##################################

# Where we store the "partial failure" counter
COUNTER_FILE="/tmp/network_partial_fail_count"
if [ -f "$COUNTER_FILE" ]; then
  PARTIAL_FAIL_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null)
else
  PARTIAL_FAIL_COUNT=0
fi

# Targets for testing (adjust as needed)
IPV4_TEST="1.1.1.1"
IPV6_TEST="2606:4700:4700::1111"

# Check connectivity
INFO4="$(check_ipv4_pingable "$IPV4_TEST")"
INFO6="$(check_ipv6_pingable "$IPV6_TEST")"

# Log the current status
logger -t netcheck "IPv4 ping=$INFO4, IPv6 ping=$INFO6, partial_fail_count=$PARTIAL_FAIL_COUNT"

# CASE 1: Both OK
if [ "$INFO4" -eq 1 ] && [ "$INFO6" -eq 1 ]; then
  # Reset partial-failure counter
  echo 0 > "$COUNTER_FILE"
  logger -t netcheck "Both IPv4 and IPv6 are reachable, counter reset to 0. Nothing to do."
  exit 0
fi

# CASE 2: Both fail => immediate reconnect
if [ "$INFO4" -eq 0 ] && [ "$INFO6" -eq 0 ]; then
  logger -t netcheck "Total failure (IPv4 & IPv6), reconnecting SLTE now..."
  reconnect_slte
  echo 1 > "$COUNTER_FILE"
  sleep $SLEEP1
  # Re-check
  INFO4="$(check_ipv4_pingable "$IPV4_TEST")"
  INFO6="$(check_ipv6_pingable "$IPV6_TEST")"

  if [ "$INFO4" -eq 1 ] && [ "$INFO6" -eq 1 ]; then
    logger -t netcheck "Connectivity restored after SLTE reconnect."
    echo 0 > "$COUNTER_FILE"
    exit 0
  else
    logger -t netcheck "Still no connectivity after SLTE reconnect => resetting USB modem."
    reset_usb_1
    reset_usb_2
    logger -t netcheck "Modem powered off/on, waiting 60s..."
    sleep $SLEEP2
    logger -t netcheck "Restarting odhcpd..."
    /etc/init.d/odhcpd restart
    echo 0 > "$COUNTER_FILE"
    exit 0
  fi
fi

# CASE 3: Partial failure => increment the counter
PARTIAL_FAIL_COUNT=$((PARTIAL_FAIL_COUNT + 1))
logger -t netcheck "Partial failure (one of IPv4 or IPv6 down). New count=$PARTIAL_FAIL_COUNT"

# If partial failures < 3, do nothing (just log + keep counting)
if [ "$PARTIAL_FAIL_COUNT" -lt 3 ]; then
  echo "$PARTIAL_FAIL_COUNT" > "$COUNTER_FILE"
  logger -t netcheck "Partial failure count < 3, not taking action yet."
  exit 0
fi

# If partial failures >= 3 => reconnect
logger -t netcheck "Partial failure persisted for 3 checks => reconnecting SLTE."
reconnect_slte
echo 1 > "$COUNTER_FILE"
sleep $SLEEP1

# Check again
INFO4="$(check_ipv4_pingable "$IPV4_TEST")"
INFO6="$(check_ipv6_pingable "$IPV6_TEST")"

if [ "$INFO4" -eq 1 ] && [ "$INFO6" -eq 1 ]; then
  logger -t netcheck "Connectivity restored after partial-failure reconnect."
  echo 0 > "$COUNTER_FILE"
  exit 0
else
  logger -t netcheck "Still failing after SLTE reconnect => resetting USB modem."
  reset_usb_1
  reset_usb_2
  logger -t netcheck "Modem power-cycled, waiting 60s..."
  sleep $SLEEP2
  logger -t netcheck "Restarting odhcpd..."
  /etc/init.d/odhcpd restart
  echo 0 > "$COUNTER_FILE"
  exit 0
fi

