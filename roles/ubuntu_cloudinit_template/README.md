# Ubuntu Cloud-Init Template Role

The `ubuntu_cloudinit_template` role automates the creation of Ubuntu 24.04 Cloud-Init VM templates in Proxmox Virtual Environment, providing a foundation for rapid VM deployment.

## Purpose

This role downloads Ubuntu Cloud Images and creates properly configured VM templates with Cloud-Init support, enabling infrastructure-as-code VM provisioning with tools like Terraform or direct Proxmox cloning.

## Features

- **Automated Template Creation**: Downloads and configures Ubuntu 24.04 Cloud Images
- **Cloud-Init Integration**: Fully configured Cloud-Init support for automated VM provisioning
- **UEFI Support**: Modern UEFI/OVMF BIOS configuration with secure boot
- **Ceph Storage**: Configured for Ceph storage pools
- **Guest Agent**: QEMU Guest Agent enabled for better VM management
- **Idempotent Operations**: Safe to run multiple times without conflicts

## Default Variables

### Image Configuration
```yaml
# Ubuntu Cloud Image URL (Ubuntu 24.04 LTS)
ubuntu_cloudinit_template_image_url: "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
```

### VM Template Configuration
```yaml
ubuntu_cloudinit_template_vm_id: 9000                           # Proxmox VM ID
ubuntu_cloudinit_template_vm_name: "ubuntu-2404-cloud-template" # Template name
ubuntu_cloudinit_template_vm_memory: 2048                       # RAM in MB
ubuntu_cloudinit_template_vm_cores: 2                           # CPU cores
ubuntu_cloudinit_template_vm_machine: "q35"                     # Machine type
ubuntu_cloudinit_template_vm_bios: "ovmf"                       # UEFI BIOS
ubuntu_cloudinit_template_vm_bridge: "vmbr0"                    # Network bridge
ubuntu_cloudinit_template_vm_storage_pool: "ceph-vm"            # Storage pool
```

### Cloud-Init Configuration
```yaml
ubuntu_cloudinit_template_ci_username: "ubuntu"                 # Default user
ubuntu_cloudinit_template_ci_password: "password"               # Default password
```

### System Configuration
```yaml
ubuntu_cloudinit_template_directory: "/tmp"                     # Download directory
```

## Required Variables

The following variables must be defined (typically in group_vars or inventory):

```yaml
# Proxmox API credentials for template creation
ubuntu_cloudinit_template_proxmox_user: "{{ ansible_user }}"
ubuntu_cloudinit_template_proxmox_password: "{{ ansible_password }}"
```

## Requirements

### System Requirements
- Proxmox VE 7.0+ or 8.0+
- Sufficient storage space for image download and VM creation
- Internet connectivity for image download
- Python dependencies: `proxmoxer`, `qemu-guest-agent`

### Permissions
- VM creation permissions in Proxmox
- Storage access to the configured storage pool
- Ability to convert VMs to templates

## Dependencies

- `preconfigure` role (for system prerequisites and Python packages)

## Usage

### Basic Usage

```yaml
- hosts: proxmox_nodes
  roles:
    - preconfigure
    - ubuntu_cloudinit_template
```

### Custom Configuration

```yaml
- hosts: proxmox_nodes
  roles:
    - ubuntu_cloudinit_template
  vars:
    ubuntu_cloudinit_template_vm_id: 9001
    ubuntu_cloudinit_template_vm_name: "ubuntu-2404-production-template"
    ubuntu_cloudinit_template_vm_memory: 4096
    ubuntu_cloudinit_template_vm_cores: 4
    ubuntu_cloudinit_template_vm_storage_pool: "local-lvm"
```

### Multiple Templates

```yaml
- hosts: proxmox_nodes
  tasks:
    - name: Create Ubuntu 22.04 template
      include_role:
        name: ubuntu_cloudinit_template
      vars:
        ubuntu_cloudinit_template_vm_id: 9000
        ubuntu_cloudinit_template_vm_name: "ubuntu-2204-template"
        ubuntu_cloudinit_template_image_url: "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
    
    - name: Create Ubuntu 24.04 template
      include_role:
        name: ubuntu_cloudinit_template
      vars:
        ubuntu_cloudinit_template_vm_id: 9001
        ubuntu_cloudinit_template_vm_name: "ubuntu-2404-template"
```

