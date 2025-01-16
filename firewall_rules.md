# Firewall Rules Manager Script

This script provides a convenient way to manage OpenWrt firewall rules by their name from the command line. It allows you to list, enable, disable, or check the status of firewall rules.

---

## Features

- **List** all firewall rules with their order numbers and names.
- **Enable** a specific firewall rule.
- **Disable** a specific firewall rule.
- **Check the status** (enabled/disabled) of a firewall rule.
- Handles **duplicate rule names** gracefully by reporting them with their indices.

---

## Prerequisites

- This script requires OpenWrt with `uci` available in the system.
- Ensure the script has executable permissions:
  ```bash
  chmod +x firewall_rules.sh
  ```

---

## Usage

```bash
./firewall_rules.sh <action> <rule_name>
```

### Parameters:

- `<action>`: The action to perform. Valid actions are:
  - `list`: Display all firewall rules with their indices and names.
  - `enable`: Enable the firewall rule with the given `<rule_name>`.
  - `disable`: Disable the firewall rule with the given `<rule_name>`.
  - `status`: Check if the rule is enabled or disabled.

- `<rule_name>`: The name of the firewall rule to manage (not needed for `list`).

### Examples:

#### 1. List All Firewall Rules
```bash
./firewall_rules.sh list
```

**Output:**
```text
rule[0]: Allow-SSH
rule[1]: Allow-DHCPv6
rule[2]: Block-HTTP
...
```

#### 2. Enable a Firewall Rule
```bash
./firewall_rules.sh enable Allow-SSH
```

**Output:**
```text
Firewall rule 'Allow-SSH' enabled.
```

#### 3. Disable a Firewall Rule
```bash
./firewall_rules.sh disable Block-HTTP
```

**Output:**
```text
Firewall rule 'Block-HTTP' disabled.
```

#### 4. Check Rule Status
```bash
./firewall_rules.sh status Allow-DHCPv6
```

**Output:**
```text
Firewall rule 'Allow-DHCPv6' is enabled.
```

#### 5. Handling Duplicate Rule Names
If two or more rules have the same name, the script will list the duplicates and exit:
```bash
./firewall_rules.sh enable DuplicateRule
```

**Output:**
```text
Error: Multiple rules with the name 'DuplicateRule' found:
  rule[5]
  rule[8]
Please ensure rule names are unique.
```

---

## Error Handling

- **Rule Not Found:** If the specified rule name doesn't exist:
  ```text
  Error: Rule 'NonexistentRule' not found.
  ```
- **Duplicate Rule Names:** If multiple rules with the same name exist, the script reports them and exits.
- **Invalid Action:** If an invalid action is provided:
  ```text
  Invalid action: invalid_action
  Usage: ./firewall_rules.sh <enable|disable|status|list> <rule_name>
  ```

---

## Notes

- Rule names must be **unique** for effective management. If duplicates exist, resolve them by renaming the rules in `/etc/config/firewall`.
- Changes are applied immediately after running the script using the `uci commit` and `firewall restart` commands.

---

## License

These scripts are redistributed under the MIT License. Feel free to modify and distribute them.

**© 2024 Vitovt ©**
