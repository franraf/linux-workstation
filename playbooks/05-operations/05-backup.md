---
title: Backup
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 04-snapshots-and-retention.md
---

# 05 — Backup

## Objetivo

Definir proteção contra perda do disco ou da própria workstation, separada da política de snapshots locais.

## Pré-requisitos

- política de manutenção definida;
- dados reconstruíveis e não reconstruíveis identificados;
- política de snapshots tratada separadamente;
- nenhuma credencial ou segredo de backup armazenado no Git.

## Procedimento

1. Inventariar os dados que precisam de backup.
2. Identificar dados que podem ser reconstruídos integralmente a partir deste repositório.
3. Definir destino de backup independente da workstation.
4. Definir criptografia e gestão de credenciais quando necessárias.
5. Definir frequência e retenção.
6. Implementar verificação de integridade.
7. Executar restauração periódica de uma amostra representativa.
8. Registrar falhas de backup e restauração como condições operacionais observáveis.

### Decisão pendente

Ferramenta, destino e política de retenção ainda não estão definidos. A escolha deve ser registrada antes de qualquer automação que copie dados pessoais ou utilize armazenamento remoto.

### Segurança

Segredos, credenciais e chaves de backup não serão versionados no repositório.

## Verificação

Backup só será considerado operacional quando houver restauração testada de dados selecionados, não apenas execução bem-sucedida do comando de cópia.

## Problemas comuns

### Backup sem restauração testada

Não considerar uma cópia bem-sucedida como evidência suficiente de recuperabilidade.

### Destino no mesmo dispositivo

Não tratar cópia armazenada apenas no mesmo disco físico como proteção contra perda do equipamento.

### Segredos no repositório

Manter material de autenticação fora do Git e documentar apenas o mecanismo de obtenção/configuração.

## Próximo playbook

`06-recovery.md`

## Referências

- `01-maintenance-policy.md`
- `04-snapshots-and-retention.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- A capacidade de restaurar é o critério de sucesso do backup; a existência de arquivos copiados é apenas uma etapa intermediária.
