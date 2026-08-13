---
title: Controle de versão
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - architecture.md
  - ADR-0005
  - ADR-0009
---

# 01 — Controle de versão

## Objetivo

Instalar e configurar o Git no host sem misturar runtimes ou SDKs específicos de projeto à workstation.

A autenticação remota adotada pelo perfil é SSH. Identidade Git e chaves privadas são dados do usuário e não pertencem ao repositório.

## Fonte canônica

A lista de pacotes desta capacidade é:

```text
packages/development/version-control.txt
```

A implementação específica do perfil é:

```text
profiles/dell-latitude-e5470/04-development/01-version-control/run.sh
```

## Pré-requisitos

* `03-desktop` concluída e validada;
* sistema Arch Linux inicializado com systemd;
* conectividade com os repositórios oficiais;
* usuário normal com acesso administrativo.

## Procedimento

Execute a partir do diretório do passo:

```bash
sudo ./run.sh
```

Quando chamado via `sudo`, o script usa `SUDO_USER` como usuário alvo. Também é possível informar explicitamente:

```bash
sudo ./run.sh --user rafael --name "Nome para commits" --email "email@example.com"
```

Se `user.name` e `user.email` já existirem na configuração global do usuário, eles são preservados como valores padrão. Se estiverem ausentes, o script solicita os valores interativamente.

O script:

1. instala os pacotes declarados em `packages/development/version-control.txt`;
2. aplica a identidade Git ao usuário normal, nunca ao `root`;
3. define `init.defaultBranch=main`;
4. garante `~/.ssh` com permissão `0700`;
5. detecta se já existe uma chave pública SSH.

## Política de SSH

O passo **não gera chave SSH automaticamente** e não armazena credenciais no repositório. Caso nenhuma chave pública exista, a execução termina com warning e a criação/registro da chave no GitHub permanece uma ação explícita do usuário.

## Verificação

Confirme:

```bash
git --version
git config --global --get user.name
git config --global --get user.email
git config --global --get init.defaultBranch
```

O resultado esperado é Git disponível, identidade definida para o usuário correto e branch inicial `main`.

A autenticação remota será validada de forma completa no gate `07-development-validation`.

## Próximo playbook

```text
02-shell-environment.md
```
