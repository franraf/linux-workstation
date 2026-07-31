---

title: Instalar gerenciador de arquivos
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

# 09 — Instalar gerenciador de arquivos

## Objetivo

Instalar um gerenciador de arquivos para utilização no ambiente gráfico da workstation.

Ao final deste playbook, a sessão gráfica permitirá navegar, organizar e manipular arquivos e diretórios.

A implementação adotada pelo projeto utiliza o **Thunar**.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o gerenciador de arquivos estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* será possível navegar pelo sistema de arquivos durante a sessão gráfica.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do gerenciador de arquivos.

---

## 2. Instalar o componente

Instale a implementação definida pela arquitetura do projeto.

---

## 3. Validar a instalação

Confirme que todos os componentes esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie o gerenciador de arquivos durante uma sessão de teste.

Confirme que é possível:

* navegar entre diretórios;
* abrir arquivos;
* criar diretórios;
* copiar e mover arquivos.

Não configure temas, integrações ou ações personalizadas nesta etapa.

---

# Verificação

Confirme que:

* o gerenciador de arquivos está instalado;
* o sistema de arquivos pode ser navegado normalmente;
* operações básicas funcionam corretamente;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O gerenciador não inicia

Revise as dependências e confirme que a sessão gráfica está operacional.

---

## Arquivos não podem ser abertos

Confirme que os aplicativos associados estão instalados e corretamente registrados.

---

## Problemas de permissões

Verifique as permissões do usuário e do sistema de arquivos antes de prosseguir.

---

# Próximo playbook

Após validar o gerenciador de arquivos, prossiga para:

```text
10-install-font-stack.md
```

---

# Referências

* Documentação oficial do Thunar
* Arch Wiki — Thunar
* Arch Wiki — XDG Base Directory Specification

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação do gerenciador de arquivos.
