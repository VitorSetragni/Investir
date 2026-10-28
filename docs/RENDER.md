# Publicar a API no Render

Preparado em 28/10/2026. **A configuração está pronta; nenhum serviço Render foi criado ou publicado nesta etapa.** O conector está disponível e o usuário confirmou `vitor's workspace` como destino. O repositório `VitorSetragni/Investir` está acessível e é público. O envio do código aguarda autorização explícita para publicação pública; nenhuma alteração foi enviada ao repositório.

## Configuração incluída

O arquivo `render.yaml`, na raiz, define um único Web Service Docker no plano **Free**, região Virginia, com verificação `/health`. O contexto de build é `backend/`; o Dockerfile já escuta em `0.0.0.0` e usa a variável `PORT`. As atualizações ficam manuais (`autoDeployTrigger: off`) até a validação da primeira publicação.

Não é criado outro banco. Os 729 ativos continuam no Supabase existente, fora do disco temporário do Render. Não execute uma nova carga inicial nem altere as regras de RLS para fazer o deploy.

## Publicação

1. O repositório próprio já foi criado: `VitorSetragni/Investir`. Preserve `.github/` ao publicar o código. As planilhas originais e `backend/.env.supabase.example` foram adicionadas ao `.gitignore` e não entram no envio público. O repositório `Carteira_investimento` contém outro aplicativo e não foi alterado.
2. No Render, conecte esse repositório e escolha **New → Blueprint**, com `render.yaml` na raiz. Confirme **Free** antes de criar o recurso. Não adicione banco, disco ou outro serviço.
3. Preencha as variáveis solicitadas abaixo. A senha do banco deve ser configurada diretamente no painel, sem aparecer em código ou conversa.

| Variável solicitada | Origem |
|---|---|
| `DATABASE_URL` | Supabase → Connect → Session pooler, porta 5432, com senha codificada na URL e `sslmode=require` |
| `SUPABASE_ANON_KEY` | Valor publicável já presente em `backend/.env.supabase.example` |
| `UPLOADER_EMAILS` | E-mail da conta Auth autorizada a importar, ou vários separados por vírgula |

O backend aceita `postgresql://` e o converte para o driver psycopg. A conexão Session pooler atende hospedagens IPv4. Não use a chave `service_role` nem coloque `DATABASE_URL` no Flutter.

Se o painel pedir configuração manual: **runtime Docker**, Dockerfile `backend/Dockerfile`, contexto `backend`, health check `/health`, plano Free; copie as variáveis do Blueprint para o formulário.

## Login e verificação

O projeto Supabase `investir` estava ativo, com 374 ações, 355 FIIs e **zero contas Auth** na conferência de 28/10/2026. A conta de administração do Supabase não é a conta de login do aplicativo. É necessário criar a conta em **Authentication → Users**, confirmar seu e-mail e incluí-lo em `UPLOADER_EMAILS`.

Depois que o Render informar **Live**, use a URL HTTPS exata retornada:

```bash
python3 scripts/check-server.py https://SUA-API.onrender.com
```

O verificador faz apenas consultas públicas: saúde, catálogo, competências e detalhes de um ativo. Não importa planilhas, não altera dados e não exige senha. O login, a importação autorizada e a instalação em aparelhos devem ser verificados separadamente.

Informe a URL do **FastAPI publicado**, e não a URL bruta do Supabase, no workflow **Testar e gerar aplicativos**. Isso gera os aplicativos com o servidor já configurado, quando as compilações passarem. O workflow e os instaladores ainda não foram executados nesta etapa.

## Primeiro acesso e limites

O plano Free pausa o serviço após 15 minutos sem tráfego e a reativação pode levar cerca de um minuto. O cliente agora aguarda até 120 segundos por solicitação e informa essa possível demora na abertura. Não repete automaticamente importações após falhas de rede.

O plano tem limites de horas, transferência e builds; um método de pagamento cadastrado pode permitir cobranças por excedentes. Não foi contratado plano pago. Consulte o painel antes de confirmar recursos. Não use chamadas periódicas artificiais para impedir a pausa.

Referências: [Blueprint](https://render.com/docs/blueprint-spec), [FastAPI](https://render.com/docs/deploy-fastapi), [Free](https://render.com/docs/free).

## Verificação desta preparação

Sintaxe YAML, caminhos do Dockerfile/contexto e variáveis solicitadas foram conferidos. O verificador público passou por cinco cenários simulados: catálogo consistente, modo demonstração, tickers duplicados, contagem divergente e falha de rede. Nenhum deles acessa produção.

As mudanças de espera/mensagem do cliente ainda não passaram por análise Flutter, testes de widgets ou compilação nativa. O SDK não está disponível neste ambiente, e não foi repetida a execução bloqueada anteriormente. Não há URL Render publicada para executar o verificador contra o serviço real.

Os **46 testes de backend passaram novamente** com as planilhas originais e, separadamente, com os dados fictícios usados na CI pública. Foram verificadas novamente as políticas RLS, a ausência de acesso direto dos clientes e a análise de segurança do Supabase, que não apresentou avisos. Isso ainda não substitui a verificação de um backend publicado com conexão PostgreSQL.
