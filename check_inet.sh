#!/bin/sh
# shellcheck shell=sh
#
# OpenWrt LTE connectivity watchdog
#
# Cron:
#   * * * * * /etc/check_inet.sh
#

###############################################################################
# CONFIGURATION — edit only this section
###############################################################################

# Logging:
#   debug  - log every run and every connectivity check
#   info   - log only reconnect/reset actions and their results
#   silent - log nothing
LOG_LEVEL="info"
LOG_TAG="netcheck"

# Lock path.
#
# Internally this is an atomic lock directory rather than a regular file.
# The path remains the same: /tmp/netcheck.lock
LOCK_PATH="/tmp/netcheck.lock"

# Connectivity mode:
#   ipv4
#   ipv6
#   both
CHECK_MODE="both"

# Used only when CHECK_MODE="both":
#
#   any - internet is considered available when IPv4 OR IPv6 works
#   all - internet is considered available only when IPv4 AND IPv6 work
#
# "any" reproduces the useful behaviour of your old script:
# one working IP stack is enough to avoid reconnecting the modem.
DUAL_STACK_POLICY="any"

# Ping targets.
#
# During one check round, targets are tried one after another.
# It is enough for one target of the selected IP family to answer.
IPV4_TARGETS="1.1.1.1 8.8.8.8"
IPV6_TARGETS="2606:4700:4700::1111 2001:4860:4860::8888"

# Optional real Linux network device used as the ping source.
#
# Examples:
#   PING_DEVICE="wwan0"
#   PING_DEVICE="eth2"
#
# Leave empty to use the normal routing table.
PING_DEVICE=""

# Number of ICMP packets sent to each target.
PING_PACKETS=1

# Ping timeout in seconds.
PING_TIMEOUT=2

# Number of complete connectivity checks before reconnecting LTE.
CHECK_ATTEMPTS=5

# Pause between complete checks, in seconds.
#
# There is no pause after the final failed check.
CHECK_INTERVAL=8

# LTE/network reconnect command.
#
# Keep exactly one active value.
RECONNECT_CMD='ifup slte'

# Alternative:
# RECONNECT_CMD='/etc/init.d/network restart'

# How long to wait for internet after RECONNECT_CMD.
#
# The script checks connectivity repeatedly during this period and continues
# immediately when internet returns.
RECONNECT_RECOVERY_TIMEOUT=75

# Pause between recovery checks.
RECOVERY_CHECK_INTERVAL=5

# Optional command executed only after internet has returned following
# RECONNECT_CMD.
#
# Leave empty to disable.
# POST_RECONNECT_CMD='/etc/init.d/odhcpd restart'

# No post-command:
POST_RECONNECT_CMD=''

# Hard USB modem reset:
#   1 - enabled
#   0 - disabled
HARD_RESET_ENABLED=1

# GPIO entries to power-cycle.
#
# Multiple entries are separated by spaces.
#
# The resulting paths are:
#   ${USB_GPIO_ROOT}/tp-link:power:usb1/value
#   ${USB_GPIO_ROOT}/tp-link:power:usb2/value
USB_GPIO_ROOT="/sys/class/gpio"
USB_POWER_PORTS="tp-link:power:usb1 tp-link:power:usb2"

# How long USB power remains off, in seconds.
USB_POWER_OFF_TIME=2

# Do not hard-reset USB more frequently than this many seconds.
#
# This prevents reset loops when the mobile network itself is unavailable.
# Set to 0 to disable the cooldown.
USB_RESET_COOLDOWN=600
USB_RESET_STATE_FILE="/tmp/netcheck.last_usb_reset"

# How long to wait for internet after USB power-cycle.
USB_RECOVERY_TIMEOUT=90

# Optional command executed only after internet has returned following
# USB power-cycle.
#
# Leave empty to disable.
# POST_USB_RESET_CMD='/etc/init.d/odhcpd restart'

# No post-command:
POST_USB_RESET_CMD=''

###############################################################################
# END OF CONFIGURATION
###############################################################################

PATH="/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

LOCK_HELD=0
LAST_IPV4="-"
LAST_IPV6="-"

###############################################################################
# Logging
###############################################################################

log_debug() {
    [ "$LOG_LEVEL" = "debug" ] || return 0
    logger -t "$LOG_TAG" "$*"
}

log_info() {
    [ "$LOG_LEVEL" = "silent" ] && return 0
    logger -t "$LOG_TAG" "$*"
}

###############################################################################
# Lock
###############################################################################

cleanup() {
    if [ "$LOCK_HELD" -eq 1 ]; then
        rm -rf "$LOCK_PATH"
        LOCK_HELD=0
    fi
}

