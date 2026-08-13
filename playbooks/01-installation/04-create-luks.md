---
title: Criar volume LUKS
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 03-partition-disk.md
  - 05-create-btrfs.md
---

# 04 — Criar volume LUKS

## Objetivo

Transformar a partição Linux LUKS criada no passo anterior em um container LUKS2 e abri-lo como:

```text
/dev/mapper/cryptroot
```

Este é um passo **destrutivo** e a senha nunca é armazenada pelo repositório.

## Execução

```bash
sudo profiles/dell-latitude-e5470/01-installation/04-create-luks/run.sh \
  --partition /dev/<particao-luks>
```

O script valida que o alvo é uma partição gravável com o GUID Linux LUKS, sem mounts, holders ativos, mapper `cryptroot` existente ou cabeçalho LUKS prévio.

Antes do `luksFormat`, exige o caminho completo da partição e a palavra `ERASE`. A senha é solicitada diretamente pelo `cryptsetup` com confirmação interativa.

## Verificação

O passo só passa quando:

- o container é LUKS versão 2;
- o mapper `/dev/mapper/cryptroot` existe;
- `cryptsetup status cryptroot` informa mapping ativo;
- o backing device do mapper é exatamente a partição selecionada.

## Próximo playbook

```text
05-create-btrfs.md
```
