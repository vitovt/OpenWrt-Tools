#!/bin/sh

#This script is a part of the OpenWRT Tools collection, designed to help you
#manage MAC addresses on the white/blacklist of wireless interface of 
#your OpenWRT router.
#You can add, remove, check, and list MAC addresses in the whitelist/blacklist,
#on specific wireless interface ensuring efficient network management and control.

#© (с)2024 Vitovt ©
#This script is redistributed under MIT License, feel free to modify it.

# Default values
IFACE=0
MAC_ADDRESSES=""
ACTION=""

# Print help message
print_help() {
    echo "Manage MAC white/blacklist addresses of the wireless interface."
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -m, --mac MAC_ADDRESS     Specify the MAC address for the action (can be used multiple times for multiple MACs)"
    echo "  -r, --remove              Remove the specified MAC address(es) from the whitelist"
    echo "  -a, --add                 Add the specified MAC address(es) to the whitelist"
    echo "  -c, --check               Check if the specified MAC address(es) are in the whitelist"
    echo "  -l, --list                List all allowed MAC addresses"
    echo "  -i, --iface IFACE_NUM     Specify the interface number (default is 0)"
    echo "  -h, --help                Display this help message"
}

# Remove the MAC addresses from the whitelist
remove_mac() {
    if [ -z "$MAC_ADDRESSES" ]; then
        echo "Error: At least one MAC address is required for remove action."
        exit 1
    fi
    for MAC_ADDRESS in $MAC_ADDRESSES; do
        uci del_list wireless.@wifi-iface[$IFACE].maclist=$MAC_ADDRESS
        echo "MAC address $MAC_ADDRESS removed from interface $IFACE."
    done
    uci commit wireless
    # Apply changes to the wireless configuration
    wifi
}

# Add the MAC addresses to the whitelist
add_mac() {
    if [ -z "$MAC_ADDRESSES" ]; then
        echo "Error: At least one MAC address is required for add action."
        exit 1
    fi
    for MAC_ADDRESS in $MAC_ADDRESSES; do
        uci add_list wireless.@wifi-iface[$IFACE].maclist=$MAC_ADDRESS
        echo "MAC address $MAC_ADDRESS added to interface $IFACE."
    done
    uci commit wireless
    # Apply changes to the wireless configuration
    wifi
}

# Check if the MAC addresses are allowed
check_mac() {
    if [ -z "$MAC_ADDRESSES" ]; then
        echo "Error: At least one MAC address is required for check action."
        exit 1
    fi
    for MAC_ADDRESS in $MAC_ADDRESSES; do
        if uci get wireless.@wifi-iface[$IFACE].maclist | grep -q "$MAC_ADDRESS"; then
            echo "$MAC_ADDRESS is allowed on interface $IFACE."
        else
            echo "$MAC_ADDRESS is not allowed on interface $IFACE."
        fi
    done
}

# Print all allowed MAC addresses
print_all_macs() {
    echo "Allowed MAC addresses on interface $IFACE:"
    uci get wireless.@wifi-iface[$IFACE].maclist
}

# Parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -m | --mac )
            shift
            MAC_ADDRESSES="$MAC_ADDRESSES $1"
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
            IFACE=$1
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

# Execute the specified action
case $ACTION in
    remove)
        remove_mac
        ;;
    add)
        add_mac
        ;;
    check)
        check_mac
        ;;
    list)
        print_all_macs
        ;;
    *)
        print_help
        ;;
esac

exit 0

