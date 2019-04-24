Role panda.config
=================

Configure panda instance with yml files and aliases to make the migration easier

Requirements
------------

Create instance inventory in groups [linux] and [windows] in file inventory/hosts

Variables
---------

Create yml file with classic and oci variables in "vars" directory

Playbook
--------

ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' panda_config.yml
