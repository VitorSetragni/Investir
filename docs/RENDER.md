# API no Render

A API do Investir está publicada no plano **Free**, usando o código de `VitorSetragni/Investir` e o banco existente. As implantações são manuais. Não crie outro serviço nem reaplique a carga inicial.

- API pública: `https://investir-api.onrender.com`
- Saúde: [abrir /health](https://investir-api.onrender.com/health)
- Administração: [Render Dashboard](https://dashboard.render.com/)

## Versão 1.1.1

O código `912c057` foi implantado em 28/10/2026, com regras `2026.10.28.1`. A verificação na API e no banco confirmou **7 FIIs preferidos, 6 aceitáveis, 28 a confirmar e 314 fora dos filtros**. As classificações das ações foram preservadas.

No detalhe de KNCR11, o valor original `-` continua armazenado; a avaliação mostra performance `0%`, benchmark `0` e critério atendido. As duas bases continuam em outubro/2026, revisão 1, com 374 ações e 355 FIIs.

Os 85 testes do backend com PostgreSQL, os 11 testes Flutter em cada plataforma e os builds Android/macOS passaram na [execução 7](https://github.com/VitorSetragni/Investir/actions/runs/40706586540). A instalação física e o login real continuam exigindo conferência própria.

## Configuração

O serviço usa Dockerfile `backend/Dockerfile`, contexto `backend/`, escuta em `0.0.0.0` e respeita a variável `PORT`. O arquivo `render.yaml` descreve uma instalação gratuita equivalente e serve de referência; não o sincronize criando um recurso duplicado.

As variáveis da instalação existente já estão configuradas na hospedagem. Para outra instalação, use os exemplos do repositório e obtenha os valores diretamente dos painéis autorizados:

| Variável | Finalidade |
|---|---|
| `DATABASE_URL` | Conexão PostgreSQL privada pelo Session pooler, com TLS |
| `SUPABASE_URL` | URL do projeto de autenticação |
| `SUPABASE_ANON_KEY` | Chave publishable/anon usada na autenticação |
| `UPLOADER_EMAILS` | E-mails autorizados a substituir as planilhas |
| `APP_ENV` | Ambiente de produção |

Mantenha credenciais, identidade técnica e informações internas de conexão na configuração privada. Não as copie para Flutter, Git, logs ou documentos públicos. A chave `service_role` não é necessária.

O banco usa uma identidade técnica com leitura/escrita limitada às tabelas do aplicativo, sem superusuário, criação de objetos ou bypass de RLS. Os clientes públicos continuam bloqueados no banco e consultam o catálogo pela API.

## Publicar uma atualização

1. Execute os testes e publique o código no repositório autorizado.
2. No serviço existente do Render, confirme a origem e use **Manual Deploy → Deploy latest commit**.
3. Acompanhe a implantação até o estado **Live** e confira o commit publicado.
4. Execute o verificador público e consulte o detalhe de um ativo afetado pela mudança.

```bash
python3 scripts/check-server.py https://investir-api.onrender.com
```

O verificador consulta saúde, catálogo, competências e detalhe de ativo. Não altera dados nem exige senha. Login e importação autorizada precisam de verificação própria.

Na primeira inicialização com uma nova versão das regras de FIIs, a API recalcula as avaliações em uma transação, preservando dados originais, evidências autorizadas e metadados das planilhas. O processo é idempotente.

## Login e limites

A conta do painel Supabase é diferente da conta de login do aplicativo. Crie a conta autorizada em **Authentication → Users**, confirme o e-mail e inclua-o em `UPLOADER_EMAILS`.

O serviço Free pode pausar por inatividade. O cliente aguarda até 120 segundos por solicitação e informa a possível demora na abertura. Importações não são repetidas automaticamente após falha de rede. O plano da instalação existente não foi alterado.

Os aplicativos já incluem a API pública padrão. Para outra instalação, configure `API_BASE_URL` na compilação. O botão de aparência alterna o tema, sem expor configuração interna da hospedagem.

Referências: [deploys](https://render.com/docs/deploys), [health checks](https://render.com/docs/health-checks), [Free](https://render.com/docs/free).
