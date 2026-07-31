---

title: Configurar o firmware (UEFI)
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

# 02 — Configurar o firmware (UEFI)

## Objetivo

Configurar o firmware da máquina para atender aos requisitos da arquitetura do projeto antes da instalação do Arch Linux.

Ao final deste playbook, o computador deverá estar apto para inicializar a mídia de instalação em modo UEFI.

---

# Pré-requisitos

* Mídia de instalação preparada.
* Computador desligado.

---

# Resultado esperado

Ao concluir este playbook:

* o firmware estará configurado conforme os padrões do projeto;
* a mídia de instalação poderá ser inicializada em modo UEFI.

---

# Procedimento

## 1. Acessar o Setup do firmware

Ligue o computador e acesse a configuração do firmware (BIOS/UEFI) utilizando a tecla correspondente ao fabricante.

---

## 2. Confirmar o modo de inicialização

Verifique se o firmware está configurado para inicialização em modo **UEFI**.

Caso exista suporte simultâneo para Legacy/CSM, selecione apenas UEFI.

---

## 3. Verificar o Secure Boot

Para a primeira versão deste projeto, mantenha o Secure Boot desabilitado.

A habilitação poderá ser documentada em uma versão futura da arquitetura.

---

## 4. Verificar o modo do controlador de armazenamento

Quando a plataforma oferecer essa configuração, utilize o modo **AHCI**.

Evite modos de compatibilidade ou configurações específicas de sistemas operacionais proprietários.

---

## 5. Ajustar a ordem de boot

Configure o pendrive contendo a mídia oficial do Arch Linux como primeiro dispositivo de inicialização.

Alternativamente, utilize o menu de boot temporário do firmware.

---

## 6. Salvar as alterações

Salve as configurações e reinicie o computador.

---

# Verificação

Antes de continuar, confirme que:

* o sistema inicializa pelo pendrive;
* a mídia inicia em modo UEFI;
* nenhuma mensagem relacionada ao Secure Boot impede a inicialização.

No ambiente live, confirme a inicialização UEFI:

```bash
ls /sys/firmware/efi
```

Se o diretório existir, o sistema foi iniciado corretamente em modo UEFI.

---

# Problemas comuns

## O computador inicia o sistema instalado em vez do pendrive

Verifique a ordem de boot ou utilize o menu de seleção temporária de dispositivos.

---

## O diretório `/sys/firmware/efi` não existe

O sistema foi iniciado em modo Legacy.

Retorne ao firmware e configure a inicialização exclusivamente em modo UEFI.

---

## O pendrive não aparece como dispositivo inicializável

Verifique se a mídia foi gravada corretamente e se o firmware reconhece o dispositivo.

---

# Próximo playbook

Após validar a configuração do firmware, prossiga para:

```text
03-partition-disk.md
```

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — Unified Extensible Firmware Interface (UEFI)

---

# Lições aprendidas

Registrar aqui eventuais particularidades do firmware da máquina, como nomenclatura das opções, limitações ou comportamentos específicos observados durante a instalação.
