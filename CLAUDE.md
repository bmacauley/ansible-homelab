# CLAUDE.md

This document provides guidance for Claude Code when working in this repository. It defines the conventions, structure, and safe-editing rules for all Ansible code, roles, playbooks, and supporting Python scripts used in the homelab infrastructure.

The conventions below apply strictly to anything that is developed in this repository.
When using third-party content (e.g. Galaxy roles, collections), aim to align with these conventions where reasonable, but a perfect match is not required.

---

## Project Scope

This repository manages a homelab environment using Ansible. It includes:
Configuration and lifecycle management for physical and virtual servers
Standard roles for system setup, networking, storage, containers, monitoring, and supporting services
Playbooks for provisioning, updating, and auditing node state
Python helper scripts that generate inventory or retrieve external secrets
Core principles: idempotency, reproducibility, and minimal drift.

---

## Workflow Conventions

### Running Playbooks

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit webservers
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags setup,config
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvv

```

### Validation & Testing

```bash
ansible-playbook --syntax-check playbooks/site.yml
ansible-lint playbooks/site.yml
ansible -i inventory/hosts.yml all -m ping
ansible -i inventory/hosts.yml all --list-hosts

```
---

## Repository Architecture

### Directory Structure
```
ansible-homelab/
├── ansible.cfg
├── inventory/
│   ├── hosts.yml
│   ├── group_vars/
│   └── host_vars/
├── playbooks/
│   ├── site.yml
│   └── *.yml
├── roles/
│   └── <role>/
│       ├── tasks/
│       ├── handlers/
│       ├── templates/
│       ├── files/
│       ├── defaults/
│       └── vars/
├── scripts/
│   └── <python scripts>
└── requirements.yml
```


### Inventory Organization
- Use YAML format for inventory files for better readability
- Group hosts by function (webservers, databases, monitoring, etc.)
- Use `group_vars/` for variables shared across host groups
- Use `host_vars/` for host-specific configuration
- Store sensitive data in Ansible Vault encrypted files


### Role Design Principles (for roles developed in this repo)

1. Single responsibility per role
  Examples: zfs, docker, k3s_node, tailscale, node_exporter.

2. Idempotency
  No changes should be reported if the system state is already correct.

3. Variable usage
  - defaults/main.yml → user-overridable variables
  - vars/main.yml → internal constants
  - Use namespaced variables (role_name_*)

4. Templates & Files
  - Jinja2 templates in templates/
  - Static files in files/
  - No inline templates inside tasks

5. Handlers
  - Only restart services when necessary
  - Keep handlers local to the role

6. Tags
  Each task must include:
  - role-<name>
  - At least one functional tag (install, config, service, etc.)

7. Error handling
  Avoid ignore_errors: true unless explicitly justified.


## Playbook Standards

site.yml
- Main entrypoint for entire environment.
- Must contain only:
  - pre_tasks
  - roles
  - post_tasks
- No inline tasks outside those sections.

Example:

```yaml
- hosts: all
  gather_facts: true

  pre_tasks:
    - name: Ensure Python exists
      ansible.builtin.raw: test -e /usr/bin/python3 || (apt update -y && apt install -y python3)

  roles:
    - common
    - tailscale
    - docker
    - kubernetes_node
    - monitoring

  post_tasks:
    - name: Validate node uptime
      ansible.builtin.command: uptime
      changed_when: false

```

## Test Playbooks

- Use playbooks/test-<role>.yml for isolated testing.
- Should load only one role.

---

## Scripts Directory (Python Only)

The scripts/ directory contains Python utilities that support Ansible workflows.
These scripts are intended for:
- Retrieving tokens or secrets (e.g. from Vault)
- Generating dynamic inventory (e.g. based on Tailscale)
- Machine-readable data transformations that Ansible consumes

## Conventions

- All scripts must be Python 3 only.
- Must be fully non-interactive.
- Must exit non-zero on error.
- Must not print secrets except intended output.
- Filenames in snake_case.
- Scripts must be safe for use from CI or a Makefile.
- Scripts should not modify files unless explicitly documented.

---

## Use of Third-Party Roles and Collections

Before developing a new role in this repo, Claude should:

1. Investigate existing third-party roles/collections
  - Search Ansible Galaxy and GitHub for suitable roles/collections (e.g. Tailscale, Docker, k3s, etc.).
  - Prefer well-maintained, widely-used roles with clear documentation.

2. Evaluate suitability
  - Do they roughly align with our needs (platform support, features, security expectations)?
  - Are they reasonably compatible with our conventions (variable naming, idempotency, structure)?
  - Are they actively maintained?

3. Propose one of the following:
  - Reuse directly via requirements.yml if it’s a good fit.
  - Wrap or extend the third-party role in a thin local role that:
    - Adapts variable names
    - Adds missing behavior
    - Keeps external code logically isolated
  - Develop a new local role only when:
  - No suitable third-party role exists, or
  - Requirements are specialised enough that wrapping would be more complex than implementing.

4. Conventions for third-party roles:
  - Third-party roles do not need to fully match our internal layout or tags.
  - Aim for consistency when possible, but do not reject a solid upstream role solely because it doesn’t perfectly follow our conventions.
  - Keep local adaptations minimal and well-documented (e.g. in role README or comments).

Claude should briefly document (in comments or commit/PR description) which options were considered and why a given approach (reuse vs wrap vs custom) was chosen.

---

## Editing Rules for Claude

### Required Behaviors
- Preserve all directory and naming conventions.
- Use fully qualified module names (ansible.builtin.*).
- Maintain role boundaries and variable scopes.
- Ensure tasks remain idempotent.
- Prefer built-in modules over shell commands.
- Move secrets to Vaulted files if encountered.
- Maintain Python coding standards in scripts/.

### Avoid
- Directly adding tasks inside site.yml
- Hardcoding hostnames anywhere
- Creating cross-role variable dependencies
- Adding prompts or interactive steps
- Using external roles without justification
- Modifying script outputs without clear reason

The intent is not to block using external code or adding new features, but to:

- Prefer reusing solid third-party work where it makes sense.
- Keep locally developed code consistent and maintainable.
- Make Claude’s changes easier to review, reason about, and roll back if needed.

## Makefile Conventions

A Makefile is used as a uniform interface for common operational tasks across the repository.
All targets must be:
- Non-interactive
- Idempotent
- Safe to run multiple times
- Explicit about their outputs

The overarching goals:
- Provide short, memorable commands (make ping, make lint, etc.)
- Wrap Ansible and Python scripts cleanly
- Avoid repeating long command chains in documentation or CI
- Standardize developer workflows


### General Guidelines
- All targets must be phony unless they build actual files.
- Use namespaced targets where appropriate (ansible-*, inventory-*, vault-*, etc.).
- Commands should run with sane defaults but permit overrides via environment variables (e.g. HOSTS, TAGS, LIMIT, EXTRA_VARS).
- Commands must fail on error (set -e inside shell blocks).

Example header:
``` make
SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Available targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
```

This enables automatic help output via:
``` make
make help
```

