# Banco preparado em 27/10/2026

**Atualização de 28/10/2026:** o serviço gratuito do Render foi criado e as compilações Android/macOS passaram. O projeto Supabase continua ativo com os 729 registros e ainda não tem contas Auth. A identidade exclusiva `investir_backend` foi criada com RLS e permanece sem login. Falta o host exato do Session pooler para ativar a conexão privada. Consulte [RENDER.md](RENDER.md); a API ainda não está operacional.

O projeto **investir** já foi criado na organização escolhida, na região **São Paulo (`sa-east-1`)**. O custo informado pelo conector para sua criação foi **US$ 0 por mês**.

[Abrir o projeto no Supabase](https://supabase.com/dashboard/project/stnckjpqjebsftcnlywu)

## O que já foi feito

| Item | Estado verificado |
|---|---|
| Banco | PostgreSQL 17.11, projeto ativo |
| Tabelas | `snapshots`, `assets`, `market_cache` |
| Ações | 374 registros, outubro/2026, revisão 1 |
| FIIs | 355 registros, outubro/2026, revisão 1 |
| Total | 729 ativos |
| RLS | Ativo nas três tabelas |
| Acesso direto dos clientes | Revogado; políticas restritivas negam leitura e escrita direta |
| Serviço Auth | Endpoint público de configuração respondeu HTTP 200 |
| Teste com chave publicável | Leitura direta de ativos e competências respondeu HTTP 401 / código PostgreSQL 42501, como esperado |
| Verificação de segurança Supabase | Sem avisos após aplicar as políticas explícitas |

As tabelas não ficam expostas ao aplicativo diretamente. A consulta pública passa pelo backend FastAPI, que mostra apenas o catálogo previsto. Os privilégios de escrita continuam no servidor. A chave publicável isolada não permite alterar nem ler essas tabelas.

O advisor de performance registrou apenas um aviso informativo de índice ainda não usado (`ix_assets_category`), esperado em uma base nova sem o backend publicado. Ele foi mantido; não é uma falha de segurança. [Referência do aviso](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index).

As migrações remotas aplicadas foram `investir_initial_schema` e `investir_deny_direct_client_access`. O arquivo `database/schema.sql` contém o estado equivalente para instalações futuras. Não reaplique a carga inicial: os ativos já estão no banco.

## O que falta para colocar o servidor online

### 1. Definir a conexão privada do banco

No painel do projeto, defina sua própria senha do banco em **Project Settings → Database → Database password**. Em **Connect**, copie a conexão **Session pooler**, porta 5432. Insira a senha na URL usando codificação de URL para caracteres especiais e mantenha `sslmode=require`.

Essa é uma senha do PostgreSQL, separada da conta do aplicativo. Configure-a diretamente nas variáveis do JustRunMy.App; não é necessário enviá-la na conversa nem colocá-la no repositório.

### 2. Criar a conta para importar

No painel, vá em **Authentication → Users → Add user → Create new user**. Crie a conta com seu e-mail e uma senha própria do aplicativo. Marque **Auto Confirm User** para que o e-mail conste como confirmado.

Sua conta da organização Supabase não é automaticamente uma conta do Auth do aplicativo. Na verificação inicial, o projeto ainda não tinha usuários Auth. O arquivo de configuração já identifica o e-mail da conta conectada em `UPLOADER_EMAILS`; ajuste-o se quiser autorizar outra pessoa.

### 3. Publicar o backend no JustRunMy.App

Use o Dockerfile da pasta `backend`. O arquivo **`backend/.env.supabase.example`** já contém a URL real do projeto e uma chave **publicável**, não privilegiada. Preencha apenas a conexão privada `DATABASE_URL`, confira `UPLOADER_EMAILS` e transfira as variáveis ao painel da hospedagem.

Exponha a porta 8000 via HTTPS e confirme `/health`. A API de produção apenas verifica o schema e o RLS; não tenta criar tabelas nem mudar permissões ao iniciar. Após publicar, informe **a URL HTTPS do FastAPI** no aplicativo. A URL do projeto Supabase é usada pelo servidor, não substitui essa URL do backend.

O backend não foi publicado: não há conexão administrativa com sua conta do JustRunMy.App nesta sessão.

## Flutter / FluxBuilder

O plugin conectado é o **FluxBuilder**, não um SDK Flutter genérico. A conta conectou, mas ainda não possui projetos nem licenças ativas. A documentação e as ferramentas disponíveis tratam de configuração/design de projetos FluxBuilder/FluxStore e builds Android/iOS/PWA. O conector não apresentou um fluxo para enviar nosso projeto Dart próprio e produzir um aplicativo macOS.

Por isso, nenhum projeto de loja foi criado, nenhuma licença foi comprada, nenhum build de outro aplicativo foi submetido e nenhum e-mail de build foi disparado.

Os instaladores **APK e macOS continuam pendentes**. Permanecem os scripts e o workflow GitHub Actions incluídos no projeto. Não foi repetida a execução local do SDK bloqueada pela revisão automática anterior.

Documentação consultada: [Importação de design/configuração](https://docs.fluxbuilder.com/import-export-and-other/) e [Builds FluxBuilder](https://docs.fluxbuilder.com/build-and-publish-your-app/).

## Testes do código

**46 testes do backend aprovados**, incluindo os cinco novos casos de integração/configuração: distinção entre credencial inválida, limite de tentativas e indisponibilidade do Auth; inicialização de produção sem DDL; recusa de schema sem RLS.

Os testes automatizados do backend usam SQLite e mocks para os cenários de startup PostgreSQL. As contagens, permissões, políticas, advisors e endpoints HTTP acima foram conferidos separadamente no projeto Supabase real. Isso não equivale a testar o FastAPI conectado ao PostgreSQL com uma senha de produção, nem a testar login de uma conta Auth já criada.
