---
title: Criar subvolumes Btrfs
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 05-create-btrfs.md
  - 07-format-efi.md
---

# 06 — Criar subvolumes Btrfs

## Objetivo

Criar a estrutura de subvolumes usada pela workstation. A fonte canônica não fica no script nem no profile:

```text
system/storage/btrfs-layout.tsv
```

Atualmente ela define `@`, `@home`, `@var`, `@var_log`, `@var_cache`, `@pkg`, `@docker` e `@snapshots` com seus respectivos mountpoints.

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/06-create-subvolumes/run.sh
```

O script monta temporariamente o top-level Btrfs (`subvolid=5`), verifica que ainda não existem subvolumes e só então apresenta o plano. A criação exige confirmação `CREATE`.

Se o passo falhar, o mount temporário criado pelo próprio script é desmontado durante o cleanup.

## Verificação

Cada entrada de `system/storage/btrfs-layout.tsv` precisa existir como subvolume Btrfs válido, e a quantidade criada deve corresponder exatamente ao layout declarado.

O mapeamento entre subvolume e mountpoint será consumido novamente pelos passos 08, 10 e 11; portanto ele possui uma única fonte de verdade.

## Próximo playbook

```text
07-format-efi.md
```
