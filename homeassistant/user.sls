{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}
{%- set options = homeassistant.install %}

homeassistant-user:
  user.present:
    - name: {{ options.user }}
