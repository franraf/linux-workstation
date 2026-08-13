---
title: Configurar SSH
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - architecture.md
  - ADR-0002
  - ADR-0003
  - ADR-0004
---

# 10 — Configurar SSH

## Objetivo

Instalar e configurar o servidor OpenSSH usando uma política versionada compartilhada.

## Fonte canônica

```text
system/openssh/10-linux-workstation.conf
```

O arquivo é instalado em:

```text
/etc/ssh/sshd_config.d/10-linux-workstation.conf
```

## Política desta fase

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
KbdInteractiveAuthentication no
X11Forwarding no
```

A autenticação por senha permanece habilitada nesta fase para evitar depender de provisionamento de chaves antes do primeiro acesso remoto. Hardening adicional pertence a uma fase posterior.

## Procedimento

Execute:

```bash
sudo ./run.sh
```

Autorize digitando `SSH` quando solicitado. O script instala `openssh` se necessário, distribui a fonte canônica, garante host keys, valida com `sshd -t` e `sshd -T`, habilita e reinicia `sshd.service`.

## Verificação

Confirme que o arquivo instalado é idêntico à fonte versionada, que a sintaxe é válida, que as opções efetivas correspondem à política e que `sshd.service` está habilitado e ativo.

## Próximo playbook

```text
11-install-base-packages.md
```

## Referências

* Arch Wiki — OpenSSH
* Manual `sshd_config`
* Documentação oficial do OpenSSH
