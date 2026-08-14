---
title: Health checks
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 02-system-updates.md
---

# 03 — Health checks

## Objetivo

Definir verificações de saúde que indiquem problemas operacionais antes que eles se transformem em falhas de uso ou recuperação.

## Pré-requisitos

- política de manutenção definida;
- serviços essenciais da workstation conhecidos;
- critérios de `PASS`, `WARN` e `FAIL` documentados antes de automatizar cada check.

## Procedimento

1. Verificar serviços systemd em estado de falha.
2. Verificar timers essenciais definidos pelo projeto.
3. Medir espaço livre e uso dos filesystems.
4. Verificar o estado observável do Btrfs.
5. Revisar erros relevantes de boot e kernel segundo critérios documentados.
6. Verificar conectividade de rede básica.
7. Verificar Docker quando instalado e habilitado.
8. Verificar existência e acessibilidade dos artefatos necessários à recuperação.
9. Consolidar o resultado em resumo determinístico.

### Política de saída

- `PASS`: condição esperada confirmada;
- `WARN`: condição que merece atenção, mas não invalida imediatamente a operação;
- `FAIL`: condição que torna o estado operacional inadequado ou impede uma ação dependente.

Avisos não devem ser tratados como sucesso silencioso nem como falha fatal sem critério documentado.

## Verificação

A implementação estará pronta quando produzir um resumo determinístico e retornar código diferente de zero apenas para condições classificadas como falha.

## Problemas comuns

### Logs ruidosos gerando falsos positivos

Não transformar qualquer mensagem histórica em falha atual; definir janela e severidade relevantes.

### Serviço opcional tratado como obrigatório

Distinguir serviços essenciais de componentes opcionais ou desabilitados intencionalmente.

### `WARN` sem ação possível

Todo aviso recorrente deve ter significado operacional documentado ou ser removido do gate.

## Próximo playbook

`04-snapshots-and-retention.md`

## Referências

- `01-maintenance-policy.md`
- `02-system-updates.md`
- `docs/standards.md`

## Lições aprendidas

- Health checks úteis precisam de critérios de severidade explícitos; quantidade de checks não substitui qualidade do sinal.
