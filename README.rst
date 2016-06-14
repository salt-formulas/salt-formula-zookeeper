
==================================
zookeeper
==================================

Service zookeeper description

Sample pillars
==============

Single zookeeper service

.. code-block:: yaml

    zookeeper:
      server:
        enabled: true
        members:
        - host: ${_param:single_address}
          id: 1

Cluster zookeeper service

.. code-block:: yaml

    zookeeper:
      server:
        enabled: true
        members:
        - host: ${_param:cluster_node01_address}
          id: 1
        - host: ${_param:cluster_node02_address}
          id: 2
        - host: ${_param:cluster_node03_address}
          id: 3

Read more
=========

* links
