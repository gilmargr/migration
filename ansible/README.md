Encryption
==========

Use ansible vault to encrypt password in var/yml files if you need to share the
configuration files.
Ansible config provided look for a file in (~/.ansible/vault_pass) with a one line password to encrypt the
string.

ansible-vault encrypt_string 'password' --name 'password'
