---
title: Configurar login da sessão
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0006
* ADR-0008

---

# 21 — Configurar login da sessão

## Objetivo

Configurar autenticação e inicialização da sessão gráfica utilizando `greetd` e `tuigreet`, garantindo que o Hyprland seja iniciado somente após autenticação bem-sucedida.

Este é o último playbook de configuração da fase `03-desktop`. Todos os componentes já foram instalados nos playbooks `01` a `11`.

---

# Pré-requisitos

* `greetd` instalado pelo playbook `11-install-session-login.md`.
* `tuigreet` instalado.
* Hyprland funcional com `start-hyprland`.
* Usuário normal existente.
* Acesso a outro TTY disponível para recuperação.

---

# Resultado esperado

Ao concluir este playbook, o fluxo de inicialização será:

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

A conta pessoal não utilizará autologin.

---

# Procedimento

## 1. Remover mecanismos de autologin conflitantes

Confirme que não existe override de `getty@tty1` configurando `--autologin` para a conta pessoal.

Confirme também que `.bash_profile`, `.profile`, `.zprofile` ou equivalentes não iniciam `start-hyprland` automaticamente como política padrão.

## 2. Configurar o greetd

Utilize `/etc/greetd/config.toml` como configuração da capacidade.

A baseline deverá executar `tuigreet` como usuário de sistema `greeter` e iniciar a sessão autenticada com:

```text
start-hyprland
```

## 3. Habilitar o serviço

Habilite `greetd.service` para o boot e evite um fluxo concorrente no `tty1`.

## 4. Validar antes do reboot

Confirme:

```text
systemctl is-enabled greetd
```

Revise `/etc/greetd/config.toml`.

## 5. Validar após reboot

Reinicie a workstation e confirme que:

* `tuigreet` é apresentado;
* usuário e senha são solicitados;
* credenciais inválidas não iniciam a sessão;
* credenciais válidas iniciam Hyprland;
* `whoami` retorna o usuário autenticado;
* não existe sessão pessoal antes da autenticação.

---

# Verificação

Confirme que:

* `greetd.service` está habilitado e ativo após o boot;
* a conta pessoal não usa autologin;
* `start-hyprland` é iniciado somente após autenticação;
* o Hyprland roda como o usuário autenticado;
* outro TTY permanece disponível para recuperação.

---

# Problemas comuns

## O sistema volta ao TTY

Revise `greetd.service`, `/etc/greetd/config.toml` e os logs do serviço.

## Hyprland não inicia após autenticação

Teste `start-hyprland` manualmente em outro TTY e corrija primeiro a sessão gráfica.

## A máquina entra diretamente no desktop

Procure overrides de `getty`, autologin e inicialização automática em arquivos de perfil do shell.

---

# Próximo playbook

```text
22-desktop-validation.md
```

---

# Referências

* ADR-0006 — Separação entre instalação e configuração
* ADR-0008 — Autenticação e inicialização da sessão gráfica
* Documentação do greetd
* Documentação do tuigreet
* Arch Wiki — greetd

---

# Lições aprendidas

A fase desktop preserva a ordem `instalar tudo → configurar tudo → validar tudo`. O login manager é instalado junto às demais capacidades e somente configurado após o restante do desktop estar preparado.
