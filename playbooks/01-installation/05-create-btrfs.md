---
title: Criar filesystem Btrfs
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 04-create-luks.md
  - 06-create-subvolumes.md
---

# 05 — Criar filesystem Btrfs

## Objetivo

Criar o filesystem Btrfs dentro do mapper LUKS ativo. O alvo padrão é:

```text
/dev/mapper/cryptroot
```

com label `linux-workstation`.

Este passo apaga quaisquer assinaturas/filesystem existentes **dentro do mapper**.

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/05-create-btrfs/run.sh
```

Opcionalmente:

```bash
sudo .../05-create-btrfs/run.sh --device /dev/mapper/cryptroot --label linux-workstation
```

O script exige um mapping `cryptsetup` ativo, não montado, sem filhos inesperados, gravável e com pelo menos 4 GiB. Antes do `mkfs.btrfs`, exige o caminho completo do mapper e `ERASE`.

## Verificação

O passo só passa quando o mapper apresenta:

- `FSTYPE=btrfs`;
- label esperado;
- UUID de filesystem não vazio.

A criação de subvolumes fica no próximo passo.

## Próximo playbook

```text
06-create-subvolumes.md
```
