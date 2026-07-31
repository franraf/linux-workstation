---

title: Configurar o Pacman
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 02 — Configurar o Pacman

## Objetivo

Configurar o gerenciador de pacotes do Arch Linux de acordo com os padrões definidos pelo projeto.

Ao final deste playbook, o sistema utilizará uma configuração consistente para gerenciamento de pacotes, priorizando segurança, desempenho e previsibilidade.

---

# Pré-requisitos

* Sistema atualizado.
* Acesso administrativo disponível.

---

# Resultado esperado

Ao concluir este playbook:

* a configuração do Pacman refletirá os padrões do projeto;
* os repositórios necessários estarão habilitados;
* opções de desempenho e segurança estarão configuradas;
* o sistema estará preparado para futuras instalações e atualizações de software.

---

# Procedimento

## 1. Revisar a configuração padrão

Analise a configuração padrão do Pacman antes de realizar alterações.

Identifique opções que serão modificadas conforme a arquitetura da workstation.

---

## 2. Configurar os repositórios

Confirme que os repositórios previstos pelo projeto estão habilitados.

Evite adicionar repositórios de terceiros sem justificativa documentada.

---

## 3. Ajustar opções de gerenciamento

Configure as opções recomendadas pelo projeto relacionadas ao gerenciamento de pacotes, downloads e verificação de integridade.

---

## 4. Definir política de cache

Configure a política adotada para armazenamento e manutenção do cache de pacotes.

A política deve equilibrar recuperação, consumo de disco e facilidade de manutenção.

---

## 5. Validar a configuração

Revise o arquivo de configuração e confirme que todas as alterações correspondem aos padrões definidos pelo projeto.

---

# Verificação

Confirme que:

* a configuração do Pacman foi aplicada corretamente;
* os repositórios configurados estão acessíveis;
* a sincronização dos bancos de dados ocorre sem erros;
* não existem avisos relacionados à configuração.

---

# Problemas comuns

## Repositório indisponível

Verifique a conectividade e confirme que o repositório está corretamente configurado.

---

## Erros de assinatura

Revise a configuração das chaves de confiança e confirme a integridade dos repositórios.

---

## Configuração inconsistente

Compare o arquivo atual com o padrão definido pelo projeto e remova alterações não documentadas.

---

# Próximo playbook

Após validar o Pacman, prossiga para:

```text
03-install-microcode.md
```

---

# Referências

* Arch Wiki — Pacman
* Arch Wiki — Pacman/Tips and tricks
* Arch Wiki — Official repositories

---

# Lições aprendidas

Registrar aqui alterações na configuração do Pacman, políticas de gerenciamento de pacotes adotadas pelo projeto ou observações relevantes identificadas durante a manutenção da workstation.
