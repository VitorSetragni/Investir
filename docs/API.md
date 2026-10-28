# Contrato da API

Prefixo público `/api`. Todas as respostas são JSON. Exemplos e validações estão disponíveis em `/docs` depois que a API inicia.

| Método | Rota | Acesso | Função |
|---|---|---|---|
| GET | `/health` | Público | Estado da API e banco |
| GET | `/api/catalog` | Público | Ativos resumidos e competência/revisão de cada planilha |
| GET | `/api/assets/{ticker}` | Público | Dados e resultado de cada regra |
| GET | `/api/assets/{ticker}/market` | Público | Preço, histórico, pagamentos e origem/horário |
| POST | `/api/auth/login` | Credenciais | Troca e-mail/senha por sessão Supabase |
| POST | `/api/auth/refresh` | Refresh token | Renovação com rotação de token |
| POST | `/api/auth/logout` | Bearer | Revogação da sessão |
| POST | `/api/imports/preview` | Bearer autorizado | Validação XLSX e prévia sem alterar a base |
| POST | `/api/imports` | Bearer autorizado | Substituição transacional |
| POST | `/api/assets/{ticker}/evidence` | Bearer autorizado | Conferência documental específica da base |

## Importação

Prévia `multipart/form-data`: `kind` (`stocks` ou `fiis`), `reference` (`AAAA-MM`), `file` (`.xlsx`, até 12 MB). A resposta inclui `sha256`, `expected_revision`, competência anterior e contagens por classificação.

Confirmação: envie o mesmo arquivo e os mesmos campos, mais `sha256` e `expected_revision` retornados pela prévia. Conflitos retornam 409. O backend não guarda arquivos de upload entre as duas etapas; o cliente mantém os bytes até a confirmação.

O backend reconhece cabeçalhos nas primeiras 15 linhas e a aba “Método Davi”. Cabeçalhos são normalizados por acentos e maiúsculas. Tickers duplicados, limites de arquivo, tipo incorreto e competência conflitante interrompem a importação. Percentuais numéricos devem usar frações, como `0.30`; textos `30%` também são aceitos. Campo numérico ausente não é zero: a regra fica a confirmar. A importação deve ser feita com a planilha previamente recalculada em Excel/LibreOffice se ela contiver fórmulas.

## Dados de mercado

`quote.as_of` é o horário da cotação, em ISO 8601 UTC, diferente de `fetched_at`, que é a consulta ao provedor. `cached` indica uso de cache; `stale` indica cache antigo mantido por falha do provedor. A UI converte o horário para o fuso do dispositivo. Somente tickers presentes na base atual podem ser consultados.

`dividends[].payment_date` nunca é preenchida a partir de data ex. Eventos que só possuem data ex ficam em `ex_date_events`. Último pagamento/frequência/dia ficam indisponíveis se as datas de pagamento não forem fornecidas. Mensagens em `warnings` aparecem no aplicativo.

## Segurança e operação

Banco e credenciais ficam no backend. Tokens nativos ficam no Keychain/armazenamento seguro da plataforma. A URL pública do servidor pode ficar nas preferências locais. O app de produção aceita HTTPS. Sem senha padrão, cadastro público ou chave privilegiada dentro do cliente.

RLS e políticas restritivas bloqueiam acesso direto às tabelas pelas roles públicas do Supabase. Em produção, a API valida o schema e não executa DDL. A conexão de banco fica no servidor, via TLS. Login e importações têm limite por endereço observado pelo servidor. Uvicorn inicia sem confiar em cabeçalhos de proxy enviados pelo cliente; ajuste a configuração apenas se conhecer e restringir os IPs do proxy da hospedagem. Sem ajuste, vários usuários atrás de um proxy podem compartilhar o limite.

Para produção com maior tráfego, use provedor de dados com contrato e limite distribuído externo (Redis ou equivalente), além de observabilidade e backups. A entrega é para um catálogo pequeno, uma instância e um worker.
