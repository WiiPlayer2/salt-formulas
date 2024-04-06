{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import cloudstack with context %}

include:
  - .repo
  - ntp
  - nfs.server
  - libvirt

cloudstack-agent-dependencies:
  pkg.installed:
    - pkgs:
      - bridge-utils

cloudstack-agent-network:
  network.managed:
    - name: eno1 # TODO
    - enabled: true
    - hotplug: true
    - type: eth
    - proto: auto
    - enable_ipv6: true
    - ipv6_autoconf: true
    - bridge: cloudbr0

cloudstack-agent-bridge:
  network.managed:
    - name: cloudbr0
    - enabled: true
    - type: bridge
    - proto: dhcp
    - bridge: cloudbr0
    - delay: 5
    - ports: eno1 # TODO
    - bypassfirewall: true
    - enable_ipv6: false
    - ipv6_autoconf: false
    - use:
      - network: cloudstack-agent-network
    - require:
      - network: cloudstack-agent-network
    {# - contents: |
        DEVICE=cloudbr0
        TYPE=Bridge
        ONBOOT=yes
        BOOTPROTO=static
        IPV6INIT=no
        IPV6_AUTOCONF=no
        DELAY=5
        IPADDR={{ grains['ip4']|last }}
        GATEWAY={{ grains['ip4_gw'] }}
        NETMASK=255.255.255.0
        DNS1=8.8.8.8
        DNS2=8.8.4.4
        STP=yes
        USERCTL=no
        NM_CONTROLLED=no #}

{% for dir in ['primary', 'secondary'] %}

cloudstack-agent-directory-{{ dir }}:
  file.directory:
    - name: /export/{{ dir }}

cloudstack-agent-export-{{ dir }}:
  nfs_export.present:
    - name: /export/{{ dir }}
    - hosts: '*'
    - options:
      - rw
      - async
      - no_root_squash
      - no_subtree_check

{% endfor %}

cloudstack-agent-pkg:
  pkg.installed:
    - name: cloudstack-agent

cloudstack-agent-libvirt-conf:
  file.managed:
    - name: /etc/libvirt/libvirt.conf
    - contents: |
        listen_tls = 0
        listen_tcp = 1
        tcp_port = "16509"
        auth_tcp = "none"
        mdns_adv = 0
    - watch_in:
      - service: libvirt-server-service-running-service-running

cloudstack-agent-qemu-conf:
  file.managed:
    - name: /etc/libvirt/qemu.conf
    - contents: |
        vnc_listen = "0.0.0.0"
    - watch_in:
      - service: libvirt-server-service-running-service-running

cloudstack-agent-libvirt-init-conf:
  file.append:
    - name: /etc/init/libvirt-bin.conf
    - text: |
        env libvirtd_opts="-d -l"
    - watch_in:
      - service: libvirt-server-service-running-service-running
