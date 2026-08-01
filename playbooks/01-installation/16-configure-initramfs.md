---

title: Configurar o initramfs
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

# 15 — Configurar o initramfs

## Objetivo

Configurar e gerar a imagem de initramfs necessária para inicialização do sistema.

Ao final deste playbook, o sistema estará preparado para iniciar utilizando a arquitetura de armazenamento definida pelo projeto.

---

# Pré-requisitos

* Ambiente `arch-chroot` ativo.
* Sistema base instalado.
* Usuários configurados.

---

# Resultado esperado

Ao concluir este playbook:

* a configuração do initramfs refletirá a arquitetura do sistema;
* a imagem de initramfs será gerada sem erros;
* o sistema estará preparado para inicialização.

---

# Procedimento

## 1. Revisar a configuração

Verifique a configuração do initramfs.

Confirme que ela contempla os componentes necessários para:

* criptografia;
* sistema de arquivos;
* inicialização da workstation.

---

## 2. Atualizar a configuração

Caso necessário, ajuste a configuração para refletir a arquitetura adotada.

---

## 3. Gerar a imagem

Gere uma nova imagem de initramfs utilizando a ferramenta recomendada pelo Arch Linux.

---

## 4. Confirmar a geração

Verifique se a geração foi concluída sem erros.

---

# Verificação

Confirme que:

* a imagem foi gerada com sucesso;
* nenhuma mensagem de erro foi apresentada;
* os componentes esperados estão contemplados na configuração.

---

# Problemas comuns

## Falha na geração

Revise a configuração antes de repetir o processo.

---

## Componentes ausentes

Confirme que a configuração contempla a arquitetura de armazenamento utilizada.

---

## Arquivos não encontrados

Verifique se todos os pacotes necessários foram instalados antes da geração da imagem.

---

# Próximo playbook

Após validar o initramfs, prossiga para:

```text id="siy0tm"
17-install-bootloader.md
```

---

# Referências

* Arch Wiki — mkinitcpio
* Arch Wiki — Initramfs
* Arch Wiki — dm-crypt

---

# Lições aprendidas

Registrar aqui ajustes na configuração do initramfs, inclusão de novos componentes ou observações relevantes para futuras instalações.

