---
title: Política de manutenção
version: 0.2
status: Implemented
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

### Cadência de manutenção

A workstation terá uma janela de manutenção **semanal**.

A janela não implica atualização automática e silenciosa. Ela define a frequência esperada para revisão operacional e atualização supervisionada do Arch Linux.

Se a janela semanal não puder ser executada, a manutenção deve ocorrer na próxima oportunidade antes de mudanças relevantes no sistema.

### Sequência da janela semanal

1. Executar health checks antes de qualquer alteração.
2. Interromper a manutenção se houver `FAIL` que possa ser agravado ou mascarado por uma atualização.
3. Executar atualização completa do Arch Linux pelo procedimento definido em `02-system-updates.md`.
4. Tratar explicitamente intervenções do gerenciador de pacotes e arquivos de configuração novos.
5. Executar novamente os health checks.
6. Investigar regressões antes de executar limpeza ou considerar a janela concluída.
7. Registrar decisões arquiteturais ou operacionais permanentes no repositório.

### Health checks adicionais

Além da janela semanal, health checks devem ser executados:

- antes e depois de mudanças sensíveis;
- após recuperação ou rollback;
- quando houver comportamento anormal da workstation;
- antes de considerar uma manutenção malsucedida como resolvida.

### Snapshots

Snapshots locais devem ser tratados como mecanismo de recuperação rápida e não como backup.

Um snapshot deve preceder mudanças classificadas como sensíveis quando a política definida em `04-snapshots-and-retention.md` indicar que o estado é recuperável por esse mecanismo.

Ferramenta e retenção permanecem responsabilidade do step 04 e não são antecipadas por esta política.

### Backup e recuperação

Backup deve existir em destino independente da workstation e ser validado por restauração, conforme `05-backup.md`.

Testes de recuperação devem ocorrer de forma controlada e não destrutiva sempre que possível. Disaster recovery completo não será simulado destrutivamente na workstation corrente.

### Operações destrutivas

Operações capazes de apagar dados, substituir estado atual, remover snapshots fora da retenção normal, alterar partições ou executar recuperação destrutiva exigem confirmação explícita do operador.

Nenhuma automação deve transformar confirmação destrutiva em resposta implícita.

### Princípios

- manutenção deve ser observável e reversível quando possível;
- atualização não deve ocultar falhas anteriores;
- Arch Linux deve ser atualizado como sistema completo, sem política de atualização parcial;
- snapshots não substituem backup;
- limpeza automática não deve apagar dados sem política explícita;
- procedimentos destrutivos exigem confirmação forte;
- o estado saudável deve ser verificável por gates objetivos;
- automação deve reduzir trabalho repetitivo sem remover decisões que exigem julgamento do operador.

## Verificação

A política está definida quando os playbooks seguintes podem derivar dela critérios objetivos sem depender de decisões implícitas.

Critérios estabelecidos neste documento:

- manutenção e atualização: semanal;
- atualização: supervisionada, não automática e silenciosa;
- health check: antes e depois da janela e de mudanças sensíveis;
- falhas relevantes devem ser investigadas antes de atualização;
- snapshots e backup possuem responsabilidades distintas;
- recuperação deve ser testável;
- operações destrutivas exigem confirmação explícita.

## Problemas comuns

### Janela semanal interpretada como atualização automática

A cadência define quando a manutenção deve ser feita. Não autoriza um timer a atualizar pacotes sem supervisão.

### Política vaga demais para ser automatizada

Substituir expressões como “periodicamente” ou “quando necessário” por critérios observáveis antes de criar timers ou scripts.

### Misturar manutenção com recuperação

Manter manutenção preventiva neste playbook e deixar restauração/rollback para os playbooks específicos de recuperação.

### Atualizar para tentar corrigir uma falha desconhecida

Registrar e investigar primeiro o estado problemático quando a atualização puder apagar evidências ou introduzir novas variáveis.

## Próximo playbook

`02-system-updates.md`

## Referências

- `docs/architecture.md`
- `docs/roadmap.md`
- `docs/standards.md`
- `02-system-updates.md`
- `03-health-checks.md`
- `04-snapshots-and-retention.md`
- `05-backup.md`
- `06-recovery.md`
- `07-disaster-recovery.md`

## Lições aprendidas

- A política deve existir antes da automação para evitar que decisões operacionais fiquem escondidas em scripts.
- Cadência de manutenção e execução automática são decisões diferentes; neste projeto a cadência é semanal e a atualização permanece supervisionada.
