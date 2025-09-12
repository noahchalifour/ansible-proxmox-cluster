# PVE Users Role

The `pve_users` role manages user accounts in Proxmox Virtual Environment, including user creation, permission assignments, and authentication realm configuration.

## Status

🚧 **Under Development** - This role is currently planned but not yet implemented.

## Purpose

This role will automate the creation and management of Proxmox users, enabling team members and services to access the Proxmox web console and API with appropriate permissions.

## Planned Features

### User Management
- Create Proxmox users in various authentication realms (PAM, PVE, LDAP, etc.)
- Assign users to groups with appropriate permissions
- Configure user-specific settings and preferences
- Manage user passwords and authentication methods

### Permission Management
- Create and manage user groups
- Assign role-based permissions to users and groups
- Configure resource-level access controls
- Manage API token permissions

### Authentication Realms
- Configure PAM authentication for local system users
- Set up LDAP/Active Directory integration
- Configure multi-factor authentication (if supported)

## Planned Variables

```yaml
# User definitions
pve_users:
  - name: "admin"
    realm: "pve"
    password: "{{ vault_admin_password }}"
    email: "admin@company.com"
    groups: ["administrators"]
    enabled: true

  - name: "developer"
    realm: "pve"
    password: "{{ vault_developer_password }}"
    email: "dev@company.com"
    groups: ["developers"]
    enabled: true

# Group definitions
pve_groups:
  - name: "administrators"
    comment: "Full administrative access"
    roles:
      - path: "/"
        role: "Administrator"

  - name: "developers"
    comment: "Development team access"
    roles:
      - path: "/vms"
        role: "VMOperator"
      - path: "/storage"
        role: "DatastoreUser"

# Authentication realm configuration
pve_realms:
  - realm: "pve"
    type: "pve"
    comment: "Proxmox VE authentication server"

# Default settings
pve_users_default_realm: "pve"
pve_users_password_policy: "strong"
```

## Requirements

- Proxmox VE cluster with API access
- Administrative privileges on Proxmox nodes
- HashiCorp Vault for password storage (recommended)

## Dependencies

- `preconfigure` role
- `pve_auth_tokens` role (for API access)

## Planned Tasks

1. **Realm Configuration**
   - Configure authentication realms
   - Set up LDAP/AD integration if required
   - Configure realm-specific settings

2. **Group Management**
   - Create user groups
   - Assign permissions to groups
   - Configure group-based access controls

3. **User Creation**
   - Create users in specified realms
   - Set user passwords securely
   - Assign users to groups
   - Configure user-specific settings

4. **Permission Assignment**
   - Apply role-based permissions
   - Configure resource-level access
   - Set up API token permissions

5. **Validation**
   - Test user authentication
   - Verify permission assignments
   - Validate group memberships

## Usage

Once implemented, this role will be used as follows:

```yaml
- hosts: proxmox_nodes
  roles:
    - preconfigure
    - pve_auth_tokens
    - pve_users
  vars:
    pve_users:
      - name: "john.doe"
        realm: "pve"
        password: "{{ vault_john_password }}"
        email: "john.doe@company.com"
        groups: ["operators"]
```

## Security Considerations

- Store passwords in Ansible Vault or external secret management
- Use strong password policies
- Implement least-privilege access principles
- Regular audit of user permissions
- Consider multi-factor authentication where possible

## Example Playbook

```yaml
---
- name: Configure Proxmox Users
  hosts: proxmox_nodes[0]  # Run on first node only
  vars:
    pve_users:
      - name: "backup-service"
        realm: "pve"
        password: "{{ vault_backup_password }}"
        groups: ["backup-operators"]
        comment: "Automated backup service account"
        
    pve_groups:
      - name: "backup-operators"
        roles:
          - path: "/"
            role: "BackupOperator"
  roles:
    - pve_users
```

## CLI Commands

When implemented, the role will use Proxmox CLI commands such as:

```bash
# Create user
pveum user add john@pve --password secret --email john@company.com

# Create group
pveum group add developers --comment "Development team"

# Assign user to group
pveum user modify john@pve --groups developers

# Set permissions
pveum acl modify /vms --users john@pve --roles VMOperator
```

## Testing

Planned testing approaches:

```bash
# Test user authentication
curl -k -d "username=john@pve&password=secret" \
  https://proxmox-host:8006/api2/json/access/ticket

# Verify user exists
pveum user list

# Check group memberships
pveum user list --full
```

## Implementation Notes

- User management should be idempotent
- Consider password rotation policies
- Implement proper error handling for authentication failures
- Document all custom roles and permissions
- Plan for user deactivation and cleanup procedures

## Related Roles

- `pve_auth_tokens`: For API token management
- `preconfigure`: For system prerequisites

## Contributing

To contribute to implementing this role:

1. Design user and group data structures
2. Implement user creation and management tasks
3. Add permission assignment logic
4. Create validation and testing tasks
5. Write comprehensive documentation
6. Add example configurations

## References

- [Proxmox VE User Management](https://pve.proxmox.com/wiki/User_Management)
- [Proxmox VE API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [pveum Command Reference](https://pve.proxmox.com/pve-docs/pveum.1.html)