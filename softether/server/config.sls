{%- set tplroot = tpldir.split('/')[0] %}
{% from tplroot ~ '/map.jinja' import softether with context %}
{% import_yaml tplroot ~ '/server/hub_defaults.yaml' as hub_defaults %}
{% import_yaml tplroot ~ '/server/user_defaults.yaml' as user_defaults %}
{% set config = softether.server.config %}

include:
  - .service

{% if config.password %}
softether-server-password:
  softether_server.password:
    - new: {{ config.password | json }}
    - old_passwords: {{ config.old_passwords | json }}
    - watch_in:
      - service: softether-server-service
{% endif %}

{% if config.dyndns.hostname %}
softether-server-dyndns:
  softether_server.dyndns:
    - name: {{ config.dyndns.hostname | json }}
    - enable_vpnazure: {{ config.dyndns.enable_vpnazure | json }}
    - password: {{ config.password | json }}
    - require:
      - service: softether-server-service
{% endif %}

{% for hub, hub_config in config.hubs.items() %}
{% set hub_config = salt['slsutil.merge'](hub_defaults, hub_config) %}

softether-server-hub-{{ hub }}:
  softether_server.hub:
    - name: {{ hub | json }}
    - hub_password: {{ hub_config.password | json }}
    - password: {{ config.password | json }}
    - require:
      - service: softether-server-service

softether-server-hub-{{ hub }}-radius:
  softether_server.radius:
    - name: {{ hub | json }}
    - password: {{ config.password | json }}
    - enable: {{ hub_config.radius.enable | json }}
    - require:
      - service: softether-server-service
{% if hub_config.radius.enable %}
    - host: {{ hub_config.radius.host | json }}
    - port: {{ hub_config.radius.port | json }}
    - secret: {{ hub_config.radius.secret | json }}
    - retry_interval: {{ hub_config.radius.retry_interval | json }}
{% endif %}

{% for bridge in hub_config.bridges %}
softether-server-hub-{{ hub }}-bridge-{{ bridge }}:
  softether_server.bridge:
    - name: {{ bridge | json }}
    - hub: {{ hub | json }}
    - password: {{ config.password | json }}
    - require:
      - service: softether-server-service
{% endfor %}

{% for user,user_config in hub_config.users.items() %}
{% set user_config = salt['slsutil.merge'](user_defaults, user_config) %}
softether-server-hub-{{ hub }}-user-{{ user }}:
  softether_server.user:
    - name: {{ user | json }}
    - hub: {{ hub | json }}
    - group: {{ user_config.group | json }}
    - realname: {{ user_config.realname | json }}
    - note: {{ user_config.realname | json }}
    - auth_type: {{ user_config.auth_type | json }}
    - auth_data: {{ user_config.auth_data | json }}
    - password: {{ config.password }}
    - require:
      - service: softether-server-service
{% endfor %}
{% endfor %}