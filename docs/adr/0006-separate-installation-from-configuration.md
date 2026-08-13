---
title: Separação entre instalação e configuração
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* ADR-0002
* ADR-0004
* ADR-0005
* architecture.md
* standards.md

---

# ADR-0006 — Separação entre instalação e configuração

## Status

Aceito.

## Contexto

Durante a implementação da fase `03-desktop`, tornou-se necessário distinguir duas responsabilidades que inicialmente poderiam parecer parte da mesma tarefa:

* disponibilizar uma capacidade por meio da instalação de seus pacotes;
* configurar o comportamento dessa capacidade dentro da sessão da workstation.

Misturar essas responsabilidades no mesmo playbook ou script dificulta a validação, reduz a idempotência e faz com que ajustes de configuração possam alterar o conjunto de pacotes instalado sem necessidade.

Essa separação também está alinhada aos princípios de responsabilidade única e evolução incremental adotados pelo projeto.

## Decisão

A instalação de uma capacidade e sua configuração deverão permanecer em etapas distintas sempre que houver separação técnica natural entre elas.

Playbooks e scripts de instalação serão responsáveis por:

* declarar os pacotes necessários;
* instalar os pacotes;
* validar a presença dos binários e artefatos essenciais;
* realizar apenas testes funcionais mínimos que não dependam de personalização posterior.

Playbooks e scripts de configuração serão responsáveis por:

* criar ou atualizar arquivos de configuração;
* integrar a capacidade à sessão;
* definir comportamento, atalhos e políticas;
* validar o estado configurado;
* não instalar silenciosamente novos pacotes.

Quando uma configuração depender de um pacote que ainda não esteja instalado, o script deverá falhar explicitamente e indicar a etapa de instalação correspondente.

## Aplicação na fase desktop

A fase `03-desktop` adota o seguinte padrão conceitual:

```text
Instalar capacidade
      ↓
Validar instalação
      ↓
Configurar capacidade
      ↓
Validar configuração
      ↓
Validar integração
```

Exemplos:

```text
04-install-screen-locker
    ↓
13-configure-session-lock

05-install-idle-manager
    ↓
14-configure-session-lifecycle

06-install-application-launcher
    ↓
15-configure-application-launcher

07-install-notification-center
    ↓
16-configure-notification-center

08-install-terminal-emulator
    ↓
17-configure-terminal-emulator

09-install-file-manager
    ↓
18-configure-file-manager
```

## Consequências positivas

* Reduz efeitos colaterais durante ajustes de configuração.
* Facilita reinstalação e troubleshooting.
* Torna scripts de configuração mais previsíveis.
* Permite validar instalação e configuração separadamente.
* Evita que uma personalização modifique o estado de pacotes do sistema.
* Favorece reutilização das capacidades em diferentes perfis.

## Consequências negativas

* A quantidade de playbooks e scripts aumenta.
* Uma capacidade pode exigir duas etapas antes de estar completamente integrada.
* Alterações de dependências exigem identificar corretamente se pertencem à instalação ou à configuração.

## Alternativas consideradas

### Instalar e configurar no mesmo script

Rejeitada porque mistura responsabilidades e torna a execução menos previsível.

### Permitir que scripts de configuração instalem dependências ausentes automaticamente

Rejeitada porque esconde mudanças no estado do sistema e dificulta reprodução e auditoria.

### Centralizar toda instalação de pacotes em uma única etapa

Não adotada como regra porque reduz a associação entre uma capacidade e suas dependências específicas.

## Regras de aplicação

* Scripts de configuração não deverão executar `pacman -S` para satisfazer dependências ausentes.
* Uma dependência nova deverá ser adicionada à etapa de instalação apropriada.
* A ausência de pré-requisito deverá produzir erro claro e acionável.
* Ajustes visuais ou comportamentais não deverão modificar o conjunto de pacotes sem decisão explícita.

## Lições aprendidas

A implementação incremental do desktop mostrou que separar instalação de configuração reduz retrabalho e torna mais simples identificar se uma falha pertence ao pacote, à configuração ou à integração da sessão.
