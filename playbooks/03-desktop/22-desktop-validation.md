---
title: Validar desktop
version: 1.2
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

Reinicie a workstation e confirme o fluxo definido pela ADR-0008:

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

Confirme que não existe autologin da conta pessoal e que a sessão é executada como o usuário autenticado.

## 2. Validar a configuração do Hyprland

Execute:

```text
hyprctl version
hyprctl configerrors
hyprctl monitors
hyprctl devices
hyprctl binds
```

`hyprctl configerrors` deverá retornar `ok` ou ausência de erros, conforme a versão instalada.

Confirme que o arquivo principal carrega os fragments esperados:

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

Confirme a execução dos componentes configurados em `50-autostart.conf`, incluindo quando aplicável:

```text
Waybar
Hypridle
SwayNC
mecanismo de wallpaper
```

Não devem existir processos duplicados decorrentes de entradas concorrentes.

## 4. Validar Waybar

Confirme que:

* a barra ocupa corretamente o output;
* workspaces ficam à esquerda;
* janela ativa fica ao centro;
* status do sistema fica à direita;
* não existem erros de parsing JSONC.

## 5. Validar bloqueio e ciclo de vida

Teste Hyprlock manualmente e confirme autenticação e retorno à sessão.

Valide os eventos definidos pelo Hypridle, incluindo bloqueio automático, gerenciamento do monitor, suspensão e retomada.

## 6. Validar launcher e notificações

Confirme que:

* Rofi abre sem bindings duplicados;
* aplicações podem ser localizadas e iniciadas;
* SwayNC recebe notificações;
* o histórico e a central estão acessíveis.

## 7. Validar aplicações fundamentais

Teste Kitty e Thunar e confirme os atalhos globais configurados em `70-keybindings.conf`.

## 8. Validar aparência

Revise Hyprland, Waybar, Hyprlock, Rofi, SwayNC, Kitty, Thunar e aplicações GTK em conjunto.

Confirme tema, ícones, cursor, tipografia, wallpaper, contraste e legibilidade.

## 9. Revisar logs

Analise logs da sessão e dos serviços relacionados, incluindo `greetd`.

Erros críticos ou recorrentes deverão ser investigados antes de avançar.

## 10. Registrar o resultado

Registre o resultado objetivo da validação e as pendências conhecidas.

Warnings aceitos devem ser documentados. Falhas obrigatórias impedem o avanço.

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

Revise `20-install-session-login.md` e `21-configure-session-login.md`, remova autologin e elimine inicialização automática via perfil do shell.

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

A validação final deve usar o estado real da sessão, e não apenas a existência de arquivos. Erros de compatibilidade do Hyprland, parsing da Waybar, bindings do Rofi e autenticação da sessão só podem ser considerados resolvidos após validação integrada.
