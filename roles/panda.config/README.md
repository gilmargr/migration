Panda Config
============

Configura o panda com os arquivos de yml e cria aliases para facilitar a execucao dos comando

Requisitos
----------

Criar o inventory dos servidores que serão migrados no grupo [sources]

$panda/inventory/hosts -> Lista de servidores


Variaveis
---------

Criar o yml das credenciais no $panda/vars

Para esta role é necessario apenas a variavel classic:


Exemplo
-------

Passar de parametro o inventario e o yml criado no@vars:

ansible-playbook -i inventory/hosts -e '@vars/my-vars.yml' panda_config.yml
