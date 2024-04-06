{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import cloudstack with context %}

cloudstack-repository:
  pkgrepo.managed:
    - name: deb http://download.cloudstack.org/ubuntu xenial 4.13
    - key_url: http://download.cloudstack.org/release.asc
    - keyserver: keyserver.ubuntu.com
