---

title: Plataforma de contêineres
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

# 04 — Plataforma de contêineres

## Objetivo

Adicionar à workstation uma plataforma de contêineres para execução de ambientes de desenvolvimento isolados, reproduzíveis e portáveis.

Ao final deste playbook, a workstation estará preparada para executar projetos utilizando contêineres de desenvolvimento, mantendo a máquina hospedeira livre de dependências específicas de linguagem.

A implementação adotada pelo projeto utiliza o **Docker Engine**.

---

# Pré-requisitos

* Ambiente de shell configurado.
* Editor de código configurado.
* Capacidade de controle de versão concluída.

---

# Resultado esperado

Ao concluir este playbook:

* a plataforma de contêineres estará instalada;
* o usuário poderá executar contêineres sem privilégios administrativos;
* o editor estará integrado aos Dev Containers;
* a workstation estará preparada para desenvolvimento isolado.

---

# Estrutura da configuração

Mantenha a configuração reproduzível junto aos dotfiles da workstation.

Estrutura recomendada:

```text
dotfiles/

docker/
├── daemon.json
└── README.md
```

Sempre que possível, utilize os mecanismos nativos da plataforma para configuração.

Evite personalizações locais não documentadas.

---

# Procedimento

## 1. Instalar a plataforma

Instale os componentes definidos pela arquitetura.

Considere:

* Docker Engine;
* Docker Compose;
* Docker Buildx.

---

## 2. Configurar a plataforma

Configure a plataforma conforme os padrões do projeto.

Considere:

* inicialização automática;
* permissões do usuário;
* diretório de armazenamento;
* configurações do daemon;
* recursos experimentais, quando adotados.

---

## 3. Configurar o ambiente de desenvolvimento

Confirme que a plataforma suporta o fluxo de desenvolvimento adotado pela workstation.

Considere:

* Dev Containers;
* BuildKit;
* Compose;
* integração com o editor.

---

## 4. Integrar com a workstation

Confirme a integração com:

* editor de código;
* ambiente de shell;
* controle de versão.

---

## 5. Validar a plataforma

Execute operações básicas.

Confirme que é possível:

* iniciar um contêiner;
* construir uma imagem;
* executar um projeto com Compose;
* abrir um projeto em um Dev Container.

---

# Verificação

Confirme que:

* a plataforma inicia corretamente;
* o usuário executa contêineres sem privilégios administrativos;
* Compose funciona corretamente;
* Buildx está disponível;
* Dev Containers funcionam no editor;
* não existem erros durante a operação.

---

# Problemas comuns

## Serviço indisponível

Confirme que a plataforma está instalada e inicializada corretamente.

---

## Permissões insuficientes

Revise a configuração do usuário e confirme sua participação nos grupos necessários.

---

## Dev Containers não iniciam

Confirme a integração entre a plataforma de contêineres e o editor de código.

---

## Falhas na construção de imagens

Revise a configuração do BuildKit e valide a sintaxe dos arquivos utilizados pelo projeto.

---

## Configuração divergente

Compare a configuração local com os arquivos versionados em `dotfiles/docker/`.

---

# Próximo playbook

Após validar a plataforma de contêineres, prossiga para:

```text
05-cli-tooling.md
```

---

# Referências

* Documentação oficial do Docker Engine
* Docker Compose
* Docker Buildx
* Development Containers Specification
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui melhorias na plataforma, ajustes de configuração, novas integrações ou observações relevantes identificadas durante sua evolução.
