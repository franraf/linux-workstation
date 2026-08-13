---
title: Configurar emulador de terminal
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

# 17 — Configurar emulador de terminal

## Objetivo

Configurar o Kitty como emulador de terminal da workstation, separando comportamento, teclado e aparência conforme a ADR-0005 e integrando o terminal aos atalhos globais da sessão.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Kitty instalado.
* Stack tipográfica instalada.

---

# Resultado esperado

Ao concluir este playbook:

* Kitty estará configurado de forma modular;
* comportamento e atalhos internos estarão definidos;
* o atalho global estará registrado em `70-keybindings.conf`;
* a identidade visual final poderá ser aplicada posteriormente pelo playbook 19.

---

# Procedimento

## 1. Organizar a configuração

Utilize `~/.config/kitty/kitty.conf` como ponto de entrada e módulos separados para aparência, comportamento e teclado.

## 2. Configurar comportamento

Defina rolagem, histórico, seleção, janelas, abas e redimensionamento.

## 3. Configurar teclado

Defina apenas atalhos internos do Kitty, evitando conflitos com os atalhos globais do Hyprland.

## 4. Integrar ao Hyprland

Adicione o atalho em:

```text
~/.config/hypr/conf.d/70-keybindings.conf
```

A baseline utiliza:

```text
SUPER + RETURN → kitty
```

## 5. Validar

Confirme que `kitty --version` responde corretamente e que o terminal abre pela sessão gráfica.

---

# Verificação

Confirme que:

* Kitty inicia normalmente;
* texto, Unicode, ícones e emojis são renderizados;
* clipboard funciona;
* atalhos internos não conflitam com o Hyprland;
* `SUPER + RETURN` abre o terminal;
* a configuração permanece modular.

---

# Próximo playbook

```text
18-configure-file-manager.md
```

---

# Referências

* Documentação oficial do Kitty
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

A aparência específica do terminal deve permanecer separada de sua integração funcional, permitindo que o playbook de aparência aplique a identidade visual sem alterar comportamento ou keybindings.
