---
title: Configurar barra de status
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

# 12 — Configurar barra de status

## Objetivo

Configurar a Waybar como barra de status da sessão gráfica, mantendo sua configuração modular e distribuindo as informações de forma consistente entre as áreas esquerda, central e direita.

Este playbook configura a capacidade; a instalação da Waybar pertence ao playbook correspondente.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Waybar instalada.
* Stack tipográfica instalada.

---

# Resultado esperado

Ao concluir este playbook:

* a Waybar iniciará com a sessão;
* os módulos estarão separados em arquivos próprios;
* a barra ocupará a largura disponível do output;
* workspaces, janela ativa e status do sistema estarão distribuídos de forma previsível;
* a configuração será validada antes de avançar.

---

# Procedimento

## 1. Organizar a configuração

Utilize a estrutura modular prevista pela ADR-0005:

```text
~/.config/waybar/
├── config.jsonc
├── style.css
└── modules/
    ├── workspaces.jsonc
    ├── window.jsonc
    ├── clock.jsonc
    ├── network.jsonc
    ├── pulseaudio.jsonc
    ├── battery.jsonc
    └── tray.jsonc
```

Evite módulos duplicados ou arquivos sem referência no `include` principal.

## 2. Definir a distribuição da barra

A baseline adotada é:

```text
esquerda: workspaces
centro:   janela ativa
direita:  rede, áudio, bateria, relógio e tray
```

A Waybar horizontal não deverá receber uma largura fixa arbitrária. Em particular, não utilizar valores como:

```json
"width": 4
```

A ausência de largura fixa permite que a barra utilize corretamente a largura do output.

## 3. Configurar os módulos

Configure apenas os módulos necessários e mantenha cada responsabilidade no arquivo correspondente.

Os arquivos JSONC deverão permanecer sintaticamente válidos após inclusão pelo `config.jsonc`.

## 4. Integrar à sessão

Adicione a Waybar ao fragmento canônico:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

Não crie um segundo fragmento de autostart para a mesma responsabilidade.

## 5. Validar a execução

Execute manualmente:

```text
waybar
```

antes de considerar a integração concluída.

Erros de parsing devem ser corrigidos no módulo indicado pelo log.

---

# Verificação

Confirme que:

* `waybar` inicia sem erro de parsing;
* a barra ocupa corretamente o output;
* workspaces ficam à esquerda;
* a janela ativa fica no centro;
* rede, áudio, bateria, relógio e tray ficam à direita;
* ícones e textos são renderizados corretamente;
* existe uma única entrada de Waybar em `50-autostart.conf`.

---

# Problemas comuns

## Barra estreita ou concentrada

Verifique se `config.jsonc` possui uma largura fixa indevida. A barra horizontal deve usar a largura disponível do output.

## Erro `Missing ',' or ']'`

Leia a sequência de arquivos incluídos no log e valide o último módulo processado. Corrija a estrutura JSONC antes de reiniciar a Waybar.

## Módulo duplicado ou obsoleto

Remova módulos que não são mais utilizados e confirme que o `include` principal referencia apenas arquivos existentes.

## Barra não inicia automaticamente

Confirme que `50-autostart.conf` contém a entrada da Waybar e que a configuração principal do Hyprland carrega esse fragmento.

---

# Próximo playbook

```text
13-configure-session-lock.md
```

---

# Referências

* Documentação oficial do Waybar
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

Uma largura fixa inadequada pode fazer a Waybar ocupar apenas uma pequena região do monitor mesmo quando os módulos estão corretamente distribuídos. A validação deve incluir tanto parsing quanto geometria e posicionamento visual.
