---
title: Configurar ciclo de vida da sessão
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

# 15 — Configurar ciclo de vida da sessão

## Objetivo

Configurar as políticas de inatividade da sessão gráfica com Hypridle, definindo bloqueio automático, gerenciamento do monitor, suspensão e retomada.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Hypridle instalado.
* Bloqueio da sessão configurado.

---

# Resultado esperado

Ao concluir este playbook:

* as políticas de inatividade estarão definidas;
* o bloqueio automático estará integrado ao Hyprlock;
* o Hypridle iniciará com a sessão;
* a retomada ocorrerá de forma consistente.

---

# Procedimento

## 1. Organizar a configuração

Utilize `~/.config/hypr/hypridle.conf` para as políticas de inatividade.

## 2. Definir o ciclo de vida

Estabeleça a sequência de eventos para bloqueio, desligamento do monitor, suspensão e retomada.

## 3. Integrar ao autostart

Adicione uma única entrada do Hypridle em:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

## 4. Validar os eventos

Teste as ações individualmente antes de depender dos timeouts completos.

---

# Verificação

Confirme que:

* Hypridle inicia com a sessão;
* o bloqueio automático funciona;
* o monitor responde aos eventos configurados;
* suspensão e retomada funcionam;
* não existem processos duplicados.

---

# Próximo playbook

```text
16-configure-application-launcher.md
```

---

# Referências

* Documentação oficial do Hypridle
* Documentação oficial do Hyprland
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

O ciclo de vida depende do bloqueio já configurado, mas continua sendo uma responsabilidade separada da autenticação inicial da workstation.
