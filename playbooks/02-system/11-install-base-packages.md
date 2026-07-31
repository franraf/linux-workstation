---

title: Instalar pacotes base
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

# 11 — Instalar pacotes base

## Objetivo

Instalar o conjunto de utilitários fundamentais utilizados pela workstation para administração, diagnóstico e operação diária.

Ao final deste playbook, o sistema possuirá todas as ferramentas básicas previstas pela arquitetura do projeto.

---

# Pré-requisitos

* Sistema configurado.
* Pacman configurado.
* Política de serviços aplicada.

---

# Resultado esperado

Ao concluir este playbook:

* os utilitários básicos estarão instalados;
* ferramentas essenciais de administração estarão disponíveis;
* o sistema estará preparado para as próximas fases da configuração.

---

# Procedimento

## 1. Revisar a lista de pacotes

Confirme a relação de pacotes base definida pelo projeto.

Evite instalar ferramentas que pertençam a fases posteriores.

---

## 2. Instalar os pacotes

Instale os utilitários previstos pela arquitetura.

---

## 3. Validar dependências

Confirme que todos os pacotes foram instalados corretamente e que não existem conflitos.

---

## 4. Confirmar disponibilidade

Verifique que as ferramentas instaladas podem ser executadas normalmente.

---

# Verificação

Confirme que:

* todos os pacotes previstos foram instalados;
* não existem dependências quebradas;
* as ferramentas essenciais estão disponíveis;
* o sistema permanece íntegro após a instalação.

---

# Problemas comuns

## Pacote indisponível

Confirme se o pacote pertence aos repositórios oficiais adotados pelo projeto.

---

## Dependências em conflito

Revise a instalação antes de prosseguir para a próxima fase.

---

## Ferramenta não encontrada

Confirme se a instalação foi concluída corretamente e se o pacote corresponde ao esperado.

---

# Próximo playbook

Após instalar os pacotes base, prossiga para:

```text
12-system-validation.md
```

---

# Referências

* Arch Wiki — General recommendations
* Arch Wiki — Pacman

---

# Lições aprendidas

Registrar aqui alterações na composição do conjunto de pacotes base ou observações relevantes identificadas durante a evolução da workstation.
