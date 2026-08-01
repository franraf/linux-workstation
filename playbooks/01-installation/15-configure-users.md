---

title: Configurar usuários
version: 1.1
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 14 — Configurar usuários

## Objetivo

Configurar as identidades de acesso do sistema, incluindo o usuário administrativo inicial e suas permissões.

Ao final deste playbook, será possível autenticar-se no sistema utilizando um usuário não privilegiado com acesso administrativo quando autorizado.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.
* Rede configurada.

---

# Resultado esperado

Ao concluir este playbook:

* a senha do usuário `root` estará definida;
* o usuário principal da workstation estará criado;
* o mecanismo de elevação de privilégios estará configurado;
* o usuário principal possuirá privilégios administrativos conforme a arquitetura.

---

# Procedimento

## 1. Definir a senha do usuário root

Configure uma senha forte para a conta `root`.

Armazene-a de forma segura.

---

## 2. Criar o usuário principal

Crie o usuário definido para a instalação.

Os atributos da conta deverão seguir o perfil da workstation.

---

## 3. Configurar grupos

Adicione o usuário aos grupos necessários para utilização normal do sistema.

Evite conceder permissões além das necessárias.

---

## 4. Configurar privilégios administrativos

Instale e configure o mecanismo de elevação de privilégios adotado pelo projeto.

Conceda acesso administrativo apenas ao usuário ou grupo definido pela arquitetura.

---

## 5. Revisar a configuração

Confirme que as contas foram criadas corretamente e que as permissões correspondem ao esperado.

---

# Verificação

Confirme que:

* a conta `root` possui senha definida;
* o usuário principal existe;
* o usuário possui os grupos corretos;
* a elevação de privilégios funciona corretamente.

---

# Problemas comuns

## Usuário não criado

Verifique se o nome da conta segue as regras do sistema e se não existe outro usuário com o mesmo identificador.

---

## Permissões insuficientes

Confirme que o usuário pertence aos grupos previstos pela arquitetura.

---

## Falha na elevação de privilégios

Revise a configuração do mecanismo de administração e confirme que o usuário possui autorização para utilizá-lo.

---

# Próximo playbook

Após validar a configuração dos usuários, prossiga para:

```text id="8xylkb"
16-configure-initramfs.md
```

---

# Referências

* Arch Wiki — Users and groups
* Arch Wiki — sudo
* Arch Wiki — User management

---

# Lições aprendidas

Registrar aqui alterações na política de usuários, permissões administrativas ou observações relevantes identificadas durante futuras instalações.
