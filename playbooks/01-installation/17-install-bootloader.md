---
title: Instalar o bootloader
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 16-configure-initramfs.md
  - 18-first-boot.md
---

# 17 — Instalar o bootloader

## Objetivo

Instalar `systemd-boot` na ESP e criar as entradas de boot normal e fallback para o root LUKS2/Btrfs.

As partes estáticas da configuração são versionadas em:

```text
system/systemd-boot/loader.conf.template
system/systemd-boot/entry.conf.template
```

UUIDs, título, timeout e imagem initramfs são renderizados em runtime.

## Baseline

```text
ESP:          /boot
entry id:     arch-linux
title:        Arch Linux
timeout:      3 segundos
mapper root:  cryptroot
root fs:      Btrfs subvol=@
```

As entradas incluem `rd.luks.name`, `rd.luks.options=discard`, `root=UUID=...`, `rootfstype=btrfs`, `rootflags=subvol=@` e `rw`.

## Execução

Dentro do chroot e com efivars disponíveis:

```bash
profiles/dell-latitude-e5470/01-installation/17-install-bootloader/run.sh
```

O script valida UEFI, ESP vfat com GUID correto, kernel, microcode, initramfs normal/fallback, mapper `cryptroot`, UUID LUKS, UUID Btrfs e subvolume root `@`. Antes de instalar exige confirmação `BOOTLOADER`.

## Alterações

- executa `bootctl --esp-path=/boot install`;
- renderiza `/boot/loader/loader.conf`;
- renderiza `/boot/loader/entries/arch-linux.conf`;
- renderiza `/boot/loader/entries/arch-linux-fallback.conf`.

## Verificação

O passo exige os binários EFI do systemd-boot, valida `loader.conf`, faz `bootctl list` e confere todos os parâmetros críticos nas duas entradas.

## Próximo playbook

```text
18-first-boot.md
```
