#!/usr/bin/env python3
import yaml

# Configure yaml to use | for literal blocks
class literal_str(str): pass

def literal_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')

yaml.add_representer(literal_str, literal_presenter)

def read_file(path):
    """Read contents of a file."""
    with open(path, 'r') as f:
        return literal_str(f.read())

def generate_config(scripts_dir="scripts"):
    """Generate the cloud-init configuration."""
    cloud_config = {
        'package_update': True,
        'package_upgrade': True,
        'packages': [
            'haproxy',
            'keepalived',
            'net-tools'  # Added for network troubleshooting
        ],
        # Add network configuration
        'network': {
            'version': 2,
            'ethernets': {
                'eth0': {
                    'dhcp4': True,
                    'dhcp6': True,
                    'optional': False
                }
            }
        },
        'write_files': [
            {
                'path': '/etc/systemd/system/fusion-server.service',
                'permissions': '0644',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/fusion-server.service")
            },
            {
                'path': '/etc/systemd/system/keepalived.service',
                'permissions': '0644',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/keepalived.service")
            },
            {
                'path': '/etc/keepalived/keepalived.conf',
                'permissions': '0644',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/keepalived.conf")
            },
            {
                'path': '/etc/systemd/system/haproxy.service',
                'permissions': '0644',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/haproxy.service")
            },
            {
                'path': '/usr/local/bin/check-haproxy.sh',
                'permissions': '0755',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/check-haproxy.sh")
            },
            {
                'path': '/usr/local/bin/setup-fusion.sh',
                'permissions': '0755',
                'owner': 'root:root',
                'content': read_file(f"{scripts_dir}/setup-fusion.sh")
            }
        ],
        'runcmd': [
            # Add network verification steps
            'systemctl restart systemd-networkd',
            'networkctl status',
            'bash -x /usr/local/bin/setup-fusion.sh'
        ]
    }
    return cloud_config

if __name__ == "__main__":
    config = generate_config()
    print("#cloud-config")
    # Use default_flow_style=False for block formatting
    # Sort keys to maintain consistent ordering
    print(yaml.dump(config, default_flow_style=False, sort_keys=False))
    