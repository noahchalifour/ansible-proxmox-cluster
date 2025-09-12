# Network Role

The `network` role is responsible for configuring network interfaces on Proxmox nodes, including static IP assignments for both external and Ceph cluster networks.

## Status

🚧 **Under Development** - This role is currently planned but not yet implemented.

## Planned Features

### Static IP Configuration
- Configure static IP addresses for external network interfaces
- Configure static IP addresses for Ceph cluster network interfaces
- Ensure consistent network configuration across cluster nodes

### Network Interface Management
- Manage network bridge configurations
- Configure VLAN interfaces if required
- Set up bonding for network redundancy

## Planned Variables

```yaml
# External network configuration
network_external_interface: "vmbr0"
network_external_ip: "192.168.1.100/24"
network_external_gateway: "192.168.1.1"
network_external_dns: ["8.8.8.8", "8.8.4.4"]

# Ceph cluster network configuration
network_ceph_interface: "vmbr1"
network_ceph_ip: "10.0.0.100/24"
network_ceph_vlan: 100
```

## Requirements

- Proxmox VE nodes with network interfaces
- Network planning documentation
- VLAN configuration (if applicable)

## Dependencies

- `preconfigure` role (for system prerequisites)

## Planned Tasks

1. **Interface Configuration**
   - Configure `/etc/network/interfaces`
   - Set static IP addresses
   - Configure routing tables

2. **Bridge Management**
   - Create and configure network bridges
   - Assign physical interfaces to bridges
   - Configure bridge parameters

3. **VLAN Configuration**
   - Create VLAN interfaces if required
   - Configure VLAN tagging
   - Set up VLAN-aware bridges

4. **Network Validation**
   - Test connectivity between nodes
   - Verify routing configuration
   - Validate DNS resolution

## Usage

Once implemented, this role will be used as follows:

```yaml
- hosts: proxmox_nodes
  roles:
    - preconfigure
    - network
```

## Implementation Notes

- Network changes may require node reboots
- Backup existing network configuration before changes
- Implement rollback procedures for network failures
- Consider out-of-band access for emergency recovery

## Testing Strategy

When implemented, testing will include:

```bash
# Test network connectivity
ansible proxmox_nodes -m ping

# Validate interface configuration
ansible proxmox_nodes -m setup -a "filter=ansible_interfaces"

# Check routing tables
ansible proxmox_nodes -m shell -a "ip route show"
```

## Contributing

If you would like to contribute to implementing this role:

1. Create network configuration templates
2. Implement interface management tasks
3. Add network validation checks
4. Write comprehensive tests
5. Update this documentation

## Related Documentation

- [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
- [Ceph Network Requirements](https://docs.ceph.com/en/latest/rados/configuration/network-config-ref/)
- [Linux Network Interface Configuration](https://wiki.debian.org/NetworkConfiguration)