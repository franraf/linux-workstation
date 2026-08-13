---
title: Formatar EFI System Partition
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 06-create-subvolumes.md
  - 08-mount-filesystems.md
---

# 07 — Formatar EFI System Partition

## Objetivo

Formatar a partição marcada como EFI System Partition em FAT32, com label padrão `EFI`.

Este é um passo **destrutivo**.

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/07-format-efi/run.sh \
  --partition /dev/<esp>
```

O ambiente precisa ter sido iniciado em UEFI. O script exige um block device do tipo partição, gravável, com GUID ESP, pelo menos 260 MiB e sem mounts ativos.

Antes de apagar assinaturas e executar `mkfs.fat -F 32`, exige o caminho completo da partição e `ERASE`.

## Verificação

O passo só passa quando a partição apresenta:

- filesystem `vfat`;
- label esperado;
- UUID não vazio.

O mount da ESP em `/boot` fica para o passo seguinte.

## Próximo playbook

```text
08-mount-filesystems.md
```
