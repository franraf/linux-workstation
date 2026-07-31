---

title: Configurar barra de status
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

# 12 — Configurar barra de status

## Objetivo

Configurar a barra de status da sessão gráfica, definindo as informações apresentadas ao usuário e sua integração com os demais componentes da workstation.

Ao final deste playbook, a barra de status estará integrada à sessão gráfica e refletirá o estado operacional da workstation.

A implementação adotada pelo projeto utiliza o **Waybar**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Barra de status instalada.
* Stack tipográfica instalada.

---

# Resultado esperado

Ao concluir este playbook:

* a barra de status estará integrada à sessão;
* os módulos previstos pelo projeto estarão configurados;
* a organização da barra seguirá os padrões definidos pela arquitetura.

---

# Procedimento

## 1. Organizar a configuração

Estruture a configuração da barra de status conforme a ADR-0005.

Mantenha módulos independentes e de fácil manutenção.

---

## 2. Definir a estrutura da barra

Configure a organização lógica da barra.

Considere:

* área esquerda;
* área central;
* área direita;
* agrupamento de módulos.

---

## 3. Configurar os módulos

Configure apenas os módulos previstos pela arquitetura da workstation.

Evite adicionar módulos experimentais ou redundantes.

---

## 4. Integrar à sessão gráfica

Confirme que a barra inicia automaticamente como parte da sessão.

---

## 5. Validar a renderização

Verifique a renderização de:

* textos;
* ícones;
* espaçamento;
* alinhamento;
* atualização dinâmica dos módulos.

---

# Verificação

Confirme que:

* a barra inicia automaticamente;
* todos os módulos esperados são exibidos;
* os ícones são renderizados corretamente;
* as informações apresentadas permanecem atualizadas;
* não existem erros durante a execução.

---

# Problemas comuns

## Barra não inicia

Revise a configuração da sessão e confirme que o componente foi instalado corretamente.

---

## Módulo indisponível

Confirme que a dependência correspondente está instalada e configurada.

---

## Ícones incorretos

Verifique a stack tipográfica e confirme a disponibilidade das fontes de ícones utilizadas.

---

## Erros na configuração

Valide a estrutura dos arquivos antes de reiniciar a sessão.

---

# Próximo playbook

Após validar a barra de status, prossiga para:

```text
13-configure-session-lock.md
```

---

# Referências

* Documentação oficial do Waybar
* Arch Wiki — Wayland
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui alterações na organização dos módulos, integrações adicionadas ou observações relevantes identificadas durante a evolução da barra de status.
