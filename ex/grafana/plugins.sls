{%- set plugins = salt['pillar.get']('grafana:plugins', []) -%}

include:
  - grafana
  - grafana.service

{% for plugin in plugins %}
grafana-plugin-{{ plugin }}:
  cmd.run:
    - name: grafana-cli plugins install {{ plugin }}
    - watch_in:
      - service: grafana-service-running-service-running
{% endfor %}
