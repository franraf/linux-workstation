---

title: Ferramentas de inteligência artificial
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

# 06 — Ferramentas de inteligência artificial

## Objetivo

Adicionar à workstation ferramentas de inteligência artificial voltadas ao apoio no desenvolvimento de software.

Ao final deste playbook, o ambiente estará preparado para utilizar assistência por IA em atividades como análise de código, geração de alterações, revisão, documentação e investigação técnica.

As implementações adotadas deverão ser selecionadas conforme as necessidades reais do mantenedor, evitando ferramentas redundantes.

---

# Pré-requisitos

* Capacidade de controle de versão concluída.
* Ambiente de shell configurado.
* Editor de código configurado.
* Plataforma de contêineres operacional.
* Conectividade de rede disponível.

---

# Resultado esperado

Ao concluir este playbook:

* as ferramentas de IA previstas pelo projeto estarão instaladas;
* a autenticação estará configurada de forma segura;
* as ferramentas estarão integradas ao fluxo de desenvolvimento;
* credenciais e informações sensíveis não estarão versionadas;
* cada ferramenta possuirá uma finalidade claramente definida.

---

# Princípios de adoção

As ferramentas de IA deverão respeitar os princípios gerais do projeto.

## Uma implementação por capacidade

Evite instalar múltiplas ferramentas permanentes que executem essencialmente a mesma função.

Antes de adicionar uma nova implementação, avalie:

* qual problema ela resolve;
* qual capacidade existente ela complementa;
* se substitui uma ferramenta atual;
* qual custo de manutenção introduz;
* como será validada.

## Segredos fora do repositório

Tokens, chaves de API, credenciais e arquivos de autenticação não deverão ser armazenados nos dotfiles ou no repositório `linux-workstation`.

O repositório poderá conter:

* exemplos sem credenciais;
* nomes de variáveis esperadas;
* instruções de autenticação;
* templates seguros;
* arquivos `.example`.

## Revisão humana obrigatória

Saídas geradas por IA não deverão ser aplicadas de forma automática sem revisão.

Mudanças em código, infraestrutura, documentação ou configuração deverão ser:

* inspecionadas;
* testadas;
* versionadas;
* validadas conforme os padrões do projeto.

## Menor acesso necessário

Uma ferramenta deverá receber apenas o acesso necessário para executar sua tarefa.

Evite fornecer acesso indiscriminado a:

* diretório pessoal;
* chaves SSH;
* credenciais;
* arquivos de configuração sensíveis;
* sockets administrativos;
* repositórios não relacionados à atividade.

---

# Estrutura da configuração

Mantenha apenas configurações reproduzíveis e não sensíveis nos dotfiles.

Estrutura recomendada:

```text
dotfiles/

ai/
├── README.md
├── environment.example
├── prompts/
├── instructions/
└── tools/
    └── <tool-name>/
```

Responsabilidades:

* `README.md`: ferramentas adotadas e seus propósitos;
* `environment.example`: nomes das variáveis necessárias, sem valores;
* `prompts/`: prompts reutilizáveis e não específicos de projetos;
* `instructions/`: regras gerais de comportamento para agentes;
* `tools/`: configurações não sensíveis de cada implementação.

Configurações específicas de um projeto deverão permanecer no próprio repositório do projeto.

---

# Procedimento

## 1. Definir as capacidades necessárias

Antes da instalação, determine quais capacidades de IA serão utilizadas.

Considere, quando aplicável:

* assistência no terminal;
* análise de repositórios;
* geração e edição de código;
* revisão de alterações;
* criação de testes;
* geração de documentação;
* explicação de erros;
* suporte dentro do editor.

Não adicione uma ferramenta sem uma finalidade concreta.

---

## 2. Selecionar as implementações

Escolha uma implementação principal para cada capacidade necessária.

Registre no diretório `dotfiles/ai/`:

* nome da ferramenta;
* capacidade entregue;
* método de instalação;
* forma de autenticação;
* limitações conhecidas;
* dados aos quais ela poderá ter acesso.

---

## 3. Instalar as ferramentas

Instale apenas as implementações aprovadas pelo projeto.

Prefira:

* repositórios oficiais do Arch Linux;
* métodos oficiais de instalação do fornecedor;
* execução isolada em contêiner, quando apropriada.

