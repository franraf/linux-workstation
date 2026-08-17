---
title: Backup
version: 0.2
status: Draft
author: Rafael
last_review: 2026-08-17
related:
  - 04-snapshots-and-retention.md
---

# 05 — Backup

## Objetivo

Definir proteção contra perda do disco ou da própria workstation, separada da política de snapshots locais.

Nesta geração, a capacidade é preparada antes da disponibilidade do dispositivo externo e somente será considerada operacional após backup e restauração reais serem validados.

## Pré-requisitos

- política de manutenção definida;
- dados reconstruíveis e não reconstruíveis identificados;
- política de snapshots tratada separadamente;
- nenhuma credencial ou segredo de backup armazenado no Git;
- HD ou SSD USB dedicado disponível para a validação operacional final.

## Política aprovada

| Item | Decisão |
| --- | --- |
| ferramenta | Restic |
| destino | HD/SSD USB dedicado e removível |
| armazenamento remoto | fora do escopo desta geração |
| criptografia | criptografia nativa do repositório Restic |
| segredo | nunca versionado e não armazenado junto ao repositório de backup |
| frequência | semanal, quando o dispositivo estiver conectado |
| retenção | 4 snapshots semanais e 6 mensais |
| integridade | `restic check` |
| restore | restauração periódica de amostra para diretório temporário |

## Escopo

O backup protege dados pessoais não reconstruíveis do `/home`.

Dados integralmente reconstruíveis a partir do `linux-workstation`, caches, artefatos temporários e runtimes reconstruíveis devem ser excluídos quando isso puder ser feito de forma explícita e verificável.

A lista final de inclusões e exclusões será validada contra o conteúdo real do `/home` antes do primeiro backup. O repositório não deve presumir silenciosamente quais diretórios pessoais podem ser descartados.

## Procedimento

### Preparação — sem hardware externo

1. Registrar ferramenta, destino, criptografia, frequência e retenção.
2. Manter backup remoto automatizado fora do escopo da geração atual.
3. Não armazenar senha, token ou chave de backup no Git.
4. Não declarar a capacidade validada enquanto o dispositivo externo não existir.
5. Adiar a lista final de inclusões/exclusões até que possa ser revisada contra o `/home` real.

### Ativação — quando o dispositivo estiver disponível

1. Identificar explicitamente o dispositivo dedicado e confirmar que não contém dados a preservar.
2. Definir filesystem, label e ponto de montagem de forma documentada antes de qualquer formatação.
3. Inicializar o repositório Restic no dispositivo externo.
4. Configurar o mecanismo local de fornecimento da senha fora do Git e fora do próprio repositório de backup.
5. Revisar o inventário do `/home` e aprovar inclusões e exclusões.
6. Executar o primeiro backup supervisionado.
7. Executar `restic check`.
8. Aplicar a política de retenção somente depois de confirmar que os snapshots esperados são reconhecidos corretamente.
9. Restaurar uma amostra representativa para diretório temporário.
10. Comparar o conteúdo restaurado com a origem.
11. Somente então considerar o backup operacionalmente validado.

## Retenção

A política inicial mantém:

- 4 snapshots semanais;
- 6 snapshots mensais.

A retenção deve ser aplicada pelas capacidades nativas do Restic e sempre acompanhada de inspeção do plano/resultados durante a validação inicial.

A política poderá ser revisada quando houver dados reais de volume, duração e capacidade do dispositivo.

## Segurança

Segredos, credenciais e chaves de backup não serão versionados no repositório.

A senha do Restic também não deve ser armazenada no mesmo dispositivo que contém o repositório de backup, pois a perda conjunta eliminaria a separação esperada entre dados criptografados e material de acesso.

O dispositivo de backup deve permanecer removível e pode ser desconectado fora da janela de manutenção.

## Estado atual

**Prepared / hardware pending.**

A política está definida, mas não existe atualmente um HD/SSD externo dedicado disponível para inicialização, backup real e teste de restore.

Este estado não equivale a `Stable`, `validated` ou backup operacional.

## Verificação

Backup só será considerado operacional quando todas as condições abaixo forem atendidas:

1. repositório Restic inicializado em dispositivo externo dedicado;
2. primeiro backup concluído;
3. `restic check` concluído sem falhas;
4. retenção inspecionada;
5. restauração de amostra concluída e comparada com a origem.

## Problemas comuns

### Backup sem restauração testada

Não considerar uma cópia bem-sucedida como evidência suficiente de recuperabilidade.

### Destino no mesmo dispositivo

Não tratar cópia armazenada apenas no mesmo disco físico como proteção contra perda do equipamento.

### Segredos no repositório

Manter material de autenticação fora do Git e documentar apenas o mecanismo de obtenção/configuração.

### Exclusões excessivas

Não assumir que diretórios pessoais são reconstruíveis apenas pelo nome. Revisar o conteúdo real antes de aprovar exclusões.

### Hardware ainda indisponível

Manter o step preparado e pendente; não simular validação usando armazenamento no mesmo SSD da workstation.

## Próximo playbook

`06-recovery.md`

## Referências

- `01-maintenance-policy.md`
- `04-snapshots-and-retention.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- A capacidade de restaurar é o critério de sucesso do backup; a existência de arquivos copiados é apenas uma etapa intermediária.
- Ausência temporária do hardware de destino não deve levar a uma falsa validação nem obrigar o projeto a usar um destino inadequado.
- Escopo e exclusões de dados pessoais devem ser aprovados a partir do estado real do `/home`, não inferidos genericamente pelo repositório.
