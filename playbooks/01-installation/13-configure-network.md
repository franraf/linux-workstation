---

title: Configurar rede
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

# 13 — Configurar rede

## Objetivo

Configurar a identificação do sistema na rede e preparar a infraestrutura básica de conectividade.

Ao final deste playbook, o sistema possuirá um nome de host configurado, resolução local funcional e estará preparado para gerenciar conexões de rede após o primeiro boot.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.
* Data, hora e localização configuradas.

---

# Resultado esperado

Ao concluir este playbook:

* o hostname estará configurado;
* o arquivo de resolução local estará consistente;
* os serviços de rede previstos pela arquitetura estarão preparados para utilização.

---

# Procedimento

## 1. Definir o hostname

Configure o nome da máquina conforme o perfil da instalação.

---

## 2. Configurar a resolução local

Atualize o arquivo de resolução de nomes local.

Confirme que o hostname definido está corretamente associado às entradas de loopback.

---

## 3. Instalar os componentes de rede

Instale os componentes previstos pela arquitetura para gerenciamento de conexões.

---

## 4. Habilitar os serviços necessários

Configure os serviços para inicialização automática após o primeiro boot.

---

## 5. Revisar a configuração

Confirme que todos os arquivos foram atualizados corretamente.

---

# Verificação

Confirme que:

* o hostname está configurado;
* a resolução local está consistente;
* os serviços de rede encontram-se habilitados;
* não existem inconsistências entre o hostname e os arquivos de configuração.

---

# Problemas comuns

## Hostname incorreto

Revise a configuração e confirme que o nome corresponde ao perfil da instalação.

---

## Falha na resolução local

Verifique o conteúdo do arquivo de resolução de nomes e confirme que as entradas obrigatórias estão presentes.

---

## Serviço não habilitado

Confirme que o componente foi instalado antes da habilitação.

---

# Próximo playbook

Após validar a configuração de rede, prossiga para:

```text id="m1aw2g"
14-configure-users.md
```

---

# Referências

* Arch Wiki — Network configuration
* Arch Wiki — NetworkManager
* Arch Wiki — Hostname
* Arch Wiki — Hosts

---

# Lições aprendidas

Registrar aqui ajustes específicos de rede, alterações na configuração do hostname ou observações relevantes encontradas durante futuras instalações.
