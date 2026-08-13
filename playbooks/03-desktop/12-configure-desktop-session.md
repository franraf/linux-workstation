---
title: Configurar sessão gráfica
version: 2.0
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005
* ADR-0006
* ADR-0008
* ADR-0009
* ADR-0010

---

# 12 — Configurar sessão gráfica

## Objetivo

Configurar a sessão gráfica da workstation com Hyprland, estabelecendo a configuração Lua canônica, a estrutura modular e os pontos de integração utilizados pelas capacidades posteriores do desktop.

Este é o primeiro playbook da etapa de configuração da fase `03-desktop`. Todos os componentes necessários já devem estar instalados pelos playbooks `01` a `11`.

---

# Pré-requisitos

* Todos os playbooks de instalação `01` a `11` concluídos.
* Stack gráfica instalada e validada.
* Hyprland instalado.
* Usuário normal disponível para executar a sessão.
* Artefatos compartilhados disponíveis em `system/hyprland/`.

---

# Resultado esperado

Ao concluir este playbook:

* `~/.config/hypr/hyprland.lua` será o ponto de entrada canônico;
* a configuração estará modularizada em `~/.config/hypr/modules/`;
* ambiente, monitor, input, comportamento geral e autostart possuirão responsabilidades separadas;
* não haverá dependência operacional da configuração Hyprlang `.conf` anterior;
* a sessão poderá ser iniciada com `start-hyprland`;
* a estrutura estará preparada para os playbooks seguintes.

---

# Fonte da configuração

A configuração não deverá ser gerada como grandes heredocs dentro do script do perfil.

Os arquivos canônicos deverão residir em:

```text
system/hyprland/
├── hyprland.lua
└── modules/
    ├── 10-environment.lua
    ├── 20-monitor.lua
    ├── 30-input.lua
    ├── 40-general.lua
    └── 50-autostart.lua
```

Capacidades posteriores adicionarão:

```text
60-session-lock.lua
70-keybindings.lua
80-appearance.lua
```

O perfil é responsável por instalar ou selecionar os artefatos apropriados, conforme ADR-0009.

---

# Procedimento

## 1. Criar o ponto de entrada Lua

Utilize:

```text
~/.config/hypr/hyprland.lua
```

como arquivo principal da sessão.

O arquivo principal deverá atuar como agregador dos módulos utilizando `require()`, conforme ADR-0010.

Exemplo conceitual:

```lua
require("modules.10-environment")
require("modules.20-monitor")
require("modules.30-input")
require("modules.40-general")
require("modules.50-autostart")
```

## 2. Organizar os módulos do Hyprland

A estrutura base adotada será:

```text
~/.config/hypr/
├── hyprland.lua
└── modules/
    ├── 10-environment.lua
    ├── 20-monitor.lua
    ├── 30-input.lua
    ├── 40-general.lua
    └── 50-autostart.lua
```

A numeração expressa ordem lógica e responsabilidade, mas o carregamento é explicitamente controlado pelo arquivo principal.

## 3. Configurar o ambiente

Utilize `10-environment.lua` para variáveis necessárias à sessão Wayland por meio das APIs Lua suportadas pelo Hyprland.

Variáveis não relacionadas exclusivamente ao Hyprland deverão ser avaliadas antes de serem colocadas neste módulo.

## 4. Configurar monitor

Utilize `20-monitor.lua` para a baseline de outputs.

Particularidades realmente específicas de hardware poderão ser fornecidas pelo perfil sem duplicar a configuração compartilhada inteira.

## 5. Configurar input

Utilize `30-input.lua` para teclado, mouse e touchpad.

A configuração deverá utilizar as opções suportadas pela versão alvo do Hyprland e ser validada pelo compositor em execução.

## 6. Configurar comportamento geral

Utilize `40-general.lua` para opções gerais e layout.

Não transportar automaticamente opções legadas apenas porque existiam na configuração Hyprlang anterior. Cada opção migrada deverá existir na API/configuração Lua da versão alvo.

## 7. Preparar autostart

Utilize `50-autostart.lua` como ponto central de integração dos processos iniciados com a sessão.

Na API Lua atual, autostart deverá preferir o evento `hyprland.start` e `hl.exec_cmd()` em vez de reproduzir mecanicamente `exec-once` da sintaxe legada.

Cada playbook posterior deverá adicionar somente componentes de sua responsabilidade.

## 8. Remover ambiguidade com configuração legada

Após instalar e validar a configuração Lua, arquivos antigos que possam competir como ponto de entrada não deverão permanecer ativos.

Não manter `hyprland.conf` e `hyprland.lua` como duas fontes da verdade.

## 9. Validar a configuração

Inicie o Hyprland como usuário normal com:

```text
start-hyprland
```

Dentro da sessão, valide com:

```text
hyprctl configerrors
```

O resultado esperado é ausência de erros de configuração.

---

# Verificação

Confirme que:

* `hyprland.lua` é o ponto de entrada utilizado;
* os módulos esperados são carregados com `require()`;
* os arquivos pertencem ao usuário da sessão;
* não existe uma segunda configuração Hyprland ativa competindo com a Lua;
* `start-hyprland` inicia o compositor sem erro crítico;
* `hyprctl configerrors` não apresenta erros;
* monitor e dispositivos de entrada são reconhecidos.

---

# Problemas comuns

## Hyprland utiliza uma configuração diferente

Confirme o arquivo efetivamente carregado e verifique `HYPRLAND_CONFIG` ou uso de `--config` quando aplicável.

## Erro em módulo Lua

Identifique qual arquivo carregado por `require()` apresentou erro. Corrija o módulo específico e valide novamente.

## Configuração Hyprlang antiga interfere na migração

Remova ou desative a configuração legada após confirmar que a versão Lua está instalada corretamente. Não mantenha ambas como fontes canônicas.

## API ou opção Lua inexistente

Consulte a documentação correspondente à versão instalada do Hyprland. Não traduza mecanicamente nomes da sintaxe Hyprlang para Lua sem validar a API atual.

---

# Próximo playbook

```text
13-configure-status-bar.md
```

---

# Referências

* Documentação oficial do Hyprland — configuração Lua
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração
* ADR-0008 — Autenticação e inicialização da sessão gráfica
* ADR-0009 — Artefatos compartilhados e perfis de hardware
* ADR-0010 — Configuração do Hyprland em Lua

---

# Lições aprendidas

A primeira baseline foi validada em Hyprlang, mas a versão atual do Hyprland adotada pelo projeto já utiliza Lua como configuração canônica. A migração deve preservar comportamento validado sem carregar automaticamente opções legadas ou manter duas fontes da verdade.
