{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}
{%- set config = homeassistant.config %}
{%- set install = homeassistant.install %}

include:
  - git
  - homeassistant.user

home-assistant-config-git-repo:
  file.directory:
    - name: {{ config.path }}
    - user: {{ install.user }}
    - group: {{ install.user }}

  git.latest:
    - name: {{ config.git_repo }}
    - target: {{ config.path }}
    - user: {{ install.user }}
    - force_clone: true
    - force_checkout: true
    - require:
      - user: homeassistant-user
      - file: home-assistant-config-git-repo
