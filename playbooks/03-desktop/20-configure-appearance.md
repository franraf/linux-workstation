---
title: Configurar aparência
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
* ADR-0009
* ADR-0010

---

# 20 — Configurar aparência

## Objetivo

Configurar a identidade visual da sessão gráfica, garantindo consistência entre compositor, aplicações GTK e componentes já configurados do desktop.

Este playbook não instala temas, ícones, cursores, fontes ou outros pacotes. Recursos ausentes devem ser tratados pela etapa de instalação apropriada conforme a ADR-0006.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Stack tipográfica instalada.
* Componentes funcionais do desktop instalados e configurados.
* Recursos visuais utilizados pela baseline já disponíveis no sistema.

---

# Resultado esperado

Ao concluir este playbook:

* a identidade visual da workstation estará definida;
* GTK 3 e GTK 4 utilizarão configurações coerentes;
* ícones e cursor utilizarão a baseline Adwaita;
* Hyprland carregará `modules/80-appearance.lua`;
* Waybar, Rofi, SwayNC e Kitty compartilharão a mesma linguagem visual;
* nenhuma capacidade funcional anterior será reconfigurada indevidamente;
* nenhum pacote será instalado por esta etapa.

---

# Baseline visual

A baseline inicial utiliza:

```text
background: #1a1b26
surface:    #24283b
foreground: #c0caf5
accent:     #7aa2f7
muted:      #565f89
error:      #f7768e
```

Tipografia:

```text
interface: Noto Sans
terminal/UI técnica: JetBrainsMono Nerd Font
```

Cursor e ícones:

```text
Adwaita
```

---

# Procedimento

## 1. Configurar o Hyprland

Utilize a fonte canônica:

```text
system/hyprland/modules/80-appearance.lua
```

que será instalada em:

```text
~/.config/hypr/modules/80-appearance.lua
```

Mantenha nesse módulo apenas parâmetros visuais, utilizando a API Lua da versão do Hyprland adotada pelo projeto.

A baseline define gaps, bordas, arredondamento, sombra, blur, animações e uma cor sólida de fundo do compositor.

Um wallpaper baseado em imagem poderá ser introduzido posteriormente como capacidade explícita, sem tornar este playbook dependente de um arquivo externo não versionado.

## 2. Configurar GTK

Utilize:

```text
system/gtk-3.0/settings.ini
system/gtk-4.0/settings.ini
```

para tipografia, cursor, ícones e preferência de interface escura.

## 3. Configurar Waybar

Aplique a identidade visual exclusivamente por:

```text
system/waybar/style.css
```

sem alterar a distribuição funcional dos módulos definida pelo playbook 13.

## 4. Configurar Rofi

Mantenha comportamento em:

```text
system/rofi/config.rasi
```

e aparência em:

```text
system/rofi/theme.rasi
```

O `config.rasi` deverá carregar o tema sem redefinir bindings internos.

## 5. Configurar SwayNC

Mantenha comportamento em `config.json` e aparência em:

```text
system/swaync/style.css
```

## 6. Configurar Kitty

Mantenha a aparência em:

```text
system/kitty/appearance.conf
```

separada de `behavior.conf` e `keybindings.conf`.

## 7. Validar

Confirme consistência entre aplicações e valide a configuração do Hyprland na sessão gráfica.

---

# Verificação

Confirme que:

* `80-appearance.lua` é carregado pelo Hyprland;
* GTK 3 e GTK 4 utilizam a baseline esperada;
* cursor e ícones estão coerentes;
* Waybar, Rofi, SwayNC e Kitty possuem identidade visual consistente;
* `hyprctl configerrors` permanece limpo;
* nenhum pacote foi instalado silenciosamente por esta etapa.

---

# Próximo playbook

```text
21-configure-session-login.md
```

---

# Referências

* Documentação oficial do Hyprland
* Documentação oficial do Rofi
* Arch Wiki — Uniform look for Qt and GTK applications
* Arch Wiki — Cursor themes
* Arch Wiki — Icons
* Arch Wiki — Fonts
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração
* ADR-0009 — Artefatos compartilhados e perfis de hardware
* ADR-0010 — Configuração do Hyprland em Lua

---

# Lições aprendidas

A aparência deve permanecer estritamente configuracional. Recursos visuais precisam existir antes desta etapa, e a configuração do Hyprland deve acompanhar a API Lua da versão realmente adotada pelo projeto em vez de traduzir mecanicamente a sintaxe antiga.
