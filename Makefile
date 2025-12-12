#---------------------------
# Makefile
#---------------------------
SHELL := $(shell which bash)
.DEFAULT_GOAL := help

# Default values
PLAYBOOK ?= proxmox
SCENARIO ?= proxmox
VERBOSE ?=
EXTRA_ARGS ?=

# Handle TAGS variable
ifdef TAGS
TAGS_ARG = --tags $(TAGS)
else
TAGS_ARG =
endif

#-------------------------------------------------------------
# Usage:
#
# make <playbook> [modifiers] <action>
#
# Examples:
#   make proxmox run              - Run proxmox playbook
#   make proxmox run TAGS=mdns    - Run mdns role only
#   make proxmox run TAGS=ssl       - Run ssl config only
#   make proxmox verbose run      - Run with -vvv
#   make proxmox_bootstrap run    - Run bootstrap playbook
#   make install deps             - Install Ansible collections
#-------------------------------------------------------------

.PHONY: help
help: ## Show help
	@echo 'Usage: make <playbook> [modifiers] <action> [VARS]'
	@echo ''
	@echo 'Playbooks:'
	@echo '  proxmox              Select proxmox playbook'
	@echo '  proxmox_bootstrap    Select proxmox_bootstrap playbook'
	@echo '  storage              Select storage playbook'
	@echo '  storage_bootstrap    Select storage_bootstrap playbook'
	@echo '  ubuntu_lxc           Select ubuntu_lxc playbook'
	@echo ''
	@echo 'Actions:'
	@echo '  run                  Run the selected playbook'
	@echo '  test                 Run molecule tests for selected playbook'
	@echo '  destroy              Destroy molecule test environment'
	@echo ''
	@echo 'Modifiers (place before action):'
	@echo '  verbose              Add -vvv to ansible-playbook'
	@echo '  check                Run in check mode (dry-run)'
	@echo ''
	@echo 'Variables:'
	@echo '  TAGS=<tag>           Run with --tags <tag>'
	@echo '  EXTRA_ARGS=<args>    Pass extra args to ansible-playbook'
	@echo ''
	@echo 'Utilities:'
	@echo '  make install deps    Install Ansible collections'
	@echo '  make tests           Run all molecule tests'
	@echo '  make lint            Lint playbooks and roles'
	@echo '  make clean           Destroy all molecule environments'
	@echo ''
	@echo 'Examples:'
	@echo '  make proxmox run'
	@echo '  make proxmox verbose run'
	@echo '  make proxmox run TAGS=mdns'
	@echo '  make proxmox run TAGS=ssl'
	@echo '  make proxmox_bootstrap run'
	@echo '  make proxmox_bootstrap test'

# ----------------------------------------------------------------
# Playbook selectors (set PLAYBOOK and SCENARIO variables)
# ----------------------------------------------------------------
.PHONY: proxmox proxmox_bootstrap storage storage_bootstrap ubuntu_lxc

proxmox: ## Select proxmox playbook
	$(eval PLAYBOOK = proxmox)
	$(eval SCENARIO = proxmox)

proxmox_bootstrap: ## Select proxmox_bootstrap playbook
	$(eval PLAYBOOK = proxmox_bootstrap)
	$(eval SCENARIO = proxmox_bootstrap)

storage: ## Select storage playbook
	$(eval PLAYBOOK = storage)
	$(eval SCENARIO = storage)

storage_bootstrap: ## Select storage_bootstrap playbook
	$(eval PLAYBOOK = storage_bootstrap)
	$(eval SCENARIO = storage_bootstrap)

ubuntu_lxc: ## Select ubuntu_lxc playbook
	$(eval PLAYBOOK = ubuntu_lxc)
	$(eval SCENARIO = ubuntu_lxc)

# ----------------------------------------------------------------
# Modifiers (set flags) - place BEFORE action in command
# ----------------------------------------------------------------
.PHONY: verbose check

verbose: ## Add verbose output
	$(eval VERBOSE = -vvv)

check: ## Run in check mode (dry-run)
	$(eval EXTRA_ARGS += --check)

# ----------------------------------------------------------------
# Actions
# ----------------------------------------------------------------
.PHONY: run test destroy

run: ## Run the selected playbook
	uv run ansible-playbook playbooks/$(PLAYBOOK).yml $(VERBOSE) $(TAGS_ARG) $(EXTRA_ARGS)

test: ## Run molecule tests for selected scenario
	uv run molecule test -s $(SCENARIO)

destroy: ## Destroy molecule test environment
	uv run molecule destroy -s $(SCENARIO)

# ----------------------------------------------------------------
# Utility targets
# ----------------------------------------------------------------
.PHONY: install deps tests clean lint

install: ## Utility selector
	@:

deps: ## Install Ansible collections
	uv run ansible-galaxy collection install -r requirements.yml

tests: ## Run ALL molecule tests
	uv run molecule test -s proxmox
	uv run molecule test -s proxmox_bootstrap
	uv run molecule test -s ubuntu_lxc

clean: ## Destroy all molecule environments
	uv run molecule destroy -s proxmox || true
	uv run molecule destroy -s proxmox_bootstrap || true
	uv run molecule destroy -s ubuntu_lxc || true

lint: ## Lint Ansible playbooks and roles
	uv run ansible-lint

# ----------------------------------------------------------------
# Catch-all (prevents "No rule to make target" errors)
# ----------------------------------------------------------------
%:
	@:
