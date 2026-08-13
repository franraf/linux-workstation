---
title: Configuração do Hyprland em Lua
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-13
related:

* ADR-0005
* ADR-0009
* architecture.md
* standards.md

---

# ADR-0010 — Configuração do Hyprland em Lua

## Status

Aceito.

## Contexto

O projeto utiliza Hyprland como compositor Wayland. A configuração inicial da fase desktop foi construída com arquivos `.conf` usando Hyprlang e fragments carregados por `source`.

A partir do Hyprland 0.55, Hyprlang foi depreciado como formato de configuração do Hyprland em favor de Lua. O Hyprland utiliza `~/.config/hypr/hyprland.lua` como configuração canônica e recomenda `require()` para modularização.

A workstation atualmente utiliza Hyprland 0.56.x, portanto manter a nova implementação em Hyprlang significaria construir sobre uma interface legada já depreciada.

## Decisão

A configuração canônica do Hyprland neste projeto será escrita em Lua.

O arquivo principal será:

```text
~/.config/hypr/hyprland.lua
```

Os artefatos versionados compartilhados ficarão sob:

```text
system/hyprland/
├── hyprland.lua
└── modules/
    ├── 10-environment.lua
    ├── 20-monitor.lua
    ├── 30-input.lua
    ├── 40-general.lua
    ├── 50-autostart.lua
    ├── 60-session-lock.lua
    ├── 70-keybindings.lua
    └── 80-appearance.lua
```

O arquivo principal terá responsabilidade de orquestração e carregará os módulos com `require()`.

A numeração dos módulos continuará expressando ordem lógica e preservará a separação de responsabilidades já adotada pelo projeto.

## Escopo

Esta decisão aplica-se especificamente à configuração do Hyprland.

Ela não estabelece Lua como formato universal de configuração do desktop.

Cada componente deverá continuar utilizando seu formato nativo apropriado, por exemplo:

* Waybar — JSONC e CSS;
* Rofi — Rasi;
* greetd — TOML;
* Kitty — formato de configuração próprio;
* SwayNC — formatos suportados pelo próprio componente.

## Migração

Os arquivos `.conf` anteriormente utilizados pelo Hyprland não serão mantidos como uma segunda implementação paralela.

Durante a refatoração:

1. o comportamento validado será convertido para Lua;
2. os novos arquivos Lua serão armazenados em `system/hyprland/`;
3. scripts de perfil instalarão ou selecionarão esses artefatos;
4. configurações Hyprlang antigas serão consideradas legado e removidas quando a migração estiver validada.

Não haverá sincronização automática entre implementações `.conf` e `.lua`.

## Modularização

O projeto utilizará `require()` para dividir a configuração em módulos.

Essa abordagem é preferida porque mantém responsabilidade única e porque o mecanismo de configuração Lua do Hyprland trata arquivos requeridos como escopos separados, reduzindo o impacto de determinados erros de runtime entre módulos.

## Compatibilidade

Os módulos deverão acompanhar a sintaxe suportada pela versão estável do Hyprland empacotada para a workstation.

Antes de introduzir APIs Lua novas, deverá ser verificado se elas são suportadas pela versão alvo do compositor.

O projeto não deverá preservar sintaxe Hyprlang apenas para compatibilidade com versões anteriores do Hyprland, salvo decisão arquitetural futura explícita.

## Segurança

Arquivos de configuração Lua são código executável.

Consequentemente:

* somente arquivos versionados e confiáveis deverão ser instalados como configuração do Hyprland;
* módulos não deverão executar comandos arbitrários sem necessidade explícita;
* comandos de autostart e integrações deverão permanecer identificáveis e auditáveis;
* artefatos obtidos de fontes externas não deverão ser executados diretamente como módulos Lua sem revisão.

## Consequências positivas

* acompanha o formato recomendado pelas versões atuais do Hyprland;
* elimina dependência de uma sintaxe depreciada;
* permite modularização nativa com `require()`;
* oferece maior capacidade de composição e validação;
* evita manter duas fontes da verdade para a configuração do compositor;
* prepara o projeto para APIs atuais e futuras do Hyprland.

## Consequências negativas

* exige migração da configuração Hyprlang já validada;
* Lua possui maior poder de execução e, portanto, exige maior cuidado de segurança;
* mudanças de API do Hyprland podem exigir adaptação dos módulos;
* troubleshooting passa a envolver também erros de sintaxe/runtime Lua.

## Alternativas consideradas

### Continuar utilizando `.conf` / Hyprlang

Rejeitada porque Hyprlang está depreciado para configuração do Hyprland desde a versão 0.55.

### Manter `.conf` e `.lua` simultaneamente

Rejeitada porque criaria duas fontes da verdade e risco permanente de divergência.

### Gerar Lua dinamicamente dentro dos scripts

Rejeitada como padrão porque configurações estáticas e reutilizáveis devem existir como artefatos versionados em `system/`, conforme ADR-0009.

## Regras de aplicação

* `hyprland.lua` é a entrada canônica da configuração do Hyprland.
* módulos compartilhados ficam em `system/hyprland/modules/`.
* usar `require()` para composição modular.
* não criar nova configuração Hyprland em `.conf`.
* não manter implementação paralela Hyprlang/Lua.
* scripts de perfil não deverão conter grandes heredocs com configuração Lua estática.
* particularidades reais de hardware poderão ser fornecidas pelo perfil sem duplicar os módulos compartilhados.

## Lições aprendidas

A primeira configuração do desktop mostrou que seguir uma sintaxe funcional mas já depreciada aumenta retrabalho rapidamente. Durante uma refatoração estrutural, adotar a interface canônica da versão atual reduz dívida técnica e evita migrar a mesma configuração duas vezes.
