---
title: Arquitetura da workstation
version: 0.3
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - ADR-0001
  - ADR-0002
  - ADR-0004
  - ADR-0005
  - ADR-0009
  - ADR-0011
  - ADR-0012
---

# Arquitetura da workstation

## Objetivo

Este documento apresenta a arquitetura geral do projeto `linux-workstation`.

Seu propósito é explicar como os principais componentes da workstation se relacionam, quais responsabilidades pertencem a cada camada e quais limites devem ser preservados durante a implementação.

Detalhes sobre as razões de cada escolha devem ser registrados nos respectivos Architecture Decision Records.

## Visão geral

O projeto é dividido em três camadas funcionais da máquina e uma camada transversal de orquestração do repositório:

```text
Infraestrutura
      ↓
Sistema
      ↓
Usuário

Orquestração do repositório → coordena as três camadas sem duplicar sua lógica
```

### Infraestrutura

Responsável pelos elementos necessários para inicializar, armazenar e recuperar o sistema.

Inclui UEFI, GPT, partição EFI, LUKS2, Btrfs, subvolumes, initramfs, kernel, systemd-boot, snapshots e recuperação.

### Sistema

Responsável pelos serviços e recursos compartilhados da workstation.

Inclui gerenciamento de pacotes, rede, áudio, Bluetooth, energia, gráficos, Docker, OpenSSH, logs, timers, serviços systemd, segurança e manutenção.

### Usuário

Responsável pelo ambiente interativo e pelas configurações pessoais que pertencem à workstation.

Inclui Hyprland, greetd/tuigreet, Waybar, Kitty, Rofi, SwayNC, Hyprlock, Hypridle, Thunar, Zsh, Oh My Zsh, Starship, tmux, Visual Studio Code e demais dotfiles versionados.

### Orquestração do repositório

A coordenação de alto nível é orientada pelos manifests do profile e das fases.

Responsabilidades:

* descobrir fases declaradas pelo `profile.yaml`;
* descobrir steps, modos e entrypoints pelos `phase.yaml`;
* oferecer inspeção antes da execução;
* delegar execução para os `run.sh` existentes;
* preservar confirmações e validações dos próprios steps;
* fornecer base para retomada, bootstrap e gates integrados.

A implementação inicial é `scripts/workstation`, definida pelo ADR-0012. O runner não contém lógica de configuração específica de uma capacidade.

## Fontes canônicas e responsabilidades

O estado esperado é dividido por responsabilidade:

| Diretório | Responsabilidade |
| --- | --- |
| `packages/` | listas declarativas de pacotes |
| `system/` | configuração canônica do sistema e serviços |
| `dotfiles/` | configuração canônica do usuário pertencente à workstation |
| `profiles/` | manifests, ordem de execução e particularidades de hardware |
| `scripts/lib/` | comportamento reutilizável |
| `scripts/workstation` | orquestração de alto nível |
| `tests/` | gates estáticos e de runtime |
| `playbooks/` | procedimentos reproduzíveis e contexto operacional |

Um profile consome essas fontes; não deve duplicá-las sem necessidade específica de hardware.

## Conceitos arquiteturais centrais

### Architecture First

Decisões arquiteturais relevantes devem ser compreendidas e documentadas antes de sua implementação.

### Documentation as Source of Truth

A documentação e os artefatos versionados representam o comportamento esperado da workstation.

### Incremental Evolution

Novas capacidades são introduzidas em mudanças pequenas, verificáveis e reversíveis.

### Single Responsibility

Cada playbook, script, fonte declarativa e módulo de configuração possui responsabilidade identificável.

### Capabilities over Implementations

O projeto documenta capacidades; ferramentas específicas são implementações substituíveis.

### Modular Configuration

Configurações são organizadas por capacidade ou responsabilidade e possuem fontes canônicas compartilháveis.

### Validate Before Advancing

Cada fase termina com validação objetiva antes da fase seguinte.

### Profile-driven Orchestration

A ordem e a composição da execução pertencem aos manifests. O runner interpreta essa estrutura e delega o trabalho aos steps, em vez de reimplementar procedimentos.

## Perfil inicial de hardware

O primeiro profile é `profiles/dell-latitude-e5470/`.

