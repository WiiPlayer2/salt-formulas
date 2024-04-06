{% from "ex/packages/map.jinja" import packages with context %}

{% set wanted_pkgs = packages.chocolatey.wanted %}

{% for pkg in wanted_pkgs %}
packages-chocolatey-wanted-{{ pkg }}:
  chocolatey.installed:
    - name: {{ pkg }}
{% endfor %}