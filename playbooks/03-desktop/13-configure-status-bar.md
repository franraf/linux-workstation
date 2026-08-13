---
title: Configurar barra de status
version: 1.2
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

# 13 — Configurar barra de status

## Objetivo

Configurar a Waybar como barra de status da sessão gráfica, mantendo sua configuração modular e distribuindo as informações de forma consistente entre as áreas esquerda, central e direita.

Este playbook configura a capacidade já instalada anteriormente.

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
* workspaces, janela ativa e status do sistema estarão distribuídos de forma previsível.

---

# Procedimento

## 1. Organizar a configuração

Utilize:

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

## 2. Definir a distribuição da barra

A baseline adotada é:

```text
esquerda: workspaces
centro:   janela ativa
direita:  rede, áudio, bateria, relógio e tray
```

Não utilizar largura fixa arbitrária como:

```json
"width": 4
```

## 3. Configurar os módulos

Mantenha cada responsabilidade no arquivo correspondente e preserve JSONC válido.

## 4. Integrar à sessão

Adicione a Waybar ao fragmento canônico:

```text
~/.config/hypr/conf.d/50-autostart.conf
```

## 5. Validar a execução

Execute manualmente:

```text
waybar
```

antes de considerar a integração concluída.

---

# Verificação

Confirme que:

* `waybar` inicia sem erro de parsing;
* a barra ocupa corretamente o output;
* workspaces ficam à esquerda;
* a janela ativa fica no centro;
* rede, áudio, bateria, relógio e tray ficam à direita;
* existe uma única entrada de Waybar em `50-autostart.conf`.

---

# Problemas comuns

## Barra estreita ou concentrada

Verifique se `config.jsonc` possui largura fixa indevida.

## Erro `Missing ',' or ']'`

Leia a sequência de arquivos incluídos no log e valide o último módulo processado.

## Barra não inicia automaticamente

Confirme que `50-autostart.conf` contém a entrada da Waybar.

---

# Próximo playbook

```text
14-configure-session-lock.md
```

---

# Referências

* Documentação oficial do Waybar
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

Uma largura fixa inadequada pode fazer a Waybar ocupar apenas uma pequena região do monitor mesmo quando os módulos estão corretamente distribuídos.
