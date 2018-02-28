
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

Backup client with ssh/rsync remote host

.. code-block:: yaml

    zookeeper:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24
          target:
            host: cfg01

  .. note:: full_backups_to_keep param states how many backup will be stored locally on zookeeper client.
            More options to relocate local backups can be done using salt-formula-backupninja.

Backup client with local backup only

.. code-block:: yaml

    zookeeper:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24

  .. note:: full_backups_to_keep param states how many backup will be stored locally on zookeeper client

Backup server rsync

.. code-block:: yaml

    zookeeper:
      backup:
        server:
          enabled: true
          hours_before_full: 24
          full_backups_to_keep: 5
          key:
            zookeeper_pub_key:
              enabled: true
              key: ssh_rsa

Backup server without strict client restriction

.. code-block:: yaml

    zookeeper:
      backup:
        restrict_clients: false

Client restore from local backup:

.. code-block:: yaml

    zookeeper:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24
          target:
            host: cfg01
          restore_latest: 1
          restore_from: local

  .. note:: restore_latest param with a value of 1 means to restore db from the last full backup. 2 would mean to restore second latest full backup.


Client restore from remote backup:

.. code-block:: yaml

    zookeeper:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24
          target:
            host: cfg01
          restore_latest: 1
          restore_from: remote

  .. note:: restore_latest param with a value of 1 means to restore db from the last full backup. 2 would mean to restore second latest full backup.


Read more
=========

* links

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-zookeeper/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-zookeeper

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
