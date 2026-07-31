
---

title: Gerar o fstab
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

# 09 — Gerar o fstab

## Objetivo

Gerar o arquivo `fstab` do sistema instalado, registrando todos os sistemas de arquivos necessários para a inicialização da workstation.

Ao final deste playbook, o sistema instalado possuirá um arquivo `fstab` consistente e pronto para utilização durante o boot.

---

# Pré-requisitos

* Sistema base instalado.
* Todos os sistemas de arquivos permanecem montados em `/mnt`.

---

# Resultado esperado

Ao concluir este playbook:

* existirá um arquivo `fstab` em `/mnt/etc/fstab`;
* todas as partições e subvolumes utilizados pela arquitetura estarão registrados;
* o arquivo estará pronto para revisão antes do primeiro boot.

---

# Procedimento

## 1. Gerar o arquivo

Gere o arquivo `fstab` utilizando a ferramenta recomendada pelo Arch Linux.

O arquivo deverá ser criado diretamente no sistema instalado.

---

## 2. Revisar o conteúdo

Revise cuidadosamente o arquivo gerado.

Confirme que todas as entradas esperadas estão presentes e que correspondem à arquitetura do projeto.

---

## 3. Corrigir inconsistências, se necessário

Caso seja identificada qualquer inconsistência, realize os ajustes antes de prosseguir.

---

# Verificação

Confirme que:

* o arquivo `/mnt/etc/fstab` existe;
* todos os sistemas de arquivos esperados estão presentes;
* as opções de montagem estão corretas;
* não existem entradas duplicadas ou inválidas.

---

# Problemas comuns

## Entradas ausentes

Confirme se todos os sistemas de arquivos estavam montados antes da geração do `fstab`.

---

## UUID incorreto

Verifique se o dispositivo correto foi utilizado durante a geração.

---

## Opções de montagem inesperadas

Revise o arquivo antes de prosseguir para evitar problemas durante a inicialização.

---

# Próximo playbook

Após validar o `fstab`, prossiga para:

```text id="qwf99e"
10-enter-chroot.md
```

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — fstab
* Arch Wiki — genfstab

---

# Lições aprendidas

Registrar aqui ajustes realizados manualmente no `fstab`, alterações nas opções de montagem ou observações relevantes para futuras instalações.
