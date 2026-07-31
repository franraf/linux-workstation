---

title: Instalar central de notificações
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

# 07 — Instalar central de notificações

## Objetivo

Instalar uma central de notificações para a sessão gráfica da workstation.

Ao final deste playbook, o ambiente gráfico será capaz de receber, armazenar e apresentar notificações ao usuário.

A implementação adotada pelo projeto utiliza o **Sway Notification Center (SwayNC)**.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* a central de notificações estará instalada;
* suas dependências obrigatórias estarão disponíveis;
* o componente poderá ser iniciado durante uma sessão gráfica.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização da central de notificações.

---

## 2. Instalar o componente

Instale a implementação definida pela arquitetura do projeto.

---

## 3. Validar a instalação

Confirme que os componentes esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie a central de notificações durante uma sessão de teste.

O objetivo é apenas confirmar que o componente inicia corretamente.

Não configure aparência, widgets ou comportamento nesta etapa.

---

## 5. Validar o recebimento de notificações

Gere uma notificação de teste.

Confirme que ela é apresentada corretamente ao usuário.

---

# Verificação

Confirme que:

* a central de notificações está instalada;
* o componente inicia corretamente;
* notificações podem ser recebidas;
* notificações podem ser descartadas;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O componente não inicia

Revise as dependências e confirme que a sessão Wayland está operacional.

---

## Notificações não aparecem

Verifique se o serviço de notificações foi iniciado corretamente e se não existe outro daemon concorrente.

---

## Erros durante a execução

Analise os registros da sessão antes de prosseguir.

---

# Próximo playbook

Após validar a central de notificações, prossiga para:

```text
08-install-terminal.md
```

---

# Referências

* Documentação oficial do Sway Notification Center
* Desktop Notifications Specification
* Arch Wiki — Wayland

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação da central de notificações.
