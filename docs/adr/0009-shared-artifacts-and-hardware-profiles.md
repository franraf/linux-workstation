---
title: Artefatos compartilhados e perfis de hardware
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* ADR-0002
* ADR-0004
* ADR-0005
* ADR-0006
* ADR-0007
* architecture.md
* standards.md

---

# ADR-0009 — Artefatos compartilhados e perfis de hardware

## Status

Aceito.

## Contexto

O repositório possui diretórios de propósito geral (`packages/`, `scripts/`, `system/`, `tests/` e `examples/`) e perfis em `profiles/`.

Durante a implementação inicial, parte da lógica, das listas de pacotes e das configurações passou a ser criada diretamente dentro do perfil de hardware. Isso funciona para um único equipamento, mas aumenta duplicação e dificulta reutilização quando novos perfis forem adicionados.

Ao mesmo tempo, nem todo artefato deve ser global: seleção de GPU, monitor, firmware e outros detalhes podem depender do hardware.

## Decisão

O projeto adotará uma arquitetura em que artefatos reutilizáveis vivem nos diretórios compartilhados da raiz e os perfis de hardware selecionam, complementam ou sobrescrevem esses artefatos quando necessário.

A relação conceitual será:

```text
playbooks/
    ↓ descrevem o procedimento

profiles/
    ↓ orquestram e especializam

packages/   system/   scripts/
    ↓          ↓          ↓
   dados     configs     lógica
          \    |    /
             tests/
           validação
```

## Responsabilidades

### `packages/`

Mantém listas declarativas de pacotes reutilizáveis.

Os arquivos definem **o que** instalar e não contêm lógica de execução.

Exemplos:

```text
packages/system/base.txt
packages/desktop/compositor.txt
packages/desktop/status-bar.txt
packages/desktop/session-login.txt
```

### `system/`

Mantém configurações versionadas reutilizáveis destinadas ao sistema operacional ou à sessão do usuário.

Exemplos incluem configurações de:

* systemd;
* greetd;
* Hyprland;
* Waybar;
* Rofi;
* SwayNC;
* Kitty.

Scripts deverão preferir instalar/copiar arquivos versionados a gerar configurações extensas por heredocs quando não houver necessidade de geração dinâmica.

### `scripts/`

Mantém lógica compartilhada e helpers reutilizáveis.

Exemplos:

```text
scripts/lib/logging.sh
scripts/lib/packages.sh
scripts/lib/filesystem.sh
scripts/lib/validation.sh
```

Scripts de perfil poderão consumir essas bibliotecas para preservar comportamento e formato consistentes.

### `tests/`

Mantém verificações reutilizáveis de estado e capacidades.

Testes devem validar o estado observado da workstation e poderão ser orquestrados pelos gates finais dos perfis.

### `examples/`

Mantém apenas exemplos e material de referência.

Nenhum fluxo operacional deverá depender de arquivos em `examples/`. Quando um exemplo passar a ser necessário para execução, deverá ser promovido ao diretório compartilhado apropriado.

### `profiles/`

Mantém particularidades de hardware e orquestra os artefatos compartilhados.

Um perfil deverá conter somente o que for específico daquele equipamento ou necessário para selecionar e coordenar capacidades compartilhadas.

Exemplos de dados específicos de perfil:

* seleção de GPU;
* nomes e propriedades de outputs;
* módulos específicos de hardware;
* parâmetros de firmware;
* overrides necessários para determinado equipamento.

## Regra de reutilização

Quando um artefato puder ser utilizado por mais de um perfil sem alteração, ele deverá preferencialmente residir em um diretório compartilhado.

Quando um perfil precisar alterar comportamento compartilhado, deverá preferir override explícito em vez de duplicar silenciosamente toda a implementação.

## Resolução de caminhos

Scripts de perfil deverão resolver o diretório raiz do repositório a partir da própria localização e não depender do diretório corrente do usuário.

Referências a `packages/`, `system/`, `scripts/` e `tests/` deverão ser construídas a partir dessa raiz.

## Consequências positivas

* Reduz duplicação entre perfis.
* Centraliza correções comuns.
* Mantém listas de pacotes separadas da lógica.
* Permite versionar configurações como arquivos reais.
* Facilita testes reutilizáveis.
* Torna o perfil uma camada de especialização em vez de uma cópia completa da workstation.
* Ajuda a manter padrão consistente entre scripts.

## Consequências negativas

* A resolução de caminhos torna-se parte importante dos scripts.
* Uma mudança em artefato compartilhado pode afetar vários perfis.
* Overrides exigem regras claras para evitar comportamento implícito.
* A migração inicial exige mover conteúdo atualmente embutido em scripts de perfil.

## Alternativas consideradas

### Manter toda implementação dentro de cada perfil

Rejeitada porque cria duplicação e dificulta propagação de correções.

### Remover os diretórios compartilhados e manter apenas profiles

Rejeitada porque perde a separação entre dados, configuração, lógica e validação.

### Fazer profiles dependerem de examples

Rejeitada porque exemplos não devem fazer parte do caminho operacional.

## Regras de aplicação

* `packages/` contém dados declarativos, não lógica.
* `system/` contém configurações reutilizáveis, não orquestração.
* `scripts/` contém lógica compartilhada, não particularidades de hardware.
* `tests/` contém verificações reutilizáveis.
* `examples/` nunca é dependência de produção.
* `profiles/` contém especialização e orquestração por hardware.
* Configurações extensas e estáticas devem preferencialmente existir como arquivos em `system/` em vez de heredocs dentro de scripts.
* Funções repetidas entre scripts devem ser candidatas a promoção para `scripts/lib/`.

## Lições aprendidas

A implementação do primeiro perfil mostrou que manter tudo dentro do perfil simplifica o início, mas transforma correções comuns em trabalho repetitivo. A separação entre artefatos compartilhados e especialização de hardware preserva a clareza do perfil sem perder reutilização.
