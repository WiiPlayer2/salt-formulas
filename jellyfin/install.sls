{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import jellyfin with context %}

jellyfin-repo:
  pkgrepo.managed:
    - name: deb https://repo.jellyfin.org/ubuntu bionic main
    - key_url: https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key
    - file: /etc/apt/sources.list.d/jellyfin.list

jellyfin-pkg:
  pkg.installed:
    - name: jellyfin
    - require:
      - pkgrepo: jellyfin-repo

jellyfin-service:
  service.running:
    - name: jellyfin
    - enable: true
    - require:
      - pkg: jellyfin-pkg
