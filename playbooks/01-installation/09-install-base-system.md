---
title: Instalar o sistema base
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - architecture.md
  - ADR-0002
  - ADR-0003
  - ADR-0004
  - ADR-0009
---

# 09 — Instalar o sistema base

## Objetivo

Instalar o sistema base do Arch Linux sobre a estrutura de armazenamento preparada nos passos anteriores.

A seleção de pacotes é declarativa e não pertence ao profile. Para este perfil Intel, a fonte canônica é:

```text
packages/installation/base-system-intel.txt
```

O script do profile apenas orquestra a instalação dessa lista no target root.

## Pré-requisitos

- sistemas de arquivos montados conforme o playbook 08;
- `/mnt` apontando para o subvolume Btrfs `@`;
- ESP montada em `/mnt/boot` como `vfat`;
- conectividade com a Internet;
- relógio do ambiente live sincronizado;
- repositórios oficiais acessíveis.

## Resultado esperado

Ao concluir:

- o sistema base estará instalado em `/mnt`;
- o target será identificado como Arch Linux;
- os pacotes declarados estarão instalados no target;
- a estrutura de mounts preparada anteriormente permanecerá intacta.

## Procedimento

Execute a partir do ambiente live:

```bash
sudo profiles/dell-latitude-e5470/01-installation/09-install-base-system/run.sh
```

Por padrão o script usa:

```text
target root:    /mnt
package source: packages/installation/base-system-intel.txt
```

O target root e a fonte de pacotes podem ser sobrescritos explicitamente com `--root` e `--package-file` para testes controlados.

Antes do `pacstrap`, o script valida o mount tree, a ESP, os nomes e a disponibilidade dos pacotes e exige confirmação textual `INSTALL`.

## Verificação

O passo só é considerado concluído quando:

- `/mnt/etc/os-release` identifica Arch Linux;
- binários fundamentais como `bash`, `pacman`, `systemctl`, `cryptsetup` e `btrfs` existem no target;
- todos os pacotes declarados respondem a `pacman -Q` dentro de `arch-chroot /mnt`.

Não é responsabilidade deste passo configurar locale, timezone, usuários, initramfs ou bootloader.

## Próximo playbook

```text
10-generate-fstab.md
```

## Lições aprendidas

A lista de pacotes deixou de residir dentro do profile. Conforme ADR-0009, dados declarativos ficam em `packages/`, enquanto o profile preserva apenas a orquestração e as validações específicas da instalação.
