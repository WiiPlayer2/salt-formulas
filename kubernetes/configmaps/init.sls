{% set configmaps = salt['pillar.get']('kubernetes:configmaps', {}) %}
{% for id, content in configmaps.items() %}
{%  set namespace, name = id.split('/') %}
'kubernetes-configmap-{{ id }}':
  kubernetes.configmap_present:
    - name: {{ name }}
    - namespace: {{ namespace }}
    - data: {{ content | json }}
{% endfor %}
