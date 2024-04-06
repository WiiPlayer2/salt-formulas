{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import gitea with context %}
include:
  - gitea.service

gitea-config-file:
  file.managed:
    - name: {{ gitea.config_path }}
    - user: {{ gitea.user }}
    - group: {{ gitea.user }}
    - makedirs: true
    - mode: 650
    - source:
      - salt://gitea/files/config.jinja
    - template: jinja
    - watch_in:
      - service: gitea-service
