Atention
========

These scripts were created to facilitate in some way the processes described in [Upgrade to Oracle Cloud Infrastructure](https://docs.oracle.com/en/cloud/migrate-oci.html)

The requiremts:
- Linux shell (WSL in windows)
- Terraform
- Ansible 

Before migration day requirements
---------------------------------

- Access to customer instances is needed to validade availability of OCI drivers and kernel modules (Linux instances)
- Obtain customers's SSH keys, ask them to add you own or add through orchestration
- [Create Migration Instance](https://github.com/gilmargr/migration/blob/master/terraform/README.md) (for IaaS  migration)
