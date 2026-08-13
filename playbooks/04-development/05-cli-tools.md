---
title: Ferramentas de linha de comando
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0005
* ADR-0007

---

# 05 — Ferramentas de linha de comando

## Objetivo

Instalar o conjunto global de ferramentas de produtividade usado pela workstation sem introduzir runtimes ou SDKs específicos de projetos.

## Fonte declarativa

A fonte canônica é:

```text
packages/development/cli-tools.txt
```

Ferramentas já pertencentes à baseline de `02-system`, como `curl`, `wget`, `tree`, `zip` e `unzip`, não são repetidas nesta capacidade.

## Conjunto adotado

### Navegação e pesquisa

* `eza`
* `fd`
* `ripgrep`
* `fzf`

### Visualização e dados estruturados

* `bat`
* `jq`
* `yq`

### HTTP e produtividade de terminal

* `httpie`
* `tmux`
* `just`
* `make`

### Git

* `lazygit`
* `git-delta`

## Procedimento

Execute:

```bash
sudo ./05-cli-tools/run.sh
```

O script instala apenas pacotes ausentes, valida todos os pacotes declarados e confirma a presença dos executáveis correspondentes.

Quando não há nada a instalar, a etapa segue diretamente para validação sem exigir confirmação artificial.

## Limites da capacidade

Este playbook não instala:

* Node.js;
* .NET;
* Terraform;
* Kubernetes tooling;
* AWS CLI;
* runtimes Python específicos;
* SDKs de projetos.

Essas dependências permanecem dentro dos ambientes de desenvolvimento conforme a política de Dev Containers.

## Verificação

Confirme que os executáveis abaixo estão disponíveis:

```text
bat
delta
eza
fd
fzf
http
jq
just
lazygit
make
rg
tmux
yq
```

## Próximo playbook

```text
06-ai-tooling.md
```

## Referências

* ADR-0005 — Modularize Configuration by Capability
* ADR-0007 — Declarative Package Lists
* Arch Linux package repositories
