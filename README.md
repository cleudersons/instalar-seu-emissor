# Skill: instalar o Seu Emissor com o Claude Code

Esta skill ensina o Claude Code a colocar o Seu Emissor no ar no seu servidor, passo a passo, a partir do seu computador. O código do sistema não está aqui: ele vem no arquivo `seu-emissor-codigo-2026-11-16.zip` que você recebeu.

## Antes de começar

- Claude Code instalado no seu computador.
- Um servidor Linux (Ubuntu ou Debian) com acesso SSH. Recomendado: 2 vCPU e 4 GB de RAM.
- Um domínio onde você consiga criar registros DNS (ex.: `emissor.suaempresa.com.br`).
- O arquivo `.zip` do sistema no seu computador.

Para emitir notas depois, você também vai precisar de conta própria na Focus NFe e, para os e-mails, de conta no Resend. O manual dentro do zip explica.

## Instalar a skill (uma vez)

No terminal do seu computador:

```bash
git clone https://github.com/cleudersons/instalar-seu-emissor.git ~/.claude/skills/instalar-seu-emissor
```

No Windows (PowerShell):

```powershell
git clone https://github.com/cleudersons/instalar-seu-emissor.git "$HOME\.claude\skills\instalar-seu-emissor"
```

Para receber atualizações depois: `git -C ~/.claude/skills/instalar-seu-emissor pull`.

Sem git: na página do repositório, clique em **Code > Download ZIP**, extraia e renomeie a pasta para `instalar-seu-emissor`, colocando-a em `~/.claude/skills/` (no Windows: `C:\Users\SEU_USUARIO\.claude\skills\`). O arquivo `SKILL.md` precisa ficar direto dentro dela.

## Usar

1. Abra o Claude Code em qualquer pasta.
2. Peça: **"Instale o Seu Emissor no meu servidor"** (ou digite `/instalar-seu-emissor`).
3. O Claude vai pedir onde está o zip, o IP do servidor, o domínio e o e-mail, e vai seguir por fases, pedindo sua confirmação nas etapas importantes.

## Segurança

O Claude nunca vai pedir senhas ou chaves no chat. Quando for preciso digitar algo secreto (chaves do Resend e da OpenAI, senha do administrador), ele vai pedir que você abra um terminal seu e digite lá. Se algum dia ele pedir uma senha no chat, não envie.
