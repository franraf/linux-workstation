---
title: Recuperação
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 05-backup.md
---

# 06 — Recuperação

## Objetivo

Definir procedimentos reproduzíveis para recuperar a workstation de falhas que não exigem reconstrução completa do equipamento.

## Pré-requisitos

- fontes canônicas de configuração disponíveis no repositório;
- snapshots e/ou backups aplicáveis ao cenário disponíveis e verificáveis;
- impacto da restauração conhecido antes de substituir estado atual.

## Procedimento

1. Classificar o incidente e identificar a menor recuperação suficiente.
2. Preservar evidências e estado atual quando isso ajudar no diagnóstico.
3. Recuperar configuração a partir do repositório quando aplicável.
4. Restaurar arquivos de usuário a partir do backup quando necessário.
5. Usar rollback/restauração Btrfs apenas quando compatível com o cenário.
6. Recuperar boot ou configurações de serviços conforme a falha identificada.
7. Executar validação pós-recuperação antes de considerar o incidente encerrado.

### Segurança

Qualquer procedimento que substitua estado atual por estado anterior deve mostrar o impacto e exigir confirmação explícita antes da alteração.

## Verificação

A recuperação só será considerada validada após um ensaio controlado que demonstre restauração de pelo menos um cenário representativo sem depender de conhecimento não documentado.

## Problemas comuns

### Restaurar mais estado do que o necessário

Preferir a menor intervenção capaz de recuperar a função afetada.

### Perder evidências do problema

Quando relevante, registrar logs e estado antes de rollback ou substituição de configuração.

### Recuperação sem gate final

Sempre executar checks pós-recuperação para confirmar que o sistema voltou a um estado operacional conhecido.

## Próximo playbook

`07-disaster-recovery.md`

## Referências

- `04-snapshots-and-retention.md`
- `05-backup.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- Recuperação reproduzível depende de saber qual fonte é autoritativa para cada tipo de estado: Git, snapshot ou backup.
