{%- if pillar.zookeeper is defined %}
include:
{%- if pillar.zookeeper.server is defined %}
- zookeeper.server
{%- endif %}
{%- endif %}
