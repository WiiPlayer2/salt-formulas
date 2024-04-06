update-database:
  salt.function:
    - name: pkg.refresh_db
    - tgt: '* and not L@salt'

upgrade-packages:
  salt.function:
    - name: pkg.upgrade
    - tgt: '* and not L@salt'
    - kwarg:
        dist_upgrade: true
    - require:
      - salt: update-database

upgrade-choco-packages:
  salt.function:
    - name: choco.upgrade
    - tgt: 'G@kernel:Windows'
    - arg:
      - all
