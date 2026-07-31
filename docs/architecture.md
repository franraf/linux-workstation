---

title: Arquitetura da workstation
version: 0.1
status: Draft
author: Rafael
last_review: 2026-07-30
related:

* ADR-0001
* ADR-0002
* ADR-0004
* ADR-0005

---

# Arquitetura da workstation

## Objetivo

Este documento apresenta a arquitetura geral do projeto `linux-workstation`.

Seu propósito é explicar como os principais componentes da workstation se relacionam, quais responsabilidades pertencem a cada camada e quais limites devem ser preservados durante a implementação.

Detalhes sobre as razões de cada escolha devem ser registrados nos respectivos Architecture Decision Records.

## Visão geral

O projeto é dividido em três camadas principais:

```text
Infraestrutura
      ↓
Sistema
      ↓
Usuário
```

Cada camada possui responsabilidades distintas.

### Infraestrutura

Responsável pelos elementos necessários para inicializar, armazenar e recuperar o sistema.

Inclui:

* firmware UEFI;
* tabela de partições GPT;
* partição EFI;
* criptografia LUKS2;
* filesystem Btrfs;
* subvolumes;
* initramfs;
* kernel;
* systemd-boot;
* snapshots;
* recuperação.

### Sistema

Responsável pelos serviços e recursos compartilhados da workstation.

Inclui:

* gerenciamento de pacotes;
* rede;
* áudio;
* Bluetooth;
* energia;
* gráficos;
* Docker;
* OpenSSH;
* logs;
* timers;
* serviços systemd;
* segurança;
* manutenção.

### Usuário

Responsável pelo ambiente interativo e pelas configurações pessoais.

Inclui:

* Hyprland;
* Waybar;
* Kitty;
* Rofi;
* SwayNC;
* Hyprlock;
* Hypridle;
* Thunar;
* Zsh;
* Oh My Zsh;
* Starship;
* tmux;
* Visual Studio Code;
* chezmoi;
* dotfiles.

## Conceitos arquiteturais centrais

O projeto é orientado por um conjunto de conceitos que guiam sua documentação, implementação e evolução.

### Architecture First

Decisões arquiteturais relevantes devem ser compreendidas e documentadas antes de sua implementação.

A arquitetura define o estado desejado da workstation. Playbooks, scripts e configurações implementam esse estado.

### Documentation as Source of Truth

A documentação versionada representa o comportamento esperado da workstation.

Configurações manuais que não estejam documentadas ou representadas no repositório são consideradas dívida técnica.

### Incremental Evolution

O projeto evolui por meio de mudanças pequenas, verificáveis e reversíveis.

Novas capacidades são introduzidas progressivamente, evitando alterações extensas que dificultem revisão, validação ou recuperação.

### Single Responsibility

Cada playbook, script e módulo de configuração deve possuir uma responsabilidade claramente identificável.

A divisão ocorre por responsabilidade técnica e capacidade entregue, não apenas por tamanho de arquivo ou quantidade de comandos.

### Capabilities over Implementations

O projeto documenta capacidades da workstation, enquanto ferramentas específicas são tratadas como implementações substituíveis.

Exemplos:

| Capacidade              | Implementação atual |
| ----------------------- | ------------------- |
| Compositor Wayland      | Hyprland            |
| Barra de status         | Waybar              |
| Bloqueio da sessão      | Hyprlock            |
| Ciclo de vida da sessão | Hypridle            |
| Lançador de aplicações  | Rofi                |
| Central de notificações | SwayNC              |
| Emulador de terminal    | Kitty               |
| Gerenciador de arquivos | Thunar              |

Uma implementação pode ser substituída sem alterar a responsabilidade arquitetural da capacidade.

### Modular Configuration

Configurações devem ser organizadas por capacidade ou responsabilidade.

Arquivos principais devem atuar como pontos de entrada e delegar comportamentos específicos para módulos menores sempre que a ferramenta oferecer suporte adequado.

### Validate Before Advancing

Cada fase deve terminar com uma validação objetiva antes do início da fase seguinte.

O projeto segue o ciclo:

```text
Construir
    ↓
Configurar
    ↓
Validar
    ↓
Avançar
```

Uma fase não é considerada concluída apenas porque seus comandos foram executados.


## Perfil inicial de hardware

O primeiro perfil suportado pelo projeto é:

```text
profiles/dell-latitude-e5470/
```

Hardware previsto:

* Dell Latitude E5470;
* firmware UEFI;
* SSD dedicado ao Arch Linux;
* Intel HD Graphics 520;
* AMD Radeon R7 M360;
* Wi-Fi Qualcomm Atheros;
* Bluetooth integrado;
* processador Intel x86-64.

Não haverá dual boot.

A GPU Intel integrada será utilizada como padrão.

A GPU AMD dedicada poderá permanecer disponível para uso sob demanda, desde que isso não prejudique estabilidade, consumo de energia ou suspensão do sistema.

## Armazenamento

O disco utilizará uma tabela de partições GPT.

A estrutura inicial será:

