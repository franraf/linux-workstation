---

title: Instalar Lançador de Aplicações
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

# 06 — Instalar Lançador de Aplicações

## Objetivo

Instalar o Rofi como lançador de aplicações da workstation.

Ao final deste playbook, o sistema possuirá um componente capaz de localizar e iniciar aplicações da sessão gráfica.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Rofi estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* o lançador poderá ser iniciado durante uma sessão Hyprland.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do Rofi em ambiente Wayland.

---

## 2. Instalar o Rofi

Instale o componente utilizando os repositórios definidos pelo projeto.

---

## 3. Validar a instalação

Confirme que os arquivos esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie o Rofi durante uma sessão de teste.

O objetivo é apenas confirmar que o componente executa corretamente.

Não configure temas, atalhos ou modos adicionais nesta etapa.

---

# Verificação

Confirme que:

* o Rofi está instalado;
* o componente inicia corretamente;
* aplicações podem ser localizadas e iniciadas;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O launcher não inicia

Revise as dependências e confirme que a sessão Wayland está operacional.

---

## Aplicações não aparecem

Verifique se os arquivos `.desktop` estão disponíveis e acessíveis ao launcher.

---

## Erros durante a execução

Analise os registros da sessão antes de prosseguir.

---

# Próximo playbook

Após validar a instalação do Rofi, prossiga para:

```text id="t98p4h"
07-install-notification-center.md
```

---

# Referências

* Documentação oficial do Rofi
* Arch Wiki — Rofi
* Arch Wiki — Wayland

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação do Rofi.
