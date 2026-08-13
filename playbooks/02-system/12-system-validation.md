---
title: Validar o sistema
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0009

---

# 12 — Validar o sistema

## Objetivo

Validar que a fase `02-system` foi aplicada corretamente e que a workstation está pronta para `03-desktop`.

Este playbook é um gate: validação não deve alterar o sistema para fazê-lo passar.

## Pré-requisitos

* Etapas `01–11` concluídas.
* Sistema inicializado normalmente com systemd.
* Usuário administrativo disponível.

## 1. Validar as fontes versionadas

Na raiz do repositório execute:

```bash
bash tests/system/static-artifacts.sh
```

Esse teste valida sintaxe dos `run.sh`, bibliotecas compartilhadas, manifesto da fase e presença das fontes canônicas em `packages/` e `system/`.

Falhas estáticas devem ser corrigidas no repositório antes de investigar o estado da máquina.

## 2. Executar a validação de runtime

```bash
./profiles/dell-latitude-e5470/02-system/12-system-validation/run.sh
```

O gate de runtime deve permanecer somente leitura e verificar, entre outros pontos:

* Pacman e pacotes esperados;
* microcode Intel;
* systemd e sincronização de horário;
* journal persistente;
* ZRAM;
* TRIM periódico;
* NetworkManager e Bluetooth;
* OpenSSH;
* Btrfs, ESP e systemd-boot;
* unidades systemd em estado de falha.

## Fontes canônicas relevantes

```text
packages/system/base-workstation.txt
packages/system/services.txt
system/systemd/10-linux-workstation.conf
system/systemd/timesyncd/10-linux-workstation.conf
system/systemd/journald/10-linux-workstation.conf
system/systemd/zram/10-linux-workstation.conf
system/openssh/10-linux-workstation.conf
system/storage/btrfs-layout.tsv
```

A validação não deve manter cópias independentes dessas políticas.

## Resultado esperado

* teste estático aprovado;
* nenhuma falha crítica no gate de runtime;
* warnings aceitos analisados explicitamente;
* workstation pronta para iniciar `03-desktop`.

## Problemas comuns

### Fonte versionada ausente ou divergente

Corrija `packages/`, `system/` ou as bibliotecas; não faça patches locais apenas para satisfazer o gate.

### Serviço em falha

Retorne ao playbook responsável e corrija a origem da configuração.

### Estado de hardware variável

Bluetooth e sincronização imediata de horário podem produzir warnings dependentes do ambiente; valide o contexto antes de tratá-los como falha de configuração.

## Próximo playbook

```text
03-desktop/
01-install-graphics-stack.md
```

## Referências

* architecture.md
* ADR-0009 — Fontes compartilhadas para profiles
* Arch Wiki — General recommendations
