OCI-C to OCI
============

These scripts were created to facilitate in some way the processes described in [Upgrade to Oracle Cloud Infrastructure](https://docs.oracle.com/en/cloud/migrate-oci.html).
They are not meant to substitute the processes described in link above nor are supported by Oracle.

The requiremts:
- Linux shell (works in windows WSL)
- Terraform
- Ansible 

Before migration
----------------

- Access to customer's cloud console in OCI-Classic and OCI
- Access to customer instances is needed to validade availability of OCI drivers and kernel modules
- Obtain customers's SSH keys/ask them to add you own/add through orchestration
- Create Compartment, VCN, subnet and bucket (ocic-oci-mig) in Object Storage based on the architecture previously defined with the customer

- [Create keys](ansible/roles/pre.panda/README.md)
- [Create Migration Instance](terraform/README.md) (for IaaS  migration)
- [Config Migration Instance](ansible/roles/panda.config/README.md)

- Ssh to migration instance and configure:
  - ansible/secret.yml 
  - ansible/hosts.yml

During migration
----------------

- Migrate [windows instances](ansible/roles/win.source/README.md)
- Migrate [linux instances](ansible/roles/linux.source/README.md)
- Migrate [Oracle databases using rman](ansible/roles/db.rman/README.md)
- Run mig-srv-setup to setup the Migration instance
- Run mig-service-start to start the service
- Run mig-source-setup to verify linux instances 
  - If missing drivers/modules, install as required by the script and run again until no more errors or warnings displayed
- Run mig-ctlt-setup to create the counterpart migration instance in OCI
- Run mig-job-run to start the migration process. If properly configured, the selected instances will be shutdown

- List running jobs: mig-job-list

OCI-C instances can be started once the migration is complete if customer needs them.
