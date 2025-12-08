# ansible-homelab

Ansible roles and playbooks to configure servers in a homelab.

## Features

- **Tailscale** - Zero-config VPN mesh network with SSH access
- **mDNS** - Local network discovery via Avahi (`.local` hostnames)
- **Vault Integration** - Secure secret management via HashiCorp Vault

## Prerequisites

- Python 3.12+
- [uv](https://github.com/astral-sh/uv) package manager
- HashiCorp Vault (for Tailscale auth keys)
- Docker (for Molecule tests)

## Quick Start

```bash
# Install dependencies
uv sync

# Install Ansible collections
make install deps

# Bootstrap a new Proxmox host (via IP address)
make proxmox_bootstrap run

# Configure Proxmox host (via Tailscale)
make proxmox run
```

## Project Structure

```
.
├── inventory/
│   ├── hosts.yml              # Host inventory
│   └── group_vars/
│       ├── proxmox.yml        # Proxmox group variables
│       └── proxmox_bootstrap.yml
├── playbooks/
│   ├── proxmox.yml            # Main Proxmox configuration
│   ├── proxmox_bootstrap.yml  # Bootstrap via IP (before Tailscale)
│   └── proxmox_firstboot.yml  # Ansible-pull first boot
├── roles/
│   └── mdns/                  # Avahi mDNS configuration
├── molecule/                  # Molecule test scenarios
│   ├── proxmox/
│   └── proxmox_bootstrap/
└── Makefile                   # Task runner
```

## Usage

### Make Commands

```bash
make help                      # Show all commands

# Playbook execution
make proxmox run               # Run proxmox playbook
make proxmox run TAGS=mdns     # Run specific tag
make proxmox run TAGS=tailscale # Run tailscale only
make proxmox verbose run       # Run with -vvv
make proxmox check run         # Dry-run mode

# Bootstrap (new hosts via IP)
make proxmox_bootstrap run

# Testing
make proxmox test              # Molecule test proxmox
make proxmox_bootstrap test    # Molecule test bootstrap
make tests                     # Run all tests
make lint                      # Lint playbooks and roles

# Utilities
make install deps              # Install Ansible collections
make clean                     # Destroy test environments
```

### Workflow

1. **Bootstrap** - Install Tailscale on new hosts via IP address:
   ```bash
   # Set IP in inventory/hosts.yml under proxmox_bootstrap
   make proxmox_bootstrap run
   ```

2. **Configure** - Run full configuration via Tailscale:
   ```bash
   # Update inventory/hosts.yml with Tailscale hostname
   make proxmox run
   ```

## Vault Setup

The playbooks fetch Tailscale auth keys from HashiCorp Vault.

### Authentication

Set `VAULT_TOKEN` environment variable, or enter credentials when prompted:
```bash
export VAULT_TOKEN="your-token"
make proxmox run
```

### Secret Path

Tailscale auth key is stored at: `kv/tailscale`
```bash
vault kv put kv/tailscale auth-key="tskey-auth-..."
```

## Roles

### mdns

Configures Avahi for mDNS/Bonjour discovery.

**Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `mdns_hostname` | `{{ ansible_hostname }}` | Hostname to advertise |
| `mdns_interface` | `vmbr0` | Network interface |
| `mdns_domain` | `local` | mDNS domain |
| `mdns_publish_ssh` | `true` | Advertise SSH service |
| `mdns_publish_http` | `true` | Advertise Proxmox web UI |
| `mdns_http_port` | `8006` | Proxmox web UI port |

**Usage:**
```bash
# After running, access via:
ssh root@proxmox.local
https://proxmox.local:8006
```

## Inventory

### hosts.yml

```yaml
all:
  children:
    proxmox:
      hosts:
        proxmox01:
          ansible_host: proxmox.local  # Tailscale or mDNS hostname
          ansible_user: root

    proxmox_bootstrap:
      hosts:
        proxmox01_bootstrap:
          ansible_host: 192.168.1.30   # IP for initial bootstrap
          ansible_user: root
```

## Testing

Uses [Molecule](https://molecule.readthedocs.io/) with Docker for testing.

```bash
# Run all tests
make tests

# Run specific scenario
make proxmox test
make proxmox_bootstrap test

# Cleanup
make clean
```

## Development

```bash
# Lint code
make lint

# Install dev dependencies
uv sync
```

## License

MIT
