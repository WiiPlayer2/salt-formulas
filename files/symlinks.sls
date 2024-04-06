{% set mappings = salt['pillar.get']('files:symlink', {}) %}
{% for target,data in mappings.items() %}
"file-symlink-{{target}}":
  file.symlink:
    - name: {{ target }}
{% for k,v in data.items() %}
    - {{ k }}: {{ v | json }}
{% endfor %}
{% endfor %}
