# PVE Auto Update Role

The `pve_auto_update` role configures automatic updates for Proxmox Virtual Environment nodes by deploying a script and cron job to run `pveupdate` and `pveupgrade` daily.

## Purpose

This role automates the process of keeping Proxmox VE nodes up-to-date by:
- Creating an update script that runs `pveupdate` and `pveupgrade`
- Setting up a daily cron job to execute updates automatically
- Logging all update operations for auditing
- Optionally handling automatic reboots when required

## Features

- **Automated Updates**: Runs `pveupdate` and `pveupgrade` on a configurable schedule
- **Comprehensive Logging**: All operations logged to `/var/log/pve-auto-update.log`
- **Log Rotation**: Automatic log rotation configured via logrotate
- **Reboot Detection**: Checks if system reboot is required after updates
- **Optional Auto-Reboot**: Can automatically reboot nodes if needed (disabled by default)
- **Idempotent**: Safe to run multiple times

## Default Variables

```yaml
# Script location
pve_auto_update_script_path: /usr/local/bin/pve-auto-update.sh

# Log file location
pve_auto_update_log_file: /var/log/pve-auto-update.log

# Cron schedule (daily at 3:00 AM by default)
pve_auto_update_cron_hour: "3"
pve_auto_update_cron_minute: "0"

# Whether to enable automatic updates
pve_auto_update_enabled: true

# Whether to automatically reboot if required (set to false by default for safety)
pve_auto_update_auto_reboot: false
```

## Requirements

- Proxmox VE 7.0+ or 8.0+
- Root access to Proxmox nodes
- Cron service running

## Dependencies

None

## Usage

### Basic Usage

Include the role in your playbook:

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auto_update
```

### Custom Schedule

Run updates at a different time:

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auto_update
  vars:
    pve_auto_update_cron_hour: "2"
    pve_auto_update_cron_minute: "30"
```

### Enable Auto-Reboot

**Warning**: This will automatically reboot nodes when updates require it. Use with caution in production environments.

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auto_update
  vars:
    pve_auto_update_auto_reboot: true
```

### Disable Automatic Updates

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auto_update
  vars:
    pve_auto_update_enabled: false
```

### Per-Host Configuration

Configure different schedules for different nodes:

```yaml
# In host_vars/pve0.yml
pve_auto_update_cron_hour: "2"
pve_auto_update_cron_minute: "0"

# In host_vars/pve1.yml
pve_auto_update_cron_hour: "3"
pve_auto_update_cron_minute: "0"
```

## Tasks Overview

### Main Tasks

1. **Deploy Update Script**: Creates the bash script from template at `/usr/local/bin/pve-auto-update.sh`
2. **Create Log File**: Ensures the log file exists with proper permissions
3. **Configure Log Rotation**: Sets up weekly log rotation with 12-week retention
4. **Create Cron Job**: Adds a cron job to run updates daily at the specified time
5. **Display Status**: Shows configuration summary during playbook execution

## Update Script Details

The deployed script (`pve-auto-update.sh`) performs the following:

1. **Update Package Lists**: Runs `pveupdate` to refresh available packages
2. **Upgrade System**: Runs `pveupgrade -y` with non-interactive mode
3. **Check Reboot Status**: Detects if system reboot is required
4. **Handle Reboots**: Either notifies or automatically reboots based on configuration
5. **Log Everything**: All operations and outputs logged with timestamps

## Log Management

### Viewing Logs

```bash
# View recent log entries
tail -f /var/log/pve-auto-update.log

# View last update
tail -100 /var/log/pve-auto-update.log

# Search for errors
grep ERROR /var/log/pve-auto-update.log
```

### Log Rotation

Logs are automatically rotated weekly and kept for 12 weeks. Configuration is in `/etc/logrotate.d/pve-auto-update`.

## Manual Execution

You can manually run the update script:

```bash
# Run as root
sudo /usr/local/bin/pve-auto-update.sh

# View output in real-time
sudo /usr/local/bin/pve-auto-update.sh | tee /dev/tty
```

## Cron Job Management

### View Cron Job

```bash
crontab -l | grep pve-auto-update
```

