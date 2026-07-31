---

title: Instalar microcode do processador
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

# 03 — Instalar microcode do processador

## Objetivo

Instalar o pacote de microcode correspondente ao processador da workstation e integrá-lo ao processo de inicialização do sistema.

Ao final deste playbook, o sistema carregará automaticamente o microcode apropriado durante o boot.

---

# Pré-requisitos

* Sistema atualizado.
* Pacman configurado.
* Modelo do processador identificado.

---

# Resultado esperado

Ao concluir este playbook:

* o pacote de microcode correspondente ao processador estará instalado;
* o bootloader reconhecerá a imagem de microcode;
* o microcode será carregado automaticamente durante a inicialização.

---

# Procedimento

## 1. Identificar o fabricante do processador

Determine se a workstation utiliza um processador Intel ou AMD.

---

## 2. Instalar o pacote adequado

Instale exclusivamente o pacote correspondente ao fabricante identificado.

Evite instalar pacotes de microcode desnecessários.

---

## 3. Atualizar a configuração de inicialização

Confirme que a configuração do bootloader contempla o carregamento da imagem de microcode.

Caso necessário, atualize a configuração conforme a arquitetura do projeto.

---

## 4. Revisar a instalação

Verifique se os arquivos necessários foram instalados e estão disponíveis para o processo de boot.

---

# Verificação

Confirme que:

* o pacote de microcode está instalado;
* o bootloader referencia corretamente a imagem de microcode;
* o sistema carrega o microcode durante a inicialização;
* não existem avisos relacionados ao microcode nos logs do sistema.

---

# Problemas comuns

## Microcode não carregado

Verifique a configuração do bootloader e confirme que a imagem está sendo referenciada corretamente.

---

## Pacote incorreto

Confirme o fabricante do processador antes de instalar ou substituir o pacote.

---

## Arquivos ausentes

Verifique se a instalação do pacote foi concluída com sucesso e se os arquivos estão presentes na partição de boot.

---

# Próximo playbook

Após validar o microcode, prossiga para:

```text id="0v4j8r"
04-configure-time-sync.md
```

---

# Referências

* Arch Wiki — Microcode
* Arch Wiki — Intel
* Arch Wiki — AMD

---

# Lições aprendidas

Registrar aqui alterações relacionadas ao microcode, atualizações específicas do fabricante ou observações relevantes identificadas durante futuras manutenções.
