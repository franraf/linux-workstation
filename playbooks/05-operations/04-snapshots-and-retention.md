---
title: Snapshots e retenção
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 03-health-checks.md
---

# 04 — Snapshots e retenção

## Objetivo

Transformar a intenção arquitetural de snapshots do subvolume raiz em uma política operacional verificável.

## Limites

Snapshots são mecanismo local de recuperação rápida do estado do sistema. Eles não substituem backup e não devem ser tratados como proteção contra perda física do disco.

## Escopo

A implementação deverá definir:

* ferramenta e configuração efetivamente utilizadas;
* criação de snapshots antes de mudanças sensíveis quando aplicável;
* retenção e limpeza controlada;
* validação do subvolume de snapshots;
* procedimento de restauração compatível com o layout Btrfs do projeto.

## Decisão pendente

Parâmetros de retenção e automação deverão ser definidos antes da implementação e podem exigir ADR caso alterem de forma relevante a estratégia de recuperação.

## Verificação

Deve ser possível listar snapshots, comprovar a política de retenção e executar um teste de recuperação não destrutivo ou controlado.

## Próximo playbook

`05-backup.md`
