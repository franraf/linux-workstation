---
title: Configurar serviços do sistema
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

# 09 — Configurar serviços do sistema

## Objetivo

Instalar e habilitar a baseline de serviços gerais da workstation sem absorver responsabilidades dos playbooks dedicados.

## Fonte canônica de pacotes

```text
packages/system/services.txt
```

A lista contém apenas os pacotes pertencentes a esta capacidade: NetworkManager e Bluetooth. ZRAM, OpenSSH, sincronização de tempo e TRIM continuam sob seus próprios passos.

## Serviços gerenciados

```text
NetworkManager.service
bluetooth.service
```

O NetworkManager deve permanecer habilitado e ativo. O Bluetooth deve permanecer habilitado; sua ativação imediata depende da presença de hardware exposto pelo kernel.

## Procedimento

Execute:

```bash
sudo ./run.sh
```

Autorize digitando `SERVICES` quando solicitado. O script consome `packages/system/services.txt` por meio de `scripts/lib/packages.sh`, instala apenas pacotes ausentes e habilita os serviços previstos.

## Verificação

Confirme que todos os pacotes declarados estão instalados, que os units existem, que `NetworkManager.service` está habilitado/ativo e que `bluetooth.service` está habilitado.

## Próximo playbook

```text
10-configure-ssh.md
```

## Referências

* Arch Wiki — NetworkManager
* Arch Wiki — Bluetooth
* Arch Wiki — systemd
