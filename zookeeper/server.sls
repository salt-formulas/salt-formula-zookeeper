{%- from "zookeeper/map.jinja" import server with context %}
{%- if server.enabled %}

zookeeper_server_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

/etc/zookeeper/conf/zoo.cfg:
  file.managed:
  - source: salt://zookeeper/files/zoo.cfg
  - template: jinja
  - require:
    - pkg: zookeeper_server_packages

/var/lib/zookeeper/myid:
  file.managed:
  - contents: '{{ database.id }}'

zookeeper_server_services:
  service.running:
  - names: {{ server.services }}
  - enable: true
  - watch:
    - file: /etc/zookeeper/conf/zoo.cfg

{%- if grains.get('virtual_subtype', None) == "Docker" %}

zookeeper_entrypoint:
  file.managed:
  - name: /entrypoint.sh
  - template: jinja
  - source: salt://zookeeper/files/entrypoint.sh
  - mode: 755

{%- endif %}

{%- endif %}
