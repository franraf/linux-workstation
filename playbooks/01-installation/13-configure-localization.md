---
title: Configurar localização do sistema
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 12-configure-time.md
  - 14-configure-network.md
---

# 13 — Configurar localização do sistema

## Objetivo

Configurar locales e keymap persistente do console dentro do sistema instalado.

A baseline é:

```text
locale primário:  pt_BR.UTF-8
locale fallback:  en_US.UTF-8
console keymap:   br-abnt2
```

Os arquivos finais são renderizados a partir de:

```text
system/localization/locale.conf.template
system/localization/vconsole.conf.template
```

## Execução

Dentro do chroot:

```bash
profiles/dell-latitude-e5470/01-installation/13-configure-localization/run.sh
```

Os três valores podem ser sobrescritos explicitamente por argumentos. O script valida se os locales existem em `/etc/locale.gen`, se o keymap existe e exige confirmação `LOCALE`.

## Alterações

- habilita os locales necessários em `/etc/locale.gen`;
- executa `locale-gen`;
- gera `/etc/locale.conf` a partir do template;
- gera `/etc/vconsole.conf` a partir do template.

## Verificação

O passo só passa quando os locales estão efetivamente gerados, as entradas de `locale.gen` estão habilitadas, `LANG` e `KEYMAP` correspondem ao solicitado e o locale primário usa UTF-8.

## Próximo playbook

```text
14-configure-network.md
```
