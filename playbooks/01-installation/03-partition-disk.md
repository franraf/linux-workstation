---

title: Particionar o disco
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

Liste os discos disponíveis.

```bash
lsblk -o NAME,SIZE,TYPE,MODEL
```

Confirme cuidadosamente qual será o disco utilizado na instalação.

---

## 2. Confirmar o dispositivo de destino

Antes de modificar qualquer disco, confirme:

* capacidade;
* modelo;
* ausência de dados importantes.

Nunca prossiga em caso de dúvida.

---

## 3. Remover a tabela de partições existente

Apague todas as partições existentes no disco de destino.

Este procedimento deverá resultar em um disco completamente vazio.

---

## 4. Criar uma nova tabela GPT

Inicialize o disco utilizando GPT.

Esta é a única tabela de partições suportada pela arquitetura do projeto.

---

## 5. Criar a EFI System Partition (ESP)

Criar uma partição destinada ao firmware UEFI.

Características:

* tipo: EFI System Partition;
* início do disco;
* tamanho conforme definido pela arquitetura.

---

## 6. Criar a partição do sistema

Criar uma segunda partição ocupando o restante do disco.

Esta partição será utilizada no próximo playbook para criação do volume criptografado LUKS2.

---

## 7. Gravar as alterações

Salvar a nova tabela de partições.

Caso necessário, solicitar ao kernel a releitura da tabela.

---

# Verificação

Confirme que:

* a tabela de partições é GPT;
* existe exatamente uma ESP;
* existe exatamente uma partição destinada ao sistema;
* não existem partições inesperadas.

Exemplo de verificação:

```bash
lsblk -f
```

---

# Problemas comuns

## Disco incorreto selecionado

Interrompa imediatamente o procedimento.

Não continue até identificar corretamente o dispositivo.

---

## A tabela antiga continua sendo exibida

Solicite ao kernel a releitura da tabela de partições ou reinicie o ambiente live.

---

## O firmware não reconhece a ESP

Verifique se a partição foi criada com o tipo correto e se está marcada como EFI System Partition.

---

# Próximo playbook

Após validar o particionamento, prossiga para:

```text
04-create-luks.md
```

---

# Referências

* Arch Wiki — Partitioning
* Arch Wiki — GPT
* Arch Wiki — EFI System Partition

---

# Lições aprendidas

Registrar particularidades encontradas durante o particionamento de diferentes modelos de hardware ou controladoras de armazenamento.
