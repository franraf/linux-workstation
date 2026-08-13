---
title: Configurar o initramfs
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 15-configure-users.md
  - 17-install-bootloader.md
---

# 16 — Configurar o initramfs

## Objetivo

Configurar o mkinitcpio para inicializar a workstation com early userspace systemd, root LUKS2, Btrfs, console brasileiro e Intel i915.

A configuração canônica é:

```text
system/mkinitcpio/10-linux-workstation-intel.conf
```

Ela define:

```text
MODULES: i915
HOOKS:   base systemd autodetect microcode modconf kms keyboard
         sd-vconsole block sd-encrypt filesystems fsck
```

## Execução

Dentro do chroot:

```bash
profiles/dell-latitude-e5470/01-installation/16-configure-initramfs/run.sh
```

O script exige `KEYMAP=br-abnt2`, valida pacotes, preset do kernel, disponibilidade dos hooks e do módulo i915 e solicita confirmação `INITRAMFS`.

## Alterações

O artefato canônico é instalado como:

```text
/etc/mkinitcpio.conf.d/10-linux-workstation.conf
```

Depois o script executa:

```bash
mkinitcpio -P
```

## Verificação

Além de comparar o arquivo instalado com a fonte versionada, o passo inspeciona a imagem gerada com `lsinitcpio` e exige `systemd-cryptsetup`, o generator correspondente, `i915` e `/etc/vconsole.conf` dentro do initramfs.

## Próximo playbook

```text
17-install-bootloader.md
```
