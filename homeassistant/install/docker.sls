{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}
{%- set options = homeassistant.install %}
include:
  - docker

home-assistant-image:
  docker_image.present:
    - name: {{ options.docker_image }}
    - force: true # TODO add setting to enable updating
    - retry: true

home-assistant-container:
  docker_container.running:
    - name: {{ options.docker_name }}
    - image: {{ options.docker_image }}
    - binds:
      - {{ options.config }}:/config
{%- for bind in options.docker_binds %}
      - {{ bind }}
{%- endfor %}
    - environment:
      - TZ: {{ options.docker_timezone }}
    - network_mode: host
    - restart: always
    - retry: true
