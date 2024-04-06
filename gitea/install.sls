{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import gitea with context %}
include:
  - git
  - gitea.service

gitea-user:
  user.present:
    - name: {{ gitea.user }}

gitea-binary:
  file.managed:
    - name: /usr/local/bin/gitea
    - source: {{ gitea.download_url }}
    - source_hash: {{ gitea.download_url }}.sha256
    - mode: 755
    - require_in:
      - service: gitea-service

gitea-work-directory:
  file.directory:
    - name: {{ gitea.work_path }}
    - user: {{ gitea.user }}
    - group: {{ gitea.user }}
    - mode: 750
    - require:
      - user: gitea-user
    - require_in:
      - service: gitea-service

gitea-custom-directory:
  file.directory:
    - name: {{ gitea.custom_path }}
    - user: {{ gitea.user }}
    - group: {{ gitea.user }}
    - mode: 750
    - require:
      - user: gitea-user
    - require_in:
      - service: gitea-service

gitea-init.d-script:
  pkg.installed:
    - name: sudo

  file.managed:
    - name: /etc/init.d/gitea
    - source:
      - salt://gitea/files/init/default/gitea.jinja
    - template: jinja
    - mode: 755
    - require:
      - pkg: gitea-init.d-script
    - watch_in:
      - service: gitea-service
