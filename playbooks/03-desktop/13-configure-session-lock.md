---

title: Configurar bloqueio da sessão
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004
* ADR-0005

---

# 13 — Configurar bloqueio da sessão

## Objetivo

Configurar o comportamento e a aparência do bloqueio da sessão gráfica, garantindo uma experiência consistente e segura.

Ao final deste playbook, a workstation possuirá uma política de bloqueio alinhada com os padrões definidos pelo projeto.

A implementação adotada pelo projeto utiliza o **Hyprlock**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Componente de bloqueio instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o bloqueio da sessão seguirá a identidade visual do projeto;
* a autenticação funcionará corretamente;
* o componente estará integrado à sessão gráfica.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos de configuração conforme a ADR-0005.

Mantenha aparência e comportamento separados sempre que possível.

---

## 2. Configurar a interface

Defina os elementos visuais do bloqueio.

Considere:

* plano de fundo;
* relógio;
* data;
* informações da sessão;
* campo de autenticação.

---

## 3. Configurar o comportamento

Defina o comportamento esperado durante o bloqueio da sessão.

Considere aspectos como:

* autenticação;
* mensagens de erro;
* indicadores visuais;
* retorno à sessão.

---

## 4. Integrar à sessão gráfica

Confirme que o bloqueio pode ser acionado normalmente a partir da sessão configurada.

---

## 5. Validar o desbloqueio

Execute testes completos de bloqueio e desbloqueio.

Confirme que a sessão retorna exatamente ao estado anterior.

---

# Verificação

Confirme que:

* o bloqueio é iniciado corretamente;
* a autenticação funciona normalmente;
* a sessão é restaurada após o desbloqueio;
* a interface é renderizada corretamente;
* não existem erros durante a execução.

---

# Problemas comuns

## Tela de bloqueio não aparece

Confirme que o componente está corretamente integrado à sessão.

---

## Autenticação falha

Revise a integração com o mecanismo de autenticação do sistema.

---

## Problemas de renderização

Verifique a disponibilidade das fontes, imagens e demais recursos utilizados.

---

## Retorno incorreto à sessão

Revise os registros do sistema e confirme que a sessão permanece íntegra durante o bloqueio.

---

# Próximo playbook

Após validar o bloqueio da sessão, prossiga para:

```text
14-configure-idle-manager.md
```

---

# Referências

* Documentação oficial do Hyprlock
* Documentação oficial do Hyprland
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui ajustes na política de bloqueio, alterações na interface ou observações relevantes identificadas durante a evolução da workstation.
