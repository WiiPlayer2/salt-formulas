{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import proxmox with context %}

include:
  - .pve_exporter

proxmox-enterprise-repository-removed:
  file.absent:
    - name: /etc/apt/sources.list.d/pve-enterprise.list

proxmox-repository:
  pkgrepo.managed:
{% if proxmox.use_subscription %}
    - name: deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise
{% else %}
    - name: deb http://download.proxmox.com/debian/pve buster pve-no-subscription
{% endif %}
    - file: /etc/apt/sources.list.d/proxmox.list
    - require:
      - file: proxmox-enterprise-repository-removed