---
title: Instalar screen locker
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

# 04 — Instalar screen locker

## Objetivo

Instalar o Hyprlock como mecanismo de bloqueio da sessão, sem configurar aparência, atalhos ou integração com o ciclo de inatividade.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/screen-locker.txt
```

Baseline:

```text
hyprlock
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `hyprlock`.
5. Confirmar que a versão pode ser consultada.

## Verificação

Confirme que:

* o pacote `hyprlock` está instalado;
* o executável está disponível;
* a versão pode ser consultada.

## Fora de escopo

Não executar bloqueio/desbloqueio como requisito desta etapa e não criar `hyprlock.conf`. Autenticação interativa e integração com Hypridle serão validadas após configuração.

## Próximo playbook

```text
05-install-idle-manager.md
```
