---
title: Formatar a partição EFI
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

# 07 — Formatar a partição EFI

## Objetivo

Formatar a EFI System Partition como FAT32 para receber os arquivos do bootloader.

---

# Pré-requisitos

* Ambiente de instalação inicializado em modo UEFI.
* Disco particionado.
* EFI System Partition identificada corretamente.

> **Atenção:** a formatação apaga qualquer conteúdo existente na partição selecionada.

---

# Resultado esperado

Ao concluir este playbook:

* a ESP estará formatada como FAT32;
* a partição continuará identificada como EFI System Partition;
* estará preparada para montagem em `/boot`.

---

# Procedimento

## 1. Identificar a partição EFI

Confirme dispositivo, tamanho, tipo e disco de origem.

Não prossiga em caso de dúvida.

## 2. Confirmar que a partição não está montada

Desmonte a ESP antes de qualquer formatação.

## 3. Exigir confirmação destrutiva

Imediatamente antes da formatação, solicite confirmação forte conforme `docs/standards.md`.

O usuário deverá digitar exatamente:

```text
ERASE
```

Qualquer outra entrada deverá cancelar o procedimento.

## 4. Formatar a partição

Somente após a confirmação, crie o sistema de arquivos FAT32 na ESP.

## 5. Validar o resultado

Confirme que o sistema reconheceu o novo filesystem e que a partição permanece com o tipo EFI System Partition.

---

# Verificação

Confirme que:

* a partição correta foi formatada;
* o filesystem é FAT32;
* a partição continua identificada como ESP;
* nenhuma outra partição foi alterada;
* a ESP está pronta para montagem em `/boot`.

---

# Problemas comuns

## Partição incorreta

Não execute a formatação. Identifique novamente a ESP.

## Confirmação diferente de `ERASE`

Cancele a operação.

## Partição montada

Desmonte a partição antes de formatá-la.

## Ferramenta de formatação indisponível

Confirme a disponibilidade dos utilitários FAT no ambiente de instalação.

---

# Próximo playbook

```text
08-mount-filesystems.md
```

---

# Referências

* Arch Wiki — EFI system partition
* Arch Wiki — Installation guide
* `docs/standards.md`

---

# Lições aprendidas

A política de confirmação destrutiva também se aplica à ESP, mesmo quando a partição acabou de ser criada durante a instalação atual.
