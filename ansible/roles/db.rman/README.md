Role DBRMAN
===========

This role perform a database backup using rman from a DBCS instance (Oracle Linux 6) to the backup area of the OCI DB System.

Requirements
------------

Create instance inventory in group [dbrman] in file inventory/hosts

Variables
---------

Create yml file with credentials in vars directory

This role just needs "oci" variable

Example
-------

> ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' dbrman.config.yml
