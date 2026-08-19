---
title: Validação de segurança
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-19
related:
  - 01-security-baseline.md
  - 02-secrets-management.md
  - 03-ssh-hardening.md
  - 04-disk-encryption-review.md
  - 05-secure-boot.md
  - 06-tpm2.md
  - 07-hardware-token.md
---

# 08 — Validação de segurança

## Objetivo

Consolidar os controles obrigatórios da fase Security em um gate objetivo e read-only.

## Controles obrigatórios

- LUKS2 ativo no root;
- Secure Boot ativo;
- boot atual pelo UKI/systemd-stub;
- UKI e OS medidos;
- artefatos registrados no `sbctl` assinados;
- slots LUKS de senha preservados e token TPM2 presente;
- política efetiva de SSH sem root login e sem autenticação por senha;
- nenhuma chave privada ou arquivo de segredo óbvio rastreado pelo Git.

## Controle opcional

Hardware token permanece opcional e não bloqueia este gate enquanto `07-hardware-token.md` estiver explicitamente em estado Deferred.

## Estado atual

O gate deve permanecer bloqueado enquanto o SSH ainda permitir `PasswordAuthentication yes`. A alteração só deve ocorrer depois de existir ao menos uma chave autorizada de outro dispositivo e uma nova sessão SSH por chave ter sido validada.

## Execução

```bash
sudo bash profiles/dell-latitude-e5470/06-security/08-security-validation/run.sh
```

## Critério

Zero `FAIL`. Warnings documentados podem existir somente para controles não obrigatórios.