### Temporarily Disable

Set `pve_auto_update_enabled: false` and re-run the playbook, or manually:

```bash
crontab -e
# Comment out the pve-auto-update line
```

## Security Considerations

1. **Auto-Reboot Risk**: By default, auto-reboot is disabled to prevent unexpected downtime
2. **Update Timing**: Schedule updates during maintenance windows for critical systems
3. **Log Monitoring**: Regularly review logs for failed updates or errors
4. **Staggered Updates**: Consider staggering update times across cluster nodes
5. **Testing**: Test updates in non-production environments first

## Best Practices

### Cluster Considerations

When managing a Proxmox cluster:

1. **Stagger Update Times**: Update nodes at different times to maintain availability
   ```yaml
   # host_vars/pve0.yml
   pve_auto_update_cron_hour: "2"
   
   # host_vars/pve1.yml
   pve_auto_update_cron_hour: "3"
   
   # host_vars/pve2.yml
   pve_auto_update_cron_hour: "4"
   ```

2. **Monitor Quorum**: Ensure cluster quorum is maintained during updates
3. **VM Migration**: Consider migrating critical VMs before scheduled updates
4. **Backup First**: Ensure backups are current before automatic updates

### Production Environments

1. **Disable Auto-Reboot**: Keep `pve_auto_update_auto_reboot: false` in production
2. **Schedule Maintenance**: Plan reboot windows separately from update times
3. **Alert on Failures**: Set up monitoring to alert on update failures
4. **Test Updates**: Use staging/test environments first

## Troubleshooting

### Updates Not Running

1. **Check Cron Service**
   ```bash
   systemctl status cron
   ```

2. **Verify Cron Job**
   ```bash
   crontab -l | grep pve-auto-update
   ```

3. **Check Script Permissions**
   ```bash
   ls -la /usr/local/bin/pve-auto-update.sh
   ```

4. **Test Script Manually**
   ```bash
   sudo /usr/local/bin/pve-auto-update.sh
   ```

### Update Failures

1. **Check Logs**
   ```bash
   tail -100 /var/log/pve-auto-update.log
   ```

2. **Verify Network Connectivity**
   ```bash
   ping -c 3 download.proxmox.com
   ```

3. **Check Repository Configuration**
   ```bash
   cat /etc/apt/sources.list.d/pve-*.list
   ```

4. **Run Updates Manually**
   ```bash
   pveupdate
   pveupgrade
   ```

### Reboot Not Happening

If auto-reboot is enabled but not working:

1. **Check Script Configuration**
   ```bash
   grep AUTO_REBOOT /usr/local/bin/pve-auto-update.sh
   ```

2. **Verify Reboot Detection**
   ```bash
   ls -la /var/run/reboot-required
   ```

## File Structure

```
roles/pve_auto_update/
├── defaults/
│   └── main.yml           # Default variables
├── handlers/
│   └── main.yml           # Service handlers (cron restart)
├── tasks/
│   └── main.yml           # Main tasks
├── templates/
│   └── pve-auto-update.sh.j2  # Update script template
└── README.md              # This file
```

## Integration Examples

### With Monitoring

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_auto_update
  post_tasks:
    - name: Send notification
      ansible.builtin.uri:
        url: "{{ monitoring_webhook }}"
        method: POST
        body_format: json
        body:
          message: "Auto-update configured on {{ inventory_hostname }}"
```

### With Backup Integration

```yaml
- hosts: proxmox_nodes
  roles:
    - pve_backup  # Run backups first
    - pve_auto_update
  vars:
    pve_auto_update_cron_hour: "4"  # Run after backup completes
```

## Contributing

When contributing to this role:

1. Test with different Proxmox versions
2. Ensure idempotency is maintained
3. Update documentation for new features
4. Follow existing code style and patterns
5. Test in non-production environment

## Related Documentation

- [Proxmox VE Updates Documentation](https://pve.proxmox.com/wiki/Package_Repositories)
- [Debian APT Documentation](https://wiki.debian.org/Apt)
- [Cron Documentation](https://man7.org/linux/man-pages/man8/cron.8.html)
