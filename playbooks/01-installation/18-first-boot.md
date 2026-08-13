---
title: Validar o primeiro boot
version: 1.2
status: Stable
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 17-install-bootloader.md
---

# 18 — Validar o primeiro boot

## Objetivo

Validar que a fase `01-installation` entregou um sistema bootável e coerente antes de iniciar `02-system`.

Este passo não deve corrigir automaticamente a instalação.

## Gate estático antes de reiniciar

Antes de sair do ambiente de instalação, rode no repositório:

```bash
bash tests/installation/static-artifacts.sh
```

Esse teste não toca em disco. Ele valida sintaxe dos scripts, presença das fontes compartilhadas, layout Btrfs, configuração mkinitcpio, templates do systemd-boot e sudoers. Ele não substitui o teste de boot real.

## Primeiro boot

Saia do chroot, desmonte os filesystems de instalação com segurança, reinicie e remova a mídia live. O boot esperado é:

```text
UEFI
  → systemd-boot
  → initramfs
  → prompt LUKS
  → cryptroot
  → Btrfs @
  → systemd
```

Faça login com o usuário criado no passo 15.

## Validações

Execute e confira:

```bash
bootctl status
findmnt /
findmnt /boot
lsblk -f
timedatectl
locale
id
sudo -v
systemctl status NetworkManager --no-pager
uname -r
systemctl --failed
```

O resultado esperado inclui:

- systemd-boot operacional;
- `/` em Btrfs sobre o subvolume `@` e root desbloqueado via `cryptroot`;
- ESP FAT32 montada em `/boot`;
- subvolumes previstos em `system/storage/btrfs-layout.tsv` disponíveis;
- timezone `America/Sao_Paulo` e locale `pt_BR.UTF-8` na baseline do perfil;
- usuário administrativo com sudo funcional;
- NetworkManager disponível;
- nenhuma falha crítica de serviço.

## Limite da fase

Não instale nem reconfigure capacidades pertencentes à `02-system` apenas para fazer este gate passar. Falhas da instalação devem ser corrigidas na fase 01; novas capacidades começam somente depois que este playbook estiver aprovado.

## Próximo playbook

```text
02-system/01-update-system.md
```
