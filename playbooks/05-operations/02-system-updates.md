---
title: Atualizações do sistema
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 01-maintenance-policy.md
---

# 02 — Atualizações do sistema

## Objetivo

Definir um procedimento reproduzível para atualizar a workstation Arch Linux sem transformar manutenção em uma sequência opaca de comandos.

## Pré-requisitos

- política de manutenção definida;
- conectividade de rede funcional;
- Pacman operacional;
- ausência de falhas críticas conhecidas que devam ser investigadas antes da atualização.

## Procedimento

1. Verificar o estado atual da workstation e registrar falhas relevantes antes da atualização.
2. Sincronizar e executar atualização completa do sistema pelo Pacman, sem atualização parcial.
3. Revisar mensagens e intervenções solicitadas pelo gerenciador de pacotes.
4. Identificar e revisar arquivos `.pacnew` e `.pacsave`.
5. Reiniciar serviços afetados quando aplicável e de forma explícita.
6. Após mudanças sensíveis, validar boot e serviços essenciais.
7. Só realizar limpeza posterior depois de confirmar que a atualização ficou saudável.

### Segurança

A automação não deve responder automaticamente prompts que exijam decisão do operador e não deve implementar atualização parcial do Arch Linux.

## Verificação

A implementação futura deverá provar que o sistema está atualizado, que intervenções pendentes foram identificadas e que os serviços essenciais permanecem saudáveis.

## Problemas comuns

### Atualização parcial

Não instalar versões isoladas de pacotes ignorando a atualização completa do sistema.

### `.pacnew` ignorado

Tratar arquivos de configuração novos como intervenção explícita; não substituí-los automaticamente sem comparação.

### Falha anterior atribuída à atualização

Executar health checks antes da manutenção para separar problemas preexistentes de regressões introduzidas pela atualização.

## Próximo playbook

`03-health-checks.md`

## Referências

- `01-maintenance-policy.md`
- `docs/standards.md`
- Arch Linux package-management policy adotada pelo projeto

## Lições aprendidas

- Atualização segura exige observar o estado antes e depois, não apenas verificar o código de saída do Pacman.
