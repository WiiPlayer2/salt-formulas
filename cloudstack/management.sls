{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import cloudstack with context %}

include:
  - .repo
  - mysql.server

cloudstack-management-dependencies:
  pkg.installed:
    - pkgs:
      - mysql-connector-python

cloudstack-management-pkg:
  pkg.installed:
    - name: cloudstack-management

cloudstack-management-setup:
  cmd.run:
    - name: |
        cloudstack-setup-databases cloud:password@localhost --deploy-as=root
        cloudstack-setup-management
    - onchanges:
      - pkg: cloudstack-management-pkg
