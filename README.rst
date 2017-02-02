
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
