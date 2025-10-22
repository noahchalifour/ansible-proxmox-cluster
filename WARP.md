# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is an Ansible automation project for managing Proxmox Virtual Environment (PVE) clusters. The playbook configures Proxmox clustering with Ceph storage, manages API tokens with HashiCorp Vault integration, and creates Ubuntu Cloud-Init templates for VM provisioning.

## Key Commands

### Installation & Setup
```bash
# Install all dependencies (Python packages + Ansible collections)
task install

# Manual installation
pip install -r requirements/pip.txt
ansible-galaxy install -r requirements/ansible.yml
```

### Validation & Testing
```bash
# Validate playbooks (runs ansible-lint and syntax check)
task validate

# Syntax check only
ansible-playbook --syntax-check main.yml

# Test connectivity to Proxmox nodes
ansible proxmox_nodes -i inventories/proxmox.yml -m ping
```

### Deployment
```bash
# Deploy to default inventory (proxmox.yml)
task deploy

# Deploy to specific inventory
task deploy INVENTORY=production

# Deploy with custom SSH key
task deploy SSH_PRIVATE_KEY=~/.ssh/custom_key

# Deploy with verbosity
task deploy VERBOSITY=vvv

# Manual deployment (requires .vault-pass file)
ansible-playbook -i inventories/proxmox.yml --vault-password-file .vault-pass main.yml
```

## Architecture

### Inventory System
- Uses **Proxmox dynamic inventory plugin** (`community.proxmox.proxmox`)
- Inventory files in `inventories/` define connection to Proxmox API
- The plugin auto-discovers Proxmox nodes and VMs from the Proxmox cluster
- Configure inventory in `inventories/proxmox.yml`

### Playbook Structure
The main playbook (`main.yml`) has two plays:

1. **Proxmox Node Configuration** (targets `proxmox_nodes` group):
   - `preconfigure`: Install system prerequisites (python3-packaging, python3-apt)
   - `lae.proxmox`: External role for core Proxmox/Ceph setup
   - `network`: Network configuration (planned)
   - `pve_users`: User management (planned)
   - `pve_auth_tokens`: Generate API tokens and store in HashiCorp Vault
   - `ubuntu_cloudinit_template`: Create Ubuntu 24.04 Cloud-Init templates
   - `pve_auto_update`: Configure automatic daily updates via cron

2. **VM Guest Configuration** (targets `proxmox_all_qemu` group):
   - `qemu_vm`: Configure QEMU virtual machines

### Role Execution Patterns

**Single-node execution**: Some roles (like `ubuntu_cloudinit_template`) only run on the first Proxmox node to avoid conflicts:
```yaml
when: ansible_host == hostvars[groups['proxmox_nodes'] | sort | first]['ansible_host']
```

**Idempotent operations**: Roles handle existing resources gracefully (e.g., API tokens skip creation if they already exist).

### Configuration Hierarchy
1. **Environment variables** (`.env` file, loaded by Taskfile)
   - `PROXMOX_USER`, `PROXMOX_PASSWORD`
2. **Group variables** (`group_vars/proxmox_nodes/`)
   - `pve.yml`: Cluster and Ceph configuration
   - `hc_vault.yml`: Vault endpoint configuration
   - `ssh_auth.yml`: SSH authentication settings
3. **Host variables** (`host_vars/`)
   - Per-node specific overrides
4. **Role defaults** (`roles/*/defaults/main.yml`)

### HashiCorp Vault Integration
- API tokens created by `pve_auth_tokens` role are stored in Vault
- Vault endpoint configured in `group_vars/proxmox_nodes/hc_vault.yml`
- Token path: defined by `proxmox_api_token_secret_path` variable
- Vault operations delegated to `localhost` (control node)

### Ceph Storage Configuration
- Configured through `lae.proxmox` role variables in `group_vars/proxmox_nodes/pve.yml`
- Default pool: `ceph-vm` (for VM storage)
- Pool parameters: size, min-size, pgs (placement groups), replication rule
- Storage pool must exist before running `ubuntu_cloudinit_template` role

