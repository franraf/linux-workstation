---

title: Criar o sistema de arquivos Btrfs
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

# 05 — Criar o sistema de arquivos Btrfs

## Objetivo

Criar o sistema de arquivos Btrfs sobre o volume criptografado preparado no playbook anterior.

Ao final deste playbook, o volume criptografado estará formatado e pronto para a criação dos subvolumes.

---

# Pré-requisitos

* Volume LUKS2 criado e aberto.
* Dispositivo mapeado disponível.

> **Atenção:** este procedimento remove permanentemente qualquer dado existente no volume selecionado.

---

# Resultado esperado

Ao concluir este playbook:

* o dispositivo mapeado conterá um sistema de arquivos Btrfs;
* o sistema de arquivos estará pronto para montagem;
* ainda não existirão subvolumes personalizados.

---

# Procedimento

## 1. Confirmar o dispositivo mapeado

Verifique qual dispositivo corresponde ao volume criptografado aberto no playbook anterior.

Confirme que o dispositivo selecionado é o destino correto.

---

## 2. Criar o sistema de arquivos

Formate o dispositivo utilizando Btrfs.

O sistema de arquivos deverá ser criado diretamente sobre o volume criptografado.

---

## 3. Confirmar a criação

Verifique se a formatação foi concluída sem erros.

---

# Verificação

Confirme que:

* o sistema de arquivos é Btrfs;
* o dispositivo permanece acessível;
* nenhuma mensagem de erro foi apresentada durante a formatação.

Uma verificação simples pode ser realizada utilizando ferramentas de inspeção do sistema de arquivos.

---

# Problemas comuns

## Sistema de arquivos não criado

Verifique se o volume criptografado está aberto e se o dispositivo correto foi selecionado.

---

## Dispositivo ocupado

Confirme que o volume não está montado ou sendo utilizado por outro processo.

---

## Ferramentas Btrfs indisponíveis

Certifique-se de que o ambiente live possui as ferramentas necessárias para manipulação do Btrfs.

---

# Próximo playbook

Após validar a criação do sistema de arquivos, prossiga para:

```text
06-create-subvolumes.md
```

---

# Referências

* Arch Wiki — Btrfs
* Arch Wiki — mkfs.btrfs

---

# Lições aprendidas

Registrar aqui observações sobre compatibilidade, desempenho, mensagens relevantes ou ajustes necessários para futuras instalações envolvendo Btrfs.
