# ansible-homelab

Ansible roles and playbooks to configure servers in a homelab.

## Features

- **Tailscale** - Zero-config VPN mesh network with SSH access
- **MagicDNS** - Tailscale DNS integration via systemd-resolved
- **mDNS** - Local network discovery via Avahi (`.local` hostnames)
- **MinIO** - S3-compatible object storage
- **Proxmox** - Hypervisor configuration with SSL, repos, and LXC templates
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

# Bootstrap a new storage host (via IP address)
make storage_bootstrap run

# Configure storage host (via Tailscale)
make storage run
```

## Project Structure

```
.
├── inventory/
│   ├── hosts.yml                 # Host inventory
│   └── group_vars/
│       ├── proxmox.yml           # Proxmox group variables
│       ├── proxmox_bootstrap.yml
│       ├── storage.yml           # Storage group variables
│       └── storage_bootstrap.yml
├── playbooks/
│   ├── proxmox.yml               # Proxmox configuration
│   ├── proxmox_bootstrap.yml     # Proxmox bootstrap (Tailscale install)
│   ├── storage.yml               # Storage node configuration
│   ├── storage_bootstrap.yml     # Storage bootstrap (Tailscale install)
│   └── site.yml                  # Main entrypoint (all hosts)
├── roles/
│   ├── proxmox/                  # Proxmox hypervisor configuration
│   ├── dns/                      # systemd-resolved + Tailscale MagicDNS
│   ├── mdns/                     # Avahi mDNS configuration
│   └── minio/                    # MinIO S3-compatible storage
├── molecule/                     # Molecule test scenarios
│   ├── proxmox/
│   ├── proxmox_bootstrap/
│   ├── storage/
│   └── storage_bootstrap/
└── Makefile                      # Task runner
```

## Playbooks

### proxmox_bootstrap

Bootstrap a new Proxmox host by installing Tailscale via IP address.

```bash
make proxmox_bootstrap run
```

**What it does:**
- Connects via IP address with root password
- Authenticates to Vault for Tailscale auth key
- Disables Proxmox enterprise repositories
- Installs Tailscale and joins the tailnet
- Configures DNS for MagicDNS resolution

### proxmox

Configure Proxmox hosts (assumes Tailscale already installed).

```bash
make proxmox run
make proxmox run TAGS=ssl        # SSL certificates only
make proxmox run TAGS=dns        # DNS configuration only
make proxmox run TAGS=mdns       # mDNS/Avahi only
```

**Roles included:** proxmox, dns, mdns

### storage_bootstrap

Bootstrap a new storage host by installing Tailscale via IP address.

```bash
make storage_bootstrap run
```

**What it does:**
- Connects via IP address with ubuntu user password
- Authenticates to Vault for Tailscale auth key
- Configures passwordless sudo for ubuntu user
- Installs Tailscale and joins the tailnet

### storage

Configure storage hosts with MinIO and mDNS.

```bash
make storage run
make storage run TAGS=minio      # MinIO only
make storage run TAGS=mdns       # mDNS only
```

**Roles included:** mdns, minio

## Roles

### proxmox

Configures Proxmox hypervisor settings including repositories, SSL, and LXC templates.

| Variable | Default | Description |
|----------|---------|-------------|
| `proxmox_timezone` | `Europe/London` | System timezone |
| `proxmox_disable_enterprise_repo` | `true` | Disable enterprise repos |
| `proxmox_enable_no_subscription_repo` | `true` | Enable no-subscription repo |
| `proxmox_ssl_enabled` | `true` | Enable Tailscale SSL certificates |
| `proxmox_ssl_auto_renew` | `true` | Setup cert renewal cron job |
| `proxmox_lxc_templates_enabled` | `true` | Download LXC templates |
| `proxmox_lxc_templates` | `[ubuntu-24.04, debian-13, alpine-3.22]` | Templates to download |

**Tags:** `proxmox`, `ssl`, `iso-builder`, `repos`

### dns

Configures systemd-resolved for Tailscale MagicDNS integration.

| Variable | Default | Description |
|----------|---------|-------------|
| `dns_enable_resolved` | `true` | Enable systemd-resolved |
| `dns_tailscale_accept_dns` | `true` | Accept Tailscale MagicDNS |
| `dns_fallback_servers` | `[1.1.1.1, 8.8.8.8]` | Fallback DNS servers |
| `dns_multicast_dns` | `resolve` | mDNS mode (allow Avahi) |
| `dns_dnssec` | `allow-downgrade` | DNSSEC validation mode |
| `dns_over_tls` | `false` | Enable DNS over TLS |

**Tags:** `role-dns`, `install`, `config`, `service`, `tailscale`

### mdns

Configures Avahi for mDNS/Bonjour discovery (`.local` hostnames).

| Variable | Default | Description |
|----------|---------|-------------|
| `mdns_hostname` | `{{ ansible_hostname }}` | Hostname to advertise |
| `mdns_interface` | `vmbr0` | Network interface |
| `mdns_domain` | `local` | mDNS domain |
| `mdns_publish_ssh` | `true` | Advertise SSH service |
| `mdns_publish_http` | `true` | Advertise HTTP service |
| `mdns_http_port` | `8006` | HTTP port to advertise |

**Tags:** `role-mdns`, `install`, `config`, `service`

**Usage:**
```bash
# After running, access via:
ssh root@proxmox.local
https://proxmox.local:8006
```

### minio

Installs and configures MinIO S3-compatible object storage.

| Variable | Default | Description |
|----------|---------|-------------|
| `minio_root_user` | (required) | MinIO admin username |
| `minio_root_password` | (required) | MinIO admin password |
| `minio_server_port` | `9000` | S3 API port |
| `minio_console_port` | `9001` | Web console port |
| `minio_data_dirs` | `[/var/lib/minio]` | Data directories |
| `minio_install_server` | `true` | Install MinIO server |
| `minio_install_client` | `true` | Install MinIO client (mc) |
| `minio_enable_tls` | `false` | Enable TLS |
| `minio_service_enabled` | `true` | Enable service on boot |

**Tags:** `role-minio`, `install`, `config`, `service`

## Usage

### Make Commands

```bash
make help                         # Show all commands

