# Proxmox Ansible Playbook

A comprehensive Ansible playbook for configuring and managing Proxmox Virtual Environment (PVE) clusters with Ceph storage, user management, API tokens, and Ubuntu Cloud-Init templates.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Roles](#roles)
- [Directory Structure](#directory-structure)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This playbook automates the setup and configuration of a Proxmox cluster with the following capabilities:

- **Cluster Configuration**: Sets up Proxmox cluster with Ceph storage
- **User Management**: Creates and manages Proxmox users
- **API Authentication**: Generates and manages API tokens with HashiCorp Vault integration
- **Template Creation**: Builds Ubuntu 24.04 Cloud-Init templates for VM provisioning
- **Network Configuration**: Configures networking (planned)

## Features

- ✅ **Automated Cluster Setup**: Configure Proxmox clustering with Ceph
- ✅ **Ceph Storage Pool Management**: Create and configure Ceph pools for VM storage
- ✅ **API Token Management**: Generate API tokens and store them securely in HashiCorp Vault
- ✅ **Ubuntu Cloud-Init Templates**: Automated creation of Ubuntu 24.04 VM templates
- ✅ **Task Runner Integration**: Use Taskfile for simplified command execution
- 🚧 **Network Configuration**: Static IP configuration (planned)
- 🚧 **User Management**: Proxmox user creation (planned)

## Prerequisites

- **Ansible**: 2.17+ with Python 3.8+
- **Proxmox VE**: 7.0+ or 8.0+
- **Python Packages**: Listed in `requirements/pip.txt`
- **Ansible Collections**: Listed in `requirements/ansible.yml`
- **Task**: [go-task](https://taskfile.dev/) for simplified command execution
- **HashiCorp Vault**: For secure API token storage (optional)

### System Requirements

- **Control Node**: Linux/macOS with Ansible installed
- **Target Nodes**: Proxmox VE nodes with SSH access
- **Network**: All nodes should be able to communicate with each other

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd proxmox-ansible
   ```

2. **Install dependencies using Task**:
   ```bash
   task install
   ```

   Or manually:
   ```bash
   pip install -r requirements/pip.txt
   ansible-galaxy install -r requirements/ansible.yml
   ```

3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```bash
# Proxmox Authentication
PROXMOX_URL="http://pve0.lan:8006"
PROXMOX_USER="root@pam"
PROXMOX_PASSWORD="your-password"
```

### Inventory Configuration

Edit `inventories/proxmox.yml` to match your environment. The inventory uses the Proxmox dynamic inventory plugin.

### Group Variables

Configure cluster settings in `group_vars/proxmox_nodes/pve.yml`:

```yaml
pve_group: proxmox_nodes
pve_cluster_enabled: true
pve_cluster_clustername: pvec01
pve_ceph_enabled: true
pve_ceph_pools:
  - name: ceph-vm
    pgs: 32
    storage: true
    application: rbd
    rule: replicated_rule
    size: 2
    min-size: 1
```

## Usage

### Validate Configuration

```bash
task validate
```

### Deploy to Proxmox Cluster

```bash
task deploy
```

### Deploy to Specific Inventory

```bash
task deploy INVENTORY=production
```

### Manual Execution

```bash
ansible-playbook -i inventories/proxmox.yml --vault-password-file .vault-pass main.yml
```

## Roles

| Role | Description | Status |
|------|-------------|---------|
| [preconfigure](roles/preconfigure/README.md) | System prerequisites and base configuration | ✅ Complete |
| [lae.proxmox](https://github.com/lae/ansible-role-proxmox) | Core Proxmox and Ceph setup | ✅ External |
| [network](roles/network/README.md) | Network configuration | 🚧 Planned |
| [pve_users](roles/pve_users/README.md) | Proxmox user management | 🚧 Planned |
| [pve_auth_tokens](roles/pve_auth_tokens/README.md) | API token generation and Vault storage | ✅ Complete |
| [ubuntu_cloudinit_template](roles/ubuntu_cloudinit_template/README.md) | Ubuntu Cloud-Init template creation | ✅ Complete |

## Directory Structure

```
proxmox-ansible/
├── README.md                           # This file
├── main.yml                           # Main playbook
├── Taskfile.yml                       # Task runner configuration
├── requirements/
│   ├── ansible.yml                    # Ansible collections and roles
│   └── pip.txt                        # Python dependencies
├── inventories/
│   └── proxmox.yml                    # Dynamic inventory configuration
├── group_vars/
│   └── proxmox_nodes/
│       ├── pve.yml                    # Proxmox cluster configuration
│       └── ssh_auth.yml               # SSH authentication settings
└── roles/
    ├── preconfigure/                  # System preparation role
    ├── network/                       # Network configuration role
    ├── pve_users/                     # User management role
    ├── pve_auth_tokens/              # API token management role
    └── ubuntu_cloudinit_template/     # Ubuntu template creation role
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PROXMOX_USER` | Proxmox username (e.g., root@pam) | Yes | - |
| `PROXMOX_PASSWORD` | Proxmox password | Yes | - |

## Troubleshooting

### Common Issues

1. **Connection Timeout**
   ```bash
   # Check SSH connectivity
   ansible proxmox_nodes -i inventories/proxmox.yml -m ping
   ```

2. **Permission Denied**
   - Ensure PROXMOX_USER has sufficient privileges
   - Verify SSH key authentication or password

3. **Ceph Configuration Issues**
   - Check network connectivity between nodes
   - Verify storage configuration in group_vars

4. **Template Creation Fails**
   - Ensure sufficient storage space
   - Check internet connectivity for image download

### Debug Mode

Run with verbose output:
```bash
ansible-playbook -vvv -i inventories/proxmox.yml main.yml
```

### Syntax Check

```bash
ansible-playbook --syntax-check main.yml
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Development Guidelines

- Follow Ansible best practices
- Update documentation for new features
- Test changes in a lab environment
- Use meaningful commit messages

## License

[Specify your license here]

## Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review role-specific documentation

---

**Note**: This playbook is designed for infrastructure automation. Always test in a non-production environment first.