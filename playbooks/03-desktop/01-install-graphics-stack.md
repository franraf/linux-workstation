---
title: Instalar a stack gráfica
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

# 01 — Instalar a stack gráfica

## Objetivo

Instalar e validar a base gráfica necessária para uma sessão Wayland e para a posterior instalação do Hyprland.

Este playbook instala capacidade. Ele não configura a sessão gráfica nem aplica personalizações.

## Pré-requisitos

* fase `02-system` concluída e validada;
* hardware gráfico identificado pelo perfil;
* Pacman operacional;
* acesso administrativo disponível.

## Fonte declarativa

A lista de pacotes deve residir em `packages/desktop/` e ser selecionada pelo perfil de hardware conforme a ADR-0009.

Para o perfil Dell Latitude E5470, a implementação utiliza:

```text
packages/desktop/graphics-intel-amd.txt
```

A lista contempla a base Wayland/XWayland e os componentes Intel/AMD necessários ao hardware do perfil.

## Procedimento

1. Confirmar as GPUs presentes e os drivers de kernel esperados.
2. Carregar a lista declarativa de pacotes correspondente ao perfil.
3. Validar que os pacotes declarados estão disponíveis nos repositórios configurados.
4. Instalar somente os pacotes ausentes.
5. Confirmar que os módulos de kernel esperados estão presentes.
6. Confirmar a disponibilidade das ferramentas de validação gráfica instaladas pela stack.

## Verificação

Confirme que:

* a GPU integrada esperada foi identificada;
* a GPU dedicada opcional foi identificada quando presente;
* `i915` está carregado no hardware Intel;
* `amdgpu` é reconhecido quando a GPU AMD estiver ativa;
* os pacotes declarados estão instalados;
* ferramentas de OpenGL, VA-API e Vulkan estão disponíveis;
* falhas de inicialização dependentes de uma sessão gráfica são registradas para validação posterior, e não tratadas como erro de instalação quando a ferramenta não pode inicializar fora da sessão.

## Fora de escopo

Este playbook não deve:

* instalar Hyprland;
* configurar monitores;
* configurar variáveis de sessão;
* definir GPU principal por configuração do compositor;
* aplicar aparência ou atalhos.

## Próximo playbook

```text
02-install-compositor.md
```

## Lições aprendidas

A validação de uma stack gráfica deve distinguir a presença correta dos drivers e ferramentas da capacidade de inicializar APIs que dependem de uma sessão gráfica já ativa.
