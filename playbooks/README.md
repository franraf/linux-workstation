---
title: Playbooks
version: 1.1
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* ADR-0002
* ADR-0003
* ADR-0004
* ADR-0006
* ADR-0007
* docs/architecture.md
* docs/standards.md

---

# Playbooks

## Objetivo

Os playbooks descrevem os procedimentos operacionais do projeto `linux-workstation`.

Eles documentam, de forma reproduzível, as etapas necessárias para instalar, configurar, validar, manter e recuperar a workstation.

Os playbooks são escritos para execução humana. A automação é consequência dessa documentação, nunca seu substituto.

---

# Filosofia

Os playbooks seguem os princípios definidos pelos ADRs do projeto, em especial:

* documentação antes da implementação;
* automação depois do entendimento;
* mudanças pequenas e verificáveis;
* responsabilidade única;
* separação entre instalação e configuração quando tecnicamente apropriado;
* listas declarativas para conjuntos de pacotes;
* validação antes de avançar.

---

# Organização

```text
playbooks/
├── README.md
├── 01-installation/
├── 02-system/
├── 03-desktop/
├── 04-development/
├── 05-maintenance/
└── 06-recovery/
```

## 01-installation

Instalação inicial do Arch Linux: mídia, firmware, armazenamento, LUKS2, Btrfs, sistema base, configuração inicial, initramfs, bootloader e primeiro boot.

## 02-system

Linha de base operacional do sistema: atualização, Pacman, microcode, systemd, horário, journald, zram, TRIM, serviços, SSH, pacotes base e validação.

## 03-desktop

Construção do ambiente gráfico: stack gráfica, Hyprland, Waybar, Hyprlock, Hypridle, Rofi, SwayNC, Kitty, Thunar, fontes, configuração da sessão, aparência, autenticação gráfica e validação final.

## 04-development

Preparação para desenvolvimento: Git, shell, editor, contêineres, ferramentas CLI, ferramentas de IA e validação integrada.

## 05-maintenance

Reservado para procedimentos recorrentes de manutenção. A fase ainda não possui playbooks implementados.

## 06-recovery

Reservado para procedimentos de recuperação. A fase ainda não possui playbooks implementados.

---

# Ordem de execução

Os playbooks deverão ser executados na ordem indicada pela numeração dos diretórios e dos arquivos.

A numeração representa a sequência operacional recomendada. Dependências específicas devem permanecer explícitas no documento.

---

# Estrutura dos playbooks

Todo playbook deverá possuir, quando aplicável:

1. Objetivo
2. Pré-requisitos
3. Resultado esperado
4. Procedimento
5. Verificação
6. Problemas comuns
7. Próximo playbook
8. Referências
9. Lições aprendidas

---

# Separação entre instalação e configuração

Quando uma capacidade possuir separação técnica natural entre disponibilizar seus pacotes e definir seu comportamento, os playbooks deverão refletir essa divisão conforme a ADR-0006.

Playbooks de configuração não devem instalar silenciosamente dependências ausentes.

---

# Pacotes declarativos

Conjuntos de pacotes deverão utilizar listas declarativas quando apropriado, conforme a ADR-0007.

Os arquivos de pacotes definem **o que** instalar. Scripts e procedimentos definem **como** instalar e validar.

---

# Operações destrutivas

Operações destrutivas devem seguir `docs/standards.md`.

Antes de operações como particionamento, formatação ou `cryptsetup luksFormat`, o usuário deverá confirmar explicitamente digitando:

```text
ERASE
```

---

# Validação

Nenhum playbook é considerado concluído apenas porque os comandos terminaram sem erro.

Ao final de cada procedimento deverá existir uma verificação objetiva do estado resultante.

Falhas encontradas durante validação devem corrigir a fonte versionada — playbook, script, configuração ou teste — e não apenas o estado local da máquina.

---

# Relação com automações

Scripts em `scripts/` deverão implementar procedimentos documentados e compreendidos.

Sempre que houver divergência entre script e playbook, ambos deverão ser revisados até voltarem a representar o mesmo processo.

---

# Perfis de hardware

Particularidades específicas de hardware pertencem a `profiles/<hardware>/` e não devem ser incorporadas silenciosamente ao fluxo genérico.

---

# Sequência atual

## 01-installation

```text
01-prepare-install-media.md
02-configure-firmware.md
03-partition-disk.md
04-create-luks.md
05-create-btrfs.md
06-create-subvolumes.md
07-format-efi.md
08-mount-filesystems.md
09-install-base-system.md
10-generate-fstab.md
11-enter-chroot.md
12-configure-time.md
13-configure-localization.md
14-configure-network.md
15-configure-users.md
16-configure-initramfs.md
17-install-bootloader.md
18-first-boot.md
```

## 02-system

```text
01-update-system.md
02-configure-pacman.md
03-install-microcode.md
04-configure-systemd.md
05-configure-time-sync.md
06-configure-journald.md
07-configure-zram.md
08-configure-trim.md
09-configure-system-services.md
10-configure-ssh.md
11-install-base-packages.md
12-system-validation.md
```

## 03-desktop

```text
01-install-graphics-stack.md
02-install-compositor.md
03-install-status-bar.md
04-install-screen-locker.md
05-install-idle-manager.md
06-install-application-launcher.md
07-install-notification-center.md
08-install-terminal-emulator.md
09-install-file-manager.md
10-install-font-stack.md
11-configure-desktop-session.md
12-configure-status-bar.md
13-configure-session-lock.md
14-configure-session-lifecycle.md
15-configure-application-launcher.md
16-configure-notification-center.md
17-configure-terminal-emulator.md
18-configure-file-manager.md
19-configure-appearance.md
20-install-session-login.md
21-configure-session-login.md
22-desktop-validation.md
```

## 04-development

```text
01-version-control.md
02-shell-environment.md
03-code-editor.md
04-container-platform.md
05-cli-tools.md
06-ai-tooling.md
07-development-validation.md
```

---

# Lições aprendidas

O índice deve refletir os arquivos reais do repositório. Listas planejadas que divergem da implementação reduzem a confiabilidade da documentação como fonte da verdade.
