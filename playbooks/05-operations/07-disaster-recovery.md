---
title: Disaster recovery
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 06-recovery.md
---

# 07 — Disaster recovery

## Objetivo

Definir como reconstruir a workstation após perda total do sistema ou do disco, usando o repositório e backups disponíveis como fontes de recuperação.

## Escopo

O plano deverá identificar:

* dependências mínimas fora da máquina;
* como obter o repositório em um ambiente novo;
* como recuperar credenciais sem armazená-las no Git;
* ordem de reconstrução das fases da workstation;
* restauração de dados não reconstruíveis;
* validação final do sistema recuperado.

## Limite de validação

O projeto não realizará uma reinstalação destrutiva artificial na workstation atual. O procedimento deverá ser testado em ambiente apropriado ou durante uma reconstrução real futura, registrando qualquer lacuna encontrada.

## Verificação

O documento deverá ser suficiente para que a reconstrução possa ser conduzida sem depender da memória do operador sobre caminhos internos dos scripts.

## Próximo playbook

`08-operations-validation.md`
