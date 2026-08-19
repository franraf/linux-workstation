---
title: SSH hardening
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-18
related:
  - 01-security-baseline.md
---

# 03 — SSH hardening

## Objetivo

Alinhar a configuração efetiva do OpenSSH à política declarada da workstation sem introduzir risco de lockout remoto.

## Política

- `PermitRootLogin no`;
- `PubkeyAuthentication yes`;
- `PasswordAuthentication no`;
- `PermitEmptyPasswords no`;
- `KbdInteractiveAuthentication no`;
- `X11Forwarding no`.

A fonte canônica é `system/openssh/10-linux-workstation.conf`.

## Procedimento

1. Confirmar que o usuário operacional possui ao menos uma chave autorizada em `~/.ssh/authorized_keys` antes de desabilitar autenticação por senha.
2. Comparar a configuração instalada com a fonte canônica.
3. Instalar a fonte canônica em `/etc/ssh/sshd_config.d/10-linux-workstation.conf`.
4. Validar sintaxe com `sshd -t`.
5. Confirmar a política efetiva com `sshd -T`.
6. Recarregar `sshd.service`, sem reiniciar sessões existentes.
7. Abrir uma nova sessão SSH usando chave pública antes de encerrar qualquer sessão remota atual.

## Segurança

O script deve recusar a aplicação quando não houver `authorized_keys` não vazio para o usuário alvo. Isso evita desabilitar senha sem um caminho alternativo de autenticação validável.

## Verificação

A configuração efetiva deve reportar:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
```

A validação manual final é uma nova conexão SSH autenticada por chave pública.

## Problemas comuns

### Lockout após desabilitar senha

Não aplicar hardening sem chave autorizada. Manter a sessão atual aberta até a nova conexão por chave ser confirmada.

### Arquivo correto mas configuração efetiva divergente

Usar `sshd -T` como fonte do estado efetivo e revisar precedência de includes/configurações adicionais.

## Próximo playbook

`04-disk-encryption-review.md`

## Referências

- `system/openssh/10-linux-workstation.conf`
- `profiles/dell-latitude-e5470/profile.yaml`
- `docs/standards.md`
