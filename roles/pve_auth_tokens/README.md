# PVE Auth Tokens Role

The `pve_auth_tokens` role manages API authentication tokens for Proxmox Virtual Environment, including token creation and secure storage in HashiCorp Vault.

## Purpose

This role automates the creation of API tokens for various services (like Ansible and Terraform) that need to interact with the Proxmox API. It ensures secure token generation and storage while providing a consistent way to manage API access credentials.

## Features

- **Automated Token Creation**: Creates API tokens for specified services
- **Idempotent Operations**: Safely handles existing tokens without duplication
- **Vault Integration**: Securely stores tokens in HashiCorp Vault
- **Error Handling**: Robust error handling for token creation failures

## Variables

### Default Variables (`defaults/main.yml`)

```yaml
pve_auth_tokens_ids:
  - ansible    # Token for Ansible automation
  - terraform  # Token for Terraform infrastructure
```

### Required Variables (`vars/main.yml`)

```yaml
# Proxmox user for token creation (from environment)
pve_auth_tokens_user: "{{ lookup('ansible.builtin.env', 'PROXMOX_USER') }}"
```

### External Variables (Group Vars)

The following variables should be defined in your group_vars or inventory:

```yaml
# HashiCorp Vault configuration
hashicorp_vault_endpoint: "https://vault.example.com"
hashicorp_vault_token: "{{ vault_token }}"
proxmox_api_token_secret_path: "proxmox/api-tokens"
```

## Requirements

- Proxmox VE with administrative access
- HashiCorp Vault server (optional but recommended)
- Environment variables for Proxmox authentication

### Environment Variables

```bash
PROXMOX_USER="root@pam"           # Proxmox user with token creation privileges
PROXMOX_PASSWORD="your-password"  # User password
```

## Dependencies

- `preconfigure` role (for system prerequisites)

## Usage

### Basic Usage

Include the role in your playbook:

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auth_tokens
```

### Custom Token IDs

Override the default token list:

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auth_tokens
  vars:
    pve_auth_tokens_ids:
      - ansible
      - terraform  
      - monitoring
      - backup-service
```

### Without Vault Integration

If not using HashiCorp Vault, tokens will be created but not stored externally:

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auth_tokens
  vars:
    hashicorp_vault_endpoint: ""  # Disable Vault storage
```

## Tasks

### Main Task Flow (`tasks/main.yml`)

1. **Token Creation Loop**: Iterates through each token ID in `pve_auth_tokens_ids`
2. **Includes**: Calls the `create_token.yml` task for each token

### Token Creation (`tasks/create_token.yml`)

1. **Create Token**: Uses `pveum` command to create the API token
2. **Extract Token Value**: Parses the token secret from command output
3. **Store in Vault**: Saves token details to HashiCorp Vault (if configured)

## Task Details

### Token Creation Command

```bash
pveum user token add {{ pve_auth_tokens_user }} {{ token_id }}
```

**Behavior**:
- Creates new token if it doesn't exist
- Skips creation if token already exists
- Fails only on unexpected errors

### Token Value Extraction

Uses regex to extract the token secret from command output:
```yaml
pve_auth_tokens_token_value: "{{ stdout | regex_search('([0-9a-z]*-[0-9a-z]*-[0-9a-z]*-[0-9a-z]*-[0-9a-z]*)') }}"
```

### Vault Storage

Stores token information with the following structure:
```json
{
  "token_id": "ansible",
  "token_secret": "12345678-1234-1234-1234-123456789abc"
}
```

## Example Output

When tokens are successfully created, you'll see output like:

```
TASK [pve_auth_tokens : Create token: ansible] 
changed: [proxmox-node-01]

TASK [pve_auth_tokens : Write the ansible api token secret to the vault]
ok: [proxmox-node-01 -> localhost]
```

## Token Usage

Once created, tokens can be used for API authentication:

### Ansible
```yaml
proxmox_user: "root@pam!ansible"
proxmox_token_secret: "{{ vault_token_secret }}"
```

### Terraform
```hcl
provider "proxmox" {
  pm_user         = "root@pam!terraform"
  pm_token_secret = var.proxmox_token_secret
  pm_api_url      = "https://proxmox.example.com:8006/api2/json"
}
```

### cURL Example
```bash
curl -H "Authorization: PVEAPIToken=root@pam!ansible:12345678-1234-1234-1234-123456789abc" \
     https://proxmox.example.com:8006/api2/json/nodes
```

## Security Considerations

1. **Token Permissions**: Tokens inherit permissions from the user account
2. **Secure Storage**: Store token secrets securely (Vault, Ansible Vault, etc.)
3. **Access Control**: Limit who can access token values
4. **Rotation**: Consider regular token rotation for security
5. **Monitoring**: Monitor token usage for unauthorized access

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```
   Error: User does not have permission to create tokens
   ```
   **Solution**: Ensure the user has `Sys.Modify` permissions

2. **Token Already Exists**
   ```
   Error: Token already exists
   ```
   **Behavior**: This is handled gracefully and won't fail the task

3. **Vault Connection Failed**
   ```
   Error: Unable to connect to Vault
   ```
   **Solution**: Check Vault endpoint and authentication token

### Debug Mode

Run with debug output to see token creation details:

```bash
ansible-playbook -vvv playbook.yml
```

### Manual Token Management

List existing tokens:
```bash
pveum user token list root@pam
```

Remove a token:
```bash
pveum user token remove root@pam ansible
```

## File Structure

```
roles/pve_auth_tokens/
├── defaults/
│   └── main.yml          # Default token IDs
├── tasks/
│   ├── main.yml          # Main task loop
│   └── create_token.yml  # Token creation logic
└── vars/
    └── main.yml          # Required variables
```

## Best Practices

1. **Environment-Specific Tokens**: Use different token IDs for different environments
2. **Descriptive Names**: Use clear, descriptive token names
3. **Documentation**: Document what each token is used for
4. **Regular Audits**: Regularly review and audit token usage
5. **Cleanup**: Remove unused tokens to reduce attack surface

## Integration Examples

### With Terraform

```yaml
# After running the role, retrieve token from Vault
- name: Get Terraform API token from Vault
  community.hashi_vault.vault_kv2_get:
    url: "{{ hashicorp_vault_endpoint }}"
    token: "{{ hashicorp_vault_token }}"
    path: "{{ proxmox_api_token_secret_path }}"
  register: terraform_token
  delegate_to: localhost

- name: Configure Terraform variables
  ansible.builtin.template:
    src: terraform.tfvars.j2
    dest: ./terraform.tfvars
  vars:
    proxmox_token_secret: "{{ terraform_token.data.data.token_secret }}"
```

### With Monitoring

```yaml
pve_auth_tokens_ids:
  - ansible
  - terraform
  - prometheus    # For Prometheus monitoring
  - grafana       # For Grafana dashboards
```

## Contributing

When contributing to this role:

1. Maintain idempotency in all tasks
2. Add proper error handling
3. Update documentation for new features
4. Test with and without Vault integration
5. Follow Ansible best practices