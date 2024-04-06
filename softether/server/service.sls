{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import softether with context %}

softether-server-service:
  service.running:
    - name: {{ softether.server.service }}
    - enable: true