---
title: Roadmap
version: 2.3
status: Stable
author: Rafael
last_review: 2026-08-14
related:
  - ADR-0002
  - ADR-0012
  - architecture.md
---

# Roadmap

## Objetivo

Este documento registra a evolução planejada do projeto `linux-workstation` sem misturar intenção futura com estado já validado.

Itens listados aqui representam direção arquitetural e prioridades, não garantia de implementação.

## Estado atual

A fundação estrutural está consolidada. As fases 01, 02, 03 e 04 possuem implementação e validações versionadas; a fase 04 também foi exercitada na workstation com seus checks manuais concluídos.

A Milestone 5 — Repository Automation está em andamento. O primeiro runner de alto nível orientado por `profile.yaml` e `phase.yaml` já foi iniciado, sem substituir a lógica dos steps individuais.

O repositório já possui fontes compartilhadas em `packages/`, `system/` e `dotfiles/`, bibliotecas reutilizáveis em `scripts/lib/` e gates em `tests/`.

## Milestone 1 — Base Arch Installation ✅

Objetivo: realizar a instalação base do Arch Linux com UEFI, GPT, LUKS2, Btrfs e systemd-boot.

Escopo implementado:

* preparação e particionamento do disco;
* LUKS2;
* Btrfs e subvolumes;
* montagem;
* sistema base;
* fstab;
* chroot;
* timezone, locale e hostname;
* usuário e sudo;
* initramfs;
* systemd-boot;
* first boot.

Critério: sistema inicializa corretamente e a fase passa em sua validação aplicável.

## Milestone 2 — Base System ✅

Objetivo: transformar a instalação mínima em uma workstation operacional sem desktop.

Escopo implementado:

* atualização e configuração do Pacman;
* microcode;
* systemd e timesyncd;
* journald;
* ZRAM;
* TRIM;
* NetworkManager e Bluetooth;
* OpenSSH;
* pacotes base;
* validação de runtime.

Critério: serviços e baseline do sistema passam no gate da fase 02.

## Milestone 3 — Desktop Environment ✅

Objetivo: construir um desktop Wayland funcional e autenticado.

Escopo implementado:

* stack gráfico Intel/AMD;
* Hyprland;
* Waybar;
* Hyprlock e Hypridle;
* Rofi;
* SwayNC;
* Kitty;
* Thunar;
* fontes e aparência;
* greetd + tuigreet;
* validação do desktop.

Critério: login gráfico e sessão desktop passam no gate da fase 03.

## Milestone 4 — Development Environment ✅

Objetivo: preparar a workstation para desenvolvimento sem transformar o host em ambiente específico de linguagem.

Escopo validado:

* Git e identidade local;
* GitHub via SSH;
* Zsh, Oh My Zsh e Starship;
* Visual Studio Code oficial da Microsoft;
* terminal Zsh integrado ao VS Code;
* Docker Engine, Compose e Buildx;
* Dev Containers com runtime de projeto isolado do host;
* ferramentas CLI globais;
* Codex CLI com autenticação e tarefa controlada;
* gates estático e de runtime.

Critério concluído em 2026-08-14: `07-development-validation` passou e os checks manuais documentados foram exercitados na workstation.

## Milestone 5 — Repository Automation 🟡

Objetivo: elevar a automação já existente para uma experiência de reconstrução e operação mais integrada.

Parte significativa da automação de fases já existe; esta milestone agora coordena esses artefatos como um sistema, conforme ADR-0012.

Implementado até agora:

* runner `scripts/workstation`;
* descoberta das fases pelo `profile.yaml`;
* descoberta dos steps pelo `phase.yaml`;
* resolução de modos e entrypoints;
* execução explícita de um step sem automatizar confirmações destrutivas;
* parser mínimo de manifests sem dependência de Python, Node.js ou `yq`;
* comandos convenientes via `Makefile`;
* teste estático inicial do runner.

Próximos incrementos:

* validar o runner na workstation;
* adicionar execução supervisionada de uma fase completa;
* persistir estado mínimo para retomada segura;
* integrar gates pré e pós-fase;
* adicionar bootstrap de alto nível e descoberta/seleção de profile;
* adicionar testes de idempotência;
* integrar o `chezmoi` quando adotado operacionalmente;
* adicionar CI para gates estáticos e consistência do repositório.

Critério: uma nova instalação pode ser conduzida a partir da ISO e do repositório com somente as intervenções indispensáveis e sem exigir conhecimento dos scripts internos.

## Milestone 6 — Operations

Objetivo: manter a workstation durante todo seu ciclo de vida.

Escopo planejado:

* manutenção periódica;
* atualização de pacotes;
* health checks;
* snapshots e revisão de retenção;
* backup;
* recuperação;
* disaster recovery;
* validação operacional.

Critério: manutenção e recuperação possuem procedimentos reproduzíveis e testados.

## Milestone 7 — Security

Objetivo: elevar a postura de segurança sem sacrificar recuperabilidade.

Escopo planejado:

* gestão de segredos;
* revisão de SSH hardening;
* GPG quando houver caso de uso;
* revisão de criptografia do disco;
* Secure Boot;
* TPM2, se aprovado em ADR;
* hardware token opcional;
* validação de segurança.

Critério: controles aprovados estão documentados, implementados e verificáveis.

## Backlog

Itens aprovados para avaliação futura, sem prioridade atual:

* benchmark da workstation;
* instalação com menos interação;
* CI mais completa;
* geração automática de índices/documentação;
* backup remoto;
* gerenciamento de segredos;
* sincronização opcional de configurações;
* expansão de `examples/` com casos realmente reutilizáveis.

## Ideias em avaliação

Exigem decisão arquitetural antes de implementação:

* suporte geral ao AUR;
* Nix;
* systemd-homed;
* Podman;
* Flatpak;
* Distrobox;
* Bcachefs;
* TPM unlock;
* measured boot;
* compositor Wayland alternativo;
* múltiplos bootloaders.

## Fora do escopo da geração atual

* BIOS legado;
* dual boot;
* múltiplas distribuições;
* profile universal para qualquer hardware;
* ambientes de linguagem específicos instalados globalmente;
* personalização estética avançada;
* catálogo de aplicações de uso geral, mídia ou jogos.

## Critérios para inclusão

Antes de promover uma ideia para trabalho ativo:

1. Qual problema resolve?
2. Pertence à milestone atual?
3. Existe alternativa mais simples?
4. Introduz dependência ou complexidade permanente?
5. Exige ADR?
6. Como será validada?

Se não pertencer à milestone atual, permanece no roadmap.

## Revisão

Este é um documento vivo. O status deve refletir validação real, não apenas existência de código no repositório.

## Lições aprendidas

Marcar separadamente “implementado” e “validado” evita que o roadmap declare uma capacidade pronta antes de ela ser exercitada na máquina real.
