{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import homeassistant with context %}

include:
  - homeassistant.install.{{ homeassistant.install.type }}
