#!/usr/bin/env python3
import yaml
import os

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
    
    # Updated keepalived.conf content
    keepalived_conf = '''vrrp_script chk_haproxy {
    script "/usr/local/bin/check-haproxy.sh"
    interval 2
    weight 2
}

global_defs {
    enable_script_security
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp0s1
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass fusion
    }
    virtual_ipaddress {
        192.168.64.100/24
    }
    track_script {
        chk_haproxy
    }
}'''

    # Updated haproxy.cfg content
    haproxy_conf = '''global
    log /dev/log local0
    stats socket /var/run/haproxy.sock mode 600 level admin expose-fd listeners
    stats timeout 2m
    maxconn 4096

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend http-in
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    
'''

    cloud_config = {
        'package_update': True,
        'package_upgrade': True,
        'packages': [
            'haproxy',
            'keepalived',
            'net-tools'
        ],
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
                'content': literal_str(keepalived_conf)
            },
            {
                'path': '/etc/haproxy/haproxy.cfg',
                'permissions': '0644',
                'owner': 'root:root',
                'content': literal_str(haproxy_conf)
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
        ]
    }
    return cloud_config

if __name__ == "__main__":
    config = generate_config()
    print("#cloud-config")
    print(yaml.dump(config, default_flow_style=False, sort_keys=False))