## Tasks Overview

### Main Tasks (`tasks/main.yml`)

The role only creates the template on the first Proxmox node to avoid conflicts:

```yaml
- name: Create the template VM
  ansible.builtin.include_tasks: create_template.yml
  when: ansible_host == hostvars[groups['proxmox_nodes'] | sort | first]['ansible_host']
```

### Template Creation Tasks (`tasks/create_template.yml`)

1. **System Prerequisites**
   - Install `qemu-guest-agent` on Proxmox host
   - Install Python dependencies (`python3-pip`, `proxmoxer`)
   - Create download directory

2. **Image Download**
   - Download Ubuntu Cloud Image to temporary directory
   - Skip download if image already exists

3. **VM Creation**
   - Create empty VM with specified configuration
   - Configure UEFI/OVMF BIOS with secure boot
   - Set up VirtIO network interface
   - Configure serial console for Cloud-Init output

4. **Disk Management**
   - Import downloaded cloud image as VM disk
   - Add Cloud-Init CD-ROM drive
   - Configure boot order

5. **Cloud-Init Configuration**
   - Set default username and password
   - Configure DHCP networking
   - Enable QEMU Guest Agent

6. **Template Conversion**
   - Convert VM to Proxmox template
   - Verify successful template creation

## Template Features

### Hardware Configuration
- **Machine Type**: Q35 (modern chipset)
- **BIOS**: UEFI/OVMF with secure boot support
- **Network**: VirtIO driver for better performance
- **Storage**: VirtIO SCSI controller for optimal disk performance
- **Serial**: Serial console for Cloud-Init debugging

### Cloud-Init Support
- **User Management**: Configurable default user account
- **Networking**: DHCP configuration (customizable during clone)
- **SSH Keys**: Support for SSH key injection
- **Custom Scripts**: Support for user-data and meta-data

### Security Features
- **Secure Boot**: UEFI secure boot enabled
- **Guest Agent**: QEMU Guest Agent for secure communication
- **Modern Drivers**: VirtIO drivers for better security and performance

## Using the Template

### With Terraform

```hcl
resource "proxmox_vm_qemu" "ubuntu-vm" {
  name        = "ubuntu-server"
  target_node = "proxmox-node-01"
  clone       = "ubuntu-2404-cloud-template"
  
  # Override template settings
  memory      = 4096
  cores       = 2
  sockets     = 1
  
  # Cloud-Init configuration
  ciuser      = "admin"
  cipassword  = "secure-password"
  sshkeys     = file("~/.ssh/id_rsa.pub")
  
  # Network configuration
  ipconfig0   = "ip=192.168.1.100/24,gw=192.168.1.1"
  nameserver  = "8.8.8.8"
}
```

### With Proxmox CLI

```bash
# Clone the template
qm clone 9000 100 --name ubuntu-test-vm

# Configure Cloud-Init
qm set 100 --ciuser admin --cipassword mypassword
qm set 100 --sshkey ~/.ssh/id_rsa.pub
qm set 100 --ipconfig0 ip=192.168.1.100/24,gw=192.168.1.1

# Start the VM
qm start 100
```

### With Proxmox Web Interface

1. Right-click template in VM list
2. Select "Clone"
3. Configure VM settings
4. Set Cloud-Init parameters in "Cloud-Init" tab
5. Start the cloned VM

## Customization

### Custom Cloud Image

```yaml
ubuntu_cloudinit_template_image_url: "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
ubuntu_cloudinit_template_vm_name: "ubuntu-2204-template"
```

### Different Storage Backend

```yaml
ubuntu_cloudinit_template_vm_storage_pool: "local-lvm"  # or "local-zfs", "nfs-storage", etc.
```

### Resource Optimization

```yaml
ubuntu_cloudinit_template_vm_memory: 1024    # Minimal for testing
ubuntu_cloudinit_template_vm_cores: 1        # Single core for small workloads
```

