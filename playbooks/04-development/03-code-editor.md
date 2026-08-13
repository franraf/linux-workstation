---
title: Editor de código
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005

---

# 03 — Editor de código

## Objetivo

Adicionar à workstation um editor de código integrado ao Git, ao terminal e ao modelo de configuração versionada do projeto.

A implementação adotada utiliza o Visual Studio Code.

A integração completa com Dev Containers será validada somente após a plataforma de contêineres ser configurada no playbook seguinte.

---

# Pré-requisitos

* Ambiente de shell configurado.
* Controle de versão concluído.
* Sessão gráfica operacional.

---

# Resultado esperado

Ao concluir este playbook:

* o editor estará instalado e iniciará normalmente;
* configurações e extensões previstas estarão versionadas e aplicadas;
* Git e terminal integrado estarão funcionais;
* o editor estará preparado para a integração com Dev Containers, ainda não considerada validada nesta etapa.

---

# Estrutura da configuração

Mantenha configurações reproduzíveis nos dotfiles, utilizando a estrutura nativa do editor.

Exemplo:

```text
dotfiles/
└── vscode/
    ├── settings.json
    ├── keybindings.json
    ├── extensions.txt
    └── snippets/
```

---

# Procedimento

## 1. Instalar o editor

Instale a implementação definida pela arquitetura.

## 2. Restaurar a configuração

Aplique preferências, atalhos, snippets e demais arquivos versionados.

## 3. Instalar as extensões declaradas

Utilize a lista versionada como fonte da verdade. Evite extensões permanentes fora desse controle sem justificativa.

A extensão necessária para Dev Containers pode ser instalada agora, mas seu funcionamento completo depende da plataforma do próximo playbook.

## 4. Configurar integrações disponíveis

Valide nesta etapa:

* Git;
* shell;
* terminal integrado;
* edição e salvamento de arquivos.

## 5. Validar a experiência local

Abra um projeto local de teste e confirme edição, terminal integrado e operações de Git.

Não exija a criação de um Dev Container nesta etapa.

---

# Verificação

Confirme que:

* o editor inicia corretamente;
* a configuração versionada foi aplicada;
* as extensões declaradas estão instaladas;
* Git funciona no editor;
* o terminal integrado funciona;
* não existem erros críticos durante o uso local.

A validação de Dev Containers pertence a `04-container-platform.md` e ao gate `07-development-validation.md`.

---

# Problemas comuns

## Editor não inicia

Confirme instalação e sessão gráfica.

## Configuração não aplicada

Revise a origem versionada dos arquivos e o mecanismo de restauração.

## Extensões ausentes

Compare o estado instalado com a lista versionada.

## Dev Containers indisponíveis

Isso não é falha deste playbook enquanto a plataforma de contêineres ainda não foi configurada.

---

# Próximo playbook

```text
04-container-platform.md
```

---

# Referências

* Documentação oficial do Visual Studio Code
* Development Containers Specification
* ADR-0005 — Modularizar configurações por capacidade

---

# Lições aprendidas

Uma etapa não deve validar uma capacidade que depende explicitamente de um playbook posterior. A integração com Dev Containers só é verificável após a plataforma de contêineres estar operacional.
