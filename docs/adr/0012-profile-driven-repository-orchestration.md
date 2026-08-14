---
title: Orquestração do repositório orientada por profiles e manifests
version: 1.0
status: Accepted
author: Rafael
last_review: 2026-08-14
related:
  - ADR-0003
  - ADR-0004
  - ADR-0006
  - ADR-0009
  - architecture.md
  - roadmap.md
---

# ADR-0012 — Orquestração do repositório orientada por profiles e manifests

## Contexto

As fases 01 a 04 já possuem playbooks, scripts, fontes declarativas e validações próprias. Entretanto, sua execução ainda exige conhecer manualmente a árvore interna do profile e navegar até cada `run.sh`.

A próxima evolução precisa coordenar esses artefatos sem duplicar a lógica existente, sem esconder confirmações destrutivas e sem introduzir uma dependência de runtime que não esteja disponível na mídia oficial do Arch ou nas primeiras fases da instalação.

Os arquivos `profile.yaml` e `phase.yaml` já registram a ordem das fases e steps, modos de execução, entrypoints e gates de validação. Eles devem ser utilizados como fonte de orquestração em vez de criar uma segunda lista imperativa em outro script.

## Decisão

O projeto adotará um orquestrador de alto nível em Bash, localizado em `scripts/workstation`.

O orquestrador deverá:

* receber explicitamente um profile;
* descobrir fases e steps a partir dos manifests versionados;
* oferecer comandos de inspeção antes de comandos de execução;
* executar um step por vez, delegando toda lógica técnica ao `run.sh` correspondente;
* preservar prompts e confirmações implementados pelos próprios steps;
* nunca responder automaticamente confirmações destrutivas;
* falhar rapidamente quando manifests ou entrypoints estiverem inconsistentes;
* permitir evolução posterior para retomada segura e execução de fases completas.

A leitura dos manifests utilizará apenas Bash e ferramentas base como `awk`, `sed` e `grep`. O runner não dependerá de Python, Node.js, `yq` ou outro runtime que possa não existir antes da fase Development.

## Limites iniciais

A primeira implementação fornecerá somente:

* listagem das fases conhecidas pelo profile;
* listagem dos steps de uma fase;
* resolução do entrypoint de um step;
* execução explícita de um step;
* validação estrutural dos manifests antes da execução.

Execução automática de uma fase inteira, retomada após falha, persistência de estado e bootstrap desde a ISO serão adicionados incrementalmente após validação do runner básico.

## Privilégios

O orquestrador não será executado globalmente como root.

Cada step continuará sendo responsável por declarar e validar seu próprio contexto. Quando um step exigir root, o runner poderá invocá-lo via `sudo`; steps de validação ou de usuário permanecerão no contexto normal.

Essa política evita transformar todo o processo em uma sessão root e preserva as fronteiras já existentes nos scripts.

## Consequências

### Positivas

* elimina a necessidade de memorizar caminhos internos;
* reutiliza manifests já existentes como fonte de verdade;
* mantém cada step independente e testável;
* não adiciona runtime obrigatório ao bootstrap;
* cria base para retomada e automação futura.

### Negativas

* o parser Bash suportará deliberadamente apenas o subconjunto de YAML usado pelos manifests;
* mudanças estruturais no schema exigirão atualização dos testes do parser;
* a execução inicial continuará supervisionada e step-by-step.

## Validação

A implementação deverá possuir testes que confirmem:

* descoberta correta das fases existentes;
* preservação da ordem dos steps;
* resolução correta de entrypoints;
* rejeição de fase ou step inexistente;
* ausência de execução implícita de comandos destrutivos.
