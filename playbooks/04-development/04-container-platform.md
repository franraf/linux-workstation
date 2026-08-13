---
title: Plataforma de contêineres
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0005

---

# 04 — Plataforma de contêineres

## Objetivo

Instalar Docker Engine, Docker Compose e Docker Buildx como plataforma de desenvolvimento isolada da workstation.

Runtimes e SDKs específicos de projeto continuam fora do host e devem ser fornecidos preferencialmente por Dev Containers.

## Fonte declarativa

Os pacotes pertencentes à capacidade ficam em:

```text
packages/development/container-platform.txt
```

A lista atual utiliza os pacotes oficiais Arch Linux:

* `docker`;
* `docker-compose`;
* `docker-buildx`.

## Armazenamento

O Docker utiliza o caminho padrão:

```text
/var/lib/docker
```

Esse caminho já possui subvolume Btrfs dedicado definido pela fase `01-installation`, portanto este playbook não redefine `data-root` sem necessidade.

## Procedimento

Execute:

```bash
sudo ./04-container-platform/run.sh
```

O script:

1. valida sistema e usuário de destino;
2. instala apenas os pacotes ausentes;
3. solicita confirmação `DOCKER`;
4. habilita e inicia `docker.service`;
5. valida Engine, Compose e Buildx;
6. confirma o data root `/var/lib/docker`;
7. solicita separadamente `DOCKER-GROUP` antes de adicionar o usuário ao grupo `docker`.

## Política de acesso

O grupo `docker` concede acesso privilegiado ao daemon. A automação não trata essa associação como uma alteração trivial e exige confirmação específica.

Depois de adicionar o usuário ao grupo, é necessário iniciar uma nova sessão para que terminal e aplicações gráficas herdem a nova associação.

## Dev Containers

A extensão do VS Code foi preparada em `03-code-editor`. A validação ponta a ponta de Dev Containers deve ocorrer depois de uma nova sessão, quando o usuário conseguir acessar o Docker sem `sudo`.

## Verificação

Confirme que:

* `docker.service` está habilitado e ativo;
* `docker version` funciona;
* `docker compose version` funciona;
* `docker buildx version` funciona;
* `/var/lib/docker` é o data root;
* o usuário consta no grupo `docker`, quando a autorização foi concedida;
* após novo login, `docker info` funciona como usuário normal;
* o VS Code consegue conectar-se a um Dev Container.

## Próximo playbook

```text
05-cli-tools.md
```

## Referências

* Arch Linux — docker
* Arch Linux — docker-compose
* Arch Linux — docker-buildx
* Docker Engine documentation
* Development Containers Specification
