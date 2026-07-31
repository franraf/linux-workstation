---

title: Preparar a mídia de instalação
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* ADR-0003
* ADR-0004
* architecture.md

---

# 01 — Preparar a mídia de instalação

## Objetivo

Preparar uma mídia de instalação oficial do Arch Linux, inicializável em modo UEFI, pronta para ser utilizada na instalação da workstation.

Ao final deste playbook, deverá existir um pendrive funcional contendo a imagem oficial do Arch Linux.

---

# Pré-requisitos

## Hardware

* Computador com acesso à Internet.
* Pendrive de pelo menos 2 GiB (recomendado: 4 GiB ou mais).

## Software

* Navegador web.
* Ferramenta para gravação de imagens (`dd`, Rufus, Ventoy, Balena Etcher ou equivalente).

---

# Resultado esperado

Ao concluir este playbook será possível:

* inicializar o computador utilizando o pendrive;
* acessar o ambiente live oficial do Arch Linux em modo UEFI.

Nenhuma alteração será realizada no disco da workstation.

---

# Procedimento

## 1. Baixar a imagem oficial

Obtenha a ISO mais recente do Arch Linux.

Evite utilizar imagens modificadas ou distribuídas por terceiros.

---

## 2. Verificar a integridade

Antes de gravar a imagem, confirme sua integridade utilizando a soma SHA-256 publicada juntamente com a ISO.

A instalação deverá sempre utilizar uma imagem íntegra.

---

## 3. Gravar a mídia

Grave a ISO no pendrive utilizando a ferramenta de sua preferência.

Exemplos de ferramentas:

* `dd`
* Rufus
* Ventoy
* Balena Etcher

Independentemente da ferramenta utilizada, o resultado esperado é um pendrive inicializável em modo UEFI.

---

## 4. Ejetar corretamente

Após a gravação, ejete o dispositivo de forma segura antes de removê-lo.

Isso reduz a possibilidade de corrupção da mídia.

---

# Verificação

Antes de prosseguir para o próximo playbook, confirme que:

* a mídia foi criada sem erros;
* o computador reconhece o pendrive como dispositivo de boot;
* a inicialização ocorre em modo UEFI;
* o ambiente live do Arch Linux é carregado corretamente.

Caso qualquer uma dessas verificações falhe, recrie a mídia antes de continuar.

---

# Problemas comuns

## O pendrive não aparece como opção de boot

Verifique:

* se o firmware está configurado para inicialização UEFI;
* se a gravação da ISO foi concluída corretamente;
* se o pendrive está funcionando.

---

## O sistema inicia em modo Legacy

A instalação deste projeto pressupõe inicialização em modo UEFI.

Corrija a configuração do firmware antes de continuar.

---

## A ISO parece corrompida

Baixe novamente a imagem oficial e repita a verificação de integridade antes da gravação.

---

# Próximo playbook

Após confirmar que a mídia está funcional, prossiga para:

```text
02-configure-firmware.md
```

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — USB Flash Installation Medium

---

# Lições aprendidas

Registrar aqui qualquer incompatibilidade encontrada entre ferramentas de gravação, firmware ou dispositivos USB utilizados durante instalações futuras.
