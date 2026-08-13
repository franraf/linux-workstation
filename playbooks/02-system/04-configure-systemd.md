---
title: Configurar systemd
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0009

---

# 04 — Configurar systemd

## Objetivo

Aplicar a baseline global do gerenciador systemd sem manter os valores de configuração dentro do script.

## Fonte canônica

```text
system/systemd/10-linux-workstation.conf
```

Destino:

```text
/etc/systemd/system.conf.d/10-linux-workstation.conf
```

## Execução

```bash
sudo ./run.sh
```

## Resultado esperado

* a fonte versionada estará instalada com ownership `root:root`;
* `systemd-analyze cat-config systemd/system.conf` aceitará a configuração;
* o manager systemd refletirá a baseline definida pelo repositório.

## Regra arquitetural

O `run.sh` deve orquestrar instalação, reload e validação. Valores como timeouts e watchdog pertencem ao arquivo em `system/`, não ao Bash.

## Próximo playbook

```text
05-configure-time-sync.md
```
