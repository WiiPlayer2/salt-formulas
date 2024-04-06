{%- from "ex/grafana/map.jinja" import grafana with context -%}
{%- set ldap_enabled = salt['pillar.get']('grafana:config:auth.ldap:enabled', false) -%}

include:
  - grafana.config
  - grafana.service

{% if ldap_enabled -%}
grafana-ldap-config-file:
  file.managed:
    - name: {{ grafana.ldap_config_file }}
    - source: salt://ex/grafana/files/ldap.toml.jinja
    - template: jinja
    - user: root
    - mode: 640
    - group: {{ grafana.user }}
    - context:
        config: {{ grafana.ldap|json }}
    - watch_in:
      - service: grafana-service-running-service-running
{%- endif %}