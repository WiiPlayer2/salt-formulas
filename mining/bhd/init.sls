{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/bhd/map.jinja" import cfg with context %}

include:
  - docker

mining-bhd-foxy-proxy-config-dir:
  file.directory:
    - name: {{ cfg.config_path }}

mining-bhd-foxy-proxy-config:
  file.managed:
    - name: {{ cfg.config_path }}/config.yaml
    - source: salt://mining/bhd/files/config.jinja
    - template: jinja
    - context:
        cfg: {{ cfg.proxy_config | json }}
    - require:
        - file: mining-bhd-foxy-proxy-config-dir

mining-bhd-foxy-proxy-container:
  docker_container.running:
    - name: bhd-foxy-proxy
    - image: felixbrucker/foxy-proxy:latest
    - restart_policy: unless-stopped
    - port_bindings:
      - 12345:12345
    - binds:
        - {{ cfg.config_path }}:/conf
    - watch:
        - file: mining-bhd-foxy-proxy-config

mining-bhd-scavenger-config:
  file.managed:
    - name: {{ cfg.config_path }}/scavenger.yaml
    - source: salt://mining/bhd/files/config.jinja
    - template: jinja
    - context:
        cfg: {{ cfg.scavenger_config | json }}
    - require:
        - file: mining-bhd-foxy-proxy-config-dir

mining-bhd-scavenger-container:
  docker_container.running:
    - name: bhd-scavenger
    - image: pocconsortium/scavenger:latest
    - restart_policy: unless-stopped
    - binds:
      - {{ cfg.config_path }}/scavenger.yaml:/data/config.yaml
{% for bind in cfg.scavenger_config.plot_dirs %}
      - {{ bind }}:{{ bind }}
{% endfor %}
    - watch:
        - file: mining-bhd-scavenger-config

mining-bhd-watchtower-container:
  docker_container.running:
    - name: bhd-watchtower
    - image: containrrr/watchtower
    - restart_policy: unless-stopped
    - binds:
      - /var/run/docker.sock:/var/run/docker.sock
