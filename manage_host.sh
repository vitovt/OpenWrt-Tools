#!/bin/sh

# This script is a part of the OpenWRT Tools collection, designed to help you
# manage hostnames on the whitelist/blacklist of the wireless interface of 
# your OpenWRT router.
# You can add, remove, check, and list hostnames in the whitelist/blacklist,
# on specific wireless interfaces ensuring efficient network management and control.

# © (с)2024 Vitovt ©
# This script is redistributed under MIT License, feel free to modify it.

# Default values
DEFAULT_IFACE=0
HOSTNAMES=""
ACTION=""
IFACES_SET=0

# Print help message
print_help() {
    echo "Manage hostnames in the white/blacklist of the wireless interface."
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --name HOSTNAME       Specify the hostname for the action (can be used multiple times for multiple hosts)"
    echo "  -r, --remove              Remove the specified hostname(s) from the whitelist"
    echo "  -a, --add                 Add the specified hostname(s) to the whitelist"
    echo "  -c, --check               Check if the specified hostname(s) are in the whitelist"
    echo "  -l, --list                List all allowed hostnames"
    echo "  -i, --iface IFACE_NUM     Specify the interface number (can be used multiple times for multiple interfaces, default is 0)"
    echo "  -h, --help                Display this help message"
}

# Remove the hostnames from the whitelist
remove_host() {
    if [ -z "$HOSTNAMES" ]; then
        echo "Error: At least one hostname is required for remove action."
        exit 1
    fi
    for IFACE in $IFACES; do
        for HOSTNAME in $HOSTNAMES; do
            # Look up the MAC address for the hostname
            host_sections=$(uci show dhcp | grep "=host" | cut -d'=' -f1)
            MAC_ADDRESS=""
            for hs in $host_sections; do
                name=$(uci get $hs.name)
                if [ "$name" = "$HOSTNAME" ]; then
                    MAC_ADDRESS=$(uci get $hs.mac)
                    break
                fi
            done
            if [ -z "$MAC_ADDRESS" ]; then
                echo "Error: MAC address for hostname $HOSTNAME not found."
                continue
            fi
            uci del_list wireless.@wifi-iface[$IFACE].maclist=$MAC_ADDRESS
            echo "Hostname $HOSTNAME (MAC $MAC_ADDRESS) removed from interface $IFACE."
        done
    done
    uci commit wireless
    # Apply changes to the wireless configuration
    wifi reload
}

# Add the hostnames to the whitelist
add_host() {
    if [ -z "$HOSTNAMES" ]; then
        echo "Error: At least one hostname is required for add action."
        exit 1
    fi
    for IFACE in $IFACES; do
        for HOSTNAME in $HOSTNAMES; do
            # Look up the MAC address for the hostname
            host_sections=$(uci show dhcp | grep "=host" | cut -d'=' -f1)
            MAC_ADDRESS=""
            for hs in $host_sections; do
                name=$(uci get $hs.name)
                if [ "$name" = "$HOSTNAME" ]; then
                    MAC_ADDRESS=$(uci get $hs.mac)
                    break
                fi
            done
            if [ -z "$MAC_ADDRESS" ]; then
                echo "Error: MAC address for hostname $HOSTNAME not found."
                continue
            fi
            uci add_list wireless.@wifi-iface[$IFACE].maclist=$MAC_ADDRESS
            echo "Hostname $HOSTNAME (MAC $MAC_ADDRESS) added to interface $IFACE."
        done
    done
    uci commit wireless
    # Apply changes to the wireless configuration
    wifi reload
}

# Check if the hostnames are allowed
check_host() {
    if [ -z "$HOSTNAMES" ]; then
        echo "Error: At least one hostname is required for check action."
        exit 1
    fi
    for IFACE in $IFACES; do
        for HOSTNAME in $HOSTNAMES; do
            # Look up the MAC address for the hostname
            host_sections=$(uci show dhcp | grep "=host" | cut -d'=' -f1)
            MAC_ADDRESS=""
            for hs in $host_sections; do
                name=$(uci get $hs.name)
                if [ "$name" = "$HOSTNAME" ]; then
                    MAC_ADDRESS=$(uci get $hs.mac)
                    break
                fi
            done
            if [ -z "$MAC_ADDRESS" ]; then
                echo "Error: MAC address for hostname $HOSTNAME not found."
                continue
            fi
            if uci get wireless.@wifi-iface[$IFACE].maclist | grep -qi "$MAC_ADDRESS"; then
                echo "Hostname $HOSTNAME (MAC $MAC_ADDRESS) is allowed on interface $IFACE."
            else
                echo "Hostname $HOSTNAME (MAC $MAC_ADDRESS) is not allowed on interface $IFACE."
            fi
        done
    done
}

# Print all allowed hostnames
print_all_hosts() {
    for IFACE in $IFACES; do
        echo "Allowed hostnames on interface $IFACE:"
        # Get the list of allowed MAC addresses
        MACS=$(uci get wireless.@wifi-iface[$IFACE].maclist)

        # Build a mapping of MAC addresses to hostnames
        host_sections=$(uci show dhcp | grep "=host" | cut -d'=' -f1)

        # Create a temporary file to store MAC to hostname mappings
        TMPFILE=$(mktemp)

        # Build the MAC to hostname mapping
        for hs in $host_sections; do
            mac=$(uci get $hs.mac | tr '[:upper:]' '[:lower:]')
            name=$(uci get $hs.name)
            echo "$mac $name" >> "$TMPFILE"
        done

        # For each MAC address in maclist, get the hostname
        for mac in $MACS; do
            mac=$(echo $mac | tr '[:upper:]' '[:lower:]')
            name=$(grep -i "^$mac " "$TMPFILE" | awk '{print $2}')
            if [ -n "$name" ]; then
                echo "$name"
            else
                echo "$mac"
            fi
        done

        # Clean up the temporary file
        rm "$TMPFILE"
    done
}

# Parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -n | --name )
            shift
            HOSTNAMES="$HOSTNAMES $1"
            ;;
        -r | --remove )
            ACTION="remove"
            ;;
        -a | --add )
            ACTION="add"
            ;;
        -c | --check )
            ACTION="check"
            ;;
        -l | --list )
            ACTION="list"
            ;;
        -i | --iface )
            shift
            IFACES="$IFACES $1"
            IFACES_SET=1
            ;;
        -h | --help )
            print_help
            exit
            ;;
        * )
            print_help
            exit 1
    esac
    shift
done

# Use default interface if no -i option was provided
if [ $IFACES_SET -eq 0 ]; then
    IFACES=$DEFAULT_IFACE
fi

# Execute the specified action
case $ACTION in
    remove)
        remove_host
        ;;
    add)
        add_host
        ;;
    check)
        check_host
        ;;
    list)
        print_all_hosts
        ;;
    *)
        print_help
        ;;
esac

exit 
