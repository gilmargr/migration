Role DBRMAN
===========

This role perform a database backup using rman from a DBCS instance (Oracle Linux 6) to the backup area of the OCI DB System.

Requirements
------------

- Obtain password for DBCS (sys user). It will be used to restore the database in OCI

Variables
---------

- Create yml file containing classic and oci variables under "vars" directory
- This role uses the "oci" variable content

Inventory
---------

- Fill in instances configurations in inventory group [dbrman] in "inventory/hosts" file
- Create a yml file under inventory/host_vars. Use dbcs1.yml as template
  - Each file must have the same name as the one defined in "hosts" file above (Ex dbcs1.yml).

Example
-------

> ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' dbrman.config.yml
