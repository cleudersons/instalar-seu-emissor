---
name: instalar-seu-emissor
description: Use quando o usuario quiser instalar, implantar, subir ou colocar no ar o sistema "Seu Emissor" (emissor de NFS-e SaaS, pacote seu-emissor-codigo-*.zip) em um servidor Linux proprio, a partir do computador dele via SSH. Cobre conferencia do pacote, preparo do servidor, Docker, .env, banco, administrador, HTTPS e checklist final.
---

# Instalar o Seu Emissor via SSH

Voce (Claude) roda no computador do usuario (Windows, Mac ou Linux) e instala o sistema em um servidor Linux remoto, executando comandos por SSH. O usuario e o dono da instalacao; fale com ele em portugues simples, sem jargao.

**Fonte da verdade:** o `MANUAL-INSTALACAO.md` que vem dentro do zip. Leia-o inteiro na Fase 1 antes de executar qualquer coisa. Este roteiro diz a ORDEM, os PONTOS DE PARADA e COMO executar via SSH; o manual tem os detalhes. Se os dois divergirem, siga o manual e avise o usuario.

**Scripts auxiliares desta skill** (pasta `remoto/` ao lado deste arquivo): `gerar-env.sh` e `criar-admin.sh`. Eles existem para evitar problemas de aspas no SSH e para que segredos nunca passem pelo chat. Envie-os ao servidor com `scp`; nao reescreva os comandos deles a mao.

## Regras inegociaveis

1. **Segredos nunca passam pelo chat.** Nunca peca ao usuario senhas, chaves de API (Resend, OpenAI), tokens Focus NFe ou a senha do administrador. Nunca rode comando que mostre valores do `.env` (`cat .env`, `grep` que imprima valores, `docker compose config` sem `--quiet`, `docker inspect`, `env`). Quando um segredo precisar ser digitado, o USUARIO digita no terminal dele (veja "Terminal do usuario"). Se o usuario colar um segredo no chat por engano, avise e recomende troca-lo.
2. **Nada destrutivo.** Nunca rode `docker compose down -v`, `docker volume rm`, `prisma migrate reset`, `prisma migrate dev`, `prisma db push`, `rm -rf` em pastas do sistema, nem sobrescreva um `.env` existente.
3. **Pergunte antes de mudar o servidor.** Instalar pacotes (Docker, Node), alterar firewall e criar pastas fora de `/opt/emissor-saas` exigem um "sim" explicito do usuario naquele momento.
4. **Erro = parar.** Se um comando falhar de forma inesperada, nao avance. Leia os logs, explique a causa em linguagem simples e proponha a correcao. (Alguns comandos de VERIFICACAO retornam erro quando a resposta e "nao existe" — esses estao marcados abaixo.)
5. **Servidor limpo.** Se o servidor ja tiver outro sistema usando as portas 80/443, ou ja existir `/opt/emissor-saas` com conteudo, pare e pergunte. Nao reutilize banco, `.env` ou tokens de outra instalacao.

## Como executar comandos

- **Opcoes SSH padrao** (use sempre; abaixo abreviadas como `SSH`): `ssh -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 USUARIO@IP` (acrescente `-i CAMINHO_DA_CHAVE` se a chave nao for a padrao).
- **Comando remoto simples:** `SSH "cd /opt/emissor-saas && COMANDO"`. Use aspas DUPLAS por fora e evite aspas dentro do comando; no PowerShell 5.1 aspas internas se perdem. Comando que precisa de aspas internas: escreva um `.sh` local (fim de linha LF), envie com `scp` e rode `SSH "bash /caminho/arquivo.sh"`.
- **Comandos demorados** (instalar Docker, `docker compose build`): rode em segundo plano no seu harness (por exemplo `run_in_background`) ou no servidor com `nohup COMANDO > /tmp/emissor-PASSO.log 2>&1 &` e acompanhe pelo log. Nao use `sleep` para esperar; use um laco de verificacao.
- **`docker compose run`** nao interativo: sempre com `-T`.
- **Windows:** use `curl.exe` (no PowerShell `curl` e outro comando). Em Git Bash, prefixe `scp`/`ssh` com `MSYS_NO_PATHCONV=1` para que `/opt/...` nao vire caminho do Windows.
- **Se o usuario SSH nao for root:** teste `SSH "sudo -n true"`. Se falhar (sudo pede senha), voce NAO pode digitar a senha: entregue o comando ao usuario para rodar no terminal dele.
- **Terminal do usuario:** para passos interativos ou com segredo, peca ao usuario que abra um terminal proprio (PowerShell no Windows, Terminal no Mac) e rode exatamente a linha que voce fornecer. Depois ele diz "feito" ou cola a mensagem de erro (sem segredos).

