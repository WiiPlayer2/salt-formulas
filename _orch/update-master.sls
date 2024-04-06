update-master:
  salt.state:
    - tgt: 'salt'
    - sls:
      - salt.formulas
      - salt.master
      - salt.minion
