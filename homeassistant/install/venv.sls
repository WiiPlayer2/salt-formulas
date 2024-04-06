{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}
{%- set options = homeassistant.install %}

include:
  - homeassistant.user

homeassistant-pkgs:
  pkg.installed:
    - pkgs:
      - python3-pip
      - python3-venv

homeassistant-venv:
  file.directory:
    - name: {{ options.venv_path }}
    - user: {{ options.user }}
    - group: {{ options.user }}
    - require:
      - user: homeassistant-user

  virtualenv.managed:
    - name: {{ options.venv_path }}
    - user: {{ options.user }}
    - venv_bin: pyvenv
    - pip_pkgs:
      - wheel
    - require:
      - file: homeassistant-venv
      - pkg: homeassistant-pkgs
    - retry: true
  
  pip.installed:
    - name: homeassistant
    - user: {{ options.user }}
    - use_wheel: true
    - bin_env: {{ options.venv_path }}
    - require:
      - virtualenv: homeassistant-venv
    - retry: true

homeassistant-init.d-script:
  pkg.installed:
    - name: sudo

  file.managed:
    - name: /etc/init.d/home-assistant
    - mode: 754
    - source:
      - salt://homeassistant/files/venv/init/default/home-assistant.jinja
    - template: jinja
    - require:
      - pkg: homeassistant-init.d-script
    - require_in:
      - service: homeassistant-service

homeassistant-service:
  service.running:
    - name: home-assistant
    - enable: true
