# Preconfigure Role

The `preconfigure` role handles essential system preparation tasks that must be completed before other Proxmox configuration can proceed.

## Purpose

This role ensures that all Proxmox nodes have the necessary system prerequisites installed and configured properly. It serves as the foundation for subsequent configuration tasks.

## Tasks

### 1. Package Installation
- Installs required Python packages for Ansible module compatibility:
  - `python3-packaging`: Required for version comparison operations
  - `python3-apt`: Enables Ansible's apt module functionality

### 2. System Security
- Updates `/tmp` directory permissions to `1777` (sticky bit)
- Ensures proper ownership (root:root) for system directories

## Requirements

- Target systems running Debian-based Linux (Proxmox VE)
- Root or sudo access on target nodes
- Active internet connection for package downloads

## Dependencies

None. This role is designed to run first and establish the foundation for other roles.

## Variables

This role does not define any custom variables. It uses standard Ansible facts and built-in modules.

## Example Playbook

```yaml
- hosts: proxmox_nodes
  roles:
    - preconfigure
```

## Handlers

This role does not define any handlers as the tasks performed do not require service restarts.

## Tags

No custom tags are defined. Tasks can be filtered using standard Ansible task selection.

## Testing

To test this role independently:

```bash
ansible-playbook -i your_inventory --tags preconfigure main.yml
```

## Notes

- This role should always run first in the playbook sequence
- All tasks are idempotent and safe to run multiple times
- Package installation includes cache updates for reliability