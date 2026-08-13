---
title: Configurar gerenciador de arquivos
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

# 19 — Configurar gerenciador de arquivos

## Objetivo

Configurar o Thunar como gerenciador de arquivos da workstation, definindo comportamento de navegação, integração com serviços já instalados e atalho global da sessão.

A aparência global pertence ao playbook `20-configure-appearance.md`.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Thunar instalado.
* Integrações necessárias, como `gvfs`, `tumbler` e `thunar-volman`, instaladas pela etapa apropriada.

---

# Resultado esperado

Ao concluir este playbook:

* navegação e visualização estarão configuradas;
* lixeira, miniaturas e dispositivos removíveis estarão disponíveis quando suportados;
* o atalho global estará registrado em `70-keybindings.conf`;
* associações existentes serão respeitadas.

---

# Procedimento

## 1. Configurar a navegação

Defina painel lateral, modo de visualização, arquivos ocultos, ordenação e comportamento de abas.

## 2. Configurar operações

Valide operações de cópia, movimentação, exclusão e lixeira.

## 3. Validar integrações

Confirme `gvfs`, `tumbler` e `thunar-volman`. O script de configuração não deverá instalar dependências ausentes.

## 4. Preservar associações de aplicações

Não sobrescreva associações MIME de forma ampla apenas para concluir este playbook.

## 5. Integrar ao Hyprland

Adicione o atalho ao fragmento:

```text
~/.config/hypr/conf.d/70-keybindings.conf
```

A baseline utiliza:

```text
SUPER + E → thunar
```

---

# Verificação

Confirme que:

* Thunar inicia normalmente;
* navegação e manipulação de arquivos funcionam;
* lixeira e miniaturas estão disponíveis;
* dispositivos removíveis aparecem quando presentes;
* `SUPER + E` abre o Thunar.

---

# Próximo playbook

```text
20-configure-appearance.md
```

---

# Referências

* Documentação oficial do Thunar
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

Configurar o gerenciador de arquivos não deve implicar mudanças indiscriminadas nas associações MIME nem instalação silenciosa de componentes auxiliares.