## Fase 1 — Conferir pacote e coletar dados

1. Pergunte onde esta o arquivo `.zip` no computador.
2. Confira a integridade. Hash SHA-256 esperado do pacote original de 16/11/2026:
   `1F0755866C4BC9A3C6A1DFCE6E1808B241D4E4F0376BA96550E1599DA99E68DC`
   - Windows: `(Get-FileHash ARQUIVO.zip -Algorithm SHA256).Hash`
   - Mac/Linux: `shasum -a 256 ARQUIVO.zip`
   Se for diferente, avise: pode ser uma versao mais nova ou um arquivo alterado. Continue somente se o usuario confirmar a origem.
3. Extraia em uma pasta local (Windows: `Expand-Archive`; Mac/Linux: `unzip`). Localize a pasta que contem `docker-compose.yml` (pode haver uma subpasta) — essa e a `PASTA_DO_SISTEMA`. Leia `MANUAL-INSTALACAO.md` e `README.md` por inteiro.
4. Colete, um item por vez se o usuario for leigo:
   - IP do servidor e usuario SSH (ex.: `root`);
   - dominio do sistema (ex.: `emissor.empresa.com.br`), sem `https://`;
   - e-mail para o certificado HTTPS (tambem vira o destinatario dos avisos de certificado);
   - nome do sistema que os clientes vao ver.
5. Teste: `ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 USUARIO@IP "echo ok"`. Se falhar, ajude a configurar chave SSH:
   - criar: `ssh-keygen -t ed25519` (o usuario roda no terminal dele; pode deixar a frase-senha vazia ou usar o agente SSH);
   - copiar para o servidor: Mac/Linux `ssh-copy-id USUARIO@IP`; Windows `type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh USUARIO@IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"` (pede a senha do servidor uma vez, no terminal do usuario); ou colar a chave publica no painel do provedor.
   Nao prossiga sem login por chave funcionando.

**Ponto de parada:** resuma os dados coletados e peca confirmacao.

## Fase 2 — Preparar o servidor

