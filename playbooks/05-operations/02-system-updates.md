---
title: Atualizações do sistema
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 01-maintenance-policy.md
---

# 02 — Atualizações do sistema

## Objetivo

Definir um procedimento reproduzível para atualizar a workstation Arch Linux sem transformar manutenção em uma sequência opaca de comandos.

## Escopo

O procedimento deverá cobrir:

* sincronização e atualização completa pelo Pacman;
* tratamento de mensagens relevantes do gerenciador de pacotes;
* detecção de serviços que precisam ser reiniciados quando aplicável;
* revisão de arquivos `.pacnew` e `.pacsave`;
* validação do boot e dos serviços essenciais após mudanças sensíveis;
* registro de falhas antes de qualquer limpeza posterior.

## Segurança

Não será implementada atualização parcial do Arch Linux. A automação não deverá responder automaticamente prompts que exijam decisão do operador.

## Verificação

A implementação futura deverá provar que o sistema está atualizado e que os serviços essenciais permanecem saudáveis.

## Próximo playbook

`03-health-checks.md`
