---
title: Instalar idle manager
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
* ADR-0009

---

# 05 — Instalar idle manager

## Objetivo

Instalar o Hypridle como gerenciador de inatividade da sessão, sem definir políticas automáticas nesta etapa.

## Pré-requisitos

* `02-install-compositor` concluído;
* `04-install-screen-locker` concluído.

## Fonte declarativa

```text
packages/desktop/idle-manager.txt
```

Baseline:

```text
hypridle
```

## Procedimento

1. Validar Hyprland e Hyprlock como pré-requisitos.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `hypridle`.
5. Confirmar que o binário responde sem erro a uma consulta não interativa.

## Verificação

Confirme que:

* o pacote `hypridle` está instalado;
* o executável está disponível;
* a instalação pode ser validada sem iniciar uma política de inatividade.

## Fora de escopo

Não iniciar o daemon como requisito desta etapa e não criar `hypridle.conf`. Tempos de lock, DPMS e demais políticas pertencem à configuração do ciclo de vida da sessão.

## Próximo playbook

```text
06-install-application-launcher.md
```
