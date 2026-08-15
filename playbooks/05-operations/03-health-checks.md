---
title: Health checks
version: 0.2
status: Implemented
author: Rafael
last_review: 2026-08-14
related:
  - 02-system-updates.md
---

# 03 — Health checks

## Objetivo

Executar verificações determinísticas de saúde da workstation antes e depois de manutenção ou mudanças sensíveis.

## Pré-requisitos

- política de manutenção definida;
- Arch Linux inicializado com systemd;
- execução como root para acesso consistente aos dados operacionais;
- ferramentas básicas do sistema disponíveis.

## Procedimento

O entrypoint é:

```bash
sudo profiles/dell-latitude-e5470/05-operations/03-health-checks/run.sh
```

O check atual verifica:

1. unidades systemd em estado `failed`;
2. utilização do filesystem raiz;
3. tipo do filesystem raiz e contadores de erro do Btrfs;
4. existência de rota de rede padrão;
5. estado do `docker.service` quando Docker está instalado;
6. consistência da base local do Pacman;
7. mensagens de prioridade `err` no journal do boot atual.

### Política de saída

- `PASS`: condição esperada confirmada;
- `WARN`: condição que merece investigação, mas não invalida automaticamente a operação;
- `FAIL`: condição operacional impeditiva.

O script retorna código diferente de zero somente quando há pelo menos um `FAIL`.

### Critérios iniciais

Para uso do filesystem raiz:

- abaixo de 85%: `PASS`;
- de 85% a 94%: `WARN`;
- 95% ou mais: `FAIL`.

Entradas `err` do journal são `WARN`, porque a presença isolada de mensagens dessa prioridade não prova uma falha operacional atual. O operador recebe o comando de revisão correspondente.

Contadores Btrfs diferentes de zero são inicialmente `WARN`; a interpretação depende do histórico e do dispositivo afetado.

Docker ausente ou instalado mas inativo é `WARN`, não `FAIL`, porque o health check não deve tornar um componente de desenvolvimento opcional requisito de boot da workstation.

## Verificação

A implementação está pronta quando produz um resumo determinístico de `Passed`, `Warnings` e `Failed`, e retorna código diferente de zero somente diante de falhas classificadas como impeditivas.

O health check deve ser executado antes e depois de `02-system-updates` durante a janela semanal.

## Problemas comuns

### Logs ruidosos gerando falsos positivos

Mensagens `err` do boot são reportadas como aviso e precisam de revisão contextual; não são convertidas automaticamente em falha.

### Serviço opcional tratado como obrigatório

Docker é observado, mas sua ausência ou inatividade não bloqueia a saúde geral da workstation.

### Btrfs apresenta contador histórico

Um contador não zero permanece visível como `WARN`. Investigue antes de zerar estatísticas; não apague evidência automaticamente.

### Filesystem próximo da capacidade

Uso acima de 85% exige atenção e acima de 95% bloqueia o gate até que haja espaço operacional adequado.

## Próximo playbook

`04-snapshots-and-retention.md`

## Referências

- `01-maintenance-policy.md`
- `02-system-updates.md`
- `docs/standards.md`
- `profiles/dell-latitude-e5470/05-operations/03-health-checks/run.sh`

## Lições aprendidas

- Health checks úteis precisam de critérios de severidade explícitos; quantidade de checks não substitui qualidade do sinal.
- Sinais históricos ou contextuais devem permanecer visíveis sem serem promovidos artificialmente a falha fatal.
