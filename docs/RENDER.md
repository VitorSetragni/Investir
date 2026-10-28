# Publicar a API no Render

Atualizado em 28/10/2026. O código foi publicado com autorização do usuário em `VitorSetragni/Investir`. O serviço **investir-api** já foi criado no workspace confirmado, no plano **Free**, região Virginia. **Ainda não está operacional:** a inicialização parou porque `DATABASE_URL` não foi configurada.

[Painel do serviço](https://dashboard.render.com/web/srv-dbgui2flk1mc739gob5g). Endereço atribuído: `https://investir-api.onrender.com`. Não crie outro serviço com o mesmo propósito.

## Configuração incluída

O arquivo `render.yaml`, na raiz, define um único Web Service Docker no plano **Free**, região Virginia, com verificação `/health`. O contexto de build é `backend/`; o Dockerfile já escuta em `0.0.0.0` e usa a variável `PORT`. As atualizações ficam manuais (`autoDeployTrigger: off`) até a validação da primeira publicação.

Não é criado outro banco. Os 729 ativos continuam no Supabase existente, fora do disco temporário do Render. Não execute uma nova carga inicial nem altere as regras de RLS para fazer o deploy.

## Publicação

1. O repositório próprio já foi criado: `VitorSetragni/Investir`. Preserve `.github/` ao publicar o código. As planilhas originais e `backend/.env.supabase.example` foram adicionadas ao `.gitignore` e não entram no envio público. O repositório `Carteira_investimento` contém outro aplicativo e não foi alterado.
2. O serviço existente foi criado diretamente pelo conector, com o Dockerfile e contexto descritos no Blueprint. Use seu painel para configuração. O Blueprint fica como referência para uma instalação futura; não o sincronize criando um recurso duplicado.
3. `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `UPLOADER_EMAILS`, porta e ambiente já foram configurados. Falta `DATABASE_URL`. A senha deve ser guardada somente na hospedagem, sem aparecer em código ou conversa.

| Variável solicitada | Origem |
|---|---|
| `DATABASE_URL` | Supabase → Connect → Session pooler, porta 5432, com senha codificada na URL e `sslmode=require` |
| `SUPABASE_ANON_KEY` | Valor publicável já presente em `backend/.env.supabase.example` |
| `UPLOADER_EMAILS` | E-mail da conta Auth autorizada a importar, ou vários separados por vírgula |

O backend aceita `postgresql://` e o converte para o driver psycopg. A conexão Session pooler atende hospedagens IPv4. **Copie o host exato do painel Supabase → Connect → Session pooler; ele não pode ser deduzido apenas pela região.** Para solicitar ajuda, informe apenas o domínio do host, sem usuário ou senha. Não use a chave `service_role` nem coloque `DATABASE_URL` no Flutter.

A identidade `investir_backend` foi criada com permissão de leitura/escrita apenas nas três tabelas do aplicativo, sem ser superusuário, sem poder criar objetos e sem bypass de RLS. Sua política específica permite essas operações; os clientes `anon` e `authenticated` continuam bloqueados. O papel permanece **NOLOGIN**, sem senha definida, até a configuração da implantação. Ao ativá-lo, use o usuário `investir_backend.PROJECT_REF` na conexão do pooler e armazene a nova senha exclusivamente no Render.

Se o painel pedir configuração manual: **runtime Docker**, Dockerfile `backend/Dockerfile`, contexto `backend`, health check `/health`, plano Free; copie as variáveis do Blueprint para o formulário.

## Login e verificação

O projeto Supabase `investir` estava ativo, com 374 ações, 355 FIIs e **zero contas Auth** na conferência de 28/10/2026. A conta de administração do Supabase não é a conta de login do aplicativo. É necessário criar a conta em **Authentication → Users**, confirmar seu e-mail e incluí-lo em `UPLOADER_EMAILS`.

Depois que o Render informar **Live**, use a URL HTTPS exata retornada:

```bash
python3 scripts/check-server.py https://SUA-API.onrender.com
```

O verificador faz apenas consultas públicas: saúde, catálogo, competências e detalhes de um ativo. Não importa planilhas, não altera dados e não exige senha. O login, a importação autorizada e a instalação em aparelhos devem ser verificados separadamente.

Os aplicativos agora usam por padrão `https://investir-api.onrender.com`, sem exigir configuração do endereço na primeira abertura. O endereço pode ser alterado em **Servidor**. As compilações de Android e macOS passaram na execução de validação; a disponibilidade real da API continua dependendo da configuração acima.

## Primeiro acesso e limites

O plano Free pausa o serviço após 15 minutos sem tráfego e a reativação pode levar cerca de um minuto. O cliente agora aguarda até 120 segundos por solicitação e informa essa possível demora na abertura. Não repete automaticamente importações após falhas de rede.

O plano tem limites de horas, transferência e builds; um método de pagamento cadastrado pode permitir cobranças por excedentes. Não foi contratado plano pago. Consulte o painel antes de confirmar recursos. Não use chamadas periódicas artificiais para impedir a pausa.

Referências: [Blueprint](https://render.com/docs/blueprint-spec), [FastAPI](https://render.com/docs/deploy-fastapi), [Free](https://render.com/docs/free).

## Verificação desta preparação

Sintaxe YAML, caminhos do Dockerfile/contexto e variáveis solicitadas foram conferidos. O verificador público passou por cinco cenários simulados: catálogo consistente, modo demonstração, tickers duplicados, contagem divergente e falha de rede. Nenhum deles acessa produção.

Análise Flutter, seis testes Flutter e builds de Android/macOS passaram no GitHub Actions. O SDK local bloqueado anteriormente não foi executado novamente. A instalação nos aparelhos físicos, o login real e o verificador contra uma API operacional continuam pendentes.

Os **46 testes de backend passaram novamente** com as planilhas originais e, separadamente, com os dados fictícios usados na CI pública. Foram verificadas novamente as políticas RLS, a ausência de acesso direto dos clientes e a análise de segurança do Supabase, que não apresentou avisos. Isso ainda não substitui a verificação de um backend publicado com conexão PostgreSQL.
