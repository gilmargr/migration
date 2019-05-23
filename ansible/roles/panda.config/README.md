Role panda.config
=================

Configure panda instance with yml files and aliases to make the migration easier

Requirements
------------

- Fill in instances configurations in inventory groups [linux] and [windows] in "inventory/hosts" file

Variables
---------

Create a yml file containing classic and oci variables under "vars" directory

Playbook
--------

> ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' panda_config.yml
