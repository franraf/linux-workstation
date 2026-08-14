---
title: Validação operacional
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 01-maintenance-policy.md
  - 02-system-updates.md
  - 03-health-checks.md
  - 04-snapshots-and-retention.md
  - 05-backup.md
  - 06-recovery.md
  - 07-disaster-recovery.md
---

# 08 — Validação operacional

## Objetivo

Consolidar o gate final da fase Operations e impedir avanço para Security enquanto manutenção e recuperação não forem verificáveis.

## Pré-requisitos

- playbooks `01` a `07` implementados no nível exigido pela fase;
- checks automatizados executáveis quando aplicáveis;
- verificações manuais indispensáveis documentadas e concluídas;
- nenhuma falha operacional conhecida ignorada pelo gate.

## Procedimento

1. Validar que a política de manutenção possui critérios objetivos.
2. Validar o procedimento reproduzível de atualização do sistema.
3. Executar os health checks e consolidar `PASS`, `WARN` e `FAIL`.
4. Validar observabilidade da política de snapshots e retenção.
5. Confirmar backup por meio de restauração de amostra.
6. Confirmar pelo menos um cenário controlado de recuperação.
7. Verificar que disaster recovery identifica dependências externas e caminho de reconstrução.
8. Emitir resumo final e bloquear avanço enquanto houver `FAIL` ou verificação obrigatória pendente.

### Política de resultado

- `PASS`: requisito comprovado;
- `WARN`: condição conhecida que não invalida o gate, com justificativa explícita;
- `FAIL`: requisito não atendido ou condição que impede considerar Operations validada.

A fase só poderá ser marcada como validada quando não houver falhas e os checks manuais indispensáveis tiverem sido concluídos.

## Verificação

O gate estará correto quando produzir resultado determinístico, retornar código diferente de zero diante de qualquer `FAIL` e impedir avanço para Security enquanto a fase não estiver validada.

## Problemas comuns

### Gate que apenas verifica presença de arquivos

Validar comportamento e estado operacional sempre que possível, não apenas existência de scripts ou documentos.

### `WARN` usado para esconder requisito incompleto

Não rebaixar para aviso uma condição que o próprio contrato da fase define como obrigatória.

### Validação manual sem evidência

Documentar o que foi verificado e o critério usado antes de marcar a fase como validada.

## Próximo playbook

Não há outro playbook nesta fase. Após validação completa, a próxima fase declarada é `06-security`.

## Referências

- `01-maintenance-policy.md`
- `02-system-updates.md`
- `03-health-checks.md`
- `04-snapshots-and-retention.md`
- `05-backup.md`
- `06-recovery.md`
- `07-disaster-recovery.md`
- `docs/standards.md`

## Lições aprendidas

- O gate final deve provar capacidade operacional; presença de implementação sem evidência de funcionamento não encerra a fase.
