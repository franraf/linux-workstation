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

## Pré-requisitos

- fases `01-installation` a `04-development` validadas;
- arquitetura, roadmap e padrões do repositório disponíveis;
- nenhuma política operacional conflitante já aprovada.

## Procedimento

1. Definir cadência e critérios objetivos para atualização do sistema.
2. Definir quando serviços falhos, logs, espaço em disco e estado do Btrfs devem ser revisados.
3. Separar claramente snapshots locais de backup externo.
4. Definir quando testes de recuperação devem ser executados.
5. Classificar operações destrutivas e exigir confirmação forte para elas.
6. Registrar decisões que alterem arquitetura ou estratégia de recuperação em ADR antes da automação correspondente.

### Princípios

- manutenção deve ser observável e reversível quando possível;
- atualização não deve ocultar falhas anteriores;
- snapshots não substituem backup;
- limpeza automática não deve apagar dados sem política explícita;
- procedimentos destrutivos exigem confirmação forte;
- o estado saudável deve ser verificável por gates objetivos.

## Verificação

Este playbook estará concluído quando a política tiver parâmetros objetivos suficientes para os playbooks seguintes, sem depender de decisões implícitas.

## Problemas comuns

### Política vaga demais para ser automatizada

Substituir expressões como “periodicamente” ou “quando necessário” por critérios observáveis antes de criar timers ou scripts.

### Misturar manutenção com recuperação

Manter manutenção preventiva neste playbook e deixar restauração/rollback para os playbooks específicos de recuperação.

## Próximo playbook

`02-system-updates.md`

## Referências

- `docs/architecture.md`
- `docs/roadmap.md`
- `docs/standards.md`

## Lições aprendidas

- A política deve existir antes da automação para evitar que decisões operacionais fiquem escondidas em scripts.
