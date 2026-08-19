# Dev Container Test

Exemplo mínimo usado para validar o ambiente de desenvolvimento da Linux Workstation.

## Objetivo

Validar que:

- Docker Engine está funcional;
- VS Code Dev Containers consegue criar um ambiente isolado;
- runtimes específicos de projeto permanecem dentro do container;
- dependências Python podem ser instaladas no ambiente do projeto;
- testes podem ser executados dentro do Dev Container.

## Estrutura

- `.devcontainer/devcontainer.json` — configuração do Dev Container;
- `calculator.py` — código Python mínimo;
- `test_calculator.py` — testes;
- `requirements.txt` — dependências do projeto.

## Uso

Abra este diretório no Visual Studio Code e execute:

`Dev Containers: Reopen in Container`

Depois:

```bash
pytest
