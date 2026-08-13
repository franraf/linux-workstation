---
title: Configurar central de notificações
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

# 16 — Configurar central de notificações

## Objetivo

Configurar o SwayNC como central de notificações da workstation, definindo comportamento, histórico e integração com a sessão gráfica.

A aparência global do componente será tratada no playbook `19-configure-appearance.md`.

---

# Pré-requisitos

* Sessão gráfica configurada.
* SwayNC instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o SwayNC iniciará com a sessão;
* notificações serão exibidas e armazenadas no histórico;
* o controle da central estará disponível por atalho global;
* não haverá outro daemon de notificações concorrente.

---

# Procedimento

## 1. Configurar o comportamento

Utilize `~/.config/swaync/config.json` para comportamento, posição, histórico e timeouts.

Não concentre tema visual definitivo neste playbook.

## 2. Integrar ao autostart

Adicione uma única entrada do SwayNC em:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

## 3. Integrar aos keybindings

Adicione o atalho global em:

```text
~/.config/hypr/conf.d/70-keybindings.conf
```

A baseline utiliza:

```text
SUPER + N → swaync-client -t
```

## 4. Validar conflitos

Confirme que nenhum outro daemon, como `dunst`, `mako` ou `fnott`, está configurado para iniciar simultaneamente.

## 5. Validar o fluxo

Teste com:

```text
notify-send "linux-workstation" "SwayNC notification test"
```

---

# Verificação

Confirme que:

* SwayNC inicia automaticamente;
* `notify-send` produz uma notificação;
* o histórico fica acessível;
* `SUPER + N` abre e fecha a central;
* existe uma única entrada em `50-autostart.conf`;
* não existe daemon concorrente.

---

# Próximo playbook

```text
17-configure-terminal-emulator.md
```

---

# Referências

* Documentação oficial do SwayNC
* Desktop Notifications Specification
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

A integração do SwayNC possui duas responsabilidades distintas no Hyprland: inicialização em `50-autostart.conf` e controle por usuário em `70-keybindings.conf`. Essas responsabilidades não devem ser misturadas nem duplicadas.
