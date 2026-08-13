---
title: Configurar usuários
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 14-configure-network.md
  - 16-configure-initramfs.md
---

# 15 — Configurar usuários

## Objetivo

Criar ou reconciliar o usuário administrativo inicial, definir senhas interativamente e instalar a política de sudo do projeto.

A baseline do perfil é:

```text
username:  rafael
full name: Rafael
shell:     /bin/bash
group:     wheel
```

A política sudo é versionada em:

```text
system/sudoers/10-wheel
```

## Execução

Dentro do chroot:

```bash
profiles/dell-latitude-e5470/01-installation/15-configure-users/run.sh
```

Nome, descrição e shell podem ser sobrescritos por argumentos. `--no-root-password` deixa a senha de root inalterada.

Nenhuma senha ou hash é aceito por argumento, variável de ambiente ou arquivo do profile. `passwd` solicita as credenciais diretamente no terminal.

## Comportamento

Se o usuário não existir, ele é criado com home, grupo primário próprio e membership em `wheel`. Se já existir como usuário regular, os atributos definidos pelo profile são reconciliados em vez de recriar a conta.

Antes da alteração, o script exige confirmação `USER`.

## Sudo

`system/sudoers/10-wheel` é validado com `visudo`, instalado como `/etc/sudoers.d/10-wheel` com owner `root:root` e modo `0440`, e a configuração completa é validada novamente.

## Verificação

O passo só passa quando usuário, UID regular, home, shell, ownership, membership em `wheel`, estado das senhas e sudoers correspondem ao esperado, além de um login de teste inicializar `$HOME` corretamente.

## Próximo playbook

```text
16-configure-initramfs.md
```
