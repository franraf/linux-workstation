---
title: Roadmap
version: 2.8
status: Stable
author: Rafael
last_review: 2026-08-18
related:
  - ADR-0002
  - ADR-0012
  - ADR-0013
  - ADR-0014
  - architecture.md
---

# Roadmap

## Objetivo

Este documento registra a evolução planejada do projeto `linux-workstation` sem misturar intenção futura com estado já validado.

Itens listados aqui representam direção arquitetural e prioridades, não garantia de implementação.

## Estado atual

A fundação estrutural está consolidada. As fases 01, 02, 03 e 04 possuem implementação e validações versionadas e foram exercitadas na workstation real.

A Milestone 5 — Repository Automation está concluída. O runner de alto nível orientado por `profile.yaml` e `phase.yaml` suporta descoberta, status, planejamento, execução supervisionada, retomada persistente, gates pré/pós-fase, bootstrap seguro e testes de idempotência. A configuração de usuário do VS Code foi validada operacionalmente através do `chezmoi`, e os gates portáveis existentes são agregados por `make validate-portable` e executados no GitHub Actions.

O fluxo de reconstrução completa a partir da ISO será validado quando ocorrer uma instalação real. O projeto não executará uma reinstalação destrutiva artificial apenas para repetir um cenário já coberto por manifests, gates, retomada e validações locais.

A Milestone 6 — Operations está implementada em grande parte e exercitada na workstation real. Manutenção, atualização, health checks, snapshots/retenção, recuperação e disaster recovery possuem procedimentos e validações. O gate final permanece deliberadamente bloqueado porque o backup externo exige hardware dedicado ainda indisponível.

O trabalho de implementação pode avançar para a Milestone 7 — Security sem declarar Operations validada prematuramente.

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
* gates estático e de runtime;
* `chezmoi` aplicando e validando configuração versionada do VS Code.

Critério concluído em 2026-08-14: `07-development-validation` passou, os checks manuais documentados foram exercitados na workstation e a validação posterior com `chezmoi` terminou com 67 passes, zero warnings e zero falhas.

## Milestone 5 — Repository Automation ✅

Objetivo: elevar a automação já existente para uma experiência de reconstrução e operação mais integrada.

Escopo concluído:

* runner `scripts/workstation`;
* descoberta automática do profile quando existe apenas um;
* descoberta das fases pelo `profile.yaml`;
* descoberta dos steps pelo `phase.yaml`;
* resolução de modos e entrypoints;
* comando `status` com identificação da próxima fase;
* planejamento de fase completa;
* retomada explícita com `--from`;
* execução supervisionada sem automatizar confirmações destrutivas;
* bootstrap de alto nível que não executa fases apenas planejadas;
* estado persistente XDG e retomada segura via `resume`;
* gates pré e pós-fase orientados pelos manifests;
* testes de falha/retomada, incluindo falha no post-gate;
* testes de idempotência em ambiente controlado;
* parser mínimo de manifests sem dependência de Python, Node.js ou `yq`;
* comandos convenientes via `Makefile`;
* adoção operacional do `chezmoi` usando o próprio repositório como fonte canônica;
* validação real do estado aplicado pelo `chezmoi` na workstation;
* suíte agregada `make validate-portable`;
* CI no GitHub Actions executando consistência entre fases, gates estáticos de instalação/sistema/development e testes de automação.

Critério considerado atendido em 2026-08-14: a operação normal da workstation pode ser conduzida pela interface de alto nível do repositório sem conhecimento dos caminhos internos dos scripts. O `bootstrap` detecta o profile, reconhece as fases validadas e se recusa corretamente a executar fases apenas planejadas. Uma reconstrução integral a partir da ISO permanece como validação futura de campo, a ser realizada na próxima instalação real.

## Milestone 6 — Operations 🟡

Objetivo: manter a workstation durante todo seu ciclo de vida.

Escopo implementado/preparado:

* política de manutenção periódica;
* atualização supervisionada de pacotes;
* health checks;
* Snapper e política de retenção com dry-run e aplicação confirmada;
* backup preparado com Restic, aguardando HD/SSD externo dedicado;
* recuperação granular por snapshot e configuração canônica via Git validadas;
* disaster recovery documentado com bootstrap público e rota alternativa de mídia;
* gate operacional final definido.

Estado: implementação funcional avançada, porém **não validada como fase**. O requisito obrigatório de backup permanece pendente de hardware externo, primeiro backup, `restic check` e restauração de amostra.

Critério: manutenção e recuperação possuem procedimentos reproduzíveis e testados, incluindo restauração real de backup externo.

## Milestone 7 — Security 🟡

Objetivo: elevar a postura de segurança sem sacrificar recuperabilidade.

Escopo planejado:

* baseline de segurança não destrutivo;
* gestão de segredos;
* revisão de SSH hardening;
* revisão de criptografia do disco;
* Secure Boot;
* TPM2, se aprovado em ADR;
* hardware token opcional;
* GPG somente quando houver caso de uso concreto;
* validação de segurança.

Trabalho ativo: implementar `06-security`, começando por inventário/baseline somente leitura antes de qualquer hardening.

Critério: controles aprovados estão documentados, implementados e verificáveis.

## Backlog

Itens aprovados para avaliação futura, sem prioridade atual:

* benchmark da workstation;
* instalação com menos interação;
* CI mais completa;
* geração automática de índices/documentação;
* backup remoto;
* gerenciamento de segredos avançado;
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
