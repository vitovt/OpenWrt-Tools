# OpenWRT Tools

A collection of scripts and utilities to enhance the functionality and manageability of your OpenWRT routers. Various tools, including network configuration helpers, firewall rule management scripts, and other useful utilities for OpenWRT administrators.

## List of Tools
- [Manage mac](#manage-mac)

### Manage mac

[./manage_mac.sh](scripts/manage_mac.sh)

Manage white/black-list MAC addresses on the wireless interface

**Sample usage:**

List MACs on interface 1
```
./manage_mac.sh -l
```

Add MAC to list on **default** interface 0
```
./manage_mac.sh -a -m AA:BB:CC:DD:EE:FF
```

Remove two MACs from list on interface 0
```
./manage_mac.sh -r -i 0 -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
```

## Contributing

Contributions are welcome! If you have a script or tool that you think would be useful, please submit a pull request. Ensure your contributions adhere to the following guidelines:

- Follow the existing code style and structure.
- Include clear and concise documentation.
- Test your scripts thoroughly.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

---

Thank you for using OpenWRT Tools! If you have any questions or feedback, please open an issue or contact us.
