# Network Connectivity Checker (`check_inet.sh`)

`check_inet.sh` is an OpenWrt LTE connectivity watchdog. It is designed to be
started by cron once per minute, but an atomic lock directory prevents a second
copy from running while the previous one is still checking or recovering the
connection.

The script checks IPv4, IPv6, or both, reconnects the LTE interface when all
configured checks fail, polls for recovery instead of sleeping for a fixed
delay, and can power-cycle USB modem GPIO ports when the reconnect does not
restore internet access.

---

## Features

- **Repeated connectivity checks**: Runs up to `CHECK_ATTEMPTS` checks with
  `CHECK_INTERVAL` seconds between failed attempts before taking action.
- **IPv4/IPv6 modes**: Supports `CHECK_MODE=ipv4`, `CHECK_MODE=ipv6`, or
  `CHECK_MODE=both`.
- **Dual-stack policy**: With `CHECK_MODE=both`, `DUAL_STACK_POLICY=any`
  treats either working IP stack as online, while `all` requires both.
- **Recovery polling**: After `RECONNECT_CMD`, checks internet every
  `RECOVERY_CHECK_INTERVAL` seconds and continues immediately when it returns.
- **USB hard reset**: If reconnect recovery times out and
  `HARD_RESET_ENABLED=1`, power-cycles the configured USB GPIO ports.
- **USB reset cooldown**: `USB_RESET_COOLDOWN` prevents repeated power cycles
  when the mobile network itself is unavailable.
- **Post-recovery hooks**: Optional commands can run after successful reconnect
  or USB reset recovery.
- **Cron lock**: Uses `/tmp/netcheck.lock` as an atomic lock directory to avoid
  overlapping cron runs.
- **Configurable logging**: `LOG_LEVEL` controls whether the script logs debug
  checks, recovery actions only, or nothing.

---

## Prerequisites

OpenWrt should provide these commands:

- `ping`
- `ping6`
- `logger`
- `ifup` when the default `RECONNECT_CMD='ifup slte'` is used

For USB power-cycle support, the configured GPIO value files must be writable,
for example:

```text
/sys/class/gpio/tp-link:power:usb1/value
/sys/class/gpio/tp-link:power:usb2/value
```

Make the script executable:

```bash
chmod +x check_inet.sh
```

---

## Usage

Copy the script to the router, for example as `/etc/check_inet.sh`, then add it
to the root crontab:

```bash
* * * * * /etc/check_inet.sh
```

The intended execution flow is:

1. Cron starts the script once per minute.
2. The script acquires `/tmp/netcheck.lock`; if another instance is still
   running, the new one exits.
3. It performs up to `CHECK_ATTEMPTS` full connectivity checks with
   `CHECK_INTERVAL` seconds between failed checks.
4. If internet is available, it exits without action.
5. If internet is still unavailable, it runs `RECONNECT_CMD`.
6. After reconnect, it polls connectivity until either internet returns or
   `RECONNECT_RECOVERY_TIMEOUT` expires.
7. If reconnect recovery times out and `HARD_RESET_ENABLED=0`, it exits.
8. If hard reset is enabled and the USB cooldown allows it, it power-cycles the
   configured USB GPIO ports.
9. After USB reset, it polls again until either internet returns or
   `USB_RECOVERY_TIMEOUT` expires.

---

## Configuration

Edit the configuration section at the top of `check_inet.sh`.

### Logging and Locking

```sh
LOG_LEVEL="info"
LOG_TAG="netcheck"
LOCK_PATH="/tmp/netcheck.lock"
```

- `LOG_LEVEL=debug`: log every run and every connectivity check.
- `LOG_LEVEL=info`: log reconnect/reset actions and their results.
- `LOG_LEVEL=silent`: disable logging.
- `LOCK_PATH` is used as a lock directory, even though the path keeps the
  historical `.lock` name.

### Connectivity Checks

