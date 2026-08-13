---
title: Instalar pacotes base
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0009

---

# 11 — Instalar pacotes base

## Objetivo

Instalar os utilitários fundamentais de administração, diagnóstico e operação diária da workstation a partir de uma fonte declarativa compartilhada.

## Pré-requisitos

* Sistema configurado.
* Pacman funcional.
* Serviços base configurados.

## Fonte canônica

```text
packages/system/base-workstation.txt
```

O `run.sh` desta etapa é apenas o orquestrador. Leitura, validação e instalação dos pacotes reutilizam `scripts/lib/packages.sh`.

## Execução

```bash
sudo ./run.sh
```

Opcionalmente, uma lista alternativa pode ser fornecida explicitamente:

```bash
sudo ./run.sh --package-file /caminho/lista.txt
```

## Resultado esperado

* todos os pacotes declarados estarão instalados;
* comandos essenciais estarão disponíveis;
* nenhuma segunda lista de pacotes será mantida dentro do profile ou do script.

## Verificação

O script deve:

* validar a fonte declarativa;
* validar disponibilidade dos pacotes;
* instalar somente os ausentes;
* validar o estado final dos pacotes;
* confirmar os comandos essenciais da baseline.

## Problemas comuns

### Pacote indisponível

Corrija o nome na fonte canônica. Não introduza exceções hardcoded no `run.sh`.

### Lista divergente no profile

Arquivos como `11-install-base-packages/packages.txt` são legado e devem ser removidos; a fonte canônica pertence a `packages/system/`.

## Próximo playbook

```text
12-system-validation.md
```

## Referências

* Arch Wiki — General recommendations
* Arch Wiki — Pacman
* ADR-0009 — Fontes compartilhadas para profiles
