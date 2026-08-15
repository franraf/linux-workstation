---
title: Atualizações do sistema
version: 0.2
status: Implemented
author: Rafael
last_review: 2026-08-14
related:
  - 01-maintenance-policy.md
---

# 02 — Atualizações do sistema

## Objetivo

Executar uma atualização completa e supervisionada da workstation Arch Linux sem transformar manutenção em uma sequência opaca de comandos.

## Pré-requisitos

- política de manutenção definida;
- health check pré-manutenção executado quando o step 03 estiver implementado;
- conectividade de rede funcional;
- Pacman operacional;
- ausência de falhas críticas conhecidas que devam ser investigadas antes da atualização.

## Procedimento

O entrypoint operacional é:

```bash
sudo profiles/dell-latitude-e5470/05-operations/02-system-updates/run.sh
```

O script:

1. valida execução como root, Arch Linux, systemd e disponibilidade do Pacman;
2. apresenta o plano antes de alterar o sistema;
3. exige a confirmação forte `UPDATE`;
4. executa `pacman -Syu`, preservando todos os prompts do Pacman para decisão do operador;
5. procura arquivos `.pacnew` e `.pacsave` em `/etc` após a atualização;
6. informa explicitamente as ações de acompanhamento necessárias.

### Segurança

A automação não responde automaticamente prompts do Pacman, não usa `--noconfirm` e não implementa atualização parcial do Arch Linux.

O script também não reinicia a máquina, não reinicia serviços indiscriminadamente, não mescla `.pacnew` e não executa limpeza automática. Essas ações exigem contexto operacional próprio.

### Cadência

A política do projeto estabelece uma janela semanal. A execução continua sendo iniciada e supervisionada pelo operador; não há timer de atualização automática.

## Verificação

A implementação é considerada funcional quando:

- `pacman -Syu` conclui sem erro;
- intervenções `.pacnew`/`.pacsave` são apresentadas ao operador;
- nenhuma decisão interativa do Pacman é respondida automaticamente;
- o health check posterior não identifica regressões impeditivas.

A última condição será integrada quando `03-health-checks` estiver implementado.

## Problemas comuns

### Atualização parcial

Não instalar versões isoladas de pacotes ignorando a atualização completa do sistema. O entrypoint deste playbook usa exclusivamente o fluxo completo `pacman -Syu`.

### `.pacnew` ignorado

Arquivos encontrados são reportados, mas nunca mesclados automaticamente. Compare cada alteração antes de substituir configuração ativa.

### Falha anterior atribuída à atualização

Executar health checks antes da manutenção para separar problemas preexistentes de regressões introduzidas pela atualização.

### Pacman solicita uma decisão

Ler o prompt e decidir explicitamente. O script deliberadamente não tenta inferir a resposta correta.

## Próximo playbook

`03-health-checks.md`

## Referências

- `01-maintenance-policy.md`
- `03-health-checks.md`
- `docs/standards.md`
- `profiles/dell-latitude-e5470/05-operations/02-system-updates/run.sh`

## Lições aprendidas

- Atualização segura exige observar o estado antes e depois, não apenas verificar o código de saída do Pacman.
- Automatizar o comando repetitivo não significa automatizar decisões do gerenciador de pacotes.
