

---

title: Roadmap
version: 2.0
status: Stable
author: Rafael
last_review: 2026-07-30
related:

* ADR-0002
* architecture.md

---

# Roadmap

## Objetivo

Este documento descreve a evolução planejada do projeto `linux-workstation`.

O roadmap registra funcionalidades, melhorias e iniciativas futuras sem interromper a implementação em andamento.

Itens listados aqui representam intenções, não compromissos.

---

# Estado atual

## Versão atual

```text
v0.2.0
```

Situação:

* Fundação do projeto concluída.
* Arquitetura definida.
* ADRs iniciais aprovados.
* Estrutura do repositório criada.
* Documentação principal em desenvolvimento.
* Foundation concluída.
* Installation concluída.
* System concluído.
* Desktop concluído.
* Development concluído.
* Documentação alinhada à arquitetura.

A workstation já está apta para desenvolvimento de software utilizando ambientes reproduzíveis baseados em contêineres.

---

# Milestone 1 — Base Arch Installation ✅

Objetivo:

Realizar uma instalação manual completa do Arch Linux seguindo a documentação oficial.

Escopo:

* Preparação do disco
* GPT
* EFI
* LUKS2
* Btrfs
* Subvolumes
* Montagem
* Pacstrap
* fstab
* Chroot
* Kernel
* Microcode
* Locale
* Timezone
* Hostname
* Usuário
* sudo
* systemd-boot
* Boot funcional

Critério de conclusão:

O sistema inicializa corretamente até um terminal de login.

---

# Milestone 2 — Base System ✅

Objetivo:

Transformar a instalação mínima em uma workstation utilizável.

Escopo:

* NetworkManager
* PipeWire
* BlueZ
* OpenSSH
* fstrim.timer
* Snapper
* Pacman configuration
* Ferramentas essenciais
* Atualizações

Critério de conclusão:

Sistema totalmente operacional sem interface gráfica.

---

# Milestone 3 — Desktop Environment ✅

Objetivo:

Construir o ambiente gráfico Wayland.

Escopo:

* Hyprland
* Waybar
* Kitty
* Rofi
* SwayNC
* Hyprlock
* Hypridle
* Thunar
* Fontes
* Temas mínimos

Critério de conclusão:

Login gráfico funcional e ambiente utilizável.

---

# Milestone 4 — Development Environment ✅

Objetivo:

Preparar a workstation para desenvolvimento de software.

Escopo:

* Docker
* Docker Compose
* VS Code
* Dev Containers
* Git
* SSH
* chezmoi

Critério de conclusão:

Projetos podem ser desenvolvidos utilizando containers sem instalar SDKs diretamente no host.

---

# Milestone 5 — Automation

Objetivo:

Automatizar os procedimentos documentados e validados, permitindo reconstruir a workstation diretamente a partir do repositório.

Escopo:

* scripts de instalação;
* bootstrap da workstation;
* seleção de perfil;
* listas declarativas de pacotes;
* aplicação das configurações do sistema;
* integração com o repositório de dotfiles;
* validações automáticas;
* testes de idempotência;
* confirmações fortes para operações destrutivas.

Critério de conclusão:

Uma nova instalação pode ser realizada a partir da ISO oficial do Arch Linux, utilizando o repositório e exigindo apenas as intervenções indispensáveis, como seleção do disco, credenciais e confirmação de ações destrutivas.

---

# Milestone 6 — Operations

Objetivo:

Operar, manter e recuperar a workstation durante todo o seu ciclo de vida.

Escopo:

* Backup
* System Maintenance
* Package Management
* System Upgrades
* Health Check
* Recovery
* Disaster Recovery
* Operations Validation

Critério de conclusão:

A workstation pode ser mantida e recuperada de forma reproduzível durante todo seu ciclo de vida.

---

# Milestone 7 — Security

Objetivo:

Aumentar a segurança e confiabilidade.

Escopo:

* Secrets Management
* GPG
* SSH Hardening
* YubiKey (optional)
* Disk Encryption Review
* Security Validation

Critério de conclusão:

A workstation segue as práticas de segurança adotadas pelo projeto.

---

# Backlog

Ideias aprovadas, mas sem prioridade definida.

* Suporte ao AUR
* Benchmark da workstation
* Instalação sem interação
* Integração contínua mais completa
* Verificação automática de documentação
* Geração automática de índice da documentação
* Backup remoto
* Gerenciamento de segredos
* Sincronização opcional de configurações

---

# Ideias em avaliação

Estas propostas ainda não possuem decisão arquitetural.

* Nix
* systemd-homed
* Podman
* Flatpak
* Distrobox
* Bcachefs
* TPM unlock
* Boot medido
* Wayland alternativo
* Múltiplos bootloaders

Nenhuma delas deverá ser implementada antes da criação de um ADR correspondente.

---

# Fora do escopo

A primeira geração do projeto não pretende oferecer:

* suporte a BIOS legado;
* dual boot;
* múltiplas distribuições Linux;
* instalação universal para qualquer hardware;
* configuração automática de ambientes de desenvolvimento específicos;
* personalização estética avançada.
* aplicações de uso geral (office, media, gaming etc.);
* SDKs e runtimes específicos de projetos instalados diretamente no host;
* ambientes de desenvolvimento específicos de linguagens;

---

# Critérios para inclusão

Antes de adicionar uma nova funcionalidade ao roadmap, responder:

1. Qual problema ela resolve?
2. Ela é necessária para a milestone atual?
3. Existe uma alternativa mais simples?
4. Ela aumenta a complexidade do projeto?
5. Exige um novo ADR?

Se a resposta à segunda pergunta for "não", a funcionalidade deve permanecer no roadmap até o momento adequado.

---

# Revisão

O roadmap é um documento vivo.

Mudanças são esperadas conforme o projeto evolui, desde que respeitem a arquitetura definida e os princípios estabelecidos nos ADRs.

---

# Lições aprendidas

Registrar ideias futuras em um roadmap permite manter o foco na implementação atual sem perder oportunidades de evolução.
