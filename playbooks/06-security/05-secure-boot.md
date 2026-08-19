---
title: Secure Boot
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-19
related:
  - 04-disk-encryption-review.md
---

# 05 — Secure Boot

## Objetivo

Manter uma cadeia de boot verificável com systemd-boot, UKI e Secure Boot, preservando recuperação e atualização automática dos artefatos assinados.

## Estado validado

- firmware UEFI com Secure Boot ativo em User Mode;
- systemd-boot 261.2 e systemd-stub 261.2;
- UKI principal em `/boot/EFI/Linux/arch-linux-uki.efi`;
- `Measured UKI: yes` e `Measured OS: yes`;
- root LUKS2 continua desbloqueando normalmente;
- `/etc/kernel/cmdline` contém a cmdline canônica do root criptografado/Btrfs;
- `/etc/mkinitcpio.d/linux.preset` gera o UKI automaticamente no preset `default`;
- fallback tradicional permanece disponível;
- post hook do `sbctl` assina automaticamente artefatos regenerados;
- chaves privadas do `sbctl` permanecem fora do Git em `/var/lib/sbctl/keys`;
- certificados OEM originais foram exportados fora do repositório para recuperação;
- enrollment inclui as chaves locais e certificados Microsoft necessários.

## Gate A — UKI

O UKI foi introduzido em paralelo às entradas BLS Type #1 existentes. O gate foi validado somente após reboot real pelo UKI.

Critérios comprovados:

- UKI detectado pelo systemd-boot como Type #2;
- `bootctl status --print-stub-path` aponta para `/boot/EFI/Linux/arch-linux-uki.efi`;
- systemd-stub ativo;
- LUKS2 `cryptroot` desbloqueado;
- Btrfs `@` montado como `/`;
- kernel iniciado normalmente;
- entradas tradicionais preservadas durante a migração.

## Gate B — Secure Boot

Procedimento validado:

1. instalar `sbctl` e criar chaves locais;
2. exportar os certificados previamente enrolled antes de modificar o firmware;
3. assinar e registrar systemd-boot, fallback EFI, UKI e kernel;
4. confirmar `sbctl verify` antes do enrollment;
5. colocar o firmware em Setup Mode;
6. realizar enrollment das chaves locais incluindo certificados Microsoft;
7. reiniciar para o firmware consolidar o novo estado;
8. confirmar saída de Setup Mode;
9. habilitar Secure Boot no firmware;
10. iniciar explicitamente pelo UKI;
11. confirmar Secure Boot ativo e todas as assinaturas válidas.

Estado final comprovado:

```text
Secure Boot: enabled (user)
Measured UKI: yes
Measured OS: yes
Setup Mode: Disabled
```

`sbctl verify` confirmou assinatura válida para:

- `/boot/EFI/BOOT/BOOTX64.EFI`;
- `/boot/EFI/Linux/arch-linux-uki.efi`;
- `/boot/EFI/systemd/systemd-bootx64.efi`;
- `/boot/vmlinuz-linux`.

## Atualizações

O preset `default` do mkinitcpio gera `/boot/EFI/Linux/arch-linux-uki.efi`. O post hook do `sbctl` assina o UKI após sua regeneração. O fluxo foi testado manualmente com `mkinitcpio -p linux` e terminou com `sbctl verify` integralmente válido.

Uma atualização de kernel não deve ser considerada pronta para reboot se a geração do UKI ou sua assinatura falhar.

## Recuperação

- manter acesso ao firmware para desabilitar Secure Boot em caso de recuperação;
- preservar as entradas tradicionais enquanto forem úteis ao processo de recuperação;
- manter backup externo dos certificados OEM exportados;
- nunca versionar `/var/lib/sbctl/keys` nem qualquer chave privada;
- a mídia Arch oficial pode exigir Secure Boot desabilitado, salvo uso futuro de mídia de recuperação assinada.

## Regras de segurança

- não executar enrollment de chaves de forma automática ou silenciosa;
- não usar opções de força do `sbctl` como procedimento normal;
- não limpar PK/KEK/db sem backup e plano explícito de recuperação;
- não realizar enrollment TPM2 neste step;
- alterações futuras na cadeia de boot devem terminar com `sbctl verify` e reboot de validação quando afetarem artefatos EFI.

## Validação

```bash
bootctl status
sudo sbctl status
sudo sbctl verify
```

Critérios de PASS:

- Secure Boot ativo;
- Setup Mode desabilitado;
- boot atual pelo UKI/systemd-stub;
- UKI e OS medidos;
- todos os artefatos registrados pelo sbctl assinados.

## Próximo playbook

`06-tpm2.md`
