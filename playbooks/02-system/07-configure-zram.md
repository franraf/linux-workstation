---
title: Configurar ZRAM
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0009

---

# 07 — Configurar ZRAM

## Objetivo

Configurar swap comprimido com `zram-generator` usando uma fonte versionada.

## Fonte canônica

```text
system/systemd/zram/10-linux-workstation.conf
```

Destino:

```text
/etc/systemd/zram-generator.conf.d/10-linux-workstation.conf
```

## Execução

```bash
sudo ./run.sh
```

## Resultado esperado

* `zram-generator` instalado;
* configuração instalada sem divergência;
* `/dev/zram0` criado;
* swap ZRAM ativo com algoritmo, tamanho e prioridade esperados.

## Regra arquitetural

Tamanho, algoritmo de compressão e prioridade pertencem ao arquivo em `system/`, não ao Bash.

## Próximo playbook

```text
08-configure-trim.md
```
