---
title: Validar o primeiro boot
version: 1.1
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004

---

# 18 — Validar o primeiro boot

## Objetivo

Validar que a instalação inicial foi concluída com sucesso e que o sistema está pronto para iniciar a fase `02-system`.

Este playbook não modifica o sistema.

---

# Pré-requisitos

* Playbook `17-install-bootloader.md` concluído.
* Sistema reiniciado a partir do disco instalado.
* Login realizado com o usuário criado durante a instalação.

---

# Resultado esperado

Ao concluir este playbook:

* boot UEFI estará funcional;
* systemd-boot estará operacional;
* raiz LUKS2/Btrfs estará montada corretamente;
* subvolumes previstos estarão disponíveis;
* timezone e locale estarão configurados;
* usuário administrativo e sudo estarão funcionais;
* NetworkManager estará operacional;
* não existirão falhas críticas que impeçam o início de `02-system`.

---

# Procedimento

## 1. Validar o bootloader

```bash
bootctl status
```

Confirme que o systemd-boot está instalado e que a entrada utilizada para iniciar o sistema é reconhecida.

## 2. Validar a raiz e a ESP

```bash
findmnt /
findmnt /boot
```

Confirme:

* `/` em Btrfs usando o subvolume esperado;
* `/boot` montado a partir da ESP FAT32.

## 3. Validar LUKS e armazenamento

```bash
lsblk -f
findmnt
```

Confirme a presença do volume criptografado, mapper esperado e pontos de montagem previstos pela arquitetura.

## 4. Validar timezone e locale

```bash
timedatectl
locale
```

A baseline atual utiliza:

```text
America/Sao_Paulo
pt_BR.UTF-8
```

## 5. Validar usuário e sudo

```bash
id
sudo -v
```

Confirme que o usuário possui o acesso administrativo previsto pelo projeto.

## 6. Validar rede

```bash
systemctl status NetworkManager --no-pager
```

Confirme que o serviço está operacional.

## 7. Validar kernel

```bash
uname -r
```

Confirme que o kernel instalado foi carregado corretamente.

## 8. Validar falhas de serviços

```bash
systemctl --failed
```

Investigue qualquer unidade em estado de falha antes de avançar.

---

# Verificação

Confirme que:

* o sistema inicia pelo disco instalado;
* o bootloader funciona;
* LUKS2 e Btrfs estão montados conforme a arquitetura;
* timezone e locale estão corretos;
* usuário e sudo funcionam;
* NetworkManager está operacional;
* não existem falhas críticas de serviços.

Não valide nesta fase capacidades pertencentes a `02-system`, como instalação de microcode ou atualização completa da linha de base. Essas responsabilidades serão tratadas pelos playbooks correspondentes da próxima fase.

---

# Problemas comuns

## Boot falha antes do desbloqueio

Revise initramfs, parâmetros do kernel e configuração do bootloader.

## Root filesystem não corresponde ao esperado

Revise `fstab`, subvolumes e parâmetros de montagem antes de prosseguir.

## Serviço essencial em falha

Corrija a causa antes de iniciar `02-system`.

---

# Próximo playbook

```text
02-system/
01-update-system.md
```

---

# Referências

* architecture.md
* Arch Wiki — Installation guide
* Arch Wiki — systemd-boot

---

# Lições aprendidas

A validação de primeiro boot deve permanecer estritamente dentro das capacidades entregues pela fase de instalação. Verificar ou atualizar componentes que pertencem à fase seguinte quebra os limites de responsabilidade do fluxo.
