{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import freeradius with context %}

freeradius-packages:
  pkg.installed:
    - pkgs:
{% for pkg in freeradius.packages %}
      - {{ pkg }}
{% endfor %}

{% for module, data in freeradius.modules.config.items() %}
freeradius-module-{{ module }}-config:
  file.managed:
    - name: {{ freeradius.config_dir }}mods-available/{{ module }}
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - mode: 640
    - template: jinja
    - source: salt://freeradius/files/modules/{{ module }}.jinja
    - context:
        config: {{ data | json }}
    - require:
      - pkg: freeradius-packages
    - watch_in:
      - service: freeradius-service
{% endfor %}

{# Only from Salt 2019.2 up #}
{# freeradius-disabled-modules:
  file.tidied:
    - name: {{ freeradius.config_dir }}mods-available
{%- for module in freeradius.modules.enabled %}
{%- if loop.first %}
    - matches:
      - ^((?!
{%- endif -%}
{{- module -}}
{%- if loop.last -%}
).)*$
{%- else -%}
|
{%- endif -%}
{%- endfor %} #}

{% for module in freeradius.modules.enabled %}
freeradius-module-{{ module }}-enabled:
  file.symlink:
    - name: {{ freeradius.config_dir }}mods-enabled/{{ module }}
    - target: ../mods-available/{{ module }}
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - watch_in:
      - service: freeradius-service
    - require:
      - pkg: freeradius-packages
    {# - require:
      - file: freeradius-disabled-modules #}
{% endfor %}

{% for site, data in freeradius.sites.custom.items() %}
freeradius-site-{{ site }}:
  file.managed:
    - name: {{ freeradius.config_dir }}sites-available/{{ site }}
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - contents: {{ data | yaml }}
    - require:
      - pkg: freeradius-packages
    - watch_in:
      - service: freeradius-service
{% endfor %}

{% for site in freeradius.sites.enabled %}
freeradius-site-{{ site }}-enabled:
  file.symlink:
    - name: {{ freeradius.config_dir }}sites-enabled/{{ site }}
    - target: ../sites-available/{{ site }}
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - require:
      - pkg: freeradius-packages
    - watch_in:
      - service: freeradius-service
{% endfor %}

{% for policy, data in freeradius.policies.custom.items() %}
freeradius-policy-{{ policy }}:
  file.managed:
    - name: {{ freeradius.config_dir }}policy.d/{{ policy }}
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - contents: {{ data | yaml }}
    - require:
      - pkg: freeradius-packages
    - watch_in:
      - service: freeradius-service
{% endfor %}

freeradius-clients:
  file.managed:
    - name: {{ freeradius.config_dir }}clients.conf
    - user: {{ freeradius.user }}
    - group: {{ freeradius.user }}
    - template: jinja
    - source: salt://freeradius/files/clients.conf.jinja
    - context:
        freeradius: {{ freeradius | json }}
    - require:
      - pkg: freeradius-packages
    - watch_in:
      - service: freeradius-service

freeradius-service:
  service.running:
    - name: {{ freeradius.service }}
    - enable: true
