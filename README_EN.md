### WireGuard Management Script
[中文版本](./README.md)

This script is designed to manage WireGuard tunnels, including installing WireGuard, displaying current tunnel information, creating new tunnels, and generating and printing key pairs.

### Features

1. **Check and Install WireGuard**
   - Checks if WireGuard is installed on the system. If not installed, it will install it automatically.

2. **Display All Tunnel Information**
   - Displays information about all currently configured WireGuard tunnels.

3. **Create New Tunnel**
   - Guides the user through creating a new WireGuard tunnel, including generating keys, configuring files, and starting the tunnel.

4. **Generate and Print Key Pair**
   - Generates a new WireGuard key pair and prints it.

5. **Exit Script**
   - Exits the script.

### Instructions

1. **Permission Check**
   - Ensure the script is run as root to install packages and configure network interfaces.

2. **Starting the Script**
   - **First-time use**: Download and run the script using the following commands:
     ```bash
     curl -L https://github.com/sam13142023/Wireguard-shell/raw/main/main.sh -o wireguard.sh
     chmod +x wireguard.sh
     bash wireguard.sh
     ```
   - **Subsequent use**: After the initial setup, simply run `./wireguard.sh` in the script's directory.

3. **Main Menu**
   - Upon running the script, you will be presented with a main menu offering five options (1 to 5).

4. **Option Details**
   - Select the corresponding number to execute the desired functionality.

### Option Details

#### Check and Install WireGuard

- Selecting `1` will check if WireGuard is installed on the system. If not installed, it will update the package list and proceed with installation.

#### Display All Tunnel Information

- Selecting `2` will use the `wg show` command to display information about all currently configured WireGuard tunnels.

#### Create New Tunnel

- Selecting `3` will guide you through entering necessary configuration details to create a new WireGuard tunnel configuration file and enable the tunnel.
  - Configuration details include:
    - Configuration file name
    - Server IP address
    - Server port number
    - Tunnel local IP address
    - Local service port number
    - Peer WireGuard public key
  - After confirming the configuration details, the script will generate and save the configuration file, and start the tunnel.

#### Generate and Print Key Pair

- Selecting `4` will generate a new WireGuard public-private key pair and print the keys.

#### Exit Script

- Selecting `5` will exit the script.

### Notes

- Ensure the script is run with root privileges to enable package installation and network configuration.
- When creating a new tunnel, verify the accuracy of entered configuration details, especially IP addresses and public keys.

### Contact Information

For issues or suggestions, please submit an issue on GitHub.