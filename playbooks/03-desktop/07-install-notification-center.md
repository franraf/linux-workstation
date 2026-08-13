---
title: Instalar central de notificações
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

# 07 — Instalar central de notificações

## Objetivo

Instalar o Sway Notification Center (SwayNC) como central de notificações da sessão Wayland, sem configurar aparência, widgets, atalhos ou autostart.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/notification-center.txt
```

Baseline:

```text
swaync
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar os executáveis `swaync` e `swaync-client`.
5. Confirmar que a versão pode ser consultada.

## Verificação

Confirme que:

* o pacote `swaync` está instalado;
* `swaync` está disponível;
* `swaync-client` está disponível;
* a versão pode ser consultada.

## Fora de escopo

Não iniciar o daemon nem enviar notificações como requisito desta etapa. Recebimento, descarte, atalhos e integração com a sessão serão validados após configuração.

## Próximo playbook

```text
08-install-terminal-emulator.md
```