```text
Disco
├── EFI System Partition
│   ├── FAT32
│   └── 1 GiB
│
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

## Subvolumes Btrfs

Os subvolumes planejados são:

| Subvolume    | Montagem                | Responsabilidade                   |
| ------------ | ----------------------- | ---------------------------------- |
| `@`          | `/`                     | Sistema raiz                       |
| `@home`      | `/home`                 | Dados e configurações dos usuários |
| `@var`       | `/var`                  | Dados variáveis do sistema         |
| `@var_log`   | `/var/log`              | Logs                               |
| `@var_cache` | `/var/cache`            | Cache geral                        |
| `@pkg`       | `/var/cache/pacman/pkg` | Cache de pacotes do Pacman         |
| `@docker`    | `/var/lib/docker`       | Dados do Docker                    |
| `@snapshots` | `/.snapshots`           | Snapshots do Snapper               |

As opções de montagem deverão incluir:

```text
compress=zstd:3
```

Outras opções somente serão adicionadas após justificativa técnica e validação.

## Estratégia de snapshots

O Snapper será utilizado para snapshots do sistema.

Os snapshots deverão incluir o subvolume raiz:

```text
@
```

Os seguintes dados não participarão dos snapshots do sistema:

* diretórios pessoais;
* dados do Docker;
* logs;
* caches;
* cache de pacotes.

O objetivo é permitir rollback do sistema sem misturar dados mutáveis, pessoais ou volumosos.

Snapshots não substituem backup.

## Inicialização

A inicialização utilizará:

* UEFI;
* systemd-boot;
* kernel Linux;
* initramfs;
* desbloqueio do volume LUKS2 durante o boot.

Secure Boot permanecerá desabilitado na primeira versão.

Sua adoção futura deverá ser registrada em um novo ADR.

## Sistema operacional

A distribuição base será Arch Linux.

O sistema deverá permanecer próximo das recomendações oficiais da Arch Wiki, evitando camadas desnecessárias e ferramentas sem manutenção ativa.

A instalação inicial utilizará apenas pacotes dos repositórios oficiais.

Pacotes do AUR deverão ser avaliados individualmente e exigirão uma decisão documentada quando forem essenciais.

## Ambiente gráfico

A sessão gráfica utilizará Wayland com Hyprland.

Componentes principais:

* Hyprland como compositor;
* Waybar como barra de status;
* Kitty como terminal;
* Rofi como launcher;
* SwayNC para notificações;
* Hyprlock para bloqueio;
* Hypridle para controle de inatividade;
* Thunar como gerenciador de arquivos;
* PipeWire para áudio;
* NetworkManager para rede;
* BlueZ para Bluetooth.

As configurações do usuário serão gerenciadas pelo repositório de dotfiles.

## Ambiente de desenvolvimento

O host deverá conter apenas as ferramentas fundamentais para operação da workstation:

* Git;
* Docker;
* Docker Compose;
* Visual Studio Code;
* OpenSSH.

SDKs, linguagens, CLIs e dependências específicas de projetos deverão ser instalados preferencialmente em Dev Containers.

Exemplos:

* .NET;
* Node.js;
* Terraform;
* kubectl;
* Helm;
* AWS CLI;
* ferramentas Python específicas de projetos.

Essa separação reduz conflitos de versões e facilita a reprodução dos ambientes de desenvolvimento.

## Dotfiles

As configurações pessoais serão armazenadas em um repositório separado e gerenciadas com chezmoi.

O repositório `linux-workstation` será responsável pelo sistema e pelo bootstrap do chezmoi.

O repositório de dotfiles será responsável pelas configurações do usuário.

Essa separação preserva os limites entre infraestrutura da máquina e preferências pessoais.

## Automação

A automação deverá ser adicionada somente após o procedimento manual correspondente estar entendido e documentado.

Os scripts deverão:

* utilizar Bash;
* iniciar com `set -Eeuo pipefail`;
* validar pré-requisitos;
* produzir mensagens claras;
* falhar de forma explícita;
* ser idempotentes sempre que possível;
* exigir confirmação forte antes de ações destrutivas;
* referenciar os ADRs relacionados.

Nenhum script deverá assumir silenciosamente o disco, usuário, interface de rede ou UUID corretos.

## Validação

O diretório `tests/` conterá scripts de verificação do estado da workstation.

Os testes poderão validar:

* boot;
* armazenamento;
* criptografia;
* Btrfs;
* snapshots;
* rede;
* áudio;
* Bluetooth;
* GPU;
* Docker;
* Hyprland;
* serviços;
* segurança.

Esses testes não substituem testes de software tradicionais. Eles validam a configuração e o funcionamento da workstation.

## Fluxo de mudança

Mudanças relevantes deverão seguir este fluxo:

```text
Necessidade
    ↓
ADR ou atualização de decisão
    ↓
Documentação
    ↓
Implementação
    ↓
Validação
    ↓
Changelog
```

Mudanças pequenas que não alteram decisões arquiteturais podem dispensar um novo ADR, mas ainda devem atualizar a documentação e os testes aplicáveis.

## Limites da primeira versão

A primeira versão não incluirá:

* Secure Boot;
* desbloqueio automático por TPM2;
* suporte a múltiplas distribuições;
* suporte a BIOS legado;
* dual boot;
* helper de AUR;
* instalação completa sem supervisão;
* gerenciamento centralizado de segredos;
* backup remoto automatizado.

Esses itens poderão ser adicionados posteriormente por meio do roadmap e de novos ADRs.

## Lições aprendidas

Nenhuma até o momento.
