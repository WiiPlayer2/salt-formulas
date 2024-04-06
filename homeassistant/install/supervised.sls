{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}
{%- set options = homeassistant.install %}

home-assistant-supervised-required-packages:
  pkg.installed:
    - pkgs:
      - network-manager
      - jq

home-assistant-supervised:
  file.managed:
    - name: /opt/homeassistant-supervised-installer.sh
    - source: https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh
    - mode: 544
    - skip_verify: true

# Disabled for now due to needing /dev/tty to interact with prompt
  {# cmd.run:
    - name: "yes '' | /opt/homeassistant-supervised-installer.sh"
    - creates: /etc/systemd/system/hassio-supervisor.service
    - require:
      - pkg: home-assistant-supervised-required-packages
      - file: home-assistant-supervised #}
