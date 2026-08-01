---

title: Criar os subvolumes Btrfs
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

# 06 — Criar os subvolumes Btrfs

## Objetivo

Criar a estrutura de subvolumes Btrfs definida pela arquitetura do projeto.

Ao final deste playbook, o sistema de arquivos estará organizado e pronto para montagem.

---

# Pré-requisitos

* Volume LUKS2 aberto.
* Sistema de arquivos Btrfs criado.
* O sistema de arquivos ainda não deverá estar montado para instalação.

---

# Resultado esperado

Ao concluir este playbook, existirão os seguintes subvolumes:

* `@`
* `@home`
* `@var`
* `@var_log`
* `@var_cache`
* `@pkg`
* `@docker`
* `@snapshots`

Todos os subvolumes deverão existir diretamente no volume Btrfs.

---

# Procedimento

## 1. Montar temporariamente o sistema de arquivos

Monte temporariamente o volume Btrfs em um diretório de trabalho.

Essa montagem será utilizada apenas para criação da estrutura inicial.

---

## 2. Criar os subvolumes

Criar os seguintes subvolumes:

```text
@
@home
@var
@var_log
@var_cache
@pkg
@docker
@snapshots
```

Todos deverão ser criados diretamente na raiz do sistema de arquivos.

---

## 3. Confirmar a criação

Verifique se todos os subvolumes foram criados corretamente.

---

## 4. Desmontar o sistema de arquivos

Após a validação, desmonte o volume.

A montagem definitiva será realizada no próximo playbook.

---

# Verificação

Confirme que:

* todos os subvolumes definidos pela arquitetura existem;
* nenhum subvolume adicional foi criado;
* o volume foi desmontado com sucesso ao final do procedimento.

---

# Problemas comuns

## Não é possível criar subvolumes

Verifique se o sistema de arquivos está montado e se o ponto de montagem corresponde à raiz do volume Btrfs.

---

## Subvolume criado no local incorreto

Remova o subvolume incorreto e recrie-o na raiz do sistema de arquivos.

---

## Volume ocupado ao desmontar

Verifique se não existem arquivos abertos ou processos utilizando o ponto de montagem temporário.

---

# Próximo playbook

Após validar a estrutura dos subvolumes, prossiga para:

```text
07-format-efi.md
```

---

# Referências

* Arch Wiki — Btrfs
* Arch Wiki — Btrfs Subvolumes

---

# Lições aprendidas

Registrar aqui ajustes na organização dos subvolumes, mudanças futuras na arquitetura ou observações encontradas durante instalações reais.
