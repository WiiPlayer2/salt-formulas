commit-local-changes:
  salt.function:
    - name: cmd.run
    - tgt: home
    - arg:
      - git commit -a -m "[Changes made in UI]"
    - kwarg:
        cwd: /usr/share/hassio/homeassistant
        ignore_retcode: true

pull-remote-changes:
  salt.function:
    - name: git.pull
    - tgt: home
    - arg:
      - /usr/share/hassio/homeassistant
    - kwarg:
        opts: --rebase origin master

push-merged-changes:
  salt.function:
    - name: git.push
    - tgt: home
    - arg:
      - /usr/share/hassio/homeassistant
      - origin
      - master

generate-config:
  salt.function:
    - name: cmd.run
    - tgt: home
    - arg:
      - pip3 install --no-cache-dir -r requirements.txt && python3 main.py
    - kwarg:
        cwd: /usr/share/hassio/homeassistant/auto-generation

{# restart-homeassistant:
  salt.function:
    - name: docker.restart
    - tgt: home
    - arg:
      - home-assistant #}
