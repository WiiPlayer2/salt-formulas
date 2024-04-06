{%- set cmds = salt['pillar.get']('cmd', {}) %}
{%- for cmd, data in cmds.items() %}
{{ ("cmd-" ~ cmd) | yaml_dquote }}:
  cmd.run:
    - name: {{ cmd | json }}
{%    for k,v in data.items() %}
    - {{ k }}: {{ v | json }}
{%    endfor %}
{%- endfor %}
