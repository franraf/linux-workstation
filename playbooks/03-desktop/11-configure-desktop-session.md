---
title: Configurar sessão gráfica
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
* ADR-0008

---

# 11 — Configurar sessão gráfica

## Objetivo

Configurar a sessão gráfica da workstation com Hyprland, estabelecendo os parâmetros globais, a estrutura modular da configuração e os pontos de integração utilizados pelas capacidades posteriores do desktop.

Este playbook configura a sessão. Ele não instala componentes e não substitui os playbooks específicos de Waybar, Hyprlock, Hypridle, Rofi, SwayNC, Kitty, Thunar ou aparência.

---

# Pré-requisitos

* Stack gráfica instalada e validada.
* Hyprland instalado.
* Capacidades básicas da fase de instalação do desktop concluídas.
* Usuário normal disponível para executar a sessão.

---

# Resultado esperado

Ao concluir este playbook:

* `~/.config/hypr/hyprland.conf` será o ponto de entrada da configuração;
* a configuração estará modularizada em `~/.config/hypr/conf.d/`;
* ambiente, monitor, input, comportamento geral e autostart possuirão responsabilidades separadas;
* a sessão poderá ser iniciada com `start-hyprland`;
* a estrutura estará preparada para os playbooks seguintes.

---

# Procedimento

## 1. Criar o ponto de entrada

Utilize `~/.config/hypr/hyprland.conf` como arquivo principal da sessão.

O arquivo principal deverá atuar apenas como agregador dos módulos, conforme a ADR-0005.

## 2. Organizar os fragments do Hyprland

A estrutura base adotada pela fase desktop é:

```text
~/.config/hypr/
├── hyprland.conf
└── conf.d/
    ├── 10-environment.conf
    ├── 20-monitor.conf
    ├── 30-input.conf
    ├── 40-general.conf
    └── 50-autostart.conf
```

Capacidades posteriores poderão adicionar novos fragments numerados, mantendo uma responsabilidade por arquivo.

Na configuração consolidada da fase, os fragments adicionais previstos são:

```text
60-session-lock.conf
70-keybindings.conf
80-appearance.conf
```

A numeração define a ordem de carregamento e não deve ser reutilizada para responsabilidades diferentes.

## 3. Configurar o ambiente

Utilize `10-environment.conf` para variáveis de ambiente da sessão Wayland.

Não misture keybindings, autostart ou aparência neste arquivo.

## 4. Configurar monitor e input

Utilize:

```text
20-monitor.conf
30-input.conf
```

As opções devem ser compatíveis com a versão instalada do Hyprland e validadas com o próprio compositor.

No Hyprland atualmente validado pelo projeto, a opção de tap do touchpad utiliza:

```text
tap-to-click
```

Não utilizar `tap_to_click` sem validar suporte na versão instalada.

## 5. Configurar comportamento geral

Utilize `40-general.conf` para opções gerais do compositor.

Não configure opções removidas ou sem efeito na versão atual. Em particular, `dwindle:pseudotile` não faz parte da baseline validada e não deverá ser gerado.

## 6. Preparar o autostart

Utilize exclusivamente:

```text
50-autostart.conf
```

para processos que devem iniciar com a sessão.

Cada playbook posterior adicionará apenas o componente de sua responsabilidade.

## 7. Validar a configuração

Inicie o Hyprland como usuário normal com:

```text
start-hyprland
```

Dentro da sessão, valide a configuração com:

```text
hyprctl configerrors
```

O resultado esperado é `ok` ou ausência de erros, conforme a versão instalada.

---

# Verificação

Confirme que:

* `hyprland.conf` carrega os fragments esperados;
* os arquivos pertencem ao usuário da sessão;
* `start-hyprland` inicia o compositor sem erro crítico;
* `hyprctl configerrors` não apresenta erros;
* monitor e dispositivos de entrada são reconhecidos;
* nenhuma capacidade posterior foi configurada prematuramente.

---

# Problemas comuns

## O Hyprland carrega outro arquivo de configuração

Verifique os logs de inicialização e confirme qual arquivo foi selecionado. Arquivos alternativos antigos, como `hyprland.lua`, não deverão permanecer ativos quando a baseline adotada utiliza `hyprland.conf`.

## Opção de configuração inexistente

Confirme a opção diretamente com `hyprctl getoption` e consulte a documentação correspondente à versão instalada antes de alterar a baseline.

## Componentes não inicializam

Confirme se o componente já foi configurado pelo playbook responsável e se sua entrada existe em `50-autostart.conf`.

---

# Próximo playbook

```text
12-configure-status-bar.md
```

---

# Referências

* Documentação oficial do Hyprland
* Arch Wiki — Hyprland
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração
* ADR-0008 — Autenticação e inicialização da sessão gráfica

---

# Lições aprendidas

Durante a validação com Hyprland 0.56.2, opções aparentemente equivalentes apresentaram diferenças de compatibilidade. A configuração deve ser validada pelo compositor em execução, e correções encontradas durante a instalação precisam retornar ao repositório para evitar regressões.
