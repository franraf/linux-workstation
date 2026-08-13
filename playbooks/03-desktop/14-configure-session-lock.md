---
title: Configurar bloqueio da sessão
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

# 14 — Configurar bloqueio da sessão

## Objetivo

Configurar o comportamento e a aparência do bloqueio da sessão gráfica com Hyprlock, garantindo uma experiência consistente e segura.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Hyprlock instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o bloqueio será acionável pela sessão;
* a autenticação funcionará corretamente;
* a configuração estará modularizada;
* o atalho global será mantido no fragmento canônico de keybindings.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos de configuração conforme a ADR-0005.

## 2. Configurar a interface e comportamento

Defina plano de fundo, relógio, data, campo de autenticação, mensagens de erro e retorno à sessão.

## 3. Integrar ao Hyprland

Utilize o fragmento:

```text
~/.config/hypr/conf.d/60-session-lock.conf
```

A baseline utiliza:

```text
SUPER + L → hyprlock
```

## 4. Validar o desbloqueio

Execute testes completos de bloqueio e desbloqueio e confirme que a sessão retorna ao estado anterior.

---

# Verificação

Confirme que:

* o bloqueio inicia corretamente;
* a autenticação funciona;
* a sessão é restaurada após o desbloqueio;
* não existem erros durante a execução.

---

# Próximo playbook

```text
15-configure-session-lifecycle.md
```

---

# Referências

* Documentação oficial do Hyprlock
* Documentação oficial do Hyprland
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

O bloqueio da sessão possui responsabilidade própria e não deve ser confundido com o login inicial da workstation, que será configurado posteriormente com greetd e tuigreet.
