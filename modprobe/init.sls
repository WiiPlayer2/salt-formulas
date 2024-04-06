{% set modprobe = salt['pillar.get']('modprobe', {}) %}
{% for module in modprobe %}
{% set arguments = salt['pillar.get']('modprobe:' + module, {}) %}
{% macro write_argument(argument) -%}
{%- set value = salt['pillar.get']('modprobe:' + module + ':' + argument) -%}
{{ argument }}=
{%- if value == true -%}
1
{%- elif value == false -%}
0
{%- else -%}
{{ value }}
{%- endif -%}
{%- endmacro %}

kmod-{{ module }}:
  kmod.present:
    - name: {{ module }}

{% if arguments|length > 0 %}
modprobe-{{ module }}:
  file.managed:
    - name: /etc/modprobe.d/{{ module }}.conf
    - contents: |
        # This file is managed by salt. DO NOT EDIT!
        options {{ module }}{% for argument in arguments %} {{ write_argument(argument) }}{% endfor %}
{% else %}
modprobe-{{ module }}:
  file.absent:
    - name: /etc/modprobe.d/{{ module }}.conf
{% endif %}
{% endfor %}