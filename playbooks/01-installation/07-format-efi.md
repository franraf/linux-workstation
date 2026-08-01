---

title: Formatar a partição EFI
version: 1.0
status: Draft
author: Rafael
last_review: 2026-08-01
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 07 — Formatar a partição EFI

## Objetivo

Formatar a EFI System Partition com um sistema de arquivos compatível com o firmware UEFI.

Ao final deste playbook, a partição EFI estará preparada para ser montada e receber os arquivos do bootloader.

---

# Pré-requisitos

* Ambiente de instalação inicializado em modo UEFI.
* Disco particionado.
* EFI System Partition criada.
* Partição do sistema identificada e preparada.

---

# Resultado esperado

Ao concluir este playbook:

* a EFI System Partition estará formatada como FAT32;
* a partição continuará identificada como ESP;
* o sistema estará preparado para montar a partição em `/boot`.

---

# Procedimento

## 1. Identificar a partição EFI

Confirme qual partição foi criada como EFI System Partition.

Verifique:

* dispositivo;
* tamanho;
* tipo da partição;
* disco ao qual pertence.

Não prossiga caso exista dúvida sobre a partição selecionada.

---

## 2. Confirmar que a partição não está montada

Verifique se a partição EFI não está atualmente montada.

Desmonte-a antes de realizar qualquer operação de formatação.

---

## 3. Formatar a partição

Crie um sistema de arquivos FAT32 na EFI System Partition.

A formatação apagará qualquer conteúdo anteriormente presente na partição.

---

## 4. Aguardar a atualização dos dispositivos

Confirme que o sistema reconheceu o novo sistema de arquivos antes de prosseguir.

---

## 5. Validar o resultado

Verifique se:

* o sistema de arquivos é FAT;
* a partição mantém o tipo EFI System;
* um identificador de sistema de arquivos foi gerado;
* a partição permanece desmontada.

---

# Verificação

Confirme que:

* a partição correta foi formatada;
* o sistema de arquivos é FAT32;
* a partição está identificada como ESP;
* nenhuma outra partição foi alterada;
* a partição está pronta para montagem em `/boot`.

---

# Problemas comuns

## Partição incorreta selecionada

Interrompa o procedimento antes de executar a formatação.

Revise o particionamento e identifique novamente a EFI System Partition.

---

## Partição montada

Desmonte a partição antes de formatá-la.

---

## Ferramenta de formatação indisponível

Confirme que os utilitários necessários para criação de sistemas de arquivos FAT estão disponíveis no ambiente de instalação.

---

## Sistema de arquivos não reconhecido

Aguarde a atualização dos dispositivos e revise os registros do sistema antes de repetir o procedimento.

---

# Próximo playbook

Após formatar e validar a partição EFI, prossiga para:

```text
08-mount-filesystems.md
```

---

# Referências

* Arch Wiki — EFI system partition
* Arch Wiki — Installation guide
* Documentação dos utilitários de sistemas de arquivos FAT

---

# Lições aprendidas

Registrar aqui particularidades do firmware, problemas durante a formatação ou ajustes necessários para futuras instalações.
