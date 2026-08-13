---
title: Entrar no chroot
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 10-generate-fstab.md
  - 12-configure-time.md
---

# 11 — Entrar no chroot

## Objetivo

Validar o sistema recém-instalado e fazer a transição do ambiente live para o root em `/mnt` usando `arch-chroot`.

## Execução interativa

```bash
sudo profiles/dell-latitude-e5470/01-installation/11-enter-chroot/run.sh
```

O script valida o target Arch, `fstab`, shell e todos os mounts definidos em `system/storage/btrfs-layout.tsv`, além da ESP em `/boot`. Para abrir um shell interativo exige confirmação `CHROOT`.

## Execução de comando

Também é possível executar diretamente um comando no target:

```bash
sudo .../11-enter-chroot/run.sh -- pacman -Q
```

Nesse modo não há confirmação `CHROOT`, pois o comando é fornecido explicitamente na linha de comando.

## Contexto dos próximos passos

Os passos 12–17 devem ser executados **dentro do sistema instalado**. O repositório precisa estar acessível no chroot para que os scripts encontrem `scripts/lib/` e os artefatos de `system/`.

## Próximo playbook

```text
12-configure-time.md
```
