---
title: Gerar fstab
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 09-install-base-system.md
  - 11-enter-chroot.md
---

# 10 — Gerar fstab

## Objetivo

Gerar `/mnt/etc/fstab` a partir da árvore de mounts validada, usando UUIDs como identificadores.

O layout Btrfs esperado é consumido de:

```text
system/storage/btrfs-layout.tsv
```

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/10-generate-fstab/run.sh
```

O script recusa o root em execução, exige um target Arch montado sobre o subvolume `@`, confirma todos os mountpoints do layout e `/boot`, e não sobrescreve um `fstab` que já contenha entradas.

A geração exige confirmação `GENERATE` e usa:

```bash
genfstab -U /mnt
```

## Verificação

O `fstab` só é aceito quando:

- contém exatamente os mountpoints do layout mais `/boot`;
- não contém mountpoints duplicados;
- todas as fontes usam `UUID=`;
- as entradas Btrfs usam o subvolume correto, `noatime` e `compress=zstd:3`;
- `/boot` é `vfat`;
- `mount --fake --all --fstab` aceita a sintaxe.

## Próximo playbook

```text
11-enter-chroot.md
```
