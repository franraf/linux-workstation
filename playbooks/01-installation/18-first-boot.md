
---

title: Primeiro boot
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

# 17 — Primeiro boot

## Objetivo

Inicializar o sistema recém-instalado e validar que a arquitetura foi implementada corretamente.

Ao final deste playbook, a workstation deverá iniciar utilizando o sistema instalado no disco, encerrando a fase de instalação.

---

# Pré-requisitos

* Bootloader instalado.
* Ambiente `arch-chroot` encerrado.
* Todos os sistemas de arquivos desmontados corretamente.
* Mídia de instalação removida.

---

# Resultado esperado

Ao concluir este playbook:

* o sistema inicializará a partir do disco interno;
* o volume criptografado será desbloqueado durante o processo de boot;
* o sistema chegará à tela de autenticação sem erros.

---

# Procedimento

## 1. Encerrar o ambiente de instalação

Saia do ambiente `chroot`.

Confirme que não existem operações pendentes.

---

## 2. Desmontar os sistemas de arquivos

Desmonte todos os sistemas de arquivos montados durante a instalação.

Feche o volume criptografado conforme o procedimento recomendado.

---

## 3. Reiniciar o computador

Reinicie o sistema.

Remova a mídia de instalação quando apropriado.

---

## 4. Acompanhar a inicialização

Observe o processo de boot.

Confirme que:

* o firmware localiza o bootloader;
* o bootloader inicia corretamente;
* o volume criptografado é solicitado;
* o kernel é carregado;
* o sistema conclui a inicialização.

---

## 5. Autenticar-se

Efetue login utilizando o usuário criado durante a instalação.

---

# Verificação

Confirme que:

* o sistema inicializou pelo disco interno;
* o login foi realizado com sucesso;
* data e hora estão corretas;
* hostname corresponde ao esperado;
* a conectividade de rede está funcional;
* os sistemas de arquivos foram montados conforme o `fstab`;
* não existem mensagens críticas durante a inicialização.

---

# Problemas comuns

## O bootloader não inicia

Verifique a configuração UEFI e confirme que a entrada de inicialização existe.

---

## O volume criptografado não pode ser desbloqueado

Revise a configuração do initramfs e do bootloader.

---

## O sistema entra em modo de emergência

Verifique o conteúdo do `fstab` e confirme que todos os sistemas de arquivos podem ser montados.

---

## Falha na autenticação

Confirme a criação do usuário e a configuração das credenciais.

---

# Próximos passos

Com a instalação concluída, prossiga para os playbooks da fase **02-system**, iniciando pela configuração dos componentes fundamentais da workstation.

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — systemd
* Arch Wiki — Boot process

---

# Lições aprendidas

Registrar aqui qualquer ajuste realizado após o primeiro boot, problemas identificados durante a inicialização ou melhorias incorporadas ao processo de instalação.
