Encryption
==========

If you intent to share your files, you should encrypt sensitive data.
For that, use ansible vault
The ansible config provided, look for a file in (~/.ansible/vault_pass) with a one line password to encrypt the
string.

Ex: ansible-vault encrypt_string 'password' --name 'password'
