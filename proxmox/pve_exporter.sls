{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import proxmox with context %}
{%- set config = proxmox.pve_exporter %}

proxmox-pve-exporter-venv:
  pkg.installed:
    - name: virtualenv
  virtualenv.managed:
    - name: {{ config.install_path }}
    - pip_pkgs:
      - prometheus-pve-exporter
    - require:
      - pkg: proxmox-pve-exporter-venv

proxmox-pve-exporter-config:
  file.managed:
    - name: {{ config.config_path }}
    - source: salt://proxmox/pve_exporter.yml.jinja
    - template: jinja
    - context:
        config: {{ config.config | json }}

proxmox-pve-exporter-service:
  file.managed:
    - name: /etc/systemd/system/{{ config.service }}.service
    - source: salt://proxmox/pve_exporter.service.jinja
    - template: jinja
    - context:
        config: {{ config | json }}
    - require:
      - virtualenv: proxmox-pve-exporter-venv
      - file: proxmox-pve-exporter-config
  service.running:
    - name: {{ config.service }}
    - enable: true
    - require:
      - file: proxmox-pve-exporter-service
