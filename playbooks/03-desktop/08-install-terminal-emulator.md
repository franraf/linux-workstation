---
title: Instalar emulador de terminal
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

# 08 — Instalar emulador de terminal

## Objetivo

Instalar o Kitty como emulador de terminal da sessão gráfica, sem configurar aparência, shell ou atalhos.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/terminal-emulator.txt
```

Baseline:

```text
kitty
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `kitty`.
5. Confirmar que a versão pode ser consultada.

## Verificação

Confirme que:

* o pacote `kitty` está instalado;
* o executável está disponível;
* a versão pode ser consultada.

## Fora de escopo

Não abrir uma janela gráfica como requisito desta etapa e não configurar fonte, tema ou shell. Inicialização gráfica e renderização Unicode serão validadas após a configuração e a instalação da stack tipográfica.

## Próximo playbook

```text
09-install-file-manager.md
```
