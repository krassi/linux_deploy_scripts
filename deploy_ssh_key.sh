#!/bin/bash

# Script to set up SSH public key authentication on a remote host
# Usage: ./deploy_ssh_key.sh <username>@<host>[:<port>] [<public_ssh_key>]

set -e

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <username>@<host>[:<port>] [<public_ssh_key>]"
    echo "Example: $0 user@example.com:22 \"ssh-rsa AAAAB3NzaC1yc2E...\""
    echo "Example: $0 user@example.com id_rsa.pub"
    echo "Example: $0 user@example.com (will look for ~/.ssh/id_rsa.pub)"
    exit 1
fi

# Parse the connection string
CONNECTION="$1"
PUBLIC_KEY_ARG="${2:-}"

# Extract username, host, and port
PORT="22"  # Default port
if [[ $CONNECTION =~ ^([^@]+)@([^:]+):([0-9]+)$ ]]; then
    USERNAME="${BASH_REMATCH[1]}"
    HOST="${BASH_REMATCH[2]}"
    PORT="${BASH_REMATCH[3]}"
elif [[ $CONNECTION =~ ^([^@]+)@([^:]+)$ ]]; then
    USERNAME="${BASH_REMATCH[1]}"
    HOST="${BASH_REMATCH[2]}"
else
    echo "Error: Invalid connection string format. Expected <username>@<host>[:<port>]"
    exit 1
fi

# Determine the public key to use
if [ -z "$PUBLIC_KEY_ARG" ]; then
    # No key provided, look for default key in ~/.ssh
    DEFAULT_KEY="$HOME/.ssh/id_rsa.pub"
    if [ -f "$DEFAULT_KEY" ]; then
        echo "No public key specified, using $DEFAULT_KEY"
        PUBLIC_KEY=$(cat "$DEFAULT_KEY")
    else
        echo "Error: No public key provided and $DEFAULT_KEY not found"
        exit 1
    fi
elif [ -f "$PUBLIC_KEY_ARG" ]; then
    # Argument is a file path, read the key from it
    echo "Reading public key from $PUBLIC_KEY_ARG"
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_ARG")
elif [ -f "$HOME/.ssh/$PUBLIC_KEY_ARG" ]; then
    # Check if file exists in ~/.ssh directory
    echo "Reading public key from $HOME/.ssh/$PUBLIC_KEY_ARG"
    PUBLIC_KEY=$(cat "$HOME/.ssh/$PUBLIC_KEY_ARG")
else
    # Treat it as the actual key string
    PUBLIC_KEY="$PUBLIC_KEY_ARG"
fi

# Validate public key is not empty
if [ -z "$PUBLIC_KEY" ]; then
    echo "Error: Public SSH key cannot be empty"
    exit 1
fi

echo "Connecting to $HOST:$PORT as $USERNAME..."
echo "Setting up SSH key authentication..."

# SSH into the remote host and execute commands
ssh -p "$PORT" "${USERNAME}@${HOST}" bash <<EOF
set -e

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Set correct permissions on .ssh directory
chmod 700 ~/.ssh

# Append the public key to authorized_keys
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys

# Set correct permissions on authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "SSH key successfully added to ~/.ssh/authorized_keys"
EOF

echo "Done! SSH key has been installed on $HOST"
