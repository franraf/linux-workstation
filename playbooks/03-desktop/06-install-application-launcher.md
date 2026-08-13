---
title: Instalar lançador de aplicações
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

# 06 — Instalar lançador de aplicações

## Objetivo

Instalar o Rofi como lançador de aplicações da workstation, sem configurar tema, modos ou atalhos.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/application-launcher.txt
```

Baseline:

```text
rofi
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `rofi`.
5. Confirmar que a versão pode ser consultada.

## Verificação

Confirme que:

* o pacote `rofi` está instalado;
* o executável está disponível;
* a versão pode ser consultada.

## Fora de escopo

Não abrir o launcher como requisito desta etapa e não configurar tema, bindings ou modos adicionais. A busca e abertura de aplicações serão validadas após configuração.

## Próximo playbook

```text
07-install-notification-center.md
```
