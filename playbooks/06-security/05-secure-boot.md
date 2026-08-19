---
title: Secure Boot
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-18
related:
  - 04-disk-encryption-review.md
---

# 05 — Secure Boot

## Objetivo

Migrar a cadeia de boot para uma base adequada a Secure Boot sem transformar a primeira alteração em um ponto único de falha.

A migração é dividida em gates. UKI deve funcionar com Secure Boot ainda desabilitado antes de criação/enrollment de chaves ou ativação no firmware.

## Estado observado

- firmware UEFI com suporte a Secure Boot;
- Secure Boot atualmente desabilitado;
- systemd-boot 261.2;
- ESP montada em `/boot` com espaço suficiente;
- boot atual por entradas BLS Type #1;
- kernel, microcode e initramfs separados;
- LUKS2 desbloqueado pelo initramfs systemd via `rd.luks.name=`;
- UKI ainda não utilizado;
- TPM2 disponível, mas enrollment TPM2 fora deste step.

## Estratégia

### Gate A — UKI paralelo

1. Preservar as entradas Type #1 atuais e o fallback.
2. Instalar somente as dependências necessárias à geração do UKI.
3. Gerar UKI em `/boot/EFI/Linux/` sem remover kernel/initramfs tradicionais.
4. Confirmar que systemd-boot detecta a nova entrada.
5. Reiniciar escolhendo manualmente o UKI.
6. Confirmar desbloqueio LUKS, montagem de `@` e boot normal.
7. Somente após reboot real considerar Gate A validado.

### Gate B — Secure Boot

Executado apenas depois do Gate A:

1. definir e preservar caminho de recuperação;
2. criar as chaves Secure Boot fora do Git;
3. assinar os executáveis EFI necessários;
4. verificar assinaturas antes de enrollment;
5. realizar enrollment com confirmação explícita;
6. habilitar Secure Boot no firmware;
7. reiniciar;
8. confirmar `Secure Boot: enabled` e boot normal.

## Regras de segurança

- não habilitar Secure Boot antes do UKI ser validado por reboot;
- não remover as entradas tradicionais durante Gate A;
- não versionar chaves privadas;
- não realizar enrollment TPM2 neste step;
- qualquer ação sobre chaves UEFI exige confirmação explícita;
- manter documentado que a mídia Arch oficial pode exigir Secure Boot desabilitado para recuperação, salvo se uma mídia assinada for preparada separadamente.

## Estado atual

**Gate A — preparation pending.**

O host ainda utiliza Type #1 e nenhum UKI foi criado.

## Validação

Gate A só passa após boot real pelo UKI.

Gate B só passa após Secure Boot ativo ser confirmado no sistema já iniciado.

## Próximo playbook

`06-tpm2.md`
