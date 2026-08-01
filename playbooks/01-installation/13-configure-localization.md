---

title: Configurar localização do sistema
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

# 12 — Configurar localização do sistema

## Objetivo

Configurar os parâmetros de localização do sistema, incluindo locale, idioma das mensagens e layout de teclado do console.

Ao final deste playbook, o sistema utilizará as definições de localização previstas para a instalação.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.
* Data e hora configuradas.

---

# Resultado esperado

Ao concluir este playbook:

* os locales necessários estarão habilitados;
* o locale padrão do sistema estará definido;
* o layout de teclado do console estará configurado;
* o sistema estará preparado para exibir mensagens e interpretar caracteres corretamente.

---

# Procedimento

## 1. Habilitar os locales necessários

Habilite os locales definidos para a instalação.

Evite manter locales desnecessários habilitados.

---

## 2. Gerar os locales

Gere os arquivos de locale utilizando a ferramenta recomendada pelo Arch Linux.

---

## 3. Definir o locale padrão

Configure o locale padrão do sistema.

---

## 4. Configurar o teclado do console

Defina o layout de teclado utilizado no console virtual.

---

## 5. Revisar a configuração

Confirme que todos os arquivos necessários foram criados e atualizados.

---

# Verificação

Confirme que:

* os locales foram gerados sem erros;
* o locale padrão está configurado;
* o layout do teclado corresponde ao esperado;
* caracteres acentuados são interpretados corretamente.

---

# Problemas comuns

## Locale não disponível

Verifique se o locale foi habilitado antes da geração.

---

## Mensagens continuam em idioma inesperado

Confirme se o locale padrão foi configurado corretamente.

---

## Caracteres incorretos

Revise a configuração do locale e do teclado do console.

---

# Próximo playbook

Após validar a configuração de localização, prossiga para:

```text
14-configure-network.md
```

---

# Referências

* Arch Wiki — Localization
* Arch Wiki — Locale
* Arch Wiki — Console keyboard configuration

---

# Lições aprendidas

Registrar aqui ajustes específicos de locale, layout de teclado ou codificação utilizados em futuras instalações.