```sh
CHECK_MODE="both"
DUAL_STACK_POLICY="any"
IPV4_TARGETS="1.1.1.1 8.8.8.8"
IPV6_TARGETS="2606:4700:4700::1111 2001:4860:4860::8888"
PING_DEVICE=""
PING_PACKETS=1
PING_TIMEOUT=2
CHECK_ATTEMPTS=5
CHECK_INTERVAL=8
```

- `CHECK_MODE` selects IPv4, IPv6, or both.
- `DUAL_STACK_POLICY` is used only with `CHECK_MODE=both`.
- Multiple targets are tried in order; one successful target is enough for that
  IP family.
- `PING_DEVICE` can force pings through a specific Linux interface such as
  `wwan0`; leave it empty to use normal routing.
- `CHECK_ATTEMPTS=5` and `CHECK_INTERVAL=8` mean the default initial check
  window is roughly 32 seconds after the first failed check, because there is no
  sleep after the final failed attempt.

### Reconnect Recovery

```sh
RECONNECT_CMD='ifup slte'
RECONNECT_RECOVERY_TIMEOUT=75
RECOVERY_CHECK_INTERVAL=5
POST_RECONNECT_CMD=''
```

- `RECONNECT_CMD` is run after the initial checks fail.
- The script does not sleep for a fixed recovery delay. It checks connectivity
  every `RECOVERY_CHECK_INTERVAL` seconds and continues immediately once
  internet returns.
- `POST_RECONNECT_CMD` runs only after internet has returned following
  `RECONNECT_CMD`.

### USB Hard Reset

```sh
HARD_RESET_ENABLED=1
USB_GPIO_ROOT="/sys/class/gpio"
USB_POWER_PORTS="tp-link:power:usb1 tp-link:power:usb2"
USB_POWER_OFF_TIME=2
USB_RESET_COOLDOWN=600
USB_RESET_STATE_FILE="/tmp/netcheck.last_usb_reset"
USB_RECOVERY_TIMEOUT=90
POST_USB_RESET_CMD=''
```

- `HARD_RESET_ENABLED=1` allows USB power-cycle after reconnect recovery times
  out.
- `USB_POWER_PORTS` can contain one or more GPIO entries separated by spaces.
- `USB_POWER_OFF_TIME` controls how long USB power remains off.
- `USB_RESET_COOLDOWN=600` prevents another hard reset for 10 minutes after a
  successful power-cycle.
- `USB_RECOVERY_TIMEOUT` is separate from `RECONNECT_RECOVERY_TIMEOUT`.
- `POST_USB_RESET_CMD` runs only after internet has returned following USB
  reset.

---

## Example Logs

Reconnect recovery:

```text
netcheck: Connectivity failed for 5 checks; running reconnect: ifup slte
netcheck: Internet restored after reconnect.
```

Reconnect timeout with hard reset disabled:

```text
netcheck: Internet did not return within 75s after reconnect.
netcheck: Hard USB reset is disabled; no further action.
```

USB reset cooldown:

```text
netcheck: USB reset skipped: cooldown active for another 431s.
```

USB recovery timeout:

```text
netcheck: USB power reset completed; waiting up to 90s for internet.
netcheck: Internet is still unavailable after USB reset and 90s recovery timeout.
```

---

## Troubleshooting

- Use `LOG_LEVEL=debug` to see every connectivity check and recovery polling
  attempt.
- If cron appears to skip runs, check whether an earlier instance is still
  holding `/tmp/netcheck.lock`.
- If the router was interrupted and no script instance is running, remove a
  stale lock directory:
  ```bash
  rm -rf /tmp/netcheck.lock
  ```
- If USB reset is skipped, inspect `/tmp/netcheck.last_usb_reset` and the
  `USB_RESET_COOLDOWN` value.
- If USB reset fails, verify that every configured GPIO value file exists and is
  writable by the script.

---

## License

These scripts are redistributed under the MIT License. Feel free to modify and
distribute them.

**© 2024 Vitovt ©**