1. Sistema: `SSH "cat /etc/os-release"`. Suportado: Ubuntu ou Debian. Outro sistema: avise e pergunte antes de continuar.
2. Recursos: `SSH "nproc; free -h; df -h /"`. O manual recomenda a partir de 2 vCPU e 4 GB de RAM; avise se estiver abaixo.
3. Docker: `SSH "docker version && docker compose version"`. **Erro aqui apenas significa que o Docker nao esta instalado — nao e falha.** Com o "sim" do usuario, instale pelo metodo oficial (https://docs.docker.com/engine/install/ — ex.: `curl -fsSL https://get.docker.com | sh`), em segundo plano. Se o `apt` estiver travado (servidor recem-criado fazendo atualizacoes automaticas), aguarde alguns minutos e tente de novo. Confirme com `SSH "docker run --rm hello-world"`.
4. Portas: `SSH "ss -ltnp | grep -E ':(80|443) ' || echo PORTAS_LIVRES"`. Se nao vier `PORTAS_LIVRES`, algo ja usa 80/443: pare (Regra 5).
5. Firewall local: `SSH "ufw status || echo SEM_UFW"`. Se estiver ativo, com permissao do usuario libere `OpenSSH`, `80/tcp`, `443/tcp`, `443/udp`. Lembre que o firewall do PAINEL do provedor (Hetzner, AWS, etc.) tambem precisa liberar 80 e 443 — o usuario faz isso no painel. Nunca abra 3000 nem 5432.
6. DNS: no computador local, `nslookup DOMINIO` (Windows: `Resolve-DnsName DOMINIO`). O endereco deve ser o IP do servidor. Se houver registro AAAA (IPv6), ele tambem precisa apontar para o servidor. Se o DNS ainda nao apontar, explique como criar o registro A no painel do dominio e aguarde; sem isso o HTTPS falha.

**Ponto de parada:** relate o estado do servidor e o que foi alterado.

## Fase 3 — Enviar os arquivos

1. `SSH "test -e /opt/emissor-saas && ls -A /opt/emissor-saas || echo NAO_EXISTE"`. Se listar conteudo, pare (Regra 5).
2. Crie a pasta: `SSH "mkdir -p /opt/emissor-saas"` (se nao for root: `sudo mkdir -p /opt/emissor-saas && sudo chown USUARIO: /opt/emissor-saas`).
3. Envie o conteudo: entre na `PASTA_DO_SISTEMA` e rode `scp -r . USUARIO@IP:/opt/emissor-saas/`. Nunca envie `node_modules` (o pacote nao tem; se existir localmente, envie os itens um a um sem ele).
4. Envie os scripts auxiliares: `scp PASTA_DA_SKILL/remoto/gerar-env.sh USUARIO@IP:/opt/emissor-saas/.gerar-env.sh` e o mesmo para `criar-admin.sh` -> `/opt/emissor-saas/.criar-admin.sh`.
5. Confira: `SSH "cd /opt/emissor-saas && ls -la && ls deploy"` deve listar `docker-compose.yml`, `Dockerfile`, `package.json`, `package-lock.json`, `prisma`, `src`, `scripts`, `.env.example`, `.gerar-env.sh`, `.criar-admin.sh` e `deploy/Caddyfile`. Sem `deploy/Caddyfile` o HTTPS nao sobe.

## Fase 4 — Gerar e completar o .env

1. Execute o script (ele segue a secao 4 do manual): `SSH "bash /opt/emissor-saas/.gerar-env.sh DOMINIO EMAIL NOME_SEM_ESPACOS"`. Se o nome tiver espacos, crie localmente um `.sh` de uma linha com `bash /opt/emissor-saas/.gerar-env.sh DOMINIO EMAIL "Nome Com Espacos"`, envie e execute (veja "Como executar comandos"). O script nao imprime segredos; ao final lista as variaveis ainda vazias. Se disser que `.env` ja existe, pare e pergunte.
2. Explique ao usuario o que cada variavel vazia significa (tabela da secao 4 do manual). Necessarias para recuperacao de senha e avisos: `RESEND_API_KEY`, `EMAIL_REMETENTE`. Opcionais: `OPENAI_API_KEY`, `SUTOFLY_*`. (`EMAIL_AVISOS_ADMIN` ja vem com o e-mail informado; pode ser trocado.)
3. O usuario preenche no terminal dele: `ssh -t USUARIO@IP "nano /opt/emissor-saas/.env"` (salvar: Ctrl+O, Enter; sair: Ctrl+X). Voce NAO edita valores secretos.
4. Confira sem mostrar valores: `SSH "grep -oE '^[A-Z_]+=$' /opt/emissor-saas/.env || echo NENHUMA_VAZIA"` (imprime so nomes de variaveis vazias).
5. Avise: a `TOKEN_ENCRYPTION_KEY` nunca pode ser trocada depois e precisa ir para o backup; sem ela os tokens e certificados salvos ficam ilegiveis.

## Fase 5 — Construir, banco, administrador e HTTPS

Siga a secao 5 do manual, nesta ordem, conferindo cada saida:

1. Build (demorado, em segundo plano): `SSH "cd /opt/emissor-saas && docker compose build app"`.
2. `SSH "cd /opt/emissor-saas && docker compose up -d db"`
3. `SSH "cd /opt/emissor-saas && docker compose run --rm -T app npm run db:deploy"` — deve terminar com "All migrations have been successfully applied". Se falhar, pare.
4. **Administrador (terminal do usuario):** peca ao usuario que rode no terminal dele:
   `ssh -t USUARIO@IP "bash /opt/emissor-saas/.criar-admin.sh"`
   O script pede e-mail e senha (que nao aparece na tela), exige 12+ caracteres, cria o administrador e se apaga. Recomende guardar a senha num gerenciador de senhas. Espere o "feito".
5. `SSH "cd /opt/emissor-saas && docker compose up -d && docker compose ps"` (db, app e caddy devem estar `running`; db `healthy`).
6. Do computador local: `curl.exe -fsS https://DOMINIO/health` (Mac/Linux: `curl -fsS`) deve responder `"status":"ok"`. O certificado pode levar 1–2 minutos; repita a verificacao algumas vezes antes de concluir que falhou. Se falhar, veja `SSH "cd /opt/emissor-saas && docker compose logs --tail=50 caddy"` (normalmente DNS ou porta bloqueada no painel do provedor).

## Fase 6 — Fechamento

1. Peca ao usuario para abrir `https://DOMINIO/login.html`, entrar com o administrador e abrir a area Admin.
2. Sugira criar uma oferta de teste (secao 6 do manual) e um cliente de teste em `/registrar.html`.
3. **Conta propria na Focus NFe:** a emissao exige conta Focus NFe EM NOME DO USUARIO, com token por CNPJ, comecando em homologacao (secao 7 do manual). O webhook da Focus deve apontar para `https://DOMINIO/api/focus-nfe/webhook?token=VALOR`. O usuario obtem o VALOR no terminal dele com `ssh USUARIO@IP "grep ^FOCUS_NFE_WEBHOOK_TOKEN= /opt/emissor-saas/.env | cut -d= -f2-"` e cola direto no painel da Focus. Diga: nao cole esse token nem a URL completa no chat.
4. Backup (secao 9 do manual — banco + uploads + `.env`): ofereca configurar. O script `scripts/backup.js` precisa de Node 24 no servidor; com permissao do usuario, instale (ex.: `curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && apt-get install -y nodejs`). Exemplo de agendamento diario no cron do root: `0 3 * * * cd /opt/emissor-saas && /usr/bin/node scripts/backup.js >> /var/log/emissor-backup.log 2>&1`. Avise: o script nao apaga backups antigos nem copia para fora do servidor — o usuario precisa de uma copia externa e de limpeza periodica.
5. Entregue um resumo final: dominio, o que foi instalado, o que o usuario ainda precisa fazer (Resend se faltou, Focus NFe, backup externo, homologacao fiscal antes de vender — secao 10 do manual).

## Problemas comuns

| Sintoma | Verificar |
|---|---|
| SSH pede senha / recusa | chave SSH, usuario correto, porta 22 liberada no painel |
| `permission denied` no Docker | usuario fora do grupo docker: usar `sudo` ou root |
| HTTPS nao emite | DNS A/AAAA, portas 80/443 no painel do provedor, logs do caddy |
| App reinicia em loop | `docker compose logs --tail=100 app`; nomes de variaveis do `.env` (nao valores), chave AES com 64 hex |
| Banco recusa senha | `POSTGRES_PASSWORD` mudou depois do primeiro `up` do db; nao apague volume sem falar com o usuario |
| E-mail nao chega | dominio verificado no Resend, `EMAIL_REMETENTE` desse dominio |

Ao ler logs, mostre ao usuario so o trecho relevante e mascare qualquer coisa parecida com segredo, por exemplo filtrando com `| sed -E 's/(KEY|TOKEN|SECRET|PASSWORD)=[^ ]+/\1=***/g'`. Nunca cole logs completos em canais externos: podem conter dados fiscais.