# Proxmox
make proxmox run                  # Configure Proxmox
make proxmox_bootstrap run        # Bootstrap new Proxmox host

# Storage
make storage run                  # Configure storage host
make storage_bootstrap run        # Bootstrap new storage host

# Common options
make <playbook> run TAGS=<tag>    # Run specific tags
make <playbook> verbose run       # Run with -vvv
make <playbook> check run         # Dry-run mode

# Testing
make tests                        # Run all molecule tests
make proxmox test                 # Test proxmox scenario
make storage test                 # Test storage scenario
make lint                         # Lint playbooks and roles

# Utilities
make install deps                 # Install Ansible collections
make clean                        # Destroy test environments
```

### Workflow

1. **Bootstrap** - Install Tailscale on new hosts via IP address:
   ```bash
   # Set IP in inventory/hosts.yml under proxmox_bootstrap or storage_bootstrap
   make proxmox_bootstrap run   # For Proxmox hosts
   make storage_bootstrap run   # For storage hosts
   ```

2. **Configure** - Run full configuration via Tailscale:
   ```bash
   # Update inventory/hosts.yml with Tailscale hostname
   make proxmox run    # For Proxmox hosts
   make storage run    # For storage hosts
   ```

## Vault Setup

The playbooks fetch secrets from HashiCorp Vault.

### Authentication

Playbooks prompt for Vault username/password and get a fresh token each run:
```bash
make proxmox run
# Vault username [bmacauley]:
# Vault password:
```

Set `VAULT_USERNAME` to change the default:
```bash
export VAULT_USERNAME="myuser"
```

### Required Secrets

| Path | Key | Description |
|------|-----|-------------|
| `kv/tailscale` | `auth-key` | Tailscale auth key |

```bash
# Setup Tailscale auth key
vault kv put kv/tailscale auth-key="tskey-auth-..."
```

## Inventory

### hosts.yml

```yaml
all:
  children:
    proxmox:
      hosts:
        proxmox01:
          ansible_host: proxmox.tailnet-name.ts.net
          ansible_user: root

    proxmox_bootstrap:
      hosts:
        proxmox01_bootstrap:
          ansible_host: 192.168.1.30
          ansible_user: root

    storage:
      hosts:
        storage01:
          ansible_host: storage.tailnet-name.ts.net
          ansible_user: ubuntu

    storage_bootstrap:
      hosts:
        storage01_bootstrap:
          ansible_host: 192.168.1.31
          ansible_user: ubuntu
```

## Testing

Uses [Molecule](https://molecule.readthedocs.io/) with Docker for testing.

```bash
# Run all tests
make tests

# Run specific scenario
make proxmox test
make proxmox_bootstrap test
make storage test
make storage_bootstrap test

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
