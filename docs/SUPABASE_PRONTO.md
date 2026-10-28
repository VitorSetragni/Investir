# Banco e servidor operacionais

Atualizado em **28/10/2026**. O projeto Supabase **investir**, no plano Free e na região **São Paulo (`sa-east-1`)**, está conectado à API gratuita do Render. Nenhum plano pago foi contratado.

[Abrir o projeto no Supabase](https://supabase.com/dashboard/project/stnckjpqjebsftcnlywu) · [Verificar a saúde da API](https://investir-api.onrender.com/health)

## Estado verificado

| Item | Estado |
|---|---|
| Banco | PostgreSQL 17.11, projeto ativo |
| Tabelas | `snapshots`, `assets`, `market_cache` |
| Ações | 374 registros, outubro/2026, revisão 1 |
| FIIs | 355 registros, outubro/2026, revisão 1 |
| Total | 729 ativos |
| RLS | Ativo nas três tabelas |
| Acesso direto dos clientes | Revogado; políticas restritivas negam acesso direto |
| Identidade da API | `investir_backend`, com login exclusivo e permissões nas três tabelas |
| Credencial privada | Configurada somente no Render, com autorização do usuário |
| Conexão | Session pooler IPv4, porta 5432, com TLS |
| Servidor | `https://investir-api.onrender.com`, deploy Live |
| Saúde, catálogo e detalhe | Conferidos na API pública com PostgreSQL de produção |
| Importação sem login | Recusada com HTTP 401 |
| Segurança Supabase | Sem avisos na conferência |
| Contas Auth pessoais | Nenhuma; falta criar o acesso para importar |
| Android e macOS | Compilações e testes aprovados; instalação física pendente |

Os aplicativos consultam a API FastAPI. As tabelas permanecem privadas para clientes `anon` e `authenticated`. A identidade do backend não é superusuário, não cria bancos ou papéis e não ignora RLS.

A senha técnica é separada da senha pessoal do aplicativo. Ela não deve ser copiada para o Git, para o Flutter ou para arquivos de exemplo. Não redefina a senha administrativa do projeto para configurar o app: a conexão já utiliza uma identidade exclusiva.

**Não reaplique a carga inicial:** os ativos já estão no banco. A implantação não executa DDL nem altera as políticas ao iniciar.

## Criar o acesso para importar planilhas

1. Abra **Authentication → Users → Add user → Create new user** no projeto Supabase.
2. Use seu e-mail e defina uma senha própria para o aplicativo. Marque **Auto Confirm User** para que o e-mail conste como confirmado.
3. O e-mail precisa estar em `UPLOADER_EMAILS` no Render. A lista já foi preparada para o e-mail autorizado na configuração inicial.
4. No aplicativo, abra **Importar** e entre com essa conta. Sua conta administrativa do painel Supabase não é automaticamente uma conta Auth do app.
5. Selecione o XLSX, confira a revisão e confirme a substituição. Ações e FIIs têm competências independentes.

A criação e o login de uma conta real, assim como uma importação autenticada, ainda não foram verificados. Nenhuma conta pessoal ou senha pessoal foi criada automaticamente.

## Instalar e verificar

Os arquivos são `Investir-Android-arm64.apk` e `Investir-macOS.zip`. Consulte [INSTALACAO.md](INSTALACAO.md) para os limites de assinatura e a instalação. Ambos usam a API padrão já operacional.

Para repetir a verificação pública:

```bash
python3 scripts/check-server.py https://investir-api.onrender.com
```

O teste faz apenas consultas e não exige credenciais. Foram confirmados os 729 ativos, as duas competências 2026-10 e o detalhe de AALR3. B3SA3 e KNCR11 retornaram cotação, histórico e proventos sem avisos na conferência de 28/10/2026.

Os 46 testes do backend com PostgreSQL, análise Flutter, seis testes Flutter e builds nativos passaram no [GitHub Actions](https://github.com/VitorSetragni/Investir/actions/runs/40688395379). Isso não substitui a instalação nos aparelhos e o login de uma conta pessoal.

A hospedagem gratuita pode pausar por inatividade. Não foram criadas chamadas artificiais para impedir essa pausa. Consulte [RENDER.md](RENDER.md) para o estado da implantação e a configuração.
