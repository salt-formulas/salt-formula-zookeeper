{%- from "zookeeper/map.jinja" import server with context %}
#!/bin/bash -e

cat /srv/salt/pillar/server.sls | envsubst > /tmp/server.sls
mv /tmp/server.sls /srv/salt/pillar/server.sls

salt-call --local --retcode-passthrough state.highstate

{% for service in control.services %}
service {{ service }} stop || true
{% endfor %}

/usr/bin/java -cp /etc/zookeeper/conf:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/zookeeper.jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dzookeeper.log.dir=/var/log/zookeeper -Dzookeeper.root.logger=INFO,ROLLINGFILE org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg

{#-
vim: syntax=jinja
-#}