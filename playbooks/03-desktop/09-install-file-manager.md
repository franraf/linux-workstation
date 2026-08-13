---
title: Instalar gerenciador de arquivos
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0006
* ADR-0007
* ADR-0009

---

# 09 — Instalar gerenciador de arquivos

## Objetivo

Instalar o Thunar e as integrações básicas previstas pelo projeto, sem configurar aparência, ações personalizadas ou atalhos.

## Pré-requisitos

* `02-install-compositor` concluído;
* Hyprland instalado.

## Fonte declarativa

```text
packages/desktop/file-manager.txt
```

Baseline:

```text
thunar
gvfs
tumbler
thunar-volman
```

## Procedimento

1. Validar que o compositor está instalado.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar o executável `thunar`.
5. Confirmar a presença de `gvfs`, `tumbler` e `thunar-volman`.
6. Confirmar que a versão do Thunar pode ser consultada.

## Verificação

Confirme que:

* o pacote `thunar` está instalado;
* o executável está disponível;
* as integrações declaradas estão instaladas;
* a versão pode ser consultada.

## Fora de escopo

Não abrir o gerenciador como requisito desta etapa e não realizar operações de arquivos como teste funcional. Navegação, thumbnails, mídias removíveis e integração com a sessão serão validadas após configuração.

## Próximo playbook

```text
10-install-font-stack.md
```