Não introduza AUR apenas para instalar uma ferramenta de IA sem avaliar alternativas oficiais.

---

## 4. Configurar a autenticação

Configure as credenciais utilizando mecanismos seguros.

Considere:

* variáveis de ambiente carregadas fora do Git;
* armazenamento seguro de credenciais;
* autenticação interativa;
* arquivos locais protegidos por permissões adequadas.

Confirme que nenhum segredo aparece em:

* histórico do shell;
* commits;
* logs;
* arquivos de exemplo;
* saídas de diagnóstico.

---

## 5. Configurar o comportamento

Defina instruções gerais para utilização das ferramentas.

Considere regras como:

* não modificar arquivos sem apresentar o diff;
* não executar comandos destrutivos sem autorização;
* não acessar segredos;
* respeitar os padrões do projeto;
* executar testes após alterações;
* explicar suposições e limitações;
* manter mudanças pequenas e revisáveis.

Quando a ferramenta oferecer arquivos próprios de instrução, utilize o formato nativo suportado por ela.

---

## 6. Integrar ao ambiente de desenvolvimento

Configure as integrações necessárias com:

* ambiente de shell;
* editor de código;
* Git;
* Dev Containers;
* repositórios locais.

Evite integrações globais quando a configuração pertence apenas a um projeto específico.

---

## 7. Validar em um projeto de teste

Utilize um repositório descartável ou controlado para validar as ferramentas.

Execute tarefas como:

* explicar um trecho de código;
* propor uma pequena alteração;
* gerar um teste;
* revisar um diff;
* atualizar uma seção de documentação.

Confirme que a ferramenta respeita os limites e instruções definidos.

---

## 8. Revisar segurança e privacidade

Antes de considerar a capacidade concluída, confirme:

* quais arquivos podem ser enviados ao serviço;
* se há coleta de telemetria;
* onde os dados são processados;
* como as credenciais são armazenadas;
* se existe risco de exposição de código privado;
* se o uso é compatível com políticas profissionais aplicáveis.

---

# Verificação

Confirme que:

* cada ferramenta instalada possui uma finalidade definida;
* não existem implementações redundantes sem justificativa;
* a autenticação funciona corretamente;
* nenhum segredo está versionado;
* o histórico do shell não contém credenciais;
* as integrações necessárias estão operacionais;
* mudanças produzidas podem ser revisadas antes da aplicação;
* a ferramenta respeita as instruções do projeto;
* um fluxo completo foi validado em um repositório de teste.

---

# Problemas comuns

## Credencial não reconhecida

Revise o mecanismo de autenticação adotado e confirme que a variável ou arquivo esperado está disponível na sessão atual.

---

## Segredo registrado no histórico

Remova a entrada do histórico, revogue a credencial exposta e gere uma nova credencial antes de continuar.

---

## Ferramenta acessa arquivos indevidos

Revise o diretório de execução, permissões, arquivos ignorados e regras de exclusão da implementação.

---

## Alterações excessivamente amplas

Reforce as instruções para produzir mudanças pequenas, delimitadas e revisáveis.

Divida a solicitação em tarefas menores.

---

## Resultado tecnicamente incorreto

Não aplique a alteração.

Revise as suposições, forneça mais contexto e valide a resposta utilizando documentação oficial e testes.

---

## Ferramentas redundantes

Defina qual implementação permanecerá como padrão e remova as demais quando não houver uma capacidade distinta que justifique sua manutenção.

---

## Ferramenta exige runtime no host

Avalie, nesta ordem:

1. pacote oficial do Arch Linux;
2. binário oficial independente;
3. execução em contêiner;
4. Dev Container específico;
5. outra forma oficial de isolamento.

Evite instalar runtimes de projeto no host apenas para suportar uma ferramenta auxiliar.

---

# Próximo playbook

Após validar as ferramentas de inteligência artificial, prossiga para:

```text
07-development-validation.md
```

---

# Referências

* Documentação oficial das ferramentas adotadas
* Políticas de segurança e privacidade dos respectivos fornecedores
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui ferramentas adotadas ou removidas, capacidades atendidas, limitações encontradas, incidentes envolvendo credenciais e melhorias realizadas no fluxo de desenvolvimento assistido por IA.
