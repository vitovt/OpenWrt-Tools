# Manage MAC

**Manage MAC Addresses on single list (it could be white or black) on wireless interface**

This script is designed to help you manage MAC addresses on the whitelist/blacklist of the wireless interface of your OpenWRT router. You can add, remove, check, and list MAC addresses on a specific wireless interface, ensuring efficient network management and control.

## Usage

### Options
Here are all the available options for the script:

```
./manage_mac.sh -h
```
- **-m, --mac MAC_ADDRESS**: Specify the MAC address for the action. This option can be used multiple times to specify multiple MAC addresses.
- **-r, --remove**: Remove the specified MAC address(es) from the whitelist.
- **-a, --add**: Add the specified MAC address(es) to the whitelist.
- **-c, --check**: Check if the specified MAC address(es) are in the whitelist.
- **-l, --list**: List all allowed MAC addresses.
- **-i, --iface IFACE_NUM**: Specify the interface number (default is 0).
- **-h, --help**: Display the help message with usage information.

### List All Allowed/Blacklisted MAC Addresses
List all MAC addresses allowed on interface 1:
```sh
./manage_mac.sh -i 1 -l
```

### Add MAC Addresses to the List on Default Interface 0
To add MAC address to the whitelist on the default interface (0):
```sh
./manage_mac.sh -a -m AA:BB:CC:DD:EE:FF
```

### Remove MAC Addresses from the List on Interface 0
To remove MAC address from the whitelist on interface 0:
```sh
./manage_mac.sh -r -i 0 -m AA:BB:CC:DD:EE:FF
```

### Check if MAC Address is in the List on Default Interface 0
To check if specific MAC addresses are in the whitelist on the default interface (0):
```sh
./manage_mac.sh -c -m AA:BB:CC:DD:EE:FF
```

### Add Multiple MAC Addresses
Add two MAC addresses to the whitelist on the default interface (0):
```sh
./manage_mac.sh -a -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
```

### Remove Multiple MAC Addresses
Remove two MAC addresses from the whitelist on interface 1:
```sh
./manage_mac.sh -r -i 1 -m AA:BB:CC:DD:EE:FF -m 11:22:33:44:55:66
```

## License

This script is redistributed under the MIT License. Feel free to modify and distribute it.

**© 2024 Vitovt ©**
