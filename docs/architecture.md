---
title: Arquitetura da workstation
version: 0.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0001
  - ADR-0002
  - ADR-0004
  - ADR-0005
  - ADR-0006
  - ADR-0007
  - ADR-0008
  - ADR-0009
  - ADR-0010
  - ADR-0011
---

# Arquitetura da workstation

## Objetivo

Este documento descreve a arquitetura geral do projeto `linux-workstation`: responsabilidades de cada camada, estado esperado da workstation e limites que devem ser preservados durante a implementação.

Razões detalhadas para decisões específicas pertencem aos respectivos ADRs.

## Visão geral

A workstation é organizada em três camadas funcionais:

```text
Infraestrutura
      ↓
Sistema
      ↓
Usuário
```

Essas camadas descrevem responsabilidades da máquina. A estrutura do repositório é transversal a elas e separa **fontes declarativas**, **orquestração**, **lógica reutilizável** e **validação**.

### Infraestrutura

Inclui firmware UEFI, GPT, EFI, LUKS2, Btrfs, subvolumes, initramfs, kernel, systemd-boot, snapshots e recuperação.

### Sistema

Inclui gerenciamento de pacotes, rede, áudio, Bluetooth, gráficos, serviços systemd, OpenSSH, Docker, logs, timers, segurança e manutenção.

### Usuário

Inclui sessão gráfica, shell, editor, ferramentas CLI, configuração do usuário e integrações de desenvolvimento.

## Modelo do repositório

As responsabilidades são distribuídas assim:

| Diretório | Responsabilidade |
| --- | --- |
| `docs/` | arquitetura, padrões, roadmap e decisões |
| `playbooks/` | procedimento e intenção operacional |
| `packages/` | listas declarativas de pacotes |
| `system/` | configurações canônicas compartilhadas |
| `dotfiles/` | configurações canônicas de usuário mantidas neste repositório |
| `profiles/` | manifests e orquestração específica de hardware |
| `scripts/lib/` | comportamento Bash reutilizável |
| `tests/` | gates estáticos e validação de runtime |
| `examples/` | exemplos não canônicos |

Um `run.sh` de profile deve ser pequeno: resolve contexto, carrega fontes compartilhadas, aplica mudanças e valida o resultado. Listas de pacotes, configurações e lógica reutilizável não devem ser duplicadas dentro do profile quando puderem ser compartilhadas.

## Conceitos arquiteturais centrais

### Architecture First

Decisões relevantes devem ser compreendidas e registradas antes da implementação.

### Repository as Source of Truth

O repositório representa o estado esperado da workstation. Ajustes manuais não representados por documentação ou fontes versionadas são dívida técnica.

### Incremental Evolution

Mudanças devem ser pequenas, verificáveis e reversíveis.

### Single Responsibility

Cada playbook, script, módulo e fonte declarativa deve possuir uma responsabilidade clara.

### Capabilities over Implementations

Capacidades são estáveis; implementações podem mudar.

| Capacidade | Implementação atual |
| --- | --- |
| Compositor Wayland | Hyprland |
| Barra de status | Waybar |
| Bloqueio da sessão | Hyprlock |
| Ciclo de vida da sessão | Hypridle |
| Lançador de aplicações | Rofi |
| Central de notificações | SwayNC |
| Emulador de terminal | Kitty |
| Gerenciador de arquivos | Thunar |
| Login gráfico | greetd + tuigreet |
| Shell | Zsh + Oh My Zsh + Starship |
| Editor | Visual Studio Code |
| Containers | Docker Engine + Compose + Buildx |
| IA no terminal | Codex CLI |

### Shared Sources, Profile Orchestration

Fontes reutilizáveis pertencem a `packages/`, `system/` ou `dotfiles/`. O profile escolhe e aplica essas fontes para o hardware correspondente. Essa separação reduz duplicação e permite reutilização futura em outros perfis.

### Install Then Configure When the Phase Requires It

A ordem entre instalação e configuração é definida pela responsabilidade da fase, não por uma regra universal. A fase 03, por decisão específica, instala primeiro as capacidades do desktop e depois as configura. Outras fases podem intercalar instalação e configuração quando isso fizer mais sentido operacionalmente.

### Validate Before Advancing

Cada fase termina com um gate objetivo. O ciclo é:

```text
Construir
    ↓
Configurar
    ↓
Validar
    ↓
Avançar
```

Validações estáticas verificam coerência do repositório; validações de runtime verificam o estado real da máquina. Checks manuais são permitidos quando dependem de credenciais, interação gráfica ou recursos externos.

## Perfil inicial de hardware

O primeiro perfil é `profiles/dell-latitude-e5470/`.

Hardware previsto:

