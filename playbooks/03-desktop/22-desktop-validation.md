---
title: Validar desktop
version: 1.4
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005
* ADR-0006
* ADR-0008
* ADR-0009
* ADR-0010

---

# 22 — Validar desktop

## Objetivo

Validar que todas as capacidades da fase `03-desktop` estão operacionais, integradas e coerentes com a arquitetura antes de iniciar `04-development`.

Este playbook é um gate de fase. Ele não corrige configuração automaticamente; falhas devem direcionar o mantenedor ao playbook responsável.

A fase segue:

```text
01–11  instalar todas as capacidades
12–21  configurar todas as capacidades
22     validar a integração final
```

---

# Pré-requisitos

* Todos os playbooks anteriores concluídos.
* Login via `greetd` e `tuigreet` configurado.
* Sessão Hyprland autenticada e em execução.
* Configurações aplicadas a partir do repositório.

---

# Automação

Os testes reutilizáveis ficam em:

```text
tests/desktop/
├── static-config.sh
└── runtime-session.sh
```

O profile apenas orquestra o gate:

```text
profiles/dell-latitude-e5470/03-desktop/22-desktop-validation/run.sh
```

Execute como o usuário autenticado, dentro da sessão Hyprland:

```bash
bash ./run.sh
```

Não execute este gate como `root`.

---

# Validação automática

## Configuração estática

`static-config.sh` confirma:

* `~/.config/hypr/hyprland.lua` presente;
* ausência de `hyprland.conf` legado ativo;
* módulos Lua `10` a `80` presentes;
* bindings globais obrigatórios presentes;
* `SUPER + Q` registrado para fechamento de janela;
* `SUPER + setas` registrados para navegação direcional;
* Waybar, Hypridle e SwayNC registrados uma única vez no autostart;
* arquivos essenciais de Waybar, Hyprlock, Hypridle, Rofi, SwayNC e Kitty presentes;
* Waybar sem largura fixa.

## Sessão em execução

`runtime-session.sh` confirma:

```text
hyprctl configerrors
hyprctl monitors
hyprctl devices
hyprctl binds
```

Também exige exatamente um processo de:

```text
waybar
hypridle
swaync
```

e confirma que `greetd.service` está habilitado.

---

# Validação manual obrigatória

Após os testes automáticos, confirme:

* `SUPER + Q` fecha a janela ativa;
* `SUPER + setas` move o foco entre janelas;
* `SUPER + L` bloqueia a sessão e a autenticação funciona;
* `SUPER + SPACE` abre o Rofi sem conflitos de bindings;
* `SUPER + N` abre e fecha a central do SwayNC;
* `notify-send` gera notificação e histórico;
* `SUPER + RETURN` abre o Kitty;
* clipboard, Unicode, Nerd Font e emoji funcionam no Kitty;
* `SUPER + E` abre o Thunar;
* lixeira, miniaturas e dispositivos removíveis funcionam no Thunar;
* suspensão, retomada e DPMS seguem a política do Hypridle;
* aparência permanece consistente entre Hyprland, Waybar, Hyprlock, Rofi, SwayNC, Kitty e aplicações GTK.

---

# Login e recuperação

Após pelo menos um reboot completo, confirme o fluxo:

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

A conta pessoal não deve possuir autologin. Outro TTY deve permanecer disponível para recuperação.

---

# Critério de aprovação

A fase `03-desktop` pode ser encerrada somente quando os testes automáticos passam e todas as verificações manuais obrigatórias foram confirmadas.

Falhas devem ser corrigidas na fonte versionada (`system/`, `packages/`, `scripts/lib/` ou profile responsável), nunca apenas no arquivo local da workstation.

---

# Próximo playbook

Somente após aprovação deste gate:

```text
04-development/
01-version-control.md
```

---

# Lições aprendidas

A validação final deve observar o estado real da sessão. Testes reutilizáveis pertencem a `tests/`; o profile do passo 22 apenas coordena o gate e não deve alterar a máquina para fazê-la passar.
