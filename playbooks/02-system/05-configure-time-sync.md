---
title: Configurar sincronização de horário
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0009

---

# 05 — Configurar sincronização de horário

## Objetivo

Configurar `systemd-timesyncd` a partir de uma fonte versionada e habilitar sincronização de horário via rede.

## Fonte canônica

```text
system/systemd/timesyncd/10-linux-workstation.conf
```

Destino:

```text
/etc/systemd/timesyncd.conf.d/10-linux-workstation.conf
```

## Execução

```bash
sudo ./run.sh
```

## Resultado esperado

* `systemd-timesyncd.service` habilitado e ativo;
* NTP habilitado pelo systemd;
* fonte canônica instalada sem divergência;
* sincronização efetiva validada ou registrada como warning transitório.

## Regra arquitetural

Servidores NTP e fallback pertencem ao arquivo em `system/`; o script apenas instala, habilita, reinicia e valida.

## Próximo playbook

```text
06-configure-journald.md
```
