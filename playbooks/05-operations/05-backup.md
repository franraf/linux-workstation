---
title: Backup
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 04-snapshots-and-retention.md
---

# 05 — Backup

## Objetivo

Definir proteção contra perda do disco ou da própria workstation, separada da política de snapshots locais.

## Escopo

A estratégia deverá declarar explicitamente:

* quais dados precisam de backup;
* quais dados podem ser reconstruídos a partir deste repositório;
* destino do backup;
* criptografia quando necessária;
* retenção;
* verificação de integridade;
* frequência;
* procedimento de restauração de amostra.

## Decisão pendente

Ferramenta, destino e política de retenção ainda não estão definidos. Essa escolha deverá ser registrada antes de qualquer automação que copie dados pessoais ou utilize armazenamento remoto.

## Segurança

Segredos, credenciais e chaves de backup não serão versionados no repositório.

## Verificação

Backup só será considerado operacional quando houver restauração testada de dados selecionados, não apenas execução bem-sucedida do comando de cópia.

## Próximo playbook

`06-recovery.md`
