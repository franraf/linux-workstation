---

title: Atualizar o sistema
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

# 01 — Atualizar o sistema

## Objetivo

Atualizar todos os pacotes instalados para o estado mais recente disponível nos repositórios configurados.

Ao final deste playbook, a workstation estará sincronizada com os repositórios oficiais e pronta para receber novas configurações.

---

# Pré-requisitos

* Primeiro boot concluído com sucesso.
* Login realizado com um usuário com privilégios administrativos.
* Conectividade de rede funcional.

---

# Resultado esperado

Ao concluir este playbook:

* os repositórios estarão sincronizados;
* todos os pacotes instalados estarão atualizados;
* eventuais mudanças relevantes terão sido identificadas antes das próximas configurações.

---

# Procedimento

## 1. Verificar conectividade

Confirme que a workstation possui acesso à rede.

---

## 2. Sincronizar os repositórios

Atualize a base de dados dos repositórios configurados.

---

## 3. Atualizar os pacotes

Instale todas as atualizações disponíveis.

Evite atualizações parciais.

---

## 4. Revisar mensagens importantes

Leia atentamente os avisos apresentados durante a atualização.

Caso alguma intervenção seja necessária, registre-a antes de prosseguir.

---

## 5. Reiniciar, quando necessário

Se a atualização incluir componentes críticos do sistema, reinicie a workstation antes de continuar para os próximos playbooks.

---

# Verificação

Confirme que:

* não existem pacotes pendentes de atualização;
* a atualização foi concluída sem erros;
* o sistema permanece operacional após o processo.

---

# Problemas comuns

## Espelhos indisponíveis

Verifique a conectividade e a disponibilidade dos repositórios configurados.

---

## Conflitos de pacotes

Revise as mensagens apresentadas pelo gerenciador de pacotes antes de tomar qualquer ação.

---

## Atualização interrompida

Resolva a inconsistência antes de iniciar qualquer novo playbook.

---

# Próximo playbook

Após atualizar o sistema, prossiga para:

```text
02-configure-pacman.md
```

---

# Referências

* Arch Wiki — System maintenance
* Arch Wiki — Pacman
* Arch Wiki — General recommendations

---

# Lições aprendidas

Registrar aqui ocorrências relevantes durante atualizações do sistema, mudanças de comportamento entre versões ou procedimentos adicionais adotados.

