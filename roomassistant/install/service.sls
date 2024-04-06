{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import roomassistant with context %}
include:
  - roomassistant.service
  - roomassistant.user

roomassistant-service-file:
  file.managed:
    - name: /etc/systemd/system/room-assistant.service
    - source: salt://roomassistant/install/room-assistant.service.jinja
    - template: jinja
    - context:
        binary: {{ roomassistant.binary }}
    - require:
      - user: roomassistant-user
    - require_in:
      - service: roomassistant-service
