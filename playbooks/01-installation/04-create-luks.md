---

title: Criar o volume LUKS2
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

# 04 — Criar o volume LUKS2

## Objetivo

Criptografar a partição destinada ao sistema utilizando LUKS2.

Ao final deste playbook, a partição estará protegida por criptografia e disponível para abertura durante a instalação.

---

# Pré-requisitos

* Disco particionado conforme o playbook anterior.
* Partição destinada ao sistema identificada corretamente.

> **Atenção:** este procedimento remove permanentemente qualquer dado existente na partição selecionada.

---

# Resultado esperado

Ao concluir este playbook:

* a partição do sistema estará formatada com LUKS2;
* será possível abrir o volume criptografado;
* um dispositivo mapeado estará disponível para utilização nas próximas etapas.

Nenhum sistema de arquivos será criado neste momento.

---

# Procedimento

## 1. Identificar a partição

Confirme qual partição será utilizada para a criptografia.

Verifique cuidadosamente o dispositivo antes de prosseguir.

---

## 2. Inicializar o volume LUKS2

Inicialize a partição utilizando o formato LUKS2.

Durante esta etapa será solicitada uma senha de desbloqueio.

Escolha uma senha forte e armazene-a de forma segura.

---

## 3. Abrir o volume criptografado

Desbloqueie o volume recém-criado.

O sistema criará um dispositivo mapeado no *device mapper*, que será utilizado nos próximos playbooks.

---

## 4. Confirmar o mapeamento

Verifique se o dispositivo criptografado foi aberto corretamente antes de prosseguir.

---

# Verificação

Confirme que:

* a partição utiliza o formato LUKS2;
* o volume foi aberto com sucesso;
* o dispositivo mapeado está disponível;
* nenhuma mensagem de erro foi apresentada durante a abertura.

---

# Problemas comuns

## Senha incorreta

Confirme a senha utilizada durante a criação do volume.

---

## Volume não pode ser aberto

Verifique se a inicialização do LUKS foi concluída corretamente e se a partição correta foi selecionada.

---

## Dispositivo mapeado não aparece

Confirme se o volume foi aberto com sucesso e se não existem mensagens de erro relacionadas ao `cryptsetup`.

---

# Próximo playbook

Após validar o volume criptografado, prossiga para:

```text
05-create-btrfs.md
```

---

# Referências

* Arch Wiki — dm-crypt
* Arch Wiki — LUKS
* Arch Wiki — cryptsetup

---

# Lições aprendidas

Registrar particularidades observadas durante a criação ou abertura do volume criptografado, incluindo compatibilidade de hardware, mensagens relevantes ou ajustes necessários para futuras instalações.
