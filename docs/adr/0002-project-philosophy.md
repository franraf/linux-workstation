---

title: Filosofia do projeto
version: 1.0
status: Stable
author: Rafael
last_review: 2026-07-30
related:

* ADR-0001

---

# ADR-0002 — Filosofia do projeto

## Status

Aceito.

## Contexto

Instalações pessoais de sistemas operacionais frequentemente evoluem por meio de comandos executados manualmente, tutoriais isolados e alterações não documentadas.

Com o tempo, isso torna difícil responder perguntas como:

* por que uma configuração foi adotada;
* quais arquivos foram modificados;
* como reproduzir a instalação;
* como recuperar o sistema;
* quais mudanças são seguras;
* quais dependências são realmente necessárias.

O projeto pretende evitar esse cenário tratando a workstation como infraestrutura versionada e documentada.

## Decisão

O projeto adotará os seguintes princípios.

### O repositório é a fonte da verdade

Toda configuração relevante deverá existir no repositório ou estar claramente referenciada por ele.

Configurações aplicadas manualmente e não registradas serão consideradas dívida técnica.

### Documentação antes da implementação

Procedimentos e decisões deverão ser documentados antes ou durante sua implementação.

A documentação não deverá ser criada apenas depois que o sistema já estiver funcionando.

### Automação depois do entendimento

Nenhum procedimento será automatizado antes que seus efeitos, riscos e formas de validação estejam compreendidos.

A primeira execução de etapas críticas poderá ser manual e documentada.

### Simplicidade antes de complexidade

Entre duas soluções adequadas, deverá ser preferida aquela com menos componentes, menor manutenção e comportamento mais previsível.

Complexidade adicional exigirá benefício claro.

### Preferência por ferramentas oficiais

Ferramentas dos repositórios oficiais do Arch Linux e componentes amplamente documentados terão prioridade.

AUR e soluções de terceiros somente serão utilizados quando trouxerem benefícios necessários e justificados.

### Mudanças pequenas e reversíveis

Alterações deverão ser divididas em unidades pequenas, versionadas e verificáveis.

Sempre que possível, deverá existir uma estratégia de rollback ou recuperação.

### Segurança por padrão

O projeto deverá reduzir riscos previsíveis sem tornar o ambiente impraticável.

Operações destrutivas exigirão validação explícita.

Segredos não deverão ser versionados.

### Reprodutibilidade acima da conveniência imediata

Uma solução ligeiramente mais trabalhosa poderá ser preferida quando produzir um ambiente mais fácil de reproduzir e manter.

### Separação de responsabilidades

Configurações do sistema, dados pessoais, ambientes de desenvolvimento e dotfiles deverão permanecer separados.

Essa separação deverá ser refletida no armazenamento, nos repositórios e nos scripts.

### Validação faz parte da implementação

Uma tarefa não será considerada concluída apenas porque o comando terminou sem erros.

Deverá existir uma verificação objetiva do resultado.

### Problemas geram conhecimento

Falhas relevantes encontradas durante a instalação ou manutenção deverão resultar em pelo menos uma destas ações:

* correção da documentação;
* atualização de um playbook;
* criação de um teste;
* registro em troubleshooting;
* atualização de um ADR;
* inclusão de uma lição aprendida.

## Definition of Done

Uma tarefa relevante será considerada concluída quando, conforme aplicável:

* a decisão estiver documentada;
* o procedimento estiver descrito;
* a implementação estiver versionada;
* a validação tiver sido executada;
* os testes tiverem sido criados ou atualizados;
* o changelog tiver sido atualizado;
* as lições aprendidas tiverem sido registradas;
* o resultado tiver sido revisado.

Nem todos os itens serão necessários em alterações pequenas, mas a ausência deverá ser consciente.

## Consequências positivas

* Facilita reinstalações e migrações futuras.
* Reduz dependência da memória do mantenedor.
* Melhora a capacidade de diagnosticar falhas.
* Permite revisar decisões antigas com contexto.
* Reduz alterações manuais não rastreadas.
* Cria uma base para automação segura.
* Torna o projeto reutilizável em outros perfis de hardware.

## Consequências negativas

* A implementação inicial será mais lenta.
* Mudanças simples poderão exigir atualização documental.
* Será necessário manter disciplina de versionamento.
* Alguns experimentos não poderão ser incorporados imediatamente.
* A documentação poderá exigir manutenção contínua.

Esses custos são aceitos em troca de maior previsibilidade e longevidade.

## Alternativas consideradas

### Configurar a máquina manualmente sem documentação formal

Rejeitada por não permitir reprodução confiável.

### Automatizar toda a instalação desde o início

Rejeitada porque ocultaria decisões e aumentaria o risco de automatizar erros.

### Manter apenas um README com todos os procedimentos

Rejeitada porque um único documento não escala adequadamente e mistura decisões, arquitetura, procedimentos e troubleshooting.

### Utilizar uma distribuição personalizada pronta

Não escolhida porque o objetivo inclui compreender e controlar a arquitetura da workstation.

## Regras de aplicação

Uma nova ferramenta não deverá ser adicionada somente por conveniência ou popularidade.

Antes de adotá-la, deverão ser avaliados:

* problema que resolve;
* custo de manutenção;
* dependências;
* compatibilidade com a arquitetura;
* alternativas existentes;
* possibilidade de remoção;
* forma de validação.

Ideias que não forem necessárias para a implementação atual deverão ser registradas no roadmap.

## Lições aprendidas

O planejamento inicial demonstrou a necessidade de congelar a arquitetura para evitar paralisia por análise.

Após o congelamento da versão 1.0, novas ideias estruturais deverão entrar no roadmap, salvo quando houver justificativa técnica concreta para mudança imediata.
