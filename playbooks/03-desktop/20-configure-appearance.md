---
title: Configurar aparência
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

---

# 20 — Configurar aparência

## Objetivo

Configurar a identidade visual da sessão gráfica, garantindo consistência entre compositor, aplicações GTK e componentes já configurados do desktop.

Este playbook não instala temas, ícones, cursores ou outros pacotes. Recursos ausentes devem ser tratados pela etapa de instalação apropriada conforme a ADR-0006.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Stack tipográfica instalada.
* Componentes funcionais do desktop instalados e configurados.
* Tema, ícones, cursor e mecanismo de wallpaper escolhidos já disponíveis no sistema.

---

# Resultado esperado

Ao concluir este playbook:

* a identidade visual da workstation estará definida;
* GTK 3 e GTK 4 utilizarão configurações coerentes;
* ícones e cursor estarão configurados;
* o plano de fundo será carregado pela sessão;
* o Hyprland utilizará `80-appearance.conf`;
* nenhuma capacidade funcional anterior será reconfigurada indevidamente.

---

# Procedimento

## 1. Definir a baseline visual

Estabeleça paleta, tipografia, espaçamento, bordas, cantos, transparência e contraste.

## 2. Configurar o Hyprland

Utilize:

```text
~/.config/hypr/conf.d/80-appearance.conf
```

Mantenha nesse arquivo apenas parâmetros visuais.

## 3. Configurar GTK

Configure os arquivos de usuário apropriados para GTK 3 e GTK 4 utilizando recursos já instalados.

## 4. Configurar ícones e cursor

Selecione tema e tamanho já disponíveis no sistema e mantenha as variáveis necessárias no fragmento de ambiente quando aplicável.

## 5. Configurar o wallpaper

Configure o mecanismo de wallpaper já instalado e registre sua inicialização em:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

## 6. Integrar os componentes

Aplique a identidade visual a Waybar, Hyprlock, Rofi, SwayNC, Kitty e Thunar sem alterar suas responsabilidades funcionais.

## 7. Validar

Confirme consistência entre aplicações Wayland, XWayland e componentes do desktop.

---

# Verificação

Confirme que:

* `80-appearance.conf` é carregado pelo Hyprland;
* temas, ícones e cursor são aplicados;
* wallpaper é carregado;
* os componentes permanecem funcionais;
* `hyprctl configerrors` permanece limpo;
* nenhum pacote foi instalado silenciosamente por esta etapa.

---

# Próximo playbook

```text
21-configure-session-login.md
```

---

# Referências

* Arch Wiki — Uniform look for Qt and GTK applications
* Arch Wiki — Cursor themes
* Arch Wiki — Icons
* Arch Wiki — Fonts
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

A etapa de aparência deve permanecer estritamente configuracional. Instalar recursos durante essa fase ocultaria dependências e quebraria a separação entre instalação e configuração estabelecida pelo projeto.
