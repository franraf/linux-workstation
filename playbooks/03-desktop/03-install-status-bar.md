---
title: Instalar status bar
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

# 03 — Instalar status bar

## Objetivo

Instalar o Waybar como barra de status da sessão Wayland, sem aplicar configuração visual ou integração de autostart.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/status-bar.txt
```

Baseline:

```text
waybar
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `waybar`.
5. Confirmar que a versão pode ser consultada.

## Verificação

Confirme que:

* o pacote `waybar` está instalado;
* o executável está disponível;
* a versão pode ser consultada.

## Fora de escopo

Não iniciar o Waybar como requisito desta etapa, não criar `config.jsonc` ou `style.css` e não integrá-lo ao autostart. O teste funcional ocorre após a configuração.

## Próximo playbook

```text
04-install-screen-locker.md
```
