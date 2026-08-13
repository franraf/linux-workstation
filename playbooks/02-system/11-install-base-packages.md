---
title: Instalar pacotes base
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0007

---

# 11 — Instalar pacotes base

## Objetivo

Instalar o conjunto de utilitários fundamentais utilizados pela workstation para administração, diagnóstico e operação diária.

---

# Pré-requisitos

* Sistema configurado.
* Pacman configurado.
* Política de serviços aplicada.

---

# Resultado esperado

Ao concluir este playbook:

* os utilitários básicos declarados pelo projeto estarão instalados;
* ferramentas essenciais de administração estarão disponíveis;
* a lista de pacotes será rastreável e reutilizável por scripts e validações.

---

# Procedimento

## 1. Revisar a lista declarativa

Mantenha a relação de pacotes base em arquivo de dados sob `packages/`, conforme a ADR-0007.

O arquivo declara **o que** pertence à capacidade. O procedimento e os scripts definem **como** instalar e validar.

Evite duplicar a lista de pacotes dentro de scripts ou documentação operacional.

## 2. Instalar os pacotes

Instale os pacotes declarados utilizando Pacman.

Pacotes ausentes da lista não deverão ser adicionados implicitamente durante a execução.

## 3. Validar dependências

Confirme que todos os pacotes declarados foram instalados e que não existem conflitos ou dependências quebradas.

## 4. Confirmar disponibilidade

Verifique que as ferramentas essenciais podem ser executadas normalmente.

---

# Verificação

Confirme que:

* a lista declarativa existe e é a fonte da verdade da capacidade;
* todos os pacotes declarados estão instalados;
* não existem dependências quebradas;
* as ferramentas essenciais estão disponíveis;
* o sistema permanece íntegro após a instalação.

---

# Problemas comuns

## Lista ausente ou vazia

Não mantenha uma segunda lista no script. Corrija o arquivo declarativo no repositório.

## Pacote indisponível

Confirme se o nome está correto e se pertence aos repositórios oficiais adotados pelo projeto.

## Dependências em conflito

Revise a composição da lista antes de prosseguir.

---

# Próximo playbook

```text
12-system-validation.md
```

---

# Referências

* Arch Wiki — General recommendations
* Arch Wiki — Pacman
* ADR-0007 — Listas declarativas de pacotes

---

# Lições aprendidas

A lista de pacotes deve permanecer separada da lógica de instalação para reduzir divergências entre documentação, scripts e validação.
