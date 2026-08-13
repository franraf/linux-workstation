---
title: Particionar disco
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 02-configure-firmware.md
  - 04-create-luks.md
---

# 03 — Particionar disco

## Objetivo

Preparar o disco de destino com GPT e exatamente duas partições:

```text
1  EFI System Partition   1 GiB
2  Linux LUKS             espaço restante
```

Este é um passo **destrutivo**.

## Execução

No ambiente live inicializado em UEFI:

```bash
sudo profiles/dell-latitude-e5470/01-installation/03-partition-disk/run.sh \
  --disk /dev/<disco>
```

O script recusa partições, discos read-only, discos menores que 8 GiB, dispositivos montados, swap ativo e o disco que contém o root do sistema em execução.

Antes de modificar o disco, ele exibe identificação e tamanho do alvo e exige duas confirmações: o caminho completo do disco e a palavra `ERASE`.

## Política de particionamento

A tabela é GPT. A primeira partição recebe o GUID de EFI System Partition; a segunda recebe o GUID Linux LUKS. O script remove assinaturas antigas antes de criar a nova tabela.

## Verificação

O passo só passa quando:

- o disco possui GPT;
- existem exatamente duas partições;
- existe exatamente uma ESP;
- existe exatamente uma partição Linux LUKS.

A formatação das partições fica fora deste passo.

## Próximo playbook

```text
04-create-luks.md
```
