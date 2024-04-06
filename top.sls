base:
{% if grains['id'] == 'salt' %}

  salt:
    - apt.repositories
    - ex.packages
    - files
    - kubernetes.configmaps
    - packages
    - salt

{% else %}

##########################
### Global
##########################
  '*':
    - salt.minion
    - files
    - cmd

##########################
### Linux
##########################
  'G@kernel:Linux':
    {# - apt.repositories #}
    - cron
    - ex.packages
    - mounts
    - nfs.client
    - nfs.mount
    - ntp
    - openssh
    - packages
    - timezone # linux only for now
    - users

  'G@kernel:Linux and G@roles:server':
    - rsyslog
    - systemd.journald
    - prometheus

##########################
### Windows
##########################
  'G@kernel:Windows':
    - ex.packages.chocolatey

##########################
### Misc. / Old
##########################
  'G@roles:roomassistant':
    - roomassistant

  'G@roles:mining.bhd':
    - mining.bhd

  'G@roles:car':
    - car
  
  dns:
    - bind
    - bind.config

  infra:
    - openldap.server
    - ex.openldap.server
    - jenkins
    - jenkins.plugins
    - jenkins.jobs
    - gitea

  home:
    - apt.ppa
    {# - apt.repositories #}
    {# - ex.git.config #}
    - docker
    - docker.containers

  zha:
    - docker
    - docker.containers

  murasa:
    - docker
    - docker.containers

  gensokyo:
    - proxmox
    - modprobe

  sumireko:
    - samba_ad

  komachi:
    - softether.server
  
  aya:
    - ex.grafana
    - docker
    - docker.containers

{% endif %}
