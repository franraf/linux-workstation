---

title: Entrar no ambiente chroot
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

# 10 — Entrar no ambiente chroot

## Objetivo

Entrar no sistema recém-instalado utilizando o ambiente `arch-chroot`.

Ao final deste playbook, todos os comandos serão executados diretamente no sistema instalado.

---

# Pré-requisitos

* Sistema base instalado.
* Arquivo `fstab` gerado e revisado.
* Todos os sistemas de arquivos permanecem montados.

---

# Resultado esperado

Ao concluir este playbook:

* o ambiente `chroot` estará ativo;
* o diretório raiz (`/`) corresponderá ao sistema instalado;
* as próximas configurações serão aplicadas diretamente ao sistema definitivo.

---

# Procedimento

## 1. Entrar no ambiente chroot

Acesse o sistema instalado utilizando a ferramenta recomendada pelo Arch Linux.

---

## 2. Confirmar o ambiente

Verifique se o diretório raiz corresponde ao sistema instalado.

Confirme também que os diretórios esperados estão acessíveis.

---

# Verificação

Confirme que:

* o ambiente `chroot` foi iniciado com sucesso;
* os sistemas de arquivos permanecem montados;
* o diretório `/etc` pertence ao sistema instalado.

---

# Problemas comuns

## Falha ao iniciar o chroot

Verifique se todos os sistemas de arquivos necessários continuam montados.

---

## Diretórios ausentes

Confirme se a instalação do sistema base foi concluída corretamente.

---

## Alterações sendo realizadas no ambiente live

Antes de executar qualquer configuração, confirme que o ambiente `chroot` está ativo.

---

# Próximo playbook

Após confirmar o acesso ao sistema instalado, prossiga para:

```text
11-configure-time.md
```

---

# Referências

* Arch Wiki — Installation Guide
* Arch Wiki — arch-chroot

---

# Lições aprendidas

Registrar aqui dificuldades encontradas ao acessar o ambiente `chroot`, ajustes necessários ou observações relevantes para futuras instalações.
