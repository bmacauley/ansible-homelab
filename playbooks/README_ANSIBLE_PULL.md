# Ansible Pull Usage

## Proxmox First Boot Playbook

The `proxmox_firstboot.yml` playbook is designed to be run via `ansible-pull` on a fresh Proxmox installation. It installs Tailscale without activating it, allowing for manual activation later.

### Quick Start

On a fresh Proxmox host, run:

```bash
# Install ansible if not present
apt update && apt install -y ansible git

# Pull and run the first boot playbook
ansible-pull \
  -U https://github.com/YOUR_USERNAME/ansible-homelab.git \
  -i localhost, \
  playbooks/proxmox_firstboot.yml
```

### What It Does

1. Ensures Python 3 is installed
2. Adds Tailscale APT repository
3. Installs Tailscale package
4. Enables but does NOT start the Tailscale service
5. Validates the installation

### After First Boot

To activate Tailscale after the first boot setup:

```bash
# Option 1: Manual activation with auth key
tailscale up --authkey=tskey-auth-YOUR-KEY-HERE --accept-routes --accept-dns

# Option 2: Run the full proxmox.yml playbook
ansible-pull \
  -U https://github.com/YOUR_USERNAME/ansible-homelab.git \
  -i localhost, \
  -e @/path/to/vault_vars.yml \
  --ask-vault-pass \
  playbooks/proxmox.yml
```

### Advanced Usage

#### Specify a branch or tag
```bash
ansible-pull \
  -U https://github.com/YOUR_USERNAME/ansible-homelab.git \
  -C main \
  -i localhost, \
  playbooks/proxmox_firstboot.yml
```

#### Run with specific tags
```bash
ansible-pull \
  -U https://github.com/YOUR_USERNAME/ansible-homelab.git \
  -i localhost, \
  --tags tailscale,install \
  playbooks/proxmox_firstboot.yml
```

#### Verbose output for debugging
```bash
ansible-pull \
  -U https://github.com/YOUR_USERNAME/ansible-homelab.git \
  -i localhost, \
  -vvv \
  playbooks/proxmox_firstboot.yml
```

### One-Liner for Copy/Paste

```bash
apt update && apt install -y ansible git && ansible-pull -U https://github.com/YOUR_USERNAME/ansible-homelab.git -i localhost, playbooks/proxmox_firstboot.yml
```

### Setting Up Automatic Pull on Boot

To run this automatically on every boot (until disabled):

```bash
# Create a systemd service
cat > /etc/systemd/system/ansible-pull-firstboot.service <<'EOF'
[Unit]
Description=Ansible Pull First Boot Configuration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U https://github.com/YOUR_USERNAME/ansible-homelab.git -i localhost, playbooks/proxmox_firstboot.yml
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable ansible-pull-firstboot.service

# Disable after successful first boot
systemctl disable ansible-pull-firstboot.service
```

### Security Considerations

- This playbook does NOT contain sensitive data (no auth keys)
- It only installs Tailscale without connecting to your tailnet
- Manual activation with auth key required
- For automated activation, use vault-encrypted variables with the main `proxmox.yml` playbook

### Troubleshooting

**Playbook fails to download:**
- Check internet connectivity
- Verify repository URL is correct
- Ensure git is installed

**Tailscale installation fails:**
- Check Debian/Ubuntu version compatibility
- Verify repository GPG key is accessible
- Try running with `-vvv` for detailed output

**Python not found:**
- The pre_tasks should handle this, but you can manually install: `apt install -y python3`
