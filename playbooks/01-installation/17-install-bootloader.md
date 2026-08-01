---

title: Instalar o bootloader
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 16 — Instalar o bootloader

## Objetivo

Instalar e configurar o bootloader definido pela arquitetura do projeto.

Ao final deste playbook, o firmware UEFI será capaz de localizar e iniciar o sistema operacional instalado.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.
* Initramfs configurado e gerado.
* Partição EFI montada.

---

# Resultado esperado

Ao concluir este playbook:

* o bootloader estará instalado na EFI System Partition;
* a entrada de inicialização UEFI estará disponível;
* a configuração do bootloader refletirá a arquitetura da workstation.

---

# Procedimento

## 1. Confirmar a partição EFI

Verifique se a EFI System Partition permanece montada no ponto definido pela arquitetura.

---

## 2. Instalar o bootloader

Instale o bootloader especificado pela arquitetura do projeto.

A instalação deverá utilizar o modo UEFI.

---

## 3. Gerar a configuração

Crie ou atualize os arquivos de configuração necessários para a inicialização do sistema.

---

## 4. Revisar a configuração

Confirme que a configuração contempla:

* kernel;
* initramfs;
* parâmetros de inicialização;
* volume criptografado;
* sistema de arquivos raiz.

---

## 5. Confirmar a instalação

Verifique se os arquivos do bootloader foram instalados corretamente na partição EFI.

---

# Verificação

Confirme que:

* o bootloader foi instalado sem erros;
* a configuração foi gerada com sucesso;
* a entrada UEFI está disponível;
* os arquivos necessários estão presentes na partição EFI.

---

# Problemas comuns

## Partição EFI não montada

Confirme a montagem antes da instalação.

---

## Entrada UEFI não criada

Verifique se a instalação foi realizada em modo UEFI e se o firmware permite o registro de novas entradas.

---

## Configuração incompleta

Revise os parâmetros utilizados durante a geração da configuração.

---

# Próximo playbook

Após validar a instalação do bootloader, prossiga para:

```text id="0m0g8u"
18-first-boot.md
```

---

# Referências

* Arch Wiki — systemd-boot
* Arch Wiki — Boot loader
* Arch Wiki — Unified Extensible Firmware Interface

---

# Lições aprendidas

Registrar aqui ajustes específicos do firmware, comportamento do bootloader ou observações relevantes encontradas durante futuras instalações.