## Development Patterns

### Adding New Roles
1. Create role directory in `roles/`
2. Follow standard Ansible role structure (defaults, tasks, vars, handlers)
3. Add role to appropriate play in `main.yml`
4. Document in role's README.md

### Variable Precedence
When defining variables, follow this precedence (lowest to highest):
1. Role defaults (`roles/*/defaults/main.yml`)
2. Group vars (`group_vars/proxmox_nodes/*.yml`)
3. Host vars (`host_vars/*.yml`)
4. Role vars (`roles/*/vars/main.yml`)
5. Task vars (inline in playbook)

### Ansible Vault Usage
- Vault password file: `.vault-pass` (gitignored)
- Encrypted files: `group_vars/proxmox_nodes/hc_vault_secrets.yml`
- Encrypt new variables: `ansible-vault encrypt_string 'secret_value' --name 'variable_name'`

### Testing Changes
1. Always validate before deploying: `task validate`
2. Test in non-production environment first
3. Use verbose mode for debugging: `task deploy VERBOSITY=vvv`
4. Check specific roles: `ansible-playbook -i inventories/proxmox.yml main.yml --tags role_name`

## Important Notes

### API Token Management
- Tokens created by `pve_auth_tokens` inherit permissions from the parent user
- Default tokens: `ansible`, `terraform`
- Token format: `username!tokenid` (e.g., `root@pam!ansible`)
- Tokens are idempotent - existing tokens won't be recreated

### Cloud-Init Templates
- Templates created with VM ID starting at 9000
- Only created on first node (sorted alphabetically)
- Uses Ceph storage pool specified in `ubuntu_cloudinit_template_vm_storage_pool`
- Default template: Ubuntu 24.04 with UEFI/OVMF BIOS

### Proxmox Clustering
- Cluster name defined in `pve_cluster_clustername` variable
- All nodes in `proxmox_nodes` group join the cluster
- Ceph must be enabled (`pve_ceph_enabled: true`) for storage features

### Automatic Updates
- Configured by `pve_auto_update` role to run daily at 3:00 AM by default
- Script deployed to `/usr/local/bin/pve-auto-update.sh`
- Logs to `/var/log/pve-auto-update.log` with automatic rotation
- Auto-reboot disabled by default (`pve_auto_update_auto_reboot: false`)
- Customize schedule per-host via `pve_auto_update_cron_hour` and `pve_auto_update_cron_minute`
- Disable updates by setting `pve_auto_update_enabled: false`

### CI/CD Pipeline
- GitLab CI configuration in `.gitlab-ci.yml`
- Stages: `validate`, `deploy-prod`
- Deployment to production triggered only on `internal` branch
- Requires GitLab CI variables: `VAULT_PASSWORD`, `SSH_PRIVATE_KEY`

## Environment Variables Reference

Required for deployment:
- `PROXMOX_URL`: URL for Proxmox host
- `PROXMOX_USER`: Proxmox username with admin privileges (e.g., `root@pam`)
- `PROXMOX_PASSWORD`: Password for Proxmox user

## Common Pitfalls

1. **Dynamic inventory requires valid Proxmox credentials**: The inventory plugin connects to Proxmox API, so credentials must be valid before running any playbook commands.

2. **Ceph pool must exist before template creation**: The `ubuntu_cloudinit_template` role assumes the storage pool exists. Run `lae.proxmox` role first.

3. **Vault integration is optional**: If `hashicorp_vault_endpoint` is empty, tokens are created but not stored in Vault.

4. **Template VM ID conflicts**: If VM ID 9000 exists, template creation fails. Remove existing VM or change `ubuntu_cloudinit_template_vm_id`.

5. **Single node execution**: Some tasks only run on first node. To force execution elsewhere, modify the `when` condition in task files.
