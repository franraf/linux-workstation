---
title: Plataforma de contêineres
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005

---

# 04 — Plataforma de contêineres

## Objetivo

Adicionar à workstation uma plataforma de contêineres para execução de ambientes de desenvolvimento isolados, reproduzíveis e portáveis.

A implementação adotada utiliza Docker Engine, Docker Compose e Buildx.

---

# Pré-requisitos

* Ambiente de shell configurado.
* Editor de código configurado.
* Controle de versão concluído.

---

# Resultado esperado

Ao concluir este playbook:

* a plataforma de contêineres estará instalada e operacional;
* o usuário autorizado poderá executar contêineres conforme a política definida pelo projeto;
* Compose e Buildx estarão disponíveis;
* a integração com Dev Containers poderá ser validada de ponta a ponta.

---

# Estrutura da configuração

Mantenha apenas configuração reproduzível e apropriada ao escopo da workstation.

Exemplo:

```text
dotfiles/
└── docker/
    ├── daemon.json
    └── README.md
```

Dados do Docker permanecem separados da configuração versionada.

---

# Procedimento

## 1. Instalar a plataforma

Instale Docker Engine, Docker Compose e Buildx conforme a arquitetura.

## 2. Configurar a plataforma

Defina inicialização do serviço, permissões do usuário, armazenamento e opções do daemon somente quando necessárias.

## 3. Validar operações básicas

Confirme que é possível:

* executar um contêiner;
* construir uma imagem;
* executar um projeto com Compose.

## 4. Integrar com o editor

Com a plataforma agora operacional, abra um projeto preparado para Dev Containers e confirme que o editor consegue criar ou reutilizar o ambiente e conectar-se ao contêiner.

## 5. Validar o isolamento

Confirme que dependências específicas de linguagens e projetos permanecem preferencialmente dentro dos ambientes de desenvolvimento, conforme a arquitetura.

---

# Verificação

Confirme que:

* o serviço da plataforma está operacional;
* Docker executa um contêiner de teste;
* Compose funciona;
* Buildx está disponível;
* Dev Containers funcionam no editor;
* não existem erros críticos durante a operação.

---

# Problemas comuns

## Serviço indisponível

Confirme instalação, habilitação e logs do serviço.

## Permissões insuficientes

Revise a política de acesso definida pelo projeto antes de alterar grupos ou privilégios.

## Dev Containers não iniciam

Separe o diagnóstico entre plataforma Docker, extensão/editor e configuração do projeto.

## Configuração divergente

Compare o estado local com os arquivos versionados antes de realizar ajustes manuais.

---

# Próximo playbook

```text
05-cli-tools.md
```

---

# Referências

* Documentação oficial do Docker Engine
* Docker Compose
* Docker Buildx
* Development Containers Specification
* ADR-0005 — Modularizar configurações por capacidade

---

# Lições aprendidas

A validação de Dev Containers pertence naturalmente à etapa em que a plataforma de contêineres já está disponível. O playbook do editor prepara a integração, e este playbook a valida.
