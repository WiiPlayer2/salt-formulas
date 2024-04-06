include:
  - .symlinks

{% set mappings = salt['pillar.get']('files', {}) %}
{% for target,data in mappings.items() if target != "symlink" %}
"file-{{target}}":
  file.managed:
    - name: {{ target }}
{% for k,v in data.items() %}
    - {{ k }}: {{ v | json }}
{% endfor %}
{% endfor %}
