---
title: Recuperação
version: 0.2
status: Stable
author: Rafael
last_review: 2026-08-17
related:
  - 04-snapshots-and-retention.md
  - 05-backup.md
---

# 06 — Recuperação

## Objetivo

Definir procedimentos reproduzíveis para recuperar a workstation de falhas que não exigem reconstrução completa do equipamento.

A recuperação deve usar a menor intervenção suficiente e a fonte autoritativa adequada ao tipo de estado afetado.

## Fontes autoritativas

| Estado afetado | Fonte preferencial |
| --- | --- |
| configuração gerenciada pela workstation | Git / fonte canônica do repositório |
| estado anterior do filesystem raiz | snapshot Btrfs/Snapper |
| dados pessoais não reconstruíveis | backup externo, quando operacional |
| reconstrução completa do equipamento | procedimento de disaster recovery |

Não usar snapshot para substituir configuração que pode ser reconstruída diretamente da fonte canônica sem necessidade de rollback de estado adicional.

## Pré-requisitos

- fontes canônicas de configuração disponíveis no repositório;
- snapshots e/ou backups aplicáveis ao cenário disponíveis e verificáveis;
- impacto da restauração conhecido antes de substituir estado atual;
- evidências relevantes preservadas antes de alterações destrutivas.

## Procedimento geral

1. Classificar o incidente.
2. Identificar a menor recuperação suficiente.
3. Preservar logs, evidências e estado atual quando úteis ao diagnóstico.
4. Identificar a fonte autoritativa para o estado afetado.
5. Inspecionar o conteúdo a ser restaurado antes de substituir o estado atual quando possível.
6. Mostrar o impacto de qualquer substituição destrutiva e exigir confirmação explícita.
7. Executar a recuperação mínima necessária.
8. Executar validação pós-recuperação.
9. Somente então considerar o incidente encerrado.

## Cenário A — Recuperação granular por snapshot

Usar quando um arquivo ou pequeno conjunto de arquivos do filesystem raiz precisa voltar a um estado conhecido preservado em snapshot e não é simplesmente reconstruível pelo Git.

### Procedimento

1. Identificar um snapshot adequado com `snapper -c root list`.
2. Confirmar que o objeto esperado existe em `/.snapshots/<N>/snapshot/...`.
3. Inspecionar o conteúdo antes da restauração quando aplicável.
4. Restaurar somente o objeto necessário, preservando metadados, por exemplo com `cp -a`.
5. Comparar conteúdo, proprietário, grupo e permissões relevantes.
6. Executar os health checks relacionados ao componente afetado.

### Validação realizada

Em 2026-08-17 foi executado um ensaio controlado:

1. `/etc/linux-workstation-recovery-test` foi criado com conteúdo conhecido;
2. um snapshot manual foi criado;
3. o arquivo atual foi removido para simular perda;
4. somente o arquivo foi copiado de volta do snapshot com preservação de metadados;
5. o conteúdo restaurado foi comparado com o valor esperado;
6. o teste concluiu com `Granular snapshot recovery succeeded`.

O ensaio não executou rollback do subvolume raiz.

## Cenário B — Recuperação de configuração pela fonte canônica

Usar quando uma configuração gerenciada pela workstation sofreu drift local e sua fonte autoritativa existe no Git.

### Procedimento

1. Comparar o arquivo instalado com sua fonte canônica.
2. Confirmar que existe divergência real.
3. Preservar a versão divergente se ela for útil para diagnóstico.
4. Restaurar o arquivo a partir da fonte canônica do repositório.
5. Comparar novamente os arquivos.
6. Executar a validação específica do componente restaurado.

### Validação realizada

Em 2026-08-17 foi executado um ensaio controlado com a configuração do Starship:

1. a configuração instalada foi confirmada como idêntica à fonte canônica;
2. foi introduzido drift somente em `~/.config/starship/starship.toml`;
3. a divergência foi detectada;
4. a configuração foi restaurada a partir de `system/development/starship/starship.toml`;
5. a igualdade foi confirmada novamente;
6. o teste concluiu com `Git-backed configuration recovery succeeded`.

## Backup

A recuperação de dados pessoais por backup permanece pendente enquanto o step `05-backup.md` estiver em estado `Prepared / hardware pending`.

A ausência dessa validação não deve ser mascarada por snapshots locais: snapshot e backup protegem contra classes de falha diferentes.

## Segurança

Qualquer procedimento que substitua estado atual por estado anterior deve mostrar o impacto e exigir confirmação explícita antes da alteração.

Rollback completo do filesystem raiz não é a primeira opção quando uma restauração granular resolve o incidente.

## Verificação

A recuperação local desta geração possui dois cenários representativos validados:

- restauração granular a partir de snapshot;
- restauração de configuração a partir da fonte canônica Git.

Para cada incidente real, a recuperação ainda exige o gate específico do componente e os health checks aplicáveis antes do encerramento.

A recuperação de backup será validada separadamente quando houver hardware externo disponível.

## Problemas comuns

### Restaurar mais estado do que o necessário

Preferir a menor intervenção capaz de recuperar a função afetada.

### Escolher a fonte errada

Configuração gerenciada deve preferir a fonte canônica. Estado histórico do filesystem pode exigir snapshot. Dados pessoais perdidos por falha física exigem backup externo.

### Perder evidências do problema

Quando relevante, registrar logs e estado antes de rollback ou substituição de configuração.

### Recuperação sem gate final

Sempre executar checks pós-recuperação para confirmar que o sistema voltou a um estado operacional conhecido.

### Confundir snapshot com backup

Snapshots no mesmo dispositivo não protegem contra perda física do SSD e não substituem o backup externo planejado.

## Próximo playbook

`07-disaster-recovery.md`

## Referências

- `04-snapshots-and-retention.md`
- `05-backup.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- Recuperação reproduzível depende de saber qual fonte é autoritativa para cada tipo de estado: Git, snapshot ou backup.
- Recuperação granular reduz o blast radius quando somente um objeto precisa ser restaurado.
- Um ensaio controlado deve demonstrar tanto a seleção da fonte correta quanto uma validação pós-recuperação objetiva.
