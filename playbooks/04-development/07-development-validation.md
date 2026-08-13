---
title: Validar ambiente de desenvolvimento
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0004
* ADR-0005

---

# 07 — Validar ambiente de desenvolvimento

## Objetivo

Executar o gate final da fase `04-development`, separando verificações automatizáveis de testes que dependem de credenciais, interface gráfica ou um projeto real.

Este passo não deve instalar pacotes nem corrigir automaticamente uma capacidade que falhou.

## Execução

Execute como usuário normal e dentro da sessão já renovada depois da configuração do grupo Docker:

```bash
./07-development-validation/run.sh
```

O orquestrador executa:

```text
tests/development/static-artifacts.sh
tests/development/runtime-state.sh
```

## Validação automatizada

O gate verifica:

* identidade e branch padrão do Git;
* Zsh como shell de login e inicialização sem erro;
* Starship e arquivos de configuração;
* Visual Studio Code e suas fontes canônicas;
* extensão Dev Containers;
* Docker Engine acessível sem `sudo`;
* Compose e Buildx;
* pacote e executáveis das ferramentas CLI;
* Codex CLI;
* ausência esperada de runtimes/SDKs de projeto no host, reportando divergências como warnings para revisão.

## Validações manuais obrigatórias

### GitHub

Utilize um repositório controlado e confirme autenticação SSH, `pull` e `push`.

### Visual Studio Code

Abra o editor graficamente e confirme que o terminal integrado inicia em Zsh.

### Dev Containers

Abra um projeto real preparado para Dev Containers, construa/abra o ambiente e execute os testes do projeto dentro do contêiner.

### Codex CLI

Quando necessário, autentique:

```bash
codex --login
```

Depois utilize um repositório controlado para solicitar uma pequena tarefa e revise o diff antes de aceitar qualquer alteração.

## Política de host

O host não deve receber runtimes e SDKs específicos apenas porque um projeto precisa deles. O gate sinaliza a presença de ferramentas excluídas pelo profile, incluindo Node.js, .NET, Terraform, kubectl, Helm e AWS CLI.

Uma divergência pode ser legítima no futuro, mas deve ser acompanhada de decisão arquitetural explícita.

## Resultado esperado

A fase pode ser considerada validada somente quando:

* o gate automatizado termina sem falhas;
* autenticação Git remota foi testada;
* VS Code gráfico e terminal integrado funcionam;
* um Dev Container real foi validado;
* Codex foi autenticado e testado, quando essa capacidade for utilizada;
* warnings do gate foram revisados.

## Próximos passos

Com `04-development` validada, prossiga para a próxima fase definida pelo profile.

## Referências

* Playbooks da fase `04-development`
* ADR-0004 — Playbook Granularity
* ADR-0005 — Modularize Configuration by Capability
