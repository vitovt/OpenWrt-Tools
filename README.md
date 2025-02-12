# OpenWRT Tools

A collection of scripts and utilities to enhance the functionality and manageability of your OpenWRT routers. Various tools, including network configuration helpers, firewall rule management scripts, and other useful utilities for OpenWRT administrators.

## List of Tools
- [Manage mac](#manage-mac)
- [Manage host](#manage-host)
- [Firewall Rules Manager](#firewall-rules-manager)
- [Network Connectivity Checker](#network-connectivity-checker)

- [Contributing](#contributing)
- [License](#license)

### Manage mac

[./manage_mac.sh](manage_mac.sh)
[Full documentation](manage_mac.md)

Manage white/black-list MAC addresses on the wireless interface

**Sample usage:**

Add MAC to list on **default** interface 0
```
./manage_mac.sh -a -m AA:BB:CC:DD:EE:FF
```

Remove two MACs from list on interface 0
```
./manage_mac.sh -r -i 0 -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
```

Can be used like **Parental control** for Openwrt wifi router:
```
root@OpenWrt:/# cat /etc/crontabs/root 
#Turn off wifi for children at 21:30 and turn back at 5:00
30 21 * * * /etc/manage_mac.sh -r -i 0 -i 1 -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
0  5 * * * /etc/manage_mac.sh -a -i 0 -i 1 -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
```

### Manage host

[./manage_host.sh](manage_host.sh)
[Full documentation](manage_host.md)

Manage white/black-list hostnames on the wireless interface by mapping them to their respective MAC addresses in the DHCP configuration.

**Sample usage:**

Add hostname to list on **default** interface 0
```
./manage_host.sh -a -n TERMPC
```

Remove two hostnames from list on interface 0
```
./manage_host.sh -r -i 0 -n TERMPC -n valentynapc
```

Can be used like **Parental control** for Openwrt wifi router:
```
root@OpenWrt:/# cat /etc/crontabs/root 
#Turn off wifi for children’s devices at 21:30 and turn back at 5:00
30 21 * * * /etc/manage_host.sh -r -i 0 -i 1 -n TERMPC -n valentynapc
0  5 * * * /etc/manage_host.sh -a -i 0 -i 1 -n TERMPC -n valentynapc
```

### Firewall Rules Manager

[./firewall_rules.sh](firewall_rules.sh)
[Full documentation](firewall_rules.md)

Manage OpenWrt firewall rules by their name.

#### Usage:
```bash
./firewall_rules.sh <enable|disable|status|list> <rule_name>
```

- `enable`: Enable a specific firewall rule by its name.
- `disable`: Disable a specific firewall rule by its name.
- `status`: Check if a rule is enabled or disabled.
- `list`: Display all firewall rules with their order numbers and names.

**Example:**
```bash
./firewall_rules.sh list
./firewall_rules.sh enable Allow-SSH
./firewall_rules.sh status Allow-SSH
```

### Network Connectivity Checker
[./netcheck.sh](netcheck.sh)
[Full documentation](netcheck.md)

Monitors IPv4/IPv6 connectivity on an OpenWrt router and handles SLTE/Modem reconnections as needed.

#### Usage:
Place `netcheck.sh` in `/usr/local/bin` (or another suitable location) and add it to the crontab for periodic execution:
```bash
* * * * * /path/to/netcheck.sh


---

For more detailed options see **README** of each script.

---

## Contributing

Contributions are welcome! If you have a script or tool that you think would be useful, please submit a pull request. Ensure your contributions adhere to the following guidelines:

- Follow the existing code style and structure.
- Include clear and concise documentation.
- Test your scripts thoroughly.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

---

Thank you for using OpenWRT Tools! If you have any questions or feedback, please open an issue or contact us.
