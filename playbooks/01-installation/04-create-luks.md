---
title: Criar o volume LUKS2
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

# 04 — Criar o volume LUKS2

## Objetivo

Criptografar a partição destinada ao sistema utilizando LUKS2.

Ao final deste playbook, a partição estará protegida por criptografia e disponível para abertura durante a instalação.

---

# Pré-requisitos

* Disco particionado conforme o playbook anterior.
* Partição destinada ao sistema identificada corretamente.

> **Atenção:** `cryptsetup luksFormat` remove permanentemente qualquer dado existente na partição selecionada.

---

# Resultado esperado

Ao concluir este playbook:

* a partição do sistema estará formatada com LUKS2;
* será possível abrir o volume criptografado;
* um dispositivo mapeado estará disponível para as próximas etapas.

Nenhum sistema de arquivos será criado neste momento.

---

# Procedimento

## 1. Identificar a partição

Confirme dispositivo, tamanho, disco de origem e finalidade da partição.

## 2. Exigir confirmação destrutiva

Imediatamente antes de `cryptsetup luksFormat`, solicite confirmação forte conforme `docs/standards.md`.

O usuário deverá digitar exatamente:

```text
ERASE
```

Qualquer outra entrada deverá cancelar o procedimento.

## 3. Inicializar o volume LUKS2

Somente após a confirmação, inicialize a partição utilizando LUKS2.

Durante esta etapa será solicitada uma senha de desbloqueio. Escolha uma senha forte e armazene-a de forma segura.

## 4. Abrir o volume criptografado

Desbloqueie o volume recém-criado e disponibilize o dispositivo pelo device mapper.

## 5. Confirmar o mapeamento

Verifique se o dispositivo criptografado foi aberto corretamente.

---

# Verificação

Confirme que:

* a partição utiliza LUKS2;
* o volume foi aberto com sucesso;
* o dispositivo mapeado está disponível;
* não houve erro durante a abertura.

---

# Problemas comuns

## Partição incorreta

Não execute `luksFormat`. Retorne à identificação do dispositivo.

## Confirmação diferente de `ERASE`

Cancele a operação.

## Senha incorreta

Confirme a senha utilizada durante a criação do volume.

## Volume não pode ser aberto

Verifique se a inicialização do LUKS foi concluída e se a partição correta foi selecionada.

---

# Próximo playbook

```text
05-create-btrfs.md
```

---

# Referências

* Arch Wiki — dm-crypt
* Arch Wiki — LUKS
* Arch Wiki — cryptsetup
* `docs/standards.md`

---

# Lições aprendidas

A confirmação forte deve ocorrer imediatamente antes da ação destrutiva, mesmo quando o playbook já contém avisos de risco.