## Troubleshooting

### Common Issues

1. **Download Fails**
   ```
   Error: Unable to download Ubuntu image
   ```
   **Solution**: Check internet connectivity and disk space

2. **Storage Pool Not Found**
   ```
   Error: Storage pool 'ceph-vm' not available
   ```
   **Solution**: Verify storage pool exists and is enabled

3. **VM ID Conflict**
   ```
   Error: VM ID 9000 already exists
   ```
   **Solution**: Change `ubuntu_cloudinit_template_vm_id` or remove existing VM

4. **Permission Denied**
   ```
   Error: Insufficient permissions to create VM
   ```
   **Solution**: Verify Proxmox user has VM creation permissions

### Debug Steps

1. **Check Storage**
   ```bash
   pvesm status
   ```

2. **Verify Image Download**
   ```bash
   ls -la /tmp/ubuntu-*.img
   ```

3. **Check VM Creation**
   ```bash
   qm list | grep 9000
   ```

4. **View Template Status**
   ```bash
   qm config 9000
   ```

### Manual Cleanup

If template creation fails, clean up manually:

```bash
# Remove failed VM
qm destroy 9000

# Remove downloaded image
rm /tmp/ubuntu-24.04-server-cloudimg-amd64.img

# Re-run the role
```

## Security Considerations

1. **Default Passwords**: Change default Cloud-Init password in production
2. **SSH Keys**: Use SSH key authentication instead of passwords
3. **Network Security**: Configure appropriate firewall rules
4. **Updates**: Regularly update templates with latest images
5. **Access Control**: Restrict template modification permissions

## Performance Optimization

### Template Optimization
- Use VirtIO drivers for better performance
- Enable QEMU Guest Agent for better VM management
- Configure appropriate CPU and memory settings
- Use SSD storage for better I/O performance

### Storage Optimization
```yaml
# For SSD storage pools
ubuntu_cloudinit_template_vm_storage_pool: "local-ssd"

# For high-performance Ceph pools
ubuntu_cloudinit_template_vm_storage_pool: "ceph-ssd"
```

## File Structure

```
roles/ubuntu_cloudinit_template/
├── defaults/
│   └── main.yml           # Default variables
├── tasks/
│   ├── main.yml           # Main task (single node execution)
│   └── create_template.yml # Template creation logic
└── vars/
    └── main.yml           # Internal variables
```

## Best Practices

1. **Version Control**: Pin specific Ubuntu image versions for reproducibility
2. **Testing**: Test templates before using in production
3. **Documentation**: Document custom configurations and use cases
4. **Monitoring**: Monitor template creation for failures
5. **Cleanup**: Regularly clean up old/unused templates
6. **Backup**: Consider backing up templates to external storage

## Integration Examples

### With Packer

```json
{
  "builders": [{
    "type": "proxmox-clone",
    "clone_vm": "ubuntu-2404-cloud-template",
    "vm_name": "custom-ubuntu-template",
    "template_name": "custom-ubuntu-template"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "apt-get update",
      "apt-get install -y docker.io",
      "systemctl enable docker"
    ]
  }]
}
```

### With Ansible (Post-Creation)

```yaml
- name: Customize template after creation
  hosts: proxmox_nodes[0]
  tasks:
    - name: Wait for template creation
      wait_for:
        timeout: 300
      
    - name: Clone template for customization
      proxmox_kvm:
        api_host: "{{ ansible_host }}"
        api_user: "{{ proxmox_user }}"
        api_password: "{{ proxmox_password }}"
        vmid: 9999
        clone: "{{ ubuntu_cloudinit_template_vm_name }}"
        name: "temp-customization-vm"
        
    # Add customization tasks here
```

## Contributing

When contributing to this role:

1. Test with different Ubuntu versions
2. Verify compatibility with various storage backends
3. Add support for different architectures (ARM64)
4. Improve error handling and validation
5. Update documentation for new features
6. Consider adding support for other distributions

## Related Documentation

- [Proxmox Cloud-Init Documentation](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)
- [Proxmox VM Templates](https://pve.proxmox.com/wiki/VM_Templates_and_Clones)