---

title: Configurar serviços do sistema
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

# 09 — Configurar serviços do sistema

## Objetivo

Estabelecer a política de gerenciamento dos serviços do sistema, garantindo que apenas os componentes necessários sejam iniciados automaticamente.

Ao final deste playbook, a workstation seguirá uma estratégia consistente para habilitação, desabilitação e validação de serviços.

---

# Pré-requisitos

* Componentes básicos do sistema configurados.
* Serviços essenciais instalados.

---

# Resultado esperado

Ao concluir este playbook:

* os serviços essenciais estarão habilitados;
* serviços desnecessários permanecerão desabilitados;
* a política de gerenciamento de serviços estará documentada.

---

# Procedimento

## 1. Revisar os serviços instalados

Identifique os serviços atualmente disponíveis na workstation.

---

## 2. Validar a necessidade de cada serviço

Confirme quais serviços devem iniciar automaticamente e quais devem permanecer inativos.

Adote o princípio do menor conjunto necessário.

---

## 3. Configurar inicialização automática

Habilite apenas os serviços previstos pela arquitetura.

---

## 4. Revisar dependências

Confirme que não existem dependências quebradas ou serviços redundantes.

---

## 5. Validar o estado final

Revise a lista de serviços habilitados e confirme que ela corresponde aos padrões definidos pelo projeto.

---

# Verificação

Confirme que:

* apenas os serviços necessários iniciam automaticamente;
* não existem serviços em falha;
* o estado dos serviços corresponde ao esperado.

---

# Problemas comuns

## Serviço inicia desnecessariamente

Revise a política de habilitação e desative serviços não utilizados.

---

## Dependências não atendidas

Confirme que todos os componentes necessários foram instalados antes da habilitação.

---

## Serviço em falha

Analise os registros do sistema e corrija a configuração antes de prosseguir.

---

# Próximo playbook

Após validar os serviços do sistema, prossiga para:

```text
10-install-base-packages.md
```

---

# Referências

* Arch Wiki — systemd
* Arch Wiki — systemctl
* Arch Wiki — systemd.unit

---

# Lições aprendidas

Registrar aqui alterações na política de gerenciamento de serviços ou observações relevantes identificadas durante a operação da workstation.
