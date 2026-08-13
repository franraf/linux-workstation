---
title: Autenticação e inicialização da sessão gráfica
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* ADR-0002
* ADR-0006
* architecture.md
* standards.md

---

# ADR-0008 — Autenticação e inicialização da sessão gráfica

## Status

Aceito.

## Contexto

A workstation utiliza Hyprland como compositor Wayland.

Durante a implementação foi validado que a sessão pode ser iniciada manualmente a partir de um TTY com `start-hyprland`. Também foi considerada a possibilidade de utilizar autologin no `tty1` e iniciar o compositor automaticamente por meio do shell do usuário.

Embora simples, o autologin deixaria uma sessão pessoal aberta após o boot sem exigir autenticação, permitindo acesso imediato a dados e aplicações por qualquer pessoa com acesso físico à máquina.

O projeto estabelece segurança por padrão e simplicidade antes de complexidade.

## Decisão

A workstation deverá exigir autenticação antes de iniciar a sessão gráfica do usuário.

Será utilizado `greetd` como login manager e `tuigreet` como frontend de autenticação.

Após autenticação bem-sucedida, a sessão deverá ser iniciada com:

```text
start-hyprland
```

O usuário de sistema `greeter` será utilizado apenas para executar a interface de autenticação. A sessão gráfica será executada com a identidade do usuário autenticado.

O fluxo esperado será:

```text
boot
  ↓
systemd
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

## Requisitos de segurança

* Não utilizar autologin para a conta pessoal da workstation.
* Não iniciar Hyprland automaticamente por `.bash_profile`, `.profile` ou mecanismo equivalente como configuração padrão.
* A sessão somente deverá existir após autenticação bem-sucedida.
* O bloqueio durante uma sessão já autenticada continuará sendo responsabilidade do Hyprlock e do ciclo de vida controlado pelo Hypridle.

## Consequências positivas

* Impede acesso imediato à sessão pessoal após o boot.
* Mantém autenticação separada da configuração do shell.
* Evita dependência de autologin no `getty`.
* Preserva um fluxo simples e adequado a Wayland.
* Mantém `start-hyprland` como ponto explícito de inicialização do compositor.

## Consequências negativas

* Introduz `greetd` e `tuigreet` como componentes adicionais.
* A tela de login depende do funcionamento correto do serviço `greetd`.
* Problemas no login manager podem exigir recuperação por outro TTY.

## Alternativas consideradas

### Autologin no tty1 com inicialização pelo shell

Rejeitada porque cria uma sessão pessoal sem autenticação após o boot.

### Login manual no TTY seguido de `start-hyprland`

Funcional e útil para troubleshooting, mas rejeitado como experiência padrão por exigir uma etapa manual adicional.

### SDDM ou outro display manager gráfico

Não escolhido inicialmente porque adiciona uma camada gráfica maior do que a necessária para o objetivo atual.

O projeto poderá reconsiderar essa alternativa se surgirem requisitos de seleção de sessões, temas gráficos ou integração que justifiquem a complexidade adicional.

## Recuperação

Em caso de falha no `greetd`, deverá permanecer possível acessar outro TTY, autenticar manualmente e iniciar a sessão para diagnóstico quando apropriado.

A configuração do login manager não deverá impedir a recuperação administrativa pelo console.

## Lições aprendidas

A conveniência do autologin não compensa a perda de segurança em uma workstation pessoal. O login manager mantém o boot automatizado sem eliminar a fronteira de autenticação.
