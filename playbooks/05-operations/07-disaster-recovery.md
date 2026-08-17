---
title: Disaster recovery
version: 0.2
status: Stable
author: Rafael
last_review: 2026-08-17
related:
  - 05-backup.md
  - 06-recovery.md
---

# 07 — Disaster recovery

## Objetivo

Definir como reconstruir a workstation após perda total do sistema ou do disco, usando fontes externas à máquina perdida e evitando dependências que existam apenas na memória do operador.

Disaster recovery trata reconstrução de uma instalação perdida. Recuperações pontuais em uma instalação ainda utilizável pertencem ao playbook `06-recovery.md`.

## Fontes de recuperação

| Necessidade | Fonte |
| --- | --- |
| mídia inicial | Arch Linux ISO oficial |
| configuração e automação | repositório público `franraf/linux-workstation` |
| ordem de reconstrução | profile, manifests e runner do repositório |
| credenciais pessoais | mecanismo externo ao Git |
| dados pessoais não reconstruíveis | backup externo, quando operacional |

O repositório é público. Portanto, a obtenção inicial do bootstrap não depende de chave SSH, token GitHub ou credencial armazenada na workstation perdida.

## Pré-requisitos externos

A reconstrução não deve depender da sobrevivência do SSD ou do pendrive atualmente utilizado.

Devem existir caminhos para obter externamente:

- acesso a outro computador com internet quando for necessário recriar a mídia;
- Arch Linux ISO oficial;
- capacidade de gravar a ISO em um dispositivo USB;
- conectividade de rede no ambiente live;
- acesso HTTPS público ao repositório;
- credenciais pessoais necessárias após a reconstrução, por mecanismo externo ao Git;
- backup externo dos dados pessoais, quando o step de backup estiver operacional.

## Rotas de entrada

### Rota primária — mídia existente

1. Inicializar pela mídia Arch Linux já preparada.
2. Estabelecer conectividade de rede.
3. Obter o repositório público.
4. Usar o repositório como fonte da reconstrução.

### Rota fallback — recriar a mídia

1. Em outro computador com internet, obter a Arch Linux ISO oficial.
2. Criar uma nova mídia USB inicializável.
3. Inicializar a workstation pela nova mídia.
4. Estabelecer conectividade de rede.
5. Obter o repositório público.
6. Usar o repositório como fonte da reconstrução.

A mídia física atual não é tratada como fonte única de recuperação.

## Obtenção do repositório

Quando `git` estiver disponível no ambiente apropriado:

```bash
git clone https://github.com/franraf/linux-workstation.git
cd linux-workstation
```

Se o ambiente live ainda não possuir uma dependência necessária ao bootstrap, seguir o procedimento de instalação correspondente do projeto em vez de manter uma segunda sequência informal neste documento.

## Reconstrução

1. Preparar o novo disco conforme o procedimento de instalação do projeto.
2. Obter o repositório público.
3. Identificar o profile aplicável.
4. Consultar o status e o plano pelo runner.
5. Executar as fases na ordem declarada pelo profile/manifests.
6. Respeitar gates, confirmações, reboots e pontos de resume declarados pelo runner.
7. Executar os gates de validação aplicáveis após cada estágio relevante.
8. Recuperar credenciais pessoais por mecanismo externo ao Git quando necessárias.
9. Restaurar dados pessoais a partir do backup externo quando essa capacidade estiver operacional.
10. Executar a validação final da workstation.

A ordem concreta das fases não é duplicada como autoridade neste documento. Profile, manifests e runner são a fonte canônica para essa sequência.

## Dados pessoais

A reconstrução do sistema e a restauração dos dados são problemas separados.

O repositório reconstrói estado declarativo da workstation, mas não substitui dados pessoais não reconstruíveis.

Enquanto `05-backup.md` permanecer em estado `Prepared / hardware pending`, disaster recovery de dados pessoais permanece explicitamente incompleto. Snapshots locais no SSD perdido não são considerados substitutos de backup externo.

## Credenciais

Nenhuma credencial necessária ao uso normal da workstation deve ser adicionada ao Git para facilitar disaster recovery.

O runbook deve indicar apenas o ponto em que a credencial volta a ser necessária. Sua recuperação deve ocorrer por fonte segura externa ao equipamento perdido.

Exemplos incluem autenticação GitHub para operações de escrita, serviços pessoais e outras credenciais que não sejam necessárias para o clone público inicial.

## Ensaio não destrutivo

O projeto não realizará reinstalação destrutiva artificial na workstation atual.

A validação desta geração consiste em auditar se o caminho de reconstrução pode ser iniciado sem estado exclusivo do host atual e se a sequência posterior é descoberta pelas fontes canônicas do repositório.

### Checklist

- [x] o repositório pode ser obtido publicamente sem credenciais do host perdido;
- [x] existe rota primária usando mídia já disponível;
- [x] existe rota fallback para recriar a mídia em outro computador;
- [x] a mídia física atual não é um ponto único de falha;
- [x] a ordem de reconstrução é delegada ao profile/manifests/runner;
- [x] credenciais são explicitamente externas ao Git;
- [x] uma reinstalação destrutiva artificial não é exigida para fechar este playbook;
- [ ] restauração de dados pessoais por backup externo validada — pendente de hardware.

## Verificação

A parte reconstruível da workstation é considerada documentada quando um operador pode partir de mídia Arch + rede + repositório público e chegar ao runner sem depender de caminhos internos memorizados.

A recuperação integral incluindo dados pessoais somente poderá ser considerada validada após o step de backup executar e testar uma restauração real em hardware externo.

## Problemas comuns

### Dependência escondida na máquina perdida

Toda dependência indispensável à reconstrução deve ter um caminho externo documentado.

### Repositório acessível somente por SSH

O bootstrap inicial usa o clone HTTPS público. Autenticação de escrita pode ser restaurada posteriormente.

### Pendrive como ponto único de falha

A rota fallback deve permitir recriar a mídia em outro computador.

### Credenciais versionadas para facilitar recuperação

Não armazenar segredos no Git; recuperar credenciais por fonte segura externa.

### Ordem manual divergente do profile

Usar runner e manifests como fonte da ordem de reconstrução, evitando manter uma segunda sequência autoritativa neste documento.

### Confundir reconstrução com restauração de dados

O repositório recompõe a workstation declarativa. Dados pessoais exigem backup externo.

## Próximo playbook

`08-operations-validation.md`

## Referências

- `05-backup.md`
- `06-recovery.md`
- `docs/architecture.md`
- `docs/roadmap.md`
- `docs/standards.md`

## Lições aprendidas

- Disaster recovery deve minimizar conhecimento implícito; cada dependência que existe apenas na memória do operador é uma lacuna de recuperação.
- Um repositório público remove autenticação GitHub do caminho crítico do bootstrap inicial.
- Mídia de instalação deve ser recriável e não tratada como ativo insubstituível.
- A sequência de reconstrução deve possuir uma única fonte autoritativa: o runner e seus manifests.
- Reconstrução do sistema pode ser preparada antes da disponibilidade do hardware necessário para validar restauração de dados pessoais.
