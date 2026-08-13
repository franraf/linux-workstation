---
title: Configurar o journald
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - architecture.md
  - ADR-0002
  - ADR-0003
  - ADR-0004
---

# 06 — Configurar o journald

## Objetivo

Configurar armazenamento persistente e limites do `systemd-journald` a partir de uma fonte versionada compartilhada.

## Fonte canônica

```text
system/systemd/journald/10-linux-workstation.conf
```

O `run.sh` apenas instala essa fonte em `/etc/systemd/journald.conf.d/10-linux-workstation.conf`, prepara `/var/log/journal`, reinicia o serviço e valida o resultado.

## Resultado esperado

* `Storage=persistent` aplicado;
* limites de uso e retenção correspondentes à fonte versionada;
* `/var/log/journal` preparado para persistência;
* `systemd-journald.service` operacional;
* journal verificável com `journalctl --verify`.

## Procedimento

Execute:

```bash
sudo ./run.sh
```

Autorize a alteração digitando `JOURNAL` quando solicitado.

O script não deve gerar configuração por heredoc. Mudanças de política devem ser realizadas primeiro no arquivo canônico sob `system/`.

## Verificação

Confirme que o arquivo instalado é idêntico à fonte versionada, que o serviço voltou ao estado ativo e que o armazenamento persistente pode ser lido.

## Próximo playbook

```text
07-configure-zram.md
```

## Referências

* Arch Wiki — systemd-journald
* Arch Wiki — Journal
* Arch Wiki — systemd
