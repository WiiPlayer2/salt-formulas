car-packages:
  pkg.installed:
    - pkgs:
      - git
      - gpsd
      - python3
      - python3-pip

car-mqtt-logger-app-repo:
  git.latest:
    - name: https://git.home.dark-link.info/waldemar/car-mqtt-logger.git
    - target: /opt/car-mqtt-logger
    - require:
        - pkg: car-packages

car-mqtt-logger-app-requirements:
  cmd.run:
    - name: pip3 install -r requirements.txt
    - cwd: /opt/car-mqtt-logger
    - onchanges:
        - git: car-mqtt-logger-app-repo

car-mqtt-logger-app-config:
  file.managed:
    - name: /etc/car.yaml
    - source:
        - salt://car/files/config.jinja
    - template: jinja
    - context:
        data: {{ pillar['car'] | json }}

car-mqtt-logger-app-service:
  file.managed:
    - name: /etc/systemd/system/car-mqtt-logger.service
    - mode: 644
    - source:
      - salt://car/files/systemd.service.jinja
    - template: jinja
    - require:
      - git: car-mqtt-logger-app-repo
    - require_in:
      - service: car-mqtt-logger-app-service

  service.running:
    - name: car-mqtt-logger
    - enable: true
    - watch:
        - git: car-mqtt-logger-app-repo
        - file: car-mqtt-logger-app-config
