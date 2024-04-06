{%- set tplroot = tpldir.split('/')[0] %}
{% from tplroot ~ '/_install.sls' import softether_install with context %}

include:
  - .service

{{ softether_install('server') }}
