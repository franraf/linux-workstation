---

title: Instalar Waybar
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

# 03 — Instalar Waybar

## Objetivo

Instalar o Waybar como barra de status da sessão gráfica.

Ao final deste playbook, a workstation possuirá um componente funcional para apresentação de informações do sistema durante a sessão Wayland.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Waybar estará instalado;
* todas as dependências obrigatórias estarão disponíveis;
* a barra poderá ser iniciada durante uma sessão Hyprland.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do Waybar.

---

## 2. Instalar o Waybar

Instale o Waybar utilizando os repositórios definidos pelo projeto.

---

## 3. Validar a instalação

Confirme que os componentes esperados foram instalados.

---

## 4. Executar um teste funcional

Inicie o Waybar em uma sessão de teste.

O objetivo é apenas confirmar que o componente inicia corretamente.

Não realize personalizações nesta etapa.

---

# Verificação

Confirme que:

* o Waybar está instalado;
* o componente inicia sem erros críticos;
* a barra é exibida durante a sessão de teste.

---

# Problemas comuns

## Barra não inicia

Revise as dependências e confirme que o Hyprland está operacional.

---

## Dependências ausentes

Confirme a instalação de todos os componentes necessários.

---

## Erros de execução

Revise os registros da sessão antes de prosseguir.

---

# Próximo playbook

Após validar a instalação do Waybar, prossiga para:

```text
04-install-hyprlock.md
```

---

# Referências

* Documentação oficial do Waybar
* Arch Wiki — Wayland

---

# Lições aprendidas

Registrar aqui problemas de compatibilidade, dependências adicionais ou observações relevantes identificadas durante a instalação do Waybar.
