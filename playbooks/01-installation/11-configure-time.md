---

title: Configurar data e hora
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

# 11 — Configurar data e hora

## Objetivo

Configurar o fuso horário do sistema e sincronizar o relógio de hardware conforme a arquitetura do projeto.

Ao final deste playbook, o sistema utilizará o fuso horário correto e estará preparado para manter data e hora consistentes.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.

---

# Resultado esperado

Ao concluir este playbook:

* o fuso horário estará configurado;
* o relógio de hardware estará sincronizado;
* data e hora estarão corretas.

---

# Procedimento

## 1. Configurar o fuso horário

Configure o sistema para utilizar o fuso horário definido para a instalação.

---

## 2. Sincronizar o relógio de hardware

Grave a hora atual no relógio de hardware utilizando o padrão recomendado pelo Arch Linux.

---

## 3. Confirmar a configuração

Verifique se o sistema reconhece corretamente o fuso horário configurado.

---

# Verificação

Confirme que:

* o fuso horário está correto;
* data e hora são exibidas corretamente;
* o relógio de hardware foi sincronizado sem erros.

---

# Problemas comuns

## Horário incorreto

Verifique se o fuso horário selecionado corresponde à localização desejada.

---

## Relógio de hardware dessincronizado

Repita a sincronização após confirmar que a data e a hora do sistema estão corretas.

---

## Diferença de horário após reinicialização

Confirme que o relógio de hardware foi configurado conforme a recomendação do Arch Linux.

---

# Próximo playbook

Após validar a configuração de data e hora, prossiga para:

```text id="3s3m4n"
12-configure-localization.md
```

---

# Referências

* Arch Wiki — Time
* Arch Wiki — System time

---

# Lições aprendidas

Registrar aqui ajustes específicos de fuso horário, comportamento do relógio de hardware ou observações relevantes encontradas durante futuras instalações.
