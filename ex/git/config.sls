include:
  - git

{% for user in pillar['git']['config'] %}
{% for config, value in pillar['git']['config'][user].items() %}

git-config-{{ user }}-{{ config }}:
  git.config_set:
    - name: {{ config }}
    - value: {{ value }}
    - user: {{ user }}
    - global: true

{% endfor %}
{% endfor %}
