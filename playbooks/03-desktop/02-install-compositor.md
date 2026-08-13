---
title: Instalar compositor
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

# 02 — Instalar compositor

## Objetivo

Instalar o Hyprland e validar seus artefatos essenciais, sem configurar a sessão gráfica.

## Pré-requisitos

* `01-install-graphics-stack` concluído;
* `mesa` e `wayland` instalados;
* Pacman operacional.

## Fonte declarativa

```text
packages/desktop/compositor.txt
```

Baseline:

```text
hyprland
```

## Procedimento

1. Validar os pré-requisitos gráficos.
2. Carregar e validar a lista declarativa.
3. Instalar somente os pacotes ausentes.
4. Confirmar os executáveis `Hyprland` e `start-hyprland`.
5. Confirmar que `Hyprland --version` retorna informação válida.

## Verificação

Confirme que:

* o pacote `hyprland` está instalado;
* `Hyprland` está disponível;
* `start-hyprland` está disponível;
* a versão do compositor pode ser consultada.

## Fora de escopo

Não iniciar uma sessão como requisito deste playbook e não criar `hyprland.conf`. Inicialização real e validação de configuração pertencem ao bloco de configuração e ao gate final.

## Próximo playbook

```text
03-install-status-bar.md
```
