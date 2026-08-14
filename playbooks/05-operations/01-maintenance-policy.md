---
title: Política de manutenção
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - architecture.md
  - roadmap.md
---

# 01 — Política de manutenção

## Objetivo

Definir a rotina mínima de manutenção da workstation antes de automatizar atualizações, limpeza ou reparos.

## Princípios

* manutenção deve ser observável e reversível quando possível;
* atualização não deve ocultar falhas anteriores;
* snapshots não substituem backup;
* limpeza automática não deve apagar dados sem política explícita;
* procedimentos destrutivos exigem confirmação forte;
* o estado saudável deve ser verificável por gates objetivos.

## Escopo inicial

A política deverá definir cadência e critérios para:

* atualização do sistema;
* revisão de serviços falhos;
* análise de espaço em disco e Btrfs;
* revisão de logs relevantes;
* snapshots e retenção;
* backup;
* testes periódicos de recuperação.

## Verificação

Este playbook estará concluído quando a política tiver parâmetros objetivos suficientes para os playbooks seguintes, sem depender de decisões implícitas.

## Próximo playbook

`02-system-updates.md`
