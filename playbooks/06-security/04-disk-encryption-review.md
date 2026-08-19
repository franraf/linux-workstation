---
title: Revisão da criptografia de disco
version: 0.1
status: Stable
author: Rafael
last_review: 2026-08-18
related:
  - 01-security-baseline.md
---

# 04 — Revisão da criptografia de disco

## Objetivo

Validar a configuração de criptografia do volume raiz sem recriptografar o disco nem alterar keyslots durante a revisão.

## Estado validado

A workstation utiliza:

- LUKS2 em `/dev/sda2`;
- mapper `cryptroot`;
- `aes-xts-plain64`;
- chave XTS de 512 bits;
- keyslot 0 com `argon2id`;
- custo Argon2: 1 GiB de memória, 4 threads e time cost 4;
- um único keyslot ativo;
- nenhum token LUKS2 registrado;
- desbloqueio no initramfs via systemd e `rd.luks.name=<UUID>=cryptroot`;
- root Btrfs no subvolume `@`;
- discard habilitado para o volume criptografado durante o boot.

O digest PBKDF2 exibido nos metadados LUKS2 não representa o KDF da senha do keyslot; o keyslot ativo usa Argon2id.

## Avaliação

A combinação LUKS2 + AES-XTS + Argon2id atende ao baseline desta geração e não exige recriptografia.

O único keyslot ativo é uma decisão de recuperabilidade a acompanhar: adicionar uma credencial de recuperação só deve ocorrer quando houver mecanismo externo seguro para armazená-la.

`discard` permanece aceito nesta geração como trade-off operacional para SSD. Ele pode revelar padrões de blocos livres ao dispositivo subjacente, mas não expõe diretamente o conteúdo cifrado. Qualquer mudança dessa política deve ser tratada como decisão arquitetural e validada contra TRIM e recuperação.

## Procedimento de validação

1. Identificar o dispositivo físico por trás de `cryptroot`.
2. Confirmar LUKS2 com `cryptsetup status` e `cryptsetup luksDump`.
3. Validar cipher, tamanho da chave e KDF do keyslot.
4. Contar keyslots ativos e tokens registrados.
5. Confirmar integração do initramfs e parâmetros `rd.luks.*` do bootloader.
6. Não executar operações de alteração de chave, token ou recriptografia durante este step.

## Segurança

Não executar neste step:

- `cryptsetup luksAddKey`;
- `cryptsetup luksRemoveKey`;
- `cryptsetup luksConvertKey`;
- `cryptsetup reencrypt`;
- `systemd-cryptenroll`.

Uma cópia do header LUKS pode ser útil para recuperação, mas deve ser armazenada fora do próprio disco criptografado. Isso permanece pendente até existir armazenamento externo apropriado.

## Verificação

O gate deve falhar se o root não estiver sobre `cryptroot`, se o container não for LUKS2, se o cipher esperado não estiver ativo ou se não houver keyslot Argon2id válido.

Keyslot único, ausência de tokens e discard são reportados como informações/avisos de arquitetura e não como falhas desta geração.

## Próximo playbook

`05-secure-boot.md`

## Referências

- `01-security-baseline.md`
- `docs/architecture.md`
- `docs/standards.md`

## Lições aprendidas

- O KDF do keyslot deve ser distinguido do digest interno do metadata LUKS2.
- Criptografia forte também precisa preservar recuperabilidade; mudanças em keyslots exigem uma estratégia externa para credenciais de recuperação.
