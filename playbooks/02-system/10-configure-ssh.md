---

title: Configurar SSH
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 10 — Configurar SSH

## Objetivo

Configurar o acesso remoto seguro à workstation utilizando OpenSSH.

Ao final deste playbook, o sistema aceitará conexões remotas conforme a política de acesso definida pelo projeto.

---

# Pré-requisitos

* Sistema operacional funcional.
* Conectividade de rede disponível.
* Política de gerenciamento de serviços aplicada.
* Usuário administrativo configurado.

---

# Resultado esperado

Ao concluir este playbook:

* o servidor OpenSSH estará instalado;
* o serviço SSH estará configurado e habilitado;
* o acesso remoto seguirá a política de autenticação definida pelo projeto;
* o usuário `root` não poderá acessar o sistema remotamente;
* a configuração estará validada antes da exposição do serviço.

---

# Procedimento

## 1. Instalar o OpenSSH

Instale o pacote responsável pelo cliente e pelo servidor SSH.

---

## 2. Revisar a configuração padrão

Analise a configuração fornecida pelo OpenSSH antes de realizar alterações.

Evite modificar opções sem necessidade documentada.

---

## 3. Configurar a política de autenticação

Defina os mecanismos de autenticação permitidos pela workstation.

Priorize autenticação por chave pública.

Caso o acesso por senha seja mantido temporariamente, registre essa condição para revisão posterior.

---

## 4. Restringir o acesso administrativo

Desabilite o login remoto direto da conta `root`.

O acesso administrativo deverá ocorrer por meio do usuário principal e do mecanismo de elevação de privilégios definido pelo projeto.

---

## 5. Restringir usuários autorizados

Quando aplicável, limite o acesso remoto aos usuários ou grupos previstos pela arquitetura.

Evite permitir acesso indiscriminado a todas as contas locais.

---

## 6. Validar a configuração

Valide a sintaxe da configuração antes de iniciar ou reiniciar o serviço.

Não aplique uma configuração inválida que possa impedir o acesso remoto.

---

## 7. Habilitar o serviço

Configure o servidor SSH para iniciar automaticamente com o sistema.

---

## 8. Testar o acesso remoto

Realize uma conexão a partir de outro dispositivo da rede.

Mantenha a sessão local aberta durante o primeiro teste para permitir correções em caso de falha.

---

## 9. Revisar os registros

Confirme que a autenticação foi registrada corretamente e que não existem erros relacionados ao serviço.

---

# Verificação

Confirme que:

* o serviço SSH está ativo;
* a porta configurada está acessível apenas nas redes previstas;
* o usuário autorizado consegue se autenticar;
* o login remoto da conta `root` está bloqueado;
* a autenticação segue a política definida pelo projeto;
* não existem erros críticos nos registros do serviço.

---

# Problemas comuns

## Serviço não inicia

Valide a sintaxe da configuração e revise os registros do serviço.

---

## Conexão recusada

Confirme que o serviço está ativo, que a workstation possui conectividade e que a porta utilizada está acessível.

---

## Autenticação por chave falha

Revise a chave pública instalada, as permissões dos arquivos e a associação da chave ao usuário correto.

---

## Usuário sem acesso

Confirme que a conta está autorizada pela política configurada e que não existe uma restrição conflitante.

---

## Perda de acesso remoto

Utilize o acesso local para restaurar uma configuração válida.

Evite encerrar a sessão SSH atual antes de confirmar que uma nova conexão pode ser estabelecida.

---

# Próximo playbook

Após validar o acesso SSH, prossiga para:

```text
11-install-base-packages.md
```

---

# Referências

* Arch Wiki — OpenSSH
* Arch Wiki — Secure Shell
* Manual do `sshd_config`
* Documentação oficial do OpenSSH

---

# Lições aprendidas

Registrar aqui alterações na política de autenticação, restrições de acesso, problemas com chaves ou ajustes identificados durante a operação da workstation.
