# Network Connectivity Checker (`netcheck.sh`)

This script monitors the IPv4 and IPv6 connectivity of an OpenWrt router and performs actions to restore connectivity if issues are detected. It handles SLTE (modem) interface resets, USB modem power cycling, and partial failure scenarios. The script uses a **lock file** to prevent overlapping executions.

---

## Features

- **Connectivity Monitoring**: Periodically checks the availability of specified IPv4 and IPv6 targets.
- **SLTE Reconnection**: Restarts the SLTE interface when connectivity issues are detected.
- **USB Modem Reset**: Power-cycles USB modems if connectivity cannot be restored by SLTE reconnection.
- **Partial Failure Handling**: Tracks partial failures and reconnects after a configurable number of failed checks.
- **Lock File Protection**: Prevents multiple instances of the script from running simultaneously.
- **Logging**: Logs actions and connectivity status to the system logger (`logger`).

---

## Prerequisites

1. OpenWrt router with the following utilities available:
   - `ping`
   - `ping6`
   - `logger`
2. Ensure the script is executable:
   ```bash
   chmod +x netcheck.sh
   ```

---

## Usage

1. **Place the Script**: Save `netcheck.sh` in `/usr/local/bin`, `/root`, or another suitable directory.
2. **Add to Crontab**:
   ```bash
   * * * * * /path/to/netcheck.sh
   ```
   This ensures the script runs every minute.

3. **Script Execution Flow**:
   - The script first checks IPv4 and IPv6 connectivity.
   - If both are reachable, it resets the failure counter and exits.
   - If both fail:
     1. It reconnects the SLTE interface.
     2. If the issue persists, it power-cycles the USB modem(s).
   - If only one protocol fails, it increments a partial failure counter and acts only after repeated failures.

---

## Configuration

### Variables

- **Connectivity Test Targets**:
  - IPv4: `1.1.1.1`
  - IPv6: `2606:4700:4700::1111`
  - Update these variables in the script if needed:
    ```bash
    IPV4_TEST="1.1.1.1"
    IPV6_TEST="2606:4700:4700::1111"
    ```

- **Delays**:
  - Sleep after SLTE reconnect: `140 seconds`
  - Sleep after USB modem reset: `60 seconds`

- **Lock File**:
  - The script uses `/tmp/netcheck.lock` to prevent multiple instances from running simultaneously.

---

## Error Handling

### Lock File

- If another instance is running, the script will log a message and exit:
  ```text
  Another instance of netcheck.sh is already running. Exiting.
  ```

### Connectivity Status Logging

- Connectivity status is logged to the system logger:
  ```text
  netcheck: IPv4 ping=1, IPv6 ping=0, partial_fail_count=2
  ```

---

## Example Logs

**Normal Connectivity**:
```text
netcheck: IPv4 ping=1, IPv6 ping=1, partial_fail_count=0
netcheck: Both IPv4 and IPv6 are reachable, counter reset to 0. Nothing to do.
```

**Partial Failure**:
```text
netcheck: IPv4 ping=1, IPv6 ping=0, partial_fail_count=1
netcheck: Partial failure (one of IPv4 or IPv6 down). New count=2
```

**Total Failure and Reconnection**:
```text
netcheck: IPv4 ping=0, IPv6 ping=0, partial_fail_count=0
netcheck: Total failure (IPv4 & IPv6), reconnecting SLTE now...
netcheck: Still no connectivity after SLTE reconnect => resetting USB modem.
netcheck: Modem power-cycled, waiting 60s...
```

---

## Notes

- Ensure the script has the correct permissions to modify network interfaces and access system files like `/sys/class/gpio/*`.
- Adjust `SLEEP1` and `SLEEP2` values if needed for your hardware.

---

## Troubleshooting

1. **Script Not Executing Periodically**:
   - Ensure it is added to the crontab:
     ```bash
     crontab -e
     ```
     Add:
     ```bash
     * * * * * /path/to/netcheck.sh
     ```

2. **Lock File Issues**:
   - If the script fails to remove the lock file due to an ungraceful exit, delete it manually:
     ```bash
     rm -f /tmp/netcheck.lock
     ```

3. **Connectivity Targets**:
   - Test the targets manually using `ping` and `ping6` to ensure they are reachable.

---

## License

These scripts are redistributed under the MIT License. Feel free to modify and distribute them.

**© 2024 Vitovt ©**

