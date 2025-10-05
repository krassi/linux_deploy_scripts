#!/bin/bash

# Script to set up SSH public key authentication on a remote host
# Usage: ./deploy_ssh_key.sh <username>@<host>[:<port>] <public_ssh_key>

set -e

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username>@<host>[:<port>] <public_ssh_key>"
    echo "Example: $0 user@example.com:22 id_rsa"
    echo "Example: $0 user@example.com id_rsa.pub"
    exit 1
fi

# Parse the connection string
CONNECTION="$1"
PUBLIC_SSH_KEY="$2"

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
PUBLIC_KEY=""

# Check if the argument looks like an actual SSH public key (starts with ssh-)
if [[ "$PUBLIC_SSH_KEY" =~ ^ssh-[a-z0-9]+\ [A-Za-z0-9+/=]+.* ]]; then
    # It's an actual public key string
    echo "Using provided public key string"
    PUBLIC_KEY="$PUBLIC_SSH_KEY"
else
    # It's a filename, try to find the file
    if [ -f "$PUBLIC_SSH_KEY" ]; then
        echo "Using public key from: $PUBLIC_SSH_KEY"
        PUBLIC_KEY=$(cat "$PUBLIC_SSH_KEY")
    elif [ -f "$HOME/.ssh/$PUBLIC_SSH_KEY" ]; then
        echo "Using public key from: $HOME/.ssh/$PUBLIC_SSH_KEY"
        PUBLIC_KEY=$(cat "$HOME/.ssh/$PUBLIC_SSH_KEY")
    else
        echo "Error: SSH key file not found. Tried:"
        echo "  - $PUBLIC_SSH_KEY"
        echo "  - $HOME/.ssh/$PUBLIC_SSH_KEY"
        exit 1
    fi
fi

# Validate public key is not empty
if [ -z "$PUBLIC_KEY" ]; then
    echo "Error: Public SSH key is empty"
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
