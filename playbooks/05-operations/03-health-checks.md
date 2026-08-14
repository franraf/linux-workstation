---
title: Health checks
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 02-system-updates.md
---

# 03 — Health checks

## Objetivo

Definir verificações de saúde que indiquem problemas operacionais antes que eles se transformem em falhas de uso ou recuperação.

## Escopo

Os checks deverão observar, no mínimo:

* serviços systemd em estado de falha;
* timers essenciais;
* espaço livre e uso dos filesystems;
* estado do Btrfs;
* erros relevantes de boot e kernel;
* rede básica;
* Docker quando instalado e habilitado;
* existência e acessibilidade dos artefatos necessários à recuperação.

## Política de saída

O health check deve distinguir `PASS`, `WARN` e `FAIL`. Avisos não devem ser tratados como sucesso silencioso nem como falha fatal sem critério documentado.

## Verificação

A implementação estará pronta quando produzir um resumo determinístico e retornar código diferente de zero apenas para condições classificadas como falha.

## Próximo playbook

`04-snapshots-and-retention.md`
