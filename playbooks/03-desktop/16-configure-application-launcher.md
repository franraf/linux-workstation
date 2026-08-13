---
title: Configurar lançador de aplicações
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

---

# 16 — Configurar lançador de aplicações

## Objetivo

Configurar o Rofi como lançador de aplicações da workstation, integrando-o à sessão gráfica sem introduzir conflitos de teclado.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Rofi instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Rofi estará disponível sob demanda;
* os modos `drun` e `run` estarão funcionais;
* o atalho global estará registrado em `70-keybindings.conf`;
* não existirão bindings internos duplicados.

---

# Procedimento

## 1. Organizar a configuração

Utilize `~/.config/rofi/config.rasi` para comportamento do launcher.

A identidade visual final deverá ser tratada em `20-configure-appearance.md`.

## 2. Configurar modos

Habilite `drun` e `run`.

## 3. Preservar bindings internos válidos

Não configurar simultaneamente:

```text
kb-row-left = Left,Control+b
kb-row-right = Right,Control+f
```

Antes de adicionar bindings, utilize:

```text
rofi -list-keybindings
```

## 4. Integrar ao Hyprland

Registre em:

```text
~/.config/hypr/conf.d/70-keybindings.conf
```

A baseline utiliza:

```text
SUPER + SPACE → rofi -show drun
```

## 5. Validar

Execute `rofi -show drun` e confirme que abre sem mensagens de bindings duplicados.

---

# Verificação

Confirme que:

* aplicações são listadas;
* pesquisa e navegação funcionam;
* `SUPER + SPACE` funciona;
* o Rofi não é iniciado como daemon no autostart.

---

# Próximo playbook

```text
17-configure-notification-center.md
```

---

# Referências

* Documentação oficial do Rofi
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

Bindings que parecem convenientes podem colidir com atalhos internos já reservados pelo Rofi. A validação deve consultar os bindings efetivos do binário instalado antes de personalizá-los.
