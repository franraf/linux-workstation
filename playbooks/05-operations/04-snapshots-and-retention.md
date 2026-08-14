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

## Pré-requisitos

- layout Btrfs do projeto validado;
- política de manutenção definida;
- distinção entre snapshot local e backup externo aceita;
- parâmetros de retenção aprovados antes de automatizar limpeza.

## Procedimento

1. Confirmar os subvolumes Btrfs relevantes e o local destinado aos snapshots.
2. Selecionar e documentar a ferramenta efetivamente utilizada.
3. Definir quando snapshots devem ser criados antes de mudanças sensíveis.
4. Definir retenção por critérios objetivos.
5. Implementar limpeza somente depois de a política de retenção estar explícita.
6. Validar listagem, criação e remoção controlada de snapshots.
7. Documentar procedimento de restauração compatível com o layout Btrfs do projeto.

### Limites

Snapshots são mecanismo local de recuperação rápida do estado do sistema. Eles não substituem backup e não protegem contra perda física do disco.

### Decisão pendente

Ferramenta, parâmetros de retenção e grau de automação devem ser definidos antes da implementação e podem exigir ADR caso alterem de forma relevante a estratégia de recuperação.

## Verificação

Deve ser possível listar snapshots, comprovar a política de retenção e executar um teste de recuperação não destrutivo ou controlado.

## Problemas comuns

### Snapshot tratado como backup

Garantir que a documentação e os scripts nunca apresentem snapshots locais como proteção contra perda do dispositivo.

### Retenção sem limite

Não habilitar criação recorrente sem uma política de expiração observável.

### Limpeza destrutiva automática

Não remover snapshots fora da política declarada nem automatizar decisões ambíguas.

## Próximo playbook

`05-backup.md`

## Referências

- `01-maintenance-policy.md`
- `03-health-checks.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- Snapshot é útil para rollback rápido, mas só é operacionalmente seguro quando criação, retenção e restauração são tratadas como um conjunto.
