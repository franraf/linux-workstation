---

title: Instalar Hypridle
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

# 05 — Instalar Hypridle

## Objetivo

Instalar o Hypridle como gerenciador de inatividade da sessão gráfica.

Ao final deste playbook, a workstation possuirá um componente capaz de monitorar o estado da sessão e executar ações relacionadas à inatividade.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.
* Hyprlock instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Hypridle estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* o componente poderá ser iniciado durante uma sessão Hyprland.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do Hypridle.

---

## 2. Instalar o Hypridle

Instale o componente utilizando os repositórios definidos pelo projeto.

---

## 3. Validar a instalação

Confirme que os arquivos esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie o Hypridle durante uma sessão de teste.

O objetivo é apenas confirmar que o componente inicia corretamente.

Não configure ações automáticas nesta etapa.

---

# Verificação

Confirme que:

* o Hypridle está instalado;
* o componente inicia corretamente;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O componente não inicia

Revise as dependências e confirme que a sessão Hyprland está operacional.

---

## Erros relacionados à sessão

Confirme que o ambiente gráfico foi iniciado corretamente e que o Hyprland está em execução.

---

## Dependências ausentes

Revise a instalação antes de prosseguir.

---

# Próximo playbook

Após validar a instalação do Hypridle, prossiga para:

```text
06-install-rofi.md
```

---

# Referências

* Documentação oficial do Hypridle
* Documentação oficial do Hyprland

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação do Hypridle.
