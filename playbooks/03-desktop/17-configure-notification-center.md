---
title: Configurar central de notificações
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

# 17 — Configurar central de notificações

## Objetivo

Configurar o SwayNC como central de notificações da workstation, definindo comportamento, histórico e integração com a sessão gráfica.

A aparência global do componente será tratada no playbook `20-configure-appearance.md`.

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

Confirme que nenhum outro daemon de notificações está configurado para iniciar simultaneamente.

## 5. Validar o fluxo

Teste com `notify-send`.

---

# Verificação

Confirme que:

* SwayNC inicia automaticamente;
* notificações são exibidas;
* o histórico fica acessível;
* `SUPER + N` abre e fecha a central;
* existe uma única entrada em `50-autostart.conf`.

---

# Próximo playbook

```text
18-configure-terminal-emulator.md
```

---

# Referências

* Documentação oficial do SwayNC
* Desktop Notifications Specification
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

A integração do SwayNC possui responsabilidades distintas no autostart e nos keybindings, que não devem ser duplicadas.
