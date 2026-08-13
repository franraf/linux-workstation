---
title: Instalar login manager da sessão
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0006
* ADR-0007
* ADR-0008

---

# 11 — Instalar login manager da sessão

## Objetivo

Instalar a capacidade responsável por autenticar o usuário antes do início da sessão gráfica.

A implementação adotada utiliza `greetd` como login manager e `tuigreet` como frontend de autenticação.

Este é o último playbook de instalação da fase `03-desktop`. A partir do playbook seguinte, a fase entra exclusivamente na etapa de configuração.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.
* Demais capacidades de desktop dos playbooks `01` a `10` instaladas.
* Conta de usuário normal disponível.
* Pacman operacional.

---

# Resultado esperado

Ao concluir este playbook:

* `greetd` estará instalado;
* `tuigreet` estará instalado;
* o usuário de sistema `greeter` estará disponível conforme o empacotamento;
* nenhum autologin da conta pessoal será configurado;
* nenhuma configuração do fluxo de login será aplicada nesta etapa;
* todas as capacidades necessárias da fase desktop estarão instaladas antes do início das configurações.

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

Não configure autologin, não habilite o serviço e não modifique perfis do shell nesta etapa.

## 3. Validar os binários e artefatos

Confirme a presença de:

```text
greetd
tuigreet
/etc/greetd/
```

---

# Verificação

Confirme que:

* os pacotes esperados estão instalados;
* `tuigreet` está disponível;
* `/etc/greetd/` existe;
* a conta pessoal continua exigindo autenticação;
* nenhuma configuração da sessão foi aplicada;
* os playbooks `01` a `11` concluíram apenas a etapa de instalação das capacidades do desktop.

---

# Problemas comuns

## Pacote ausente

Revise a lista declarativa de pacotes e a sincronização dos repositórios oficiais.

## Autologin já configurado anteriormente

Não trate isso como parte da instalação. Registre a situação e remova o autologin no playbook de configuração da sessão de login.

---

# Próximo playbook

```text
12-configure-desktop-session.md
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

A fase desktop instala todas as capacidades antes de iniciar qualquer configuração. Isso mantém uma fronteira clara: `01–11` disponibilizam componentes; `12–21` configuram esses componentes; `22` valida a integração final.
