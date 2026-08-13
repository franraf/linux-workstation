---
title: Instalar login manager da sessão
version: 1.2
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
* ADR-0009

---

# 11 — Instalar login manager da sessão

## Objetivo

Instalar `greetd` e `tuigreet` como capacidade de autenticação da sessão gráfica, sem configurar nem habilitar o fluxo de login nesta etapa.

Este é o último playbook de instalação da fase `03-desktop`.

## Pré-requisitos

* playbooks `01–10` concluídos;
* Hyprland instalado;
* conta de usuário normal disponível;
* Pacman operacional.

## Fonte declarativa

```text
packages/desktop/session-login.txt
```

Baseline:

```text
greetd
greetd-tuigreet
```

## Procedimento

1. Carregar e validar a lista declarativa.
2. Instalar somente os pacotes ausentes.
3. Confirmar os executáveis `greetd` e `tuigreet`.
4. Confirmar a existência de `/etc/greetd/`.
5. Confirmar a existência da conta de sistema `greeter`.
6. Confirmar que esta etapa não habilitou `greetd.service`.

## Verificação

Confirme que:

* `greetd` está instalado;
* `greetd-tuigreet` está instalado;
* os executáveis esperados estão disponíveis;
* `/etc/greetd/` existe;
* a conta `greeter` existe;
* o serviço não foi habilitado por este playbook;
* nenhum autologin da conta pessoal foi criado;
* nenhum profile de shell foi alterado.

## Fora de escopo

Não criar a configuração definitiva do `greetd`, não habilitar o serviço, não desabilitar `getty@tty1` e não iniciar Hyprland automaticamente pelo shell. Essas ações pertencem ao playbook `21-configure-session-login`.

## Próximo playbook

A instalação das capacidades do desktop termina aqui. A configuração começa em:

```text
12-configure-desktop-session.md
```

## Lições aprendidas

A fase `03-desktop` usa deliberadamente o fluxo `01–11` para instalação, `12–21` para configuração e `22` para validação final. Esse agrupamento é específico desta fase e não define a organização obrigatória das demais fases.
