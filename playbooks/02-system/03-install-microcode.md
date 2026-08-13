---
title: Instalar microcode do processador
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

# 03 — Instalar microcode do processador

## Objetivo

Instalar e validar o microcode Intel previsto pelo perfil Dell Latitude E5470.

## Escopo do perfil

O script valida que o processador reporta fabricante Intel antes de instalar `intel-ucode`. A imagem esperada é:

```text
/boot/intel-ucode.img
```

A entrada do systemd-boot criada na fase `01-installation` deve referenciar essa imagem; este passo não reescreve a política do bootloader.

## Procedimento

Execute:

```bash
sudo ./run.sh
```

Autorize digitando `MICROCODE` quando solicitado. Se `intel-ucode` já estiver instalado, o script apenas valida o pacote, a imagem e a referência de boot.

## Verificação

Confirme que:

* a CPU é Intel;
* `intel-ucode` está instalado;
* `/boot/intel-ucode.img` existe e não está vazio;
* uma entrada do systemd-boot referencia a imagem de microcode.

A confirmação de que o microcode foi efetivamente carregado ocorre na validação runtime da fase.

## Próximo playbook

```text
04-configure-systemd.md
```

## Referências

* Arch Wiki — Microcode
* Arch Wiki — Intel
* systemd-boot
