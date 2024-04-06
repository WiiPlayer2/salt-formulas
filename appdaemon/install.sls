{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import appdaemon with context %}
{%- set is_patched = appdaemon.docker_path is defined %}
{%- macro check_env(key) -%}
{%- if appdaemon[key] != None -%}
- {{ key }}: '{{ appdaemon[key] }}'
{%- endif -%}
{%- endmacro %}

include:
  - docker

appdaemon-repository:
  git.latest:
    - name: https://github.com/home-assistant/appdaemon.git
    - target: /usr/local/src/appdaemon
    - branch: master
    - force_reset: true

{% if is_patched -%}
appdaemon-dockerfile-patch:
  file.patch:
    - name: /usr/local/src/appdaemon/Dockerfile
    - source:
      - salt://appdaemon/{{ appdaemon.docker_patch }}.diff
    - require:
      - git: appdaemon-repository
{%- endif %}

appdaemon-image:
  docker_image.present:
    - name: appdaemon
    - tag: latest
    - build: /usr/local/src/appdaemon
    - force: true # TODO add setting to enable updating
    - retry: true
    - onchanges:
      - git: appdaemon-repository
{%- if is_patched %}
      - file: appdaemon-dockerfile-patch
{%- endif %}

appdaemon-container:
  docker_container.running:
    - name: {{ appdaemon.docker_name }}
    - image: appdaemon:latest
    - binds:
      - {{ appdaemon.config }}:/conf
    - environment:
      - TZ: {{ appdaemon.docker_timezone }}
      {{ check_env("HA_URL") }}
      {{ check_env("TOKEN") }}
      {{ check_env("DASH_URL") }}
    - publish:
      - '5050:5050'
    - restart: always
    - retry: true
    - watch:
      - docker_image: appdaemon-image
