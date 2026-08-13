---
title: Configurar TRIM periódico
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0009

---

# 08 — Configurar TRIM periódico

## Objetivo

Validar suporte a discard através da pilha de armazenamento e habilitar `fstrim.timer` como política periódica de TRIM.

Esta etapa não possui arquivo próprio em `system/`: utiliza unidades fornecidas pelo systemd e valida a arquitetura de armazenamento já definida na instalação.

## Execução

```bash
sudo ./run.sh
```

## Resultado esperado

* raiz em Btrfs;
* discard disponível através do mapper criptografado;
* teste de `fstrim` concluído;
* `fstrim.timer` habilitado e ativo;
* ausência de dependência em discard contínuo do mount Btrfs.

## Regra arquitetural

Não duplique política de armazenamento aqui. Parâmetros de LUKS e layout Btrfs pertencem às fontes da fase `01-installation`; esta etapa apenas verifica se o estado resultante permite TRIM periódico.

## Próximo playbook

```text
09-configure-system-services.md
```
