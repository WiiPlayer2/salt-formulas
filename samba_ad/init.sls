{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import samba_ad with context %}
{%- macro remove_databases(config) %}
samba-ad-remove-{{ config }}-tdb:
  module.run:
    - name: file.find
    - path: "{{ samba_ad[config] }}"
    - kwargs:
        iname: "*.tdb"
        delete: "f"
    - prereq:
      - file: samba-ad-config-check

samba-ad-remove-{{ config }}-ldb:
  module.run:
    - name: file.find
    - path: "{{ samba_ad[config] }}"
    - kwargs:
        iname: "*.ldb"
        delete: "f"
    - prereq:
      - file: samba-ad-config-check
{% endmacro -%}

include:
  - ntp

samba-ad-packages:
  pkg.installed:
    - pkgs:
{% for package in samba_ad.packages %}
      - {{ package }}
{% endfor %}

samba-ad-remove-config:
  file.absent:
    - name: {{ samba_ad.CONFIGFILE }}
    - prereq:
      - file: samba-ad-config-check

samba-ad-remove-kerberos-config:
  file.absent:
    - name: /etc/krb5.conf
    - prereq:
      - file: samba-ad-config-check

{{ remove_databases('LOCKDIR') }}
{{ remove_databases('STATEDIR') }}
{{ remove_databases('CACHEDIR') }}
{{ remove_databases('PRIVATE_DIR') }}

{% for service in samba_ad.service_disabled %}
samba-ad-service-disable-{{ service }}:
  service.dead:
    - name: {{ service }}
    - enable: false
    - watch_in:
      - service: samba-ad-service
    - require_in:
      - cmd: samba-ad-provision-domain

samba-ad-service-mask-{{ service }}:
  service.masked:
    - name: {{ service }}
    - watch_in:
      - service: samba-ad-service
    - require_in:
      - cmd: samba-ad-provision-domain
{% endfor %}

samba-ad-service-dead:
  service.dead:
    - name: {{ samba_ad.service }}
    - prereq:
      - file: samba-ad-config-check

samba-ad-provision-domain:
  cmd.run:
    - name: |
        samba-tool domain provision \
          {% if samba_ad.use_rfc2307 %} --use-rfc2307{% endif %} \
          --realm={{ samba_ad.realm }} \
          --domain={{ samba_ad.domain }} \
          --server-role={{ samba_ad.server_role }} \
          --dns-backend={{ samba_ad.dns_backend }} \
          --adminpass={{ samba_ad.adminpass }}
    - prereq:
      - file: samba-ad-config-check
    - require:
      - service: samba-ad-service-dead
      - file: samba-ad-remove-config
      - file: samba-ad-remove-kerberos-config
      - module: samba-ad-remove-LOCKDIR-tdb
      - module: samba-ad-remove-LOCKDIR-ldb
      - module: samba-ad-remove-STATEDIR-tdb
      - module: samba-ad-remove-STATEDIR-ldb
      - module: samba-ad-remove-CACHEDIR-tdb
      - module: samba-ad-remove-CACHEDIR-ldb
      - module: samba-ad-remove-PRIVATE_DIR-tdb
      - module: samba-ad-remove-PRIVATE_DIR-ldb
    - watch_in:
      - service: samba-ad-service

samba-ad-copy-kereberos-config:
  file.managed:
    - name: /etc/krb5.conf
    - source: '{{ samba_ad.PRIVATE_DIR }}/krb5.conf'
    - prereq:
      - file: samba-ad-config-check
    - require:
      - cmd: samba-ad-provision-domain
    - watch_in:
      - service: samba-ad-service

samba-ad-service:
  service.running:
    - name: {{ samba_ad.service }}
    - enable: true
    - unmask: true

samba-ad-create-reverse-zone:
  cmd.run:
    - name: |
        samba-tool dns zonecreate {{ grains['fqdn'] }} 0.99.10.in-addr.arpa \
        --username=administrator \
        --password={{ samba_ad.adminpass }}
    - prereq:
      - file: samba-ad-config-check
    - require:
      - service: samba-ad-service

samba-ad-kerberos-init:
  cmd.run:
    - name: |
        echo '{{ samba_ad.adminpass }}' | kinit administrator
    - prereq:
      - file: samba-ad-config-check
    - require:
      - service: samba-ad-service

samba-ad-config-check:
  file.managed:
    - name: /samba-ad.hash
    - contents: {{ salt['hashutil.sha512_digest'](
      samba_ad.use_rfc2307|string
      + samba_ad.realm
      + samba_ad.domain
      + samba_ad.server_role
      + samba_ad.dns_backend
      + samba_ad.adminpass
    ) }} {# Maybe remove adminpass from hash #}
