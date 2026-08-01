---

title: Validar ambiente de desenvolvimento
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

# 07 — Validar ambiente de desenvolvimento

## Objetivo

Validar que a workstation possui todas as capacidades necessárias para o desenvolvimento de software conforme definido pela arquitetura do projeto.

Ao final deste playbook, a workstation deverá oferecer um ambiente de desenvolvimento consistente, reproduzível e pronto para utilização.

---

# Pré-requisitos

* Todos os playbooks da fase **04-development** concluídos.

---

# Resultado esperado

Ao concluir este playbook:

* todas as capacidades de desenvolvimento terão sido verificadas;
* o fluxo completo de desenvolvimento estará funcional;
* a workstation estará pronta para utilização em projetos reais.

---

# Procedimento

## 1. Validar o controle de versão

Confirme que é possível:

* clonar um repositório remoto;
* criar uma branch;
* realizar commits;
* sincronizar alterações com o repositório remoto.

---

## 2. Validar o ambiente de shell

Abra uma nova sessão de terminal.

Confirme que:

* o shell inicia corretamente;
* o prompt é carregado;
* aliases e funções estão disponíveis;
* as ferramentas auxiliares funcionam normalmente.

---

## 3. Validar o editor de código

Abra um projeto de teste.

Confirme que:

* o editor inicia corretamente;
* as configurações versionadas foram aplicadas;
* as extensões previstas estão disponíveis;
* Git está integrado ao editor.

---

## 4. Validar a plataforma de contêineres

Confirme que é possível:

* iniciar um contêiner;
* construir uma imagem;
* executar um projeto utilizando Compose;
* abrir um Dev Container no editor.

---

## 5. Validar as ferramentas de linha de comando

Execute operações utilizando as ferramentas previstas pela arquitetura.

Considere:

* pesquisa de arquivos;
* busca textual;
* manipulação de JSON e YAML;
* gerenciamento de sessões;
* inspeção de repositórios;
* automação de tarefas.

---

## 6. Validar as ferramentas de inteligência artificial

Utilize um repositório de teste.

Confirme que é possível:

* solicitar análise de código;
* revisar alterações;
* gerar documentação;
* propor melhorias;
* executar o fluxo previsto pelo projeto sem exposição de informações sensíveis.

---

## 7. Validar o fluxo completo

Execute um fluxo representativo do dia a dia de desenvolvimento.

Sugestão de sequência:

1. Clonar um repositório.
2. Abrir o projeto no editor.
3. Inicializar o Dev Container.
4. Editar um arquivo.
5. Executar comandos pelo terminal integrado.
6. Rodar testes.
7. Revisar alterações.
8. Criar um commit.
9. Enviar as alterações ao repositório remoto.

O objetivo é validar a integração entre todas as capacidades da workstation.

---

## 8. Revisar registros e observações

Documente:

* limitações conhecidas;
* ajustes pendentes;
* melhorias futuras;
* decisões tomadas durante a configuração.

---

# Verificação

Confirme que:

* todas as capacidades previstas estão operacionais;
* Git, Shell, Editor e Plataforma de Contêineres funcionam de forma integrada;
* Dev Containers são utilizados como ambiente principal de desenvolvimento;
* as ferramentas de linha de comando estão disponíveis;
* as ferramentas de IA operam conforme os padrões definidos pelo projeto;
* nenhuma linguagem ou SDK específico de projetos foi instalado diretamente na workstation sem justificativa arquitetural;
* o fluxo completo de desenvolvimento foi executado com sucesso;
* não existem erros críticos que impeçam o desenvolvimento de software.

---

# Problemas comuns

## Fluxo interrompido

Retorne ao playbook correspondente à capacidade que apresentou falha antes de prosseguir.

---

## Dev Container não inicia

Revise a plataforma de contêineres, a integração com o editor e a configuração do projeto.

---

## Integração entre ferramentas inconsistente

Confirme que todas as configurações versionadas foram aplicadas corretamente.

---

## Ferramentas indisponíveis

Compare a workstation com os dotfiles e a documentação do projeto.

---

## Dependências instaladas no host

Revise se a dependência realmente pertence à workstation ou se deve ser movida para o Dev Container correspondente.

---

# Próximos passos

Com a fase **04-development** validada, a workstation está pronta para receber capacidades específicas de uso.

As próximas fases poderão incluir, conforme a evolução do projeto:

* aplicações de uso geral;
* virtualização;
* ferramentas de nuvem;
* segurança;
* manutenção;
* outras especializações.

---

# Referências

* Architecture Overview
* Playbooks da fase **04-development**
* ADR-0004 — Single Responsibility Playbooks
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui melhorias identificadas durante a validação, capacidades incorporadas ao fluxo de desenvolvimento ou observações relevantes para futuras instalações.