acquire_lock() {
    if mkdir "$LOCK_PATH" 2>/dev/null; then
        echo $$ > "$LOCK_PATH/pid"
        LOCK_HELD=1
        return 0
    fi

    old_pid="$(cat "$LOCK_PATH/pid" 2>/dev/null)"

    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        log_debug "Another instance is already running (pid=$old_pid); exiting."
        return 1
    fi

    log_debug "Removing stale lock: $LOCK_PATH"
    rm -rf "$LOCK_PATH"

    if mkdir "$LOCK_PATH" 2>/dev/null; then
        echo $$ > "$LOCK_PATH/pid"
        LOCK_HELD=1
        return 0
    fi

    log_debug "Could not acquire lock: $LOCK_PATH"
    return 1
}

###############################################################################
# Configuration validation
###############################################################################

validate_config() {
    case "$LOG_LEVEL" in
        debug|info|silent)
            ;;
        *)
            LOG_LEVEL="info"
            log_info "Invalid LOG_LEVEL; using info."
            ;;
    esac

    case "$CHECK_MODE" in
        ipv4|ipv6|both)
            ;;
        *)
            log_info "Invalid CHECK_MODE='$CHECK_MODE'."
            return 1
            ;;
    esac

    case "$DUAL_STACK_POLICY" in
        any|all)
            ;;
        *)
            log_info "Invalid DUAL_STACK_POLICY='$DUAL_STACK_POLICY'."
            return 1
            ;;
    esac

    case "$HARD_RESET_ENABLED" in
        0|1)
            ;;
        *)
            log_info "Invalid HARD_RESET_ENABLED='$HARD_RESET_ENABLED'."
            return 1
            ;;
    esac

    return 0
}

###############################################################################
# Ping functions
###############################################################################

ping_ipv4_target() {
    target="$1"

    if [ -n "$PING_DEVICE" ]; then
        ping \
            -I "$PING_DEVICE" \
            -c "$PING_PACKETS" \
            -W "$PING_TIMEOUT" \
            "$target" >/dev/null 2>&1
    else
        ping \
            -c "$PING_PACKETS" \
            -W "$PING_TIMEOUT" \
            "$target" >/dev/null 2>&1
    fi
}

ping_ipv6_target() {
    target="$1"

    if [ -n "$PING_DEVICE" ]; then
        ping6 \
            -I "$PING_DEVICE" \
            -c "$PING_PACKETS" \
            -W "$PING_TIMEOUT" \
            "$target" >/dev/null 2>&1
    else
        ping6 \
            -c "$PING_PACKETS" \
            -W "$PING_TIMEOUT" \
            "$target" >/dev/null 2>&1
    fi
}

check_ipv4() {
    for target in $IPV4_TARGETS; do
        if ping_ipv4_target "$target"; then
            return 0
        fi
    done

    return 1
}

check_ipv6() {
    for target in $IPV6_TARGETS; do
        if ping_ipv6_target "$target"; then
            return 0
        fi
    done

    return 1
}

###############################################################################
# Connectivity evaluation
###############################################################################

check_connectivity() {
    LAST_IPV4="-"
    LAST_IPV6="-"

    case "$CHECK_MODE" in
        ipv4)
            if check_ipv4; then
                LAST_IPV4=1
            else
                LAST_IPV4=0
            fi

            [ "$LAST_IPV4" -eq 1 ]
            ;;

        ipv6)
            if check_ipv6; then
                LAST_IPV6=1
            else
                LAST_IPV6=0
            fi

            [ "$LAST_IPV6" -eq 1 ]
            ;;

        both)
            if check_ipv4; then
                LAST_IPV4=1
            else
                LAST_IPV4=0
            fi

            if check_ipv6; then
                LAST_IPV6=1
            else
                LAST_IPV6=0
            fi

            if [ "$DUAL_STACK_POLICY" = "all" ]; then
                [ "$LAST_IPV4" -eq 1 ] &&
                    [ "$LAST_IPV6" -eq 1 ]
            else
                [ "$LAST_IPV4" -eq 1 ] ||
                    [ "$LAST_IPV6" -eq 1 ]
            fi
            ;;
    esac
}

###############################################################################
# Initial repeated checks
###############################################################################

