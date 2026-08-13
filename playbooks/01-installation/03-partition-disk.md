---
title: Particionar o disco
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

# 03 — Particionar o disco

## Objetivo

Preparar o disco para a instalação do sistema operacional, criando a tabela de partições GPT e as partições definidas pela arquitetura do projeto.

Ao final deste playbook, o disco estará pronto para receber a criptografia LUKS2.

---

# Pré-requisitos

* Mídia de instalação inicializada em modo UEFI.
* Firmware configurado conforme o playbook anterior.
* Disco de destino identificado corretamente.

> **Atenção:** este procedimento remove permanentemente todos os dados existentes no disco selecionado.

---

# Resultado esperado

Ao concluir este playbook, o disco deverá possuir:

* uma tabela de partições GPT;
* uma partição EFI (ESP);
* uma partição destinada ao LUKS2.

Nenhum sistema de arquivos será criado nesta etapa.

---

# Procedimento

## 1. Identificar os dispositivos de armazenamento

Liste os discos disponíveis:

```bash
lsblk -o NAME,SIZE,TYPE,MODEL
```

Confirme cuidadosamente qual será o disco utilizado na instalação.

## 2. Confirmar o dispositivo de destino

Antes de modificar qualquer disco, confirme capacidade, modelo e ausência de dados importantes.

Nunca prossiga em caso de dúvida.

## 3. Exigir confirmação destrutiva

Antes do primeiro comando que altere a tabela de partições, solicite confirmação explícita conforme `docs/standards.md`.

O usuário deverá digitar exatamente:

```text
ERASE
```

Qualquer outra entrada deverá cancelar o procedimento.

## 4. Remover a tabela de partições existente

Somente após a confirmação forte, apague as partições existentes no disco de destino.

## 5. Criar uma nova tabela GPT

Inicialize o disco utilizando GPT.

## 6. Criar a EFI System Partition

Crie uma ESP no início do disco com o tamanho definido pela arquitetura.

## 7. Criar a partição do sistema

Crie uma segunda partição ocupando o restante do disco para uso pelo LUKS2.

## 8. Gravar as alterações

Salve a nova tabela de partições e, quando necessário, solicite ao kernel a releitura da tabela.

---

# Verificação

Confirme que:

* a tabela de partições é GPT;
* existe exatamente uma ESP;
* existe exatamente uma partição destinada ao sistema;
* não existem partições inesperadas.

```bash
lsblk -f
```

---

# Problemas comuns

## Disco incorreto selecionado

Interrompa imediatamente o procedimento. Não continue até identificar corretamente o dispositivo.

## Confirmação diferente de `ERASE`

Cancele a operação. Confirmações genéricas como `y`, `yes` ou Enter não atendem ao padrão do projeto.

## A tabela antiga continua sendo exibida

Solicite ao kernel a releitura da tabela de partições ou reinicie o ambiente live.

## O firmware não reconhece a ESP

Verifique se a partição foi criada com o tipo correto.

---

# Próximo playbook

```text
04-create-luks.md
```

---

# Referências

* Arch Wiki — Partitioning
* Arch Wiki — GPT
* Arch Wiki — EFI System Partition
* `docs/standards.md`

---

# Lições aprendidas

Operações de armazenamento devem exigir confirmação forte imediatamente antes do primeiro efeito destrutivo, e não apenas um aviso textual no início do documento.
