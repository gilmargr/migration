Role DBRMAN
=========

Esta role faz o backup de um database rodando em Oracle Linux 6 (DBCS Classic) para a area de backup do DB System do OCI

Requisitos
------------

Criar o inventory dos servidores que serão migrados no grupo [dbrman]

$panda/inventory/hosts -> Lista de servidores


Variaveis
-----------

Criar o yml das credenciais no $panda/vars

Para esta role é necessario apenas a variavel oci:

Exemplo
---------

Passar de parametro o inventario e o yml criado no@vars:

ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' dbrman.config.yml
