---
title: Validar desktop
version: 1.3
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005
* ADR-0006
* ADR-0008

---

# 22 — Validar desktop

## Objetivo

Validar que todas as capacidades da fase `03-desktop` estão operacionais, integradas e coerentes com a arquitetura antes de iniciar `04-development`.

Este playbook é um gate de fase. Ele não deve corrigir configuração automaticamente; falhas devem direcionar o mantenedor ao playbook responsável.

A fase segue a sequência estrutural:

```text
01–11  instalar todas as capacidades
12–21  configurar todas as capacidades
22     validar a integração final
```

---

# Pré-requisitos

* Todos os playbooks anteriores da fase `03-desktop` concluídos.
* Login manager instalado e configurado.
* Sessão gráfica autenticada e em execução.
* Configurações aplicadas a partir do repositório.

---

# Resultado esperado

Ao concluir este playbook:

* autenticação e inicialização gráfica estarão validadas;
* Hyprland não apresentará erros de configuração;
* componentes de autostart estarão em execução;
* atalhos globais estarão funcionais;
* aparência e aplicações fundamentais estarão integradas;
* nenhuma falha obrigatória impedirá o início da fase seguinte.

---

# Procedimento

## 1. Validar autenticação e inicialização da sessão

Reinicie a workstation e confirme:

```text
boot
  ↓
greetd
  ↓
tuigreet
  ↓
autenticação
  ↓
start-hyprland
  ↓
Hyprland
```

Confirme que não existe autologin da conta pessoal.

## 2. Validar a configuração do Hyprland

Execute:

```text
hyprctl version
hyprctl configerrors
hyprctl monitors
hyprctl devices
hyprctl binds
```

`hyprctl configerrors` deverá retornar `ok` ou ausência de erros.

Confirme os fragments:

```text
10-environment.conf
20-monitor.conf
30-input.conf
40-general.conf
50-autostart.conf
60-session-lock.conf
70-keybindings.conf
80-appearance.conf
```

## 3. Validar componentes de autostart

Confirme Waybar, Hypridle, SwayNC e mecanismo de wallpaper quando aplicável, sem processos duplicados.

## 4. Validar Waybar

Confirme largura correta, workspaces à esquerda, janela ativa ao centro, status à direita e ausência de erros JSONC.

## 5. Validar bloqueio e ciclo de vida

Teste Hyprlock, Hypridle, suspensão e retomada.

## 6. Validar launcher e notificações

Confirme que Rofi abre sem bindings duplicados e que SwayNC recebe notificações e mantém histórico.

## 7. Validar aplicações fundamentais

Teste Kitty e Thunar e os atalhos globais configurados em `70-keybindings.conf`.

## 8. Validar aparência

Revise Hyprland, Waybar, Hyprlock, Rofi, SwayNC, Kitty, Thunar e aplicações GTK em conjunto.

## 9. Revisar logs

Analise logs da sessão e dos serviços relacionados, incluindo `greetd`.

## 10. Registrar o resultado

Registre pendências conhecidas. Falhas obrigatórias impedem o avanço.

---

# Verificação

A fase poderá ser considerada concluída somente quando:

* o login exigir autenticação;
* `greetd` estiver habilitado e operacional;
* Hyprland iniciar normalmente após autenticação;
* `hyprctl configerrors` estiver limpo;
* Waybar, Hypridle e SwayNC estiverem operacionais;
* o wallpaper estiver carregado quando configurado;
* Hyprlock funcionar;
* Rofi não apresentar conflitos de bindings;
* Kitty e Thunar funcionarem;
* atalhos globais estiverem registrados uma única vez;
* a aparência permanecer coerente;
* não existirem erros críticos que impeçam uso normal.

---

# Problemas comuns

## Hyprland apresenta erros de configuração

Utilize `hyprctl configerrors` e `hyprctl getoption` para localizar a opção incompatível. Corrija o playbook e o script responsáveis, não apenas o arquivo local.

## Waybar não aparece

Execute `waybar` manualmente e corrija primeiro erros de parsing. Depois valide sua entrada em `50-autostart.conf`.

## Rofi exibe bindings duplicados

Compare `rofi -list-keybindings` com `~/.config/rofi/config.rasi` e remova redefinições conflitantes na fonte versionada.

## Sessão inicia sem autenticação

Revise `11-install-session-login.md` e `21-configure-session-login.md`, remova autologin e elimine inicialização automática via perfil do shell.

---

# Próximo playbook

Somente após aprovação deste gate:

```text
04-development/
01-version-control.md
```

---

# Referências

* Architecture Overview
* Playbooks da fase `03-desktop`
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração
* ADR-0008 — Autenticação e inicialização da sessão gráfica

---

# Lições aprendidas

A validação final deve usar o estado real da sessão. A fase deve manter a ordem arquitetural `instalar tudo → configurar tudo → validar tudo` para reduzir dependências circulares e tornar a automação previsível.
