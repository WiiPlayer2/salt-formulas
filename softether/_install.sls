{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import softether with context %}
{%- macro softether_install(component) %}
{%- set config = softether[component] %}

softether-{{ component }}-archive-packages:
  pkg.installed:
    - pkgs:
{% for pkg in config.packages %}
      - {{ pkg }}
{% endfor %}

softether-{{ component }}-archive-extracted:
  file.directory: 
    - name: {{ config.install_dir }}

  archive.extracted:
    - name: {{ config.install_dir }}
    - source: {{ config.url }}
{% if config.hash %}
    - source_hash: {{ config.hash }}
{% else %}
    - skip_verify: true
{% endif %}
    - options: "--strip=1"
    - enforce_toplevel: false
    - require:
      - file: softether-{{ component }}-archive-extracted
  
  cmd.run:
    - name: make i_read_and_agree_the_license_agreement
    - cwd: {{ config.install_dir }}
    - creates: {{ config.install_dir }}/vpnserver
    - require:
      - archive: softether-{{ component }}-archive-extracted
    - watch_in:
      - service: softether-{{ component }}-service

softether-{{ component }}-cli:
  file.managed:
    - name: /usr/bin/vpn{{ component }}-cli
    - mode: 755
    - contents: |
        #!/bin/bash
        {{ config.install_dir }}/vpncmd "$@"
    - require:
      - cmd: softether-{{ component }}-archive-extracted

{% if grains['init'] == 'systemd' %}
softether-{{ component }}-systemd-service:
  file.managed:
    - name: /etc/systemd/system/{{ config.service }}.service
    - source: salt://softether/files/systemd.service.jinja
    - mode: 644
    - template: jinja
    - context:
        dir: {{ config.install_dir | yaml }}
        cmd: {{ ('vpn' + component) | yaml }}
    - require:
      - cmd: softether-{{ component }}-archive-extracted
    - watch_in:
      - service: softether-{{ component }}-service
{% endif %}

{% endmacro %}