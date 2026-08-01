---

title: First Boot Validation
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-01
phase: Installation
playbook: 18
related:

* phase.yaml
* architecture.md

---

# First Boot Validation

## Objetivo

Validar que a instalação foi concluída com sucesso e que o sistema está pronto para iniciar a próxima milestone (**Base System**).

Este playbook **não modifica o sistema**.

Seu objetivo é apenas confirmar que todos os componentes instalados nas etapas anteriores estão funcionando corretamente.

---

# Pré-requisitos

A instalação deve ter sido concluída até o playbook anterior:

```text
17-install-bootloader
```

O sistema deve ter sido reiniciado.

O login deve ser realizado utilizando o usuário criado durante a instalação.

---

# Checklist

## Bootloader

Verificar:

```bash
bootctl status
```

Resultado esperado:

* systemd-boot instalado
* Boot Loader Specification reconhecida
* entrada padrão localizada

---

## Sistema de arquivos raiz

Verificar:

```bash
findmnt /
```

Resultado esperado:

* Btrfs
* subvolume `@`

---

## EFI

Verificar:

```bash
findmnt /boot
```

Resultado esperado:

* ESP montada
* sistema de arquivos FAT32

---

## LUKS

Verificar:

```bash
lsblk -f
```

Resultado esperado:

* partição criptografada
* mapper `cryptroot`
* Btrfs montado corretamente

---

## Subvolumes

Verificar:

```bash
findmnt
```

Confirmar a presença dos seguintes pontos de montagem:

* /
* /home
* /var
* /var/log
* /var/cache
* /var/cache/pacman/pkg
* /var/lib/docker
* /.snapshots

---

## Timezone

Verificar:

```bash
timedatectl
```

Resultado esperado:

```text
Time zone: America/Sao_Paulo
```

---

## Locale

Verificar:

```bash
locale
```

Resultado esperado:

```text
LANG=pt_BR.UTF-8
```

---

## Usuário

Verificar:

```bash
id
```

Confirmar que o usuário pertence ao grupo:

```text
wheel
```

---

## sudo

Verificar:

```bash
sudo -v
```

Resultado esperado:

Nenhum erro.

---

## NetworkManager

Verificar:

```bash
systemctl status NetworkManager
```

Resultado esperado:

```text
active (running)
```

---

## Kernel

Verificar:

```bash
uname -r
```

Confirmar que o kernel instalado é carregado corretamente.

---

## Microcode

Verificar:

```bash
journalctl -b | grep microcode
```

Confirmar que o microcode Intel foi carregado durante o boot.

---

## Serviços

Verificar:

```bash
systemctl --failed
```

Resultado esperado:

```text
0 loaded units listed.
```

---

## Atualização

Verificar:

```bash
sudo pacman -Syu
```

Resultado esperado:

Atualização executada sem erros.

---

# Critério de conclusão

A milestone é considerada concluída quando todas as verificações acima forem aprovadas.

Ao final desta etapa o sistema deverá possuir:

* Boot UEFI funcional
* systemd-boot configurado
* raiz criptografada com LUKS2
* Btrfs com subvolumes
* timezone configurado
* locale configurado
* usuário administrativo
* sudo funcional
* NetworkManager habilitado
* sistema inicializando corretamente

---

# Próxima fase

Após a validação do primeiro boot, o projeto segue para:

```text
Milestone 2 — Base System
```

Nenhuma configuração adicional pertencente ao ambiente de desenvolvimento, desktop ou aplicações deve ser realizada antes do início da próxima milestone.
