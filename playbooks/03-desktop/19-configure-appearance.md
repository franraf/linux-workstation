---
title: Configurar aparência
version: 1.1
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

# 19 — Configurar aparência

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
* o Hyprland utilizará um fragmento dedicado de aparência;
* nenhuma capacidade funcional anterior será reconfigurada indevidamente.

---

# Procedimento

## 1. Definir a baseline visual

Estabeleça paleta, tipografia, espaçamento, bordas, cantos, transparência e contraste.

A estética não deve comprometer legibilidade ou operação.

## 2. Configurar o Hyprland

Utilize o fragmento canônico:

```text
~/.config/hypr/conf.d/80-appearance.conf
```

Mantenha nesse arquivo apenas parâmetros visuais. Não inclua keybindings, autostart ou políticas de ciclo de vida.

## 3. Configurar GTK

Configure os arquivos de usuário apropriados para GTK 3 e GTK 4 utilizando recursos já instalados.

## 4. Configurar ícones e cursor

Selecione tema e tamanho já disponíveis no sistema e mantenha as variáveis necessárias no fragmento de ambiente quando aplicável.

## 5. Configurar o wallpaper

Configure o mecanismo de wallpaper já instalado e registre sua inicialização em:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

Não crie um segundo arquivo de autostart.

## 6. Integrar os componentes

Aplique a identidade visual a Waybar, Hyprlock, Rofi, SwayNC, Kitty e Thunar sem alterar suas responsabilidades funcionais.

## 7. Validar

Reinicie ou recarregue a sessão conforme necessário e confirme consistência entre aplicações Wayland, XWayland e componentes do desktop.

---

# Verificação

Confirme que:

* `80-appearance.conf` é carregado pelo Hyprland;
* temas, ícones e cursor são aplicados;
* wallpaper é carregado;
* Waybar, Rofi, SwayNC, Kitty, Thunar e Hyprlock permanecem funcionais;
* não existem erros em `hyprctl configerrors` relacionados à aparência;
* nenhum pacote foi instalado silenciosamente por esta etapa.

---

# Problemas comuns

## Recurso visual ausente

Não instale automaticamente durante a configuração. Retorne à etapa de instalação responsável e registre a dependência no repositório.

## Cursor inconsistente

Revise as variáveis da sessão e a configuração GTK sem duplicar responsabilidades.

## Wallpaper não inicia

Confirme o arquivo de configuração do mecanismo utilizado e sua entrada única em `50-autostart.conf`.

## Baixo contraste

Ajuste a baseline visual antes de concluir a fase.

---

# Próximo playbook

```text
20-desktop-validation.md
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
