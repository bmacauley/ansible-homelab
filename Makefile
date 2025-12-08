.PHONY: help bootstrap proxmox install-collections tailscale-uninstall tailscale-reinstall test test-proxmox test-proxmox-bootstrap test-all test-verbose test-destroy

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

bootstrap: ## Bootstrap new hosts with Tailscale (via IP address)
	uv run ansible-playbook playbooks/proxmox_bootstrap.yml

proxmox: ## Run the Proxmox playbook (via Tailscale)
	uv run ansible-playbook playbooks/proxmox.yml

install-collections: ## Install required Ansible collections
	uv run ansible-galaxy collection install -r requirements.yml

tailscale-uninstall: ## Uninstall Tailscale from Proxmox hosts
	uv run ansible-playbook playbooks/proxmox.yml -e tailscale_state=absent

tailscale-reinstall: ## Reinstall Tailscale on Proxmox hosts
	uv run ansible-playbook playbooks/proxmox.yml -e tailscale_state=present

test: test-all ## Run all Molecule tests (alias)

test-proxmox: ## Run Molecule tests for proxmox scenario
	uv run molecule test -s proxmox

test-proxmox-bootstrap: ## Run Molecule tests for proxmox_bootstrap scenario
	uv run molecule test -s proxmox_bootstrap

test-all: ## Run all Molecule test scenarios
	uv run molecule test -s proxmox
	uv run molecule test -s proxmox_bootstrap

test-verbose: ## Run Molecule tests with verbose output
	uv run molecule test -s proxmox --debug

test-destroy: ## Destroy all Molecule test environments
	uv run molecule destroy -s proxmox
	uv run molecule destroy -s proxmox_bootstrap

