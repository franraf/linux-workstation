---
title: Instalar stack tipográfica
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

# 10 — Instalar stack tipográfica

## Objetivo

Instalar a stack de fontes da workstation e atualizar o cache tipográfico, sem configurar aplicações individualmente.

## Pré-requisitos

* `02-install-compositor` concluído;
* Pacman operacional.

## Fonte declarativa

```text
packages/desktop/font-stack.txt
```

Baseline:

```text
ttf-dejavu
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
ttf-jetbrains-mono-nerd
```

## Procedimento

1. Carregar e validar a lista declarativa.
2. Instalar somente os pacotes ausentes.
3. Reconstruir o cache com `fc-cache`.
4. Confirmar que Fontconfig localiza as famílias previstas.
5. Confirmar a resolução das famílias genéricas `sans-serif`, `monospace` e `emoji`.

## Verificação

Confirme que:

* todos os pacotes declarados estão instalados;
* o cache tipográfico foi reconstruído;
* DejaVu, Noto Sans, Noto Color Emoji e JetBrainsMono Nerd Font são localizados pelo Fontconfig;
* famílias genéricas podem ser resolvidas.

## Fora de escopo

A validação visual de ícones, emojis e Unicode em aplicações gráficas pertence ao bloco de configuração e ao gate final da fase.

## Próximo playbook

```text
11-install-session-login.md
```