Hardware previsto:

* Dell Latitude E5470;
* firmware UEFI;
* SSD dedicado ao Arch Linux;
* Intel HD Graphics 520;
* AMD Radeon R7 M360;
* Wi-Fi Qualcomm Atheros;
* Bluetooth integrado;
* processador Intel x86-64.

Não há dual boot. A GPU Intel integrada é padrão e a AMD permanece disponível sob demanda.

## Armazenamento

O disco utiliza GPT com uma ESP FAT32 de 1 GiB e uma partição LUKS2 contendo Btrfs.

A fonte canônica do layout de subvolumes é `system/storage/btrfs-layout.tsv`.

Subvolumes principais:

* `@` → `/`;
* `@home` → `/home`;
* `@var` → `/var`;
* `@var_log` → `/var/log`;
* `@var_cache` → `/var/cache`;
* `@pkg` → `/var/cache/pacman/pkg`;
* `@docker` → `/var/lib/docker`;
* `@snapshots` → `/.snapshots`.

Snapshots do sistema não incluem dados pessoais, Docker, logs ou caches. Snapshots não substituem backup.

## Inicialização

A inicialização utiliza UEFI, systemd-boot, kernel Linux, mkinitcpio e desbloqueio LUKS2 durante o boot.

Secure Boot permanece desabilitado nesta geração e exige ADR para adoção futura.

## Sistema operacional e pacotes

A distribuição base é Arch Linux.

Pacotes dos repositórios oficiais são preferidos. AUR permanece desabilitado por padrão. Exceções de distribuição upstream precisam de justificativa arquitetural específica, conforme ADR-0011.

## Ambiente gráfico

A sessão gráfica utiliza Wayland com Hyprland e autenticação via greetd + tuigreet.

Capacidades principais:

* compositor: Hyprland;
* status bar: Waybar;
* terminal: Kitty;
* launcher: Rofi;
* notificações: SwayNC;
* lock: Hyprlock;
* idle lifecycle: Hypridle;
* file manager: Thunar;
* áudio: PipeWire;
* rede: NetworkManager;
* Bluetooth: BlueZ.

## Ambiente de desenvolvimento

O host contém ferramentas fundamentais e globais de workstation, incluindo Git, Docker, Visual Studio Code, OpenSSH, shell e CLI tooling.

SDKs, linguagens, CLIs e dependências específicas de projetos permanecem preferencialmente em Dev Containers. A fase 04 foi validada com um Dev Container real e runtime ausente do host.

Codex CLI é a ferramenta global de assistência por IA; autenticação e segredos não são versionados.

## Dotfiles

Configurações de usuário que fazem parte da definição da workstation podem ser armazenadas em `dotfiles/` neste repositório.

O `chezmoi` continua previsto como mecanismo de aplicação/sincronização, mas sua adoção operacional ainda pertence à Milestone 5.

## Automação

Scripts Bash usam `set -Eeuo pipefail`, validam pré-requisitos, falham explicitamente e mantêm confirmações fortes para ações destrutivas.

A automação de alto nível não remove essas proteções. `scripts/workstation` apenas resolve manifests e delega a execução.

O runner inicial depende somente de Bash e ferramentas base, para permanecer utilizável antes da instalação de runtimes de desenvolvimento.

## Validação

`tests/` contém gates para armazenamento, sistema, desktop, desenvolvimento, consistência do repositório e automação.

Testes de configuração validam estado da workstation; não substituem testes tradicionais de software.

## Fluxo de mudança

```text
Necessidade
    ↓
ADR quando necessário
    ↓
Documentação / fonte canônica
    ↓
Implementação
    ↓
Validação
    ↓
Atualização do status
```

## Limites atuais

Não fazem parte da geração atual:

* Secure Boot;
* TPM2 unlock;
* BIOS legado;
* dual boot;
* suporte universal a hardware;
* AUR habilitado globalmente;
* instalação totalmente sem supervisão;
* gerenciamento centralizado de segredos;
* backup remoto automatizado.

## Lições aprendidas

A separação entre fontes canônicas, profiles, libs, steps e gates reduz duplicação e torna possível adicionar um orquestrador sem transformar o runner em um segundo sistema de configuração.
