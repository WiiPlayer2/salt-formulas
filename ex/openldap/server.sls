{% set openldap = pillar['openldap'] %}

include:
  - openldap.server

openldap-server-remove-config-database:
  file.absent:
    - name: /etc/ldap/slapd.d
    - watch_in:
      - service: slapd_service

openldap-server-initial-database-ldap-utils:
  pkg.installed:
    - name: ldap-utils

openldap-server-initial-database-domain-files:
  file.managed:
    - name: /tmp/domains.ldif
    - template: jinja
    - source:
      - salt://ex/openldap/files/domains.ldif

openldap-server-initial-database-add:
  cmd.run:
    - name: 'ldapadd -x -D "{{ openldap.rootdn }}" -w "{{ openldap.rootpw }}" -H ldapi:/// -f /tmp/domains.ldif && touch /etc/ldap/.db_initialized'
    - creates:
      - /etc/ldap/.db_initialized
    - retry: true
    - require:
      - service: slapd_service
