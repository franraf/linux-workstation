---
title: Criar o sistema de arquivos Btrfs
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004
* standards.md

---

# 05 — Criar o sistema de arquivos Btrfs

## Objetivo

Criar o sistema de arquivos Btrfs sobre o volume criptografado preparado no playbook anterior.

---

# Pré-requisitos

* Volume LUKS2 criado e aberto.
* Dispositivo mapeado disponível e identificado.

> **Atenção:** a formatação remove permanentemente qualquer dado existente no volume selecionado.

---

# Resultado esperado

Ao concluir este playbook:

* o dispositivo mapeado conterá Btrfs;
* o sistema de arquivos estará pronto para montagem;
* ainda não existirão subvolumes personalizados.

---

# Procedimento

## 1. Confirmar o dispositivo mapeado

Verifique qual dispositivo corresponde ao volume criptografado aberto no playbook anterior e confirme que não está montado.

## 2. Exigir confirmação destrutiva

Imediatamente antes da formatação, solicite confirmação forte conforme `docs/standards.md`.

O usuário deverá digitar exatamente:

```text
ERASE
```

Qualquer outra entrada deverá cancelar o procedimento.

## 3. Criar o sistema de arquivos

Somente após a confirmação, formate o dispositivo utilizando Btrfs.

## 4. Confirmar a criação

Verifique se a formatação foi concluída sem erros.

---

# Verificação

Confirme que:

* o sistema de arquivos é Btrfs;
* o dispositivo correto foi alterado;
* o volume permanece acessível;
* não houve erro durante a formatação.

---

# Problemas comuns

## Dispositivo incorreto

Não formate. Retorne à identificação do mapper.

## Confirmação diferente de `ERASE`

Cancele a operação.

## Dispositivo ocupado

Confirme que o volume não está montado ou em uso.

## Ferramentas Btrfs indisponíveis

Confirme a disponibilidade de `btrfs-progs` no ambiente live.

---

# Próximo playbook

```text
06-create-subvolumes.md
```

---

# Referências

* Arch Wiki — Btrfs
* Arch Wiki — mkfs.btrfs
* `docs/standards.md`

---

# Lições aprendidas

Formatações devem seguir a mesma política de confirmação forte aplicada ao particionamento e à criação do LUKS.
