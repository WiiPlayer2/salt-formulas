{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import prometheus as p with context %}

{%- set name = 'node_exporter' %}
{%- set config = p.exporters[name]['textfile_collectors']['apt'] %}
{%- set dir = p.pkg.component[name]['service']['args']['collector.textfile.directory'] %}
{%- set script = p.dir.archive ~ '/textfile_collectors/apt.sh' %}

prometheus-exporters-{{ name }}-textfile_collectors-apt-script:
  file.managed:
    - name: {{ script }}
    - source: salt://prometheus/exporters/{{ name }}/textfile_collectors/files/apt.sh
    - mode: 755
    - makedirs: true

prometheus-exporters-{{ name }}-textfile_collectors-apt-cronjob:
  cron.present:
    - identifier: prometheus-exporters-{{ name }}-textfile_collectors-apt-cronjob
    - name: cd {{ dir }} && LANG=C {{ script }} > .apt.prom$$ && mv .apt.prom$$ apt.prom
    - minute: "{{ config.get('minute', '15') }}"
    - comment: Prometheus' {{ name }}'s apt textfile collector
    - require:
      - file: prometheus-exporters-{{ name }}-textfile_collectors-apt-script
