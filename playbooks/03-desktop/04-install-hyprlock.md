---

title: Instalar Hyprlock
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

# 04 — Instalar Hyprlock

## Objetivo

Instalar o Hyprlock como mecanismo de bloqueio de sessão da workstation.

Ao final deste playbook, o sistema possuirá um componente capaz de bloquear a sessão gráfica de forma segura.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Hyprlock estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* o bloqueio de sessão poderá ser iniciado manualmente para testes.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do Hyprlock.

---

## 2. Instalar o Hyprlock

Instale o componente utilizando os repositórios definidos pelo projeto.

---

## 3. Validar a instalação

Confirme que todos os arquivos esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie o Hyprlock manualmente durante uma sessão Hyprland.

O objetivo é apenas confirmar que o bloqueio da sessão funciona corretamente.

Não personalize sua aparência nesta etapa.

---

# Verificação

Confirme que:

* o Hyprlock está instalado;
* o bloqueio da sessão pode ser iniciado;
* a sessão é desbloqueada corretamente após autenticação;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O bloqueio não inicia

Confirme que a sessão está utilizando Hyprland e que todas as dependências foram instaladas.

---

## Falha na autenticação

Revise a integração com o mecanismo de autenticação do sistema.

---

## Erros durante a execução

Analise os registros da sessão antes de prosseguir.

---

# Próximo playbook

Após validar a instalação do Hyprlock, prossiga para:

```text
05-install-hypridle.md
```

---

# Referências

* Documentação oficial do Hyprlock
* Documentação oficial do Hyprland

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação do Hyprlock.
