---
title: Instalar login manager da sessão
version: 1.0
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0006
* ADR-0008

---

# 20 — Instalar login manager da sessão

## Objetivo

Instalar a capacidade responsável por autenticar o usuário antes do início da sessão gráfica.

A implementação adotada utiliza `greetd` como login manager e `tuigreet` como frontend de autenticação.

Este playbook instala a capacidade. A configuração do fluxo de login pertence ao playbook seguinte.

---

# Pré-requisitos

* Hyprland instalado e funcional.
* Sessão gráfica já validada manualmente com `start-hyprland`.
* Conta de usuário normal disponível.
* Pacman operacional.

---

# Resultado esperado

Ao concluir este playbook:

* `greetd` estará instalado;
* `tuigreet` estará instalado;
* o usuário de sistema `greeter` estará disponível conforme o empacotamento;
* nenhum autologin da conta pessoal será configurado;
* o serviço ainda não dependerá de personalizações não validadas.

---

# Procedimento

## 1. Declarar os pacotes

Mantenha os pacotes da capacidade em lista declarativa conforme a ADR-0007.

A baseline da capacidade é:

```text
greetd
greetd-tuigreet
```

## 2. Instalar os pacotes

Instale os pacotes pelos repositórios oficiais do Arch Linux.

Não configure autologin e não modifique perfis do shell nesta etapa.

## 3. Validar os binários e artefatos

Confirme a presença de:

```text
greetd
tuigreet
/etc/greetd/
```

Confirme também que a instalação não substituiu a autenticação normal do usuário por autologin.

---

# Verificação

Confirme que:

* os pacotes esperados estão instalados;
* `tuigreet` está disponível;
* `/etc/greetd/` existe;
* a conta pessoal continua exigindo autenticação;
* nenhuma configuração de inicialização da sessão foi aplicada nesta etapa.

---

# Problemas comuns

## Pacote ausente

Revise a lista declarativa de pacotes e a sincronização dos repositórios oficiais.

## Autologin já configurado anteriormente

Não trate isso como parte da instalação. Registre a situação e remova o autologin no playbook de configuração.

---

# Próximo playbook

```text
21-configure-session-login.md
```

---

# Referências

* ADR-0006 — Separação entre instalação e configuração
* ADR-0007 — Listas declarativas de pacotes
* ADR-0008 — Autenticação e inicialização da sessão gráfica
* Documentação do greetd
* Arch Wiki — greetd

---

# Lições aprendidas

A autenticação da sessão deve ser instalada separadamente de sua configuração para evitar que a simples presença do pacote altere o fluxo de login sem validação explícita.
