---
title: Configurar rede
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0009
  - 13-configure-localization.md
  - 15-configure-users.md
---

# 14 — Configurar rede

## Objetivo

Configurar a identidade local da máquina e habilitar NetworkManager para o primeiro boot.

O hostname padrão é:

```text
linux-workstation
```

O `/etc/hosts` é renderizado a partir de:

```text
system/network/hosts.template
```

## Execução

Dentro do chroot:

```bash
profiles/dell-latitude-e5470/01-installation/14-configure-network/run.sh
```

Outro hostname pode ser informado com `--hostname`. O script valida o formato do nome, exige que `networkmanager` já esteja instalado e solicita confirmação `NETWORK`.

## Alterações

- grava `/etc/hostname`;
- renderiza `/etc/hosts` com entradas IPv4/IPv6 de localhost e `127.0.1.1` para o hostname;
- habilita `NetworkManager.service` para o primeiro boot.

Nenhum SSID, senha Wi-Fi ou profile de conexão é criado pelo projeto nesta etapa.

## Verificação

O passo só passa quando os arquivos contêm o hostname esperado, o NetworkManager está habilitado e não existem profiles inesperados em `/etc/NetworkManager/system-connections`.

## Próximo playbook

```text
15-configure-users.md
```
