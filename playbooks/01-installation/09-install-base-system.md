---

title: Instalar o sistema base
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

# 08 — Instalar o sistema base

## Objetivo

Instalar o sistema base do Arch Linux sobre a estrutura de armazenamento preparada nos playbooks anteriores.

Ao final deste playbook, existirá um sistema operacional mínimo instalado no disco, pronto para configuração.

---

# Pré-requisitos

* Sistemas de arquivos montados conforme o playbook anterior.
* Conectividade com a Internet.
* Relógio do sistema sincronizado.
* Repositórios oficiais acessíveis.

---

# Resultado esperado

Ao concluir este playbook:

* o sistema base estará instalado em `/mnt`;
* o gerenciador de pacotes estará disponível no sistema instalado;
* os pacotes essenciais definidos pela arquitetura estarão presentes.

---

# Procedimento

## 1. Verificar a conectividade

Confirme que o ambiente live possui acesso à Internet.

Caso utilize sincronização automática de horário, confirme também que o relógio do sistema está correto.

---

## 2. Selecionar os pacotes

Defina o conjunto mínimo de pacotes necessários para inicialização do sistema.

A seleção deverá seguir a arquitetura do projeto.

---

## 3. Instalar o sistema base

Instale o sistema no diretório `/mnt`.

A instalação deverá ser realizada exclusivamente utilizando os repositórios oficiais do Arch Linux.

---

## 4. Aguardar a conclusão

Aguarde o término da instalação.

Antes de prosseguir, confirme que não houve erros durante o processo.

---

# Verificação

Confirme que:

* todos os pacotes foram instalados com sucesso;
* não existem mensagens de erro na instalação;
* a estrutura básica do sistema foi criada em `/mnt`;
* o sistema está pronto para receber as configurações iniciais.

---

# Problemas comuns

## Falha na conexão

Verifique a conectividade antes de repetir a instalação.

---

## Erro ao acessar os repositórios

Confirme a configuração de rede e a disponibilidade dos espelhos utilizados.

---

## Espaço insuficiente

Verifique o particionamento e o espaço disponível no sistema de arquivos.

---

# Próximo playbook

Após validar a instalação do sistema base, prossiga para:

```text
10-generate-fstab.md
```

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — pacstrap

---

# Lições aprendidas

Registrar aqui ajustes na seleção de pacotes, mudanças na composição do sistema base ou observações relevantes para futuras instalações.
