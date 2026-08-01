---

title: Controle de versão
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004
* ADR-0005

---

# 01 — Controle de versão

## Objetivo

Adicionar à workstation a capacidade de controle de versão distribuído para gerenciamento de código-fonte.

Ao final deste playbook, a workstation estará preparada para clonar, versionar, revisar e publicar projetos utilizando Git.

A implementação adotada pelo projeto utiliza o **Git**.

---

# Pré-requisitos

* Fase **03-desktop** concluída e validada.
* Sessão gráfica operacional.
* Conectividade de rede disponível.

---

# Resultado esperado

Ao concluir este playbook:

* o Git estará instalado;
* a identidade do usuário estará configurada;
* a autenticação para repositórios remotos estará definida;
* o ambiente seguirá os padrões de controle de versão estabelecidos pelo projeto.

---

# Procedimento

## 1. Instalar o Git

Instale a implementação adotada pela arquitetura da workstation.

---

## 2. Configurar a identidade

Defina a identidade utilizada nos commits.

Considere:

* nome;
* endereço de e-mail;
* editor padrão;
* branch inicial.

---

## 3. Configurar o comportamento

Defina os padrões de operação do Git.

Considere aspectos como:

* estratégia de merge;
* tratamento de conflitos;
* paginação;
* cores;
* aliases;
* assinaturas de commit, quando utilizadas.

---

## 4. Configurar autenticação

Defina a estratégia de autenticação para repositórios remotos.

Considere mecanismos como:

* SSH;
* HTTPS com gerenciador de credenciais;
* tokens de acesso.

A estratégia adotada deverá estar documentada e ser reproduzível.

---

## 5. Validar a operação

Execute operações básicas utilizando um repositório de teste.

Confirme que é possível:

* inicializar um repositório;
* criar commits;
* clonar repositórios;
* autenticar em um repositório remoto;
* enviar e receber alterações.

---

# Verificação

Confirme que:

* o Git está instalado;
* a identidade do usuário está configurada;
* a autenticação funciona corretamente;
* operações locais e remotas são executadas sem erros;
* o ambiente segue os padrões definidos pelo projeto.

---

# Problemas comuns

## Falha de autenticação

Revise o método de autenticação adotado e confirme que as credenciais estão corretamente configuradas.

---

## Identidade incorreta

Confirme as configurações globais e locais do Git.

---

## Editor não abre

Verifique se o editor configurado está instalado e acessível pelo ambiente.

---

## Conflitos inesperados

Revise a estratégia de merge definida pelo projeto.

---

# Próximo playbook

Após validar a capacidade de controle de versão, prossiga para:

```text
02-shell-environment.md
```

---

# Referências

* Documentação oficial do Git
* Pro Git
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui alterações na estratégia de autenticação, novos aliases, ajustes de comportamento ou observações relevantes identificadas durante a evolução da workstation.
