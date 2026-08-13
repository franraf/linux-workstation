---
title: Montar filesystems de instalação
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 07-format-efi.md
  - 09-install-base-system.md
---

# 08 — Montar filesystems

## Objetivo

Montar em `/mnt` a árvore que receberá o sistema base.

A relação subvolume → mountpoint vem exclusivamente de:

```text
system/storage/btrfs-layout.tsv
```

As opções Btrfs padrão são:

```text
noatime,compress=zstd:3
```

A ESP é montada separadamente em `/mnt/boot`.

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/08-mount-filesystems/run.sh \
  --efi-partition /dev/<esp>
```

O Btrfs padrão é `/dev/mapper/cryptroot`. O script valida ambos os dispositivos, a ESP, o filesystem Btrfs e que o root de montagem ainda não está em uso.

A operação exige confirmação `MOUNT`.

## Segurança e rollback

Os mounts são registrados na ordem em que são criados. Se o passo não chegar ao fim, o cleanup tenta desmontá-los na ordem inversa. Quando o passo conclui com sucesso, os mounts permanecem ativos para `pacstrap`.

## Verificação

Cada mount Btrfs deve apontar para o subvolume correspondente no layout e conter `noatime` e `compress=zstd:3`. `/mnt/boot` deve ser `vfat`.

## Próximo playbook

```text
09-install-base-system.md
```
