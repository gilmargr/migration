Windows Instances
=================

This playbook prepares windows instances to OCI migration by instaling necessary drivers to run in paravirtualized mode in OCI.

Requirements
------------

- Python pywinrm library
- Firewall rule to access windows instances in port 5985

Role Variables
--------------

- Fill in instances configurations in inventory group [windows] in "inventory/hosts" file

Example Playbook
----------------

> ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' win_source.yml
