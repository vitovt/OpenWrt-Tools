# Manage Host

A collection of scripts to manage MAC addresses and hostnames on the whitelist/blacklist of a wireless interface on your OpenWRT router. This enables efficient network management and control by allowing easy addition, removal, checking, and listing of MAC addresses or hostnames on specified interfaces.

## Table of Contents
- [Manage Host](#manage-host)
  - [Usage](#usage)
    - [Options](#options)
    - [Examples](#examples)
- [License](#license)

---

**Manage Hostnames on a whitelist or blacklist on the wireless interface**

This script is designed to help you manage hostnames on the whitelist/blacklist of the wireless interface of your OpenWRT router. The script maps hostnames to their MAC addresses using the DHCP configuration, allowing you to add, remove, check, and list hostnames on specified interfaces.

## Usage

### Options
Here are all the available options for the script:

```sh
./manage_host.sh -h
```
- **-n, --name HOSTNAME**: Specify the hostname for the action. This option can be used multiple times to specify multiple hostnames.
- **-r, --remove**: Remove the specified hostname(s) from the whitelist.
- **-a, --add**: Add the specified hostname(s) to the whitelist.
- **-c, --check**: Check if the specified hostname(s) are in the whitelist.
- **-l, --list**: List all allowed hostnames.
- **-i, --iface IFACE_NUM**: Specify the interface number (default is 0).
- **-h, --help**: Display the help message with usage information.

### Examples

- **List All Allowed/Blacklisted Hostnames**  
  List all hostnames allowed on interface 1:
  ```sh
  ./manage_host.sh -i 1 -l
  ```

- **Add Hostnames to the List on Default Interface 0**  
  To add a hostname to the whitelist on the default interface (0):
  ```sh
  ./manage_host.sh -a -n TERMPC
  ```

- **Remove Hostnames from the List on Interface 0**  
  To remove a hostname from the whitelist on interface 0:
  ```sh
  ./manage_host.sh -r -i 0 -n TERMPC
  ```

- **Check if Hostname is in the List on Default Interface 0**  
  To check if specific hostnames are in the whitelist on the default interface (0):
  ```sh
  ./manage_host.sh -c -n TERMPC
  ```

- **Add Multiple Hostnames**  
  Add two hostnames to the whitelist on the default interface (0):
  ```sh
  ./manage_host.sh -a -n TERMPC -n valentynapc
  ```

- **Remove Multiple Hostnames**  
  Remove two hostnames from the whitelist on interface 1:
  ```sh
  ./manage_host.sh -r -i 1 -n TERMPC -n valentynapc
  ```

- **Add Multiple Hostnames to Multiple Interfaces**  
  Add two hostnames to the list on interfaces 0 and 1:
  ```sh
  ./manage_host.sh -i 0 -i 1 -a -n TERMPC -n valentynapc
  ```

- **List All Hostnames on Multiple Interfaces**  
  List all hostnames allowed on interfaces 0 and 1:
  ```sh
  ./manage_host.sh -i 0 -i 1 -l
  ```

---

## License

These scripts are redistributed under the MIT License. Feel free to modify and distribute them.

**© 2024 Vitovt ©**
