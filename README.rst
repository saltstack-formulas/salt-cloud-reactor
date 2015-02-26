salt-cloud-reactor
==================

This is a reactor formula, which allows supported providers in Salt Cloud to
notify Salt when an instance is created, so that it may be automatically
bootstrapped and accepted by the Salt Master, or when an instance is deleted,
so that its key can be automatically removed from the Salt Master.


Dependencies
------------
The following packages must be installed:

.. code-block:: yaml

    - Salt (develop branch)


Master Configuration
--------------------
The following files need to be configured on the Salt Master:

.. code-block:: yaml

    - /etc/salt/master
    - /etc/salt/cloud
    - /etc/salt/cloud.providers.d/*


/etc/salt/master
~~~~~~~~~~~~~~~~

The master must be set up to point the reactor to the necessary Salt Cloud
provider setting. Any additional settings to be used on the target minion, that
are not configured in the provider configuration, can also be set here.

.. code-block:: yaml

    reactor:
      - 'salt/cloud/*/cache_node_new':
        - '/srv/reactor/autoscale.sls'
      - 'salt/cloud/*/cache_node_missing':
        - '/srv/reactor/autoscale.sls'

    autoscale:
      provider: my-ec-config
      ssh_username: root


/etc/salt/cloud
~~~~~~~~~~~~~~~

Salt Cloud must be configured to use the cloud cachedir, and to generate events
based on the contents of it. The following two options need to be set:

.. code-block:: yaml

    update_cachedir: True
    diff_cache_events: True

This will cause Salt Cloud to fire events to Salt when changes are detected on
the configured provider.

Some of these events will contain data which describe a node. Because some of
the fields returned may contain sensitive data, the ``cache_event_strip_fields``
configuration option exists to strip those fields from the event return.

.. code-block:: yaml

    cache_event_strip_fields:
      - password
      - priv_key


/etc/salt/cloud.providers.d/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Existing Salt Cloud provider configuration can be used with this reactor.
Profile configuration is not necessary on the master; the instance is assumed
to already be created by the time it hits the reactor.

.. code-block:: yaml

    my-ec2-config:
      id: <aws id>
      key: <aws key>
      keyname: <my key name>
      securitygroup: <my security group>
      private_key: </path/to/my/priv_key.pem>
      location: us-east-1
      provider: ec2
      minion:
        master: saltmaster.example.com

.. [*] Note, that openstack cloud provider is currently broken and autoscaling will not work with it until
  `this bug <https://github.com/saltstack/salt/issues/20932#issuecomment-76043607>`_ is fixed.

Basic Usage
-----------
Once the Salt Master has been configured, the reactor will manage itself. When
``salt-cloud -F`` or ``salt-cloud --full-query`` is issued against a configured
provider, the cloud cache will up reviewed and updated by Salt Cloud. When a
new instance is detected, Salt Cloud will be notified to wait for it to become
available, and bootstrap it with Salt. Its key will be automatically accepted,
and if the minion configuration includes the appropriate startup state, then
the minion will configure itself, and go to work.

When the autoscaler spins down a machine, the Wheel system inside of Salt will
be notified to delete its key from the master. This causes instances to be
completely autonomous, both in setup and tear-down.

In order to perform these queries on a regular basis, the above command needs
to be issued via a scheduling system, such as cron or the Salt Scheduler. It is
recommended in most configuration to use no less than a 5 minute delay between
intervals, as a measure of respect to the cloud provider.

Caveats
-------
Because this data is polled for, rather than being triggered directly from the
cloud provider, there will be a delay between the instance being created, and
Salt Cloud being able to bootstrap it.
