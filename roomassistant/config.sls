include:
  - .user
  - .service

roomassistant-config:
  file.managed:
    - name: /var/lib/room-assistant/config/local.yaml
    - source: salt://roomassistant/config.yaml.jinja
    - template: jinja
    - makedirs: true
    - user: roomassistant
    - group: roomassistant
    - require:
      - user: roomassistant-user
    - watch_in:
      - service: roomassistant-service
