{%- if pillar.zookeeper is defined %}
include:
{%- if pillar.zookeeper.server is defined %}
- zookeeper.server
{%- endif %}
{%- if pillar.zookeeper.backup is defined %}
- zookeeper.backup
{%- endif %}
{%- endif %}
