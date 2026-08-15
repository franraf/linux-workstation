---
title: Snapshots e retenção
version: 1.0
status: Implemented
author: Rafael
last_review: 2026-08-15
related:
  - 01-maintenance-policy.md
  - 02-system-updates.md
  - 03-health-checks.md
---

# 04 — Snapshots e retenção

## Objetivo

Fornecer rollback local rápido do estado do sistema por snapshots Btrfs, com política explícita de criação e retenção, sem tratar snapshots como backup.

## Pré-requisitos

- layout Btrfs do projeto validado;
- subvolume `@snapshots` previsto em `/.snapshots`;
- política de manutenção semanal definida;
- distinção entre snapshot local e backup externo aceita;
- health checks operacionais disponíveis.

## Procedimento

1. Utilizar Snapper como ferramenta de gerenciamento dos snapshots Btrfs do sistema.
2. Manter uma configuração Snapper denominada `root` para o subvolume raiz.
3. Manter snapshots de timeline desabilitados; esta workstation não cria snapshots horários.
4. Criar um par `pre`/`post` ao redor de cada manutenção semanal que execute atualização completa do sistema.
5. Criar snapshots manuais antes de mudanças sensíveis que não façam parte do ciclo normal de atualização.
6. Manter até 10 pares de manutenção (`pre`/`post`).
7. Manter até 5 snapshots manuais protegidos pela política operacional.
8. Não habilitar limpeza destrutiva enquanto a classificação/tagging dos snapshots de manutenção e manuais não estiver implementada e validada.
9. Validar listagem, criação e remoção controlada antes de considerar a política completa.
10. Tratar restauração no playbook de recovery, separadamente da criação e retenção.

### Escopo do snapshot

O snapshot protege o subvolume raiz `@`. Conforme o layout arquitetural da workstation, dados pessoais, Docker, logs e caches vivem em subvolumes separados e não fazem parte do snapshot do sistema.

### Política aprovada

| Classe | Criação | Retenção |
| --- | --- | --- |
| manutenção | par `pre`/`post` em torno de `pacman -Syu` | 10 pares |
| manual | antes de mudança sensível, quando solicitado | 5 snapshots |
| timeline | desabilitada | nenhuma |

A retenção é baseada em quantidade, não em idade. Não há remoção automática ambígua nem limpeza por calendário nesta geração.

### Segurança

Snapshots são mecanismo local de recuperação rápida. Eles não substituem backup e não protegem contra falha, perda, roubo ou destruição física do SSD.

A remoção de snapshots é destrutiva e deve obedecer à classificação e aos limites acima. Enquanto a classificação automática não estiver validada, a limpeza permanece explícita e supervisionada.

## Verificação

Após a configuração inicial:

```bash
snapper -c root list
```

Deve existir uma configuração `root`, snapshots de timeline devem permanecer desabilitados e a listagem deve funcionar sem erro.

A integração com o updater somente será considerada validada depois de um ciclo controlado produzir um par `pre`/`post` e o health check posterior permanecer saudável.

## Problemas comuns

### `/.snapshots` já existe antes de `snapper create-config`

O layout do projeto já prevê `@snapshots` montado nesse caminho. O script deve recusar alterações automáticas quando encontrar esse estado sem uma configuração Snapper existente, para evitar substituir ou recriar inadvertidamente o subvolume canônico.

Inspecionar o mount e adaptar a configuração de forma controlada antes de prosseguir.

### Snapshot tratado como backup

Garantir que documentação e scripts nunca apresentem snapshots locais como proteção contra perda do dispositivo.

### Retenção sem limite

Não habilitar criação recorrente sem classificação e política de expiração observáveis.

### Limpeza destrutiva automática

Não remover snapshots fora da política declarada nem automatizar decisões ambíguas.

## Próximo playbook

`05-backup.md`

## Referências

- `01-maintenance-policy.md`
- `02-system-updates.md`
- `03-health-checks.md`
- `docs/architecture.md`
- `docs/standards.md`
- `packages/operations/snapshots.txt`

## Lições aprendidas

- Snapshot é útil para rollback rápido, mas criação, classificação, retenção e restauração precisam ser tratadas como responsabilidades explícitas.
- A existência prévia de `@snapshots` exige que a configuração do Snapper preserve o layout Btrfs canônico em vez de assumir uma instalação genérica.
- A política deve existir antes da limpeza automática; retenção destrutiva não deve ser inferida pelo script.
