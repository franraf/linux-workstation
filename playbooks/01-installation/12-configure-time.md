---
title: Configurar data e hora
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 11-enter-chroot.md
  - 13-configure-localization.md
---

# 12 — Configurar data e hora

## Objetivo

Configurar timezone e relógio de hardware no sistema instalado.

O padrão do perfil é:

```text
Timezone: America/Sao_Paulo
RTC:      UTC
```

## Execução

Dentro do chroot:

```bash
profiles/dell-latitude-e5470/01-installation/12-configure-time/run.sh
```

Outro timezone IANA pode ser informado com `--timezone`.

O script exige um contexto Arch instalado com `fstab`, valida o arquivo correspondente em `/usr/share/zoneinfo` e solicita confirmação `TIME`.

## Alterações

- `/etc/localtime` passa a apontar para a zona selecionada;
- `hwclock --systohc --utc` grava o relógio de hardware usando UTC;
- `/etc/adjtime` é gerado/atualizado pelo `hwclock`.

## Verificação

O passo só passa quando `/etc/localtime` aponta para o timezone esperado, `/etc/adjtime` existe e registra `UTC`, e o sistema consegue determinar a zona atual.

## Próximo playbook

```text
13-configure-localization.md
```
