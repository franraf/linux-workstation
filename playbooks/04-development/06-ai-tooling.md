---
title: Ferramentas de inteligência artificial
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0005
* ADR-0007

---

# 06 — Ferramentas de inteligência artificial

## Objetivo

Adicionar uma única ferramenta global de assistência por IA ao ambiente de desenvolvimento, evitando implementações redundantes e mantendo segredos fora do repositório.

A implementação adotada pela workstation é o **Codex CLI**.

## Fonte declarativa

```text
packages/development/ai-tooling.txt
```

O pacote utilizado é:

```text
openai-codex
```

Ele é fornecido pelos repositórios oficiais do Arch Linux, portanto esta capacidade não requer AUR, npm global ou runtime Node.js obrigatório no host.

## Configuração versionada

A política não sensível fica em:

```text
dotfiles/ai/README.md
```

Instruções específicas de projetos devem permanecer nos respectivos repositórios.

## Autenticação

A automação não grava tokens, chaves de API nem credenciais.

Depois da instalação, autentique-se na sessão normal do usuário:

```bash
codex --login
```

O fluxo de autenticação é interativo e não deve ser executado nem armazenado pelo script root da workstation.

## Procedimento

Execute:

```bash
sudo ./06-ai-tooling/run.sh
```

O script:

1. valida o sistema e o usuário de destino;
2. instala `openai-codex` quando ausente;
3. instala uma cópia da documentação da política em `~/.config/linux-workstation/ai/README.md`;
4. valida o executável `codex` e sua versão;
5. orienta a autenticação interativa posterior.

## Princípios de uso

* revisar diffs antes de aceitar alterações;
* exigir autorização explícita para ações destrutivas;
* não expor chaves SSH ou segredos não relacionados à tarefa;
* executar testes após modificações;
* limitar o escopo ao menor conjunto de arquivos e repositórios necessário;
* manter instruções específicas junto ao projeto correspondente.

## Verificação

Confirme que:

* `codex --version` funciona;
* a autenticação pode ser concluída interativamente;
* nenhum segredo foi adicionado ao repositório;
* a ferramenta funciona dentro de um repositório de teste;
* mudanças geradas podem ser revisadas antes da aplicação.

A autenticação e uma tarefa real de teste são verificações manuais do gate final.

## Próximo playbook

```text
07-development-validation.md
```

## Referências

* OpenAI Codex documentation
* Arch Linux — openai-codex
* ADR-0005 — Modularize Configuration by Capability
* ADR-0007 — Declarative Package Lists