initial_checks_pass() {
    attempt=1

    while [ "$attempt" -le "$CHECK_ATTEMPTS" ]; do
        if check_connectivity; then
            log_debug \
                "Check $attempt/$CHECK_ATTEMPTS: online " \
                "(IPv4=$LAST_IPV4, IPv6=$LAST_IPV6)."

            return 0
        fi

        log_debug \
            "Check $attempt/$CHECK_ATTEMPTS: offline " \
            "(IPv4=$LAST_IPV4, IPv6=$LAST_IPV6)."

        if [ "$attempt" -lt "$CHECK_ATTEMPTS" ]; then
            sleep "$CHECK_INTERVAL"
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

###############################################################################
# Recovery polling
###############################################################################

wait_until_online() {
    timeout="$1"
    phase="$2"

    deadline=$(( $(date +%s) + timeout ))

    while :; do
        if check_connectivity; then
            log_debug \
                "$phase: online " \
                "(IPv4=$LAST_IPV4, IPv6=$LAST_IPV6)."

            return 0
        fi

        now="$(date +%s)"

        if [ "$now" -ge "$deadline" ]; then
            log_debug \
                "$phase: timeout, still offline " \
                "(IPv4=$LAST_IPV4, IPv6=$LAST_IPV6)."

            return 1
        fi

        log_debug \
            "$phase: still offline " \
            "(IPv4=$LAST_IPV4, IPv6=$LAST_IPV6); retrying."

        sleep "$RECOVERY_CHECK_INTERVAL"
    done
}

###############################################################################
# Commands
###############################################################################

run_command() {
    command_text="$1"
    command_name="$2"

    [ -n "$command_text" ] || return 0

    log_debug "Running $command_name: $command_text"

    sh -c "$command_text"
    rc=$?

    if [ "$rc" -ne 0 ]; then
        log_info \
            "$command_name failed with exit code $rc: $command_text"

        return "$rc"
    fi

    return 0
}

###############################################################################
# USB reset cooldown
###############################################################################

usb_reset_allowed() {
    [ "$USB_RESET_COOLDOWN" -gt 0 ] || return 0
    [ -f "$USB_RESET_STATE_FILE" ] || return 0

    last_reset="$(cat "$USB_RESET_STATE_FILE" 2>/dev/null)"

    case "$last_reset" in
        ''|*[!0-9]*)
            return 0
            ;;
    esac

    now="$(date +%s)"
    age=$((now - last_reset))

    if [ "$age" -lt "$USB_RESET_COOLDOWN" ]; then
        remaining=$((USB_RESET_COOLDOWN - age))

        log_info \
            "USB reset skipped: cooldown active for another ${remaining}s."

        return 1
    fi

    return 0
}

###############################################################################
# USB power reset
###############################################################################

hard_reset_usb() {
    valid_ports=""

    for port in $USB_POWER_PORTS; do
        value_path="$USB_GPIO_ROOT/$port/value"

        if [ -w "$value_path" ]; then
            valid_ports="$valid_ports $value_path"
        else
            log_info "USB power GPIO is not writable: $value_path"
        fi
    done

    [ -n "$valid_ports" ] || return 1

    log_info "Hard-resetting USB power ports:$USB_POWER_PORTS"

    reset_failed=0

    for value_path in $valid_ports; do
        echo 0 > "$value_path" || reset_failed=1
    done

    sleep "$USB_POWER_OFF_TIME"

    # Always try to restore power on every selected port,
    # even if one previous write failed.
    for value_path in $valid_ports; do
        echo 1 > "$value_path" || reset_failed=1
    done

    [ "$reset_failed" -eq 0 ] || return 1

    date +%s > "$USB_RESET_STATE_FILE"

    return 0
}

###############################################################################
# Main
###############################################################################

main() {
    acquire_lock || exit 0

    trap cleanup 0
    trap 'exit 130' INT TERM HUP

    validate_config || exit 2

    log_debug \
        "Started: mode=$CHECK_MODE, policy=$DUAL_STACK_POLICY, " \
        "attempts=$CHECK_ATTEMPTS, interval=${CHECK_INTERVAL}s."

    if initial_checks_pass; then
        log_debug "Internet is available; no action required."
        exit 0
    fi

    log_info \
        "Connectivity failed for $CHECK_ATTEMPTS checks; " \
        "running reconnect: $RECONNECT_CMD"

    run_command "$RECONNECT_CMD" "Reconnect command"

    if wait_until_online \
        "$RECONNECT_RECOVERY_TIMEOUT" \
        "After reconnect"
    then
        log_info "Internet restored after reconnect."

        run_command \
            "$POST_RECONNECT_CMD" \
            "Post-reconnect command"

        exit 0
    fi

    log_info \
        "Internet did not return within " \
        "${RECONNECT_RECOVERY_TIMEOUT}s after reconnect."

    if [ "$HARD_RESET_ENABLED" -ne 1 ]; then
        log_info "Hard USB reset is disabled; no further action."
        exit 1
    fi

    if ! usb_reset_allowed; then
        exit 1
    fi

    if ! hard_reset_usb; then
        log_info "USB power reset failed."
        exit 1
    fi

    log_info \
        "USB power reset completed; waiting up to " \
        "${USB_RECOVERY_TIMEOUT}s for internet."

    if wait_until_online \
        "$USB_RECOVERY_TIMEOUT" \
        "After USB reset"
    then
        log_info "Internet restored after USB reset."

        run_command \
            "$POST_USB_RESET_CMD" \
            "Post-USB-reset command"

        exit 0
    fi

    log_info \
        "Internet is still unavailable after USB reset and " \
        "${USB_RECOVERY_TIMEOUT}s recovery timeout."

    exit 1
}

main "$@"
