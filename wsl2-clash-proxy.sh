#!/bin/bash

# Obtain the WSL2 IP address using PowerShell from within WSL
WSL2_IP=$(powershell.exe -Command "Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL (Hyper-V firewall))' -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress")

# Verify if the IP address was successfully obtained
if [ -z "$WSL2_IP" ]; then
    echo "Failed to obtain the WSL2 IP address."
    exit 1
fi

echo "WSL2 IP Address: $WSL2_IP"

# Proxy management based on the command argument
case "$1" in
    start)
        echo "Starting the proxy..."
        # Set up environment variables for proxy configuration
        export http_proxy="http://$WSL2_IP:7890"
        export https_proxy="https://$WSL2_IP:7890"
        ;;
    stop)
        echo "Stopping the proxy..."
        # Clear proxy environment variables
        unset http_proxy https_proxy
        ;;
    check)
        echo "Checking the proxy connection..."
        # Attempt to access a known URL and check for successful HTTP response
        if curl -s http://www.google.com > /dev/null; then
            echo "Proxy connection is up."
        else
            echo "Proxy connection is down."
        fi
        ;;
    *)
        echo "Invalid command. Use 'start', 'stop', or 'check'."
        ;;
esac
