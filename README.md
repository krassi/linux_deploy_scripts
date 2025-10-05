# linux_deploy_scripts

## deploy_ssh_key.sh

A bash script that automates the deployment of SSH public keys to remote hosts for passwordless authentication.

### Description

This script connects to a remote host via SSH and sets up SSH key-based authentication by:
- Creating the `.ssh` directory in the user's home directory (if it doesn't exist)
- Setting proper permissions (700) on the `.ssh` directory
- Appending the provided public key to the `~/.ssh/authorized_keys` file
- Setting proper permissions (600) on the `authorized_keys` file

### Usage

```bash
./deploy_ssh_key.sh [--password|-p] <username>@<host>[:<port>] <public key file or string>
```

### Parameters

- `--password` or `-p` (optional): Force password authentication and disable SSH key-based authentication when connecting
- `<username>@<host>[:<port>]`: Connection string specifying the remote user, host, and optional port (defaults to 22)
- `<public key file or string>`: Either a filename containing the SSH public key or the literal SSH public key string

### Public Key Resolution

The script intelligently determines whether the second argument is a public key string or a filename:

1. If the argument matches the SSH public key pattern (`ssh-*` followed by base64), it treats it as a literal key
2. Otherwise, it searches for the file in:
   - Current directory (exact filename)
   - User's `~/.ssh/` directory (exact filename)

### Examples

```bash
# Deploy using a key file in current directory
./deploy_ssh_key.sh user@example.com id_rsa.pub

# Deploy with custom port
./deploy_ssh_key.sh user@example.com:2222 id_rsa.pub

# Deploy using a key file from ~/.ssh
./deploy_ssh_key.sh user@example.com my_key.pub

# Deploy using literal public key string
./deploy_ssh_key.sh user@example.com "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."

# Force password authentication (useful when key-based auth is already configured)
./deploy_ssh_key.sh --password user@example.com id_rsa.pub
./deploy_ssh_key.sh -p user@example.com:2222 id_rsa.pub
```

### Requirements

- SSH access to the remote host
- Valid credentials (password or existing SSH key) for initial connection
- Bash shell on both local and remote systems