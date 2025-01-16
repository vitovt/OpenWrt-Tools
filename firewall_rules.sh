#!/bin/sh

# Usage: ./firewall_rule.sh <enable|disable|status|list> <rule_name>

ACTION="$1"
RULE_NAME="$2"

if [ "$ACTION" = "list" ]; then
    echo "Listing all firewall rules with their order numbers:"
    uci show firewall | grep -F ".name='" | sed -n "s/^firewall.\(@rule\[[0-9]*\]\).name='\(.*\)'/\1: \2/p"
    exit 0
fi

if [ -z "$RULE_NAME" ] || [ -z "$ACTION" ]; then
    echo "Usage: $0 <enable|disable|status|list> <rule_name>"
    exit 1
fi

# Find the rule index
RULE_INDEX=$(uci show firewall | grep -F "name='$RULE_NAME'" | sed -n "s/^firewall.\(@rule\[[0-9]*\]\).*/\1/p")

if [ -z "$RULE_INDEX" ]; then
    echo "Error: Rule '$RULE_NAME' not found."
    exit 2
fi

# Check if multiple rules with the same name exist
RULE_COUNT=$(echo "$RULE_INDEX" | wc -l)
if [ "$RULE_COUNT" -gt 1 ]; then
    echo "Error: Multiple rules with the name '$RULE_NAME' found:"
    echo "$RULE_INDEX" | while read -r RULE; do
        echo "  $RULE"
    done
    echo "Please ensure rule names are unique."
    exit 3
fi

# debug: print Rule-index number
#echo RULE-INDEX: $RULE_INDEX.

case "$ACTION" in
    enable)
        uci set firewall.$RULE_INDEX.enabled='1'
        uci commit firewall
        /etc/init.d/firewall restart
        echo "Firewall rule '$RULE_NAME' enabled."
        ;;
    disable)
        uci set firewall.$RULE_INDEX.enabled='0'
        uci commit firewall
        /etc/init.d/firewall restart
        echo "Firewall rule '$RULE_NAME' disabled."
        ;;
    status)
        STATUS=$(uci get firewall.$RULE_INDEX.enabled 2>/dev/null)
        if [ "$STATUS" = "1" ]; then
            echo "Firewall rule '$RULE_NAME' is enabled."
        else
            echo "Firewall rule '$RULE_NAME' is disabled."
        fi
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Usage: $0 <enable|disable|status|list> <rule_name>"
        exit 3
        ;;
esac