* Dell Latitude E5470;
* firmware UEFI;
* SSD dedicado ao Arch Linux;
* Intel HD Graphics 520;
* AMD Radeon R7 M360;
* Wi-Fi Qualcomm Atheros;
* Bluetooth integrado;
* processador Intel x86-64.

Não há dual boot. A GPU Intel é a padrão; a AMD permanece disponível sob demanda.

## Armazenamento

A estrutura é:

```text
Disco
├── EFI System Partition
│   ├── FAT32
│   └── 1 GiB
└── Linux LUKS Partition
    └── LUKS2
        └── Btrfs
            ├── @
            ├── @home
            ├── @var
            ├── @var_log
            ├── @var_cache
            ├── @pkg
            ├── @docker
            └── @snapshots
```

O layout canônico é mantido em `system/storage/btrfs-layout.tsv`.

As opções de montagem incluem `noatime` e `compress=zstd:3`.

## Snapshots

Snapper protege o subvolume raiz `@`. Home, Docker, logs e caches ficam fora dos snapshots do sistema. Snapshots não substituem backup.

## Inicialização

A inicialização utiliza UEFI, systemd-boot, kernel Linux, mkinitcpio e desbloqueio LUKS2 por passphrase. Secure Boot e TPM2 permanecem planejados, não ativos.

## Sistema operacional e pacotes

A distribuição é Arch Linux. O padrão é utilizar os repositórios oficiais e manter AUR desabilitado.

Exceções upstream são permitidas somente quando documentadas e estreitas. A ADR-0011 registra o Visual Studio Code oficial da Microsoft como exceção atual. Uma exceção não habilita genericamente software de terceiros.

## Desktop

A sessão gráfica utiliza Wayland com Hyprland. greetd + tuigreet fornecem autenticação e início da sessão. Waybar, Kitty, Rofi, SwayNC, Hyprlock, Hypridle e Thunar compõem as principais capacidades do desktop.

Configurações canônicas ficam em `system/`; o profile as aplica ao usuário quando necessário.

## Desenvolvimento

O host contém ferramentas globais de workstation, não ambientes específicos de projetos.

Baseline atual:

* Git e OpenSSH;
* Zsh, Oh My Zsh e Starship;
* Visual Studio Code oficial da Microsoft;
* Docker Engine, Compose e Buildx;
* ferramentas CLI globais de produtividade;
* Codex CLI.

Dev Containers são o ambiente principal para SDKs e runtimes de projeto. `.NET`, Node.js, Terraform, kubectl, Helm, AWS CLI e runtimes Python específicos não fazem parte da baseline do host.

## Configuração de usuário e dotfiles

O repositório possui `dotfiles/` para configurações de usuário que são parte reproduzível desta workstation, como VS Code e configuração de ferramentas de IA.

O profile também declara `chezmoi` como gerenciador planejado para sincronização de dotfiles. Até essa integração ser implementada, os scripts podem instalar diretamente as fontes versionadas apropriadas no home. Nenhum segredo deve ser armazenado em `dotfiles/`.

## Automação

Scripts Bash usam `set -Eeuo pipefail`, validam pré-requisitos, falham explicitamente e devem ser idempotentes quando possível. Funções compartilháveis pertencem a `scripts/lib/`.

Pipelines usadas apenas para testar existência devem ser evitadas quando `pipefail` puder transformar encerramento antecipado em falso erro. Prefira capturar saída e comparar diretamente quando apropriado.

Scripts não devem assumir silenciosamente disco, usuário, interface, UUID ou credencial.

## Validação

`tests/` contém gates de repositório, validações estáticas por fase e testes de runtime. Fontes declarativas devem ser reutilizadas pelos testes sempre que possível, evitando duplicar o estado esperado dentro do próprio teste.

## Fluxo de mudança

```text
Necessidade
    ↓
ADR quando necessário
    ↓
Documentação / fonte declarativa
    ↓
Implementação
    ↓
Validação
    ↓
Revisão do roadmap/status
```

Mudanças pequenas que não alteram decisões arquiteturais podem dispensar um novo ADR.

## Limites atuais

Ainda não fazem parte da baseline:

* Secure Boot;
* desbloqueio automático por TPM2;
* BIOS legado;
* dual boot;
* múltiplas distribuições;
* helper de AUR;
* instalação totalmente sem supervisão;
* gerenciamento centralizado de segredos;
* backup remoto automatizado.

Esses itens só devem avançar via roadmap e ADR quando aplicável.

## Lições aprendidas

A evolução das primeiras fases mostrou que separar fontes compartilhadas de orquestração específica de hardware reduz duplicação e torna testes e refatorações muito mais previsíveis.
