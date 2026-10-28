# Investir

Aplicativo para macOS e Android, backend FastAPI e banco PostgreSQL no Supabase Free. A consulta dos ativos é pública. Somente contas autorizadas importam e substituem a base mensal.

**Atualização de 27/10/2026:** o banco Supabase já foi criado na sua conta e recebeu os 729 ativos. Veja [o que está pronto e os três passos restantes](docs/SUPABASE_PRONTO.md). A configuração real publicável está em `backend/.env.supabase.example`, sem senha do banco.

**Atualização de 28/10/2026:** o código está publicado neste repositório. As compilações de Android e Mac passaram com PostgreSQL e testes de interface na [execução de validação](https://github.com/VitorSetragni/Investir/actions/runs/40685836185). O serviço `investir-api` foi criado no Render no plano Free, mas ainda depende da conexão privada do banco para funcionar. Veja [docs/RENDER.md](docs/RENDER.md).

## O que está implementado

- Ações organizadas por setor. FIIs separados em tijolo, papel e híbridos, agrupados por segmento.
- Seleções **Dentro dos filtros**, **Aceitáveis**, **A confirmar** e **Fora dos filtros**. Cada ativo mostra quais regras ficaram toleradas e todos os valores usados.
- Duas competências independentes, sempre visíveis. A planilha continua ativa até ser substituída, mesmo após virar o mês.
- Importação XLSX com login, prévia das contagens, confirmação e substituição transacional apenas do tipo escolhido.
- Arquivos inválidos não alteram a base. Importações concorrentes e versões anteriores são recusadas. O upload original não é persistido; apenas a base extraída atual e seus metadados ficam no banco. Registros anteriores desse tipo são apagados na transação.
- Detalhes com gráfico de até dois anos, preço e horário da cotação, último pagamento por cota, frequência e dia habituais quando o histórico permite.
- Evidências documentais registradas por usuário autorizado. São descartadas quando a planilha correspondente é substituída.

**Este repositório contém o código-fonte e os scripts de compilação.** Os instaladores são disponibilizados como arquivos após uma compilação aprovada. Eles incluem o endereço do servidor; a configuração pode ser alterada em **Servidor** no aplicativo. A disponibilidade do backend é verificada separadamente da compilação nativa. Veja [como instalar](docs/INSTALACAO.md).

## 1. Testar o backend localmente com suas planilhas

Requer Python 3.12. Os arquivos enviados estão em `examples/`, sem alterações. Não existe usuário/senha de demonstração para importação.

As planilhas originais acompanham somente o pacote privado de entrega e são ignoradas pelo Git. No clone do repositório público, coloque suas duas planilhas na pasta `examples/`, com os nomes usados pelo script, para executar essa demonstração local. A CI usa planilhas fictícias geradas pelos testes, com 374/355 linhas, incluindo os casos necessários de conferência documental. `TEST_SYNTHETIC_WORKBOOKS=1` permite executar essa mesma variante localmente. Os dados de produção continuam no banco existente.

Na pasta do projeto:

```bash
bash scripts/start-local.sh
```

Isso cria uma base SQLite **somente local**, importa 374 ações e 355 FIIs de outubro/2026 e inicia `http://127.0.0.1:8000`. A documentação da API abre em `http://127.0.0.1:8000/docs`.

Para executar o app no Mac em desenvolvimento, após instalar Flutter/Xcode/CocoaPods:

```bash
cd frontend
python3 tool/bootstrap.py
flutter pub get
flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=ALLOW_LOCAL_HTTP=true
```

O uso de HTTP é permitido no código Dart apenas com essa opção explícita de desenvolvimento. Nas compilações distribuídas, configure uma API HTTPS.

## 2. Banco e login gratuitos no Supabase

1. O projeto **investir** já foi criado em sua organização. [Abra o painel](https://supabase.com/dashboard/project/stnckjpqjebsftcnlywu). As instruções seguintes também permitem configurar outra instalação Free em [supabase.com](https://supabase.com/).
2. O schema e as políticas já estão aplicados no projeto criado. Para outra instalação, execute `database/schema.sql` no **SQL Editor**. Em produção o backend apenas valida as tabelas e o RLS, sem executar DDL. O app acessa o catálogo pela API, nunca direto pelo banco.
3. Em **Authentication → Users**, crie a conta de quem poderá importar. Confirme o e-mail. Não há cadastro público no aplicativo.
4. Em **Project Settings → API**, copie a URL do projeto e a chave **publishable/anon**. A chave `service_role` não é necessária.
5. Em **Connect**, selecione **Session pooler**, porta **5432**, que atende servidores IPv4. Copie a URL PostgreSQL. Codifique caracteres especiais da senha na URL. Use `sslmode=require`.
6. Para o projeto já criado, use `backend/.env.supabase.example`, que tem a URL e a chave publicável reais. Para outra instalação, use `backend/.env.example`. Em `UPLOADER_EMAILS`, coloque os e-mails autorizados, separados por vírgula. Estar autenticado sem estar nessa lista não permite substituir a base pública.

O plano Free consultado inclui 500 MB de banco e autenticação, suficientes para esse catálogo. Pode pausar por baixa atividade após sete dias; a reativação é feita no painel. Confira as condições atuais em [supabase.com/pricing](https://supabase.com/pricing). O custo do JustRunMy.App é separado.

## 3. Subir o backend no JustRunMy.App

Use a pasta **backend** como raiz da implantação. Há um Dockerfile pronto:

```bash
cd backend
docker build -t investir-api .
```

No JustRunMy.App, escolha a implantação Docker/ZIP conforme seu plano. Para ZIP de código, o pacote completo contém `backend`; selecione essa pasta como diretório de build. Se a interface não permitir escolher subpasta, compacte **o conteúdo de backend** como raiz do upload. Para imagem Docker, publique a imagem no registro indicado pela plataforma.

Configure estas variáveis no painel, sem colocá-las no aplicativo ou no Git:

| Variável | Valor |
|---|---|
| `DATABASE_URL` | Conexão do Session pooler Supabase, com `sslmode=require` |
| `SUPABASE_URL` | `https://SEU-PROJETO.supabase.co` |
| `SUPABASE_ANON_KEY` | Chave publishable/anon |
| `UPLOADER_EMAILS` | E-mails de quem pode importar |
| `PORT` | `8000` |
| `APP_ENV` | `production` — já definido no Dockerfile |
| `MARKET_CACHE_SECONDS` | `900` |

Exponha **a porta 8000 com HTTPS**. O processo escuta em `0.0.0.0:8000`. Use `/health` para verificar o serviço. O container roda com usuário sem privilégios e um worker. O banco externo mantém as planilhas entre reinícios e reimplantações. Produção recusa SQLite para evitar perda de dados no container.

Abra a URL HTTPS da API e acrescente `/health`; a resposta deve conter `"status":"ok"`. Não é necessário expor PostgreSQL no JustRunMy.App.

Documentação da plataforma: [Getting started](https://justrunmy.app/docs/get-started/overview) e [Networking](https://justrunmy.app/docs/concepts/networking).

## 4. Gerar o app para Mac

Requer macOS, Flutter **3.38.5 ou posterior**, Xcode com ferramentas de linha de comando e CocoaPods. O SDK fixado no workflow é 3.38.5. As plataformas nativas são geradas pelo script usando os templates oficiais do SDK, sem sobrescrever `lib/` ou `pubspec.yaml`.

```bash
bash scripts/build.sh macos
```

Também há `Criar-app-Mac.command` para executar no Terminal. Se necessário, dê permissão uma vez com `chmod +x Criar-app-Mac.command`.

Resultado esperado: `dist/Investir-macOS.zip`, contendo `Investir.app`. A API pode ser configurada em **Servidor** no próprio aplicativo, sem recompilar. Opcionalmente:

```bash
API_BASE_URL=https://SUA-API.justrunmy.app bash scripts/build.sh macos
```

Esta compilação não faz assinatura de distribuição Apple nem notarização. Para distribuir a terceiros sem o aviso do Gatekeeper, use sua conta Apple Developer e siga a [documentação de publicação macOS](https://docs.flutter.dev/deployment/macos). Para uso próprio no Mac, a abertura de uma compilação local pode exigir **Abrir** pelo menu de contexto.

## 5. Gerar o APK para Android atual

Requer Flutter, Java 17 e SDK Android. Execute:

```bash
bash scripts/build.sh android
```

Resultado esperado para seu aparelho Android moderno: **`dist/Investir-Android-arm64.apk`**. O build usa API 36, mínimo API 23, NDK r28 e empacotamento nativo moderno, para compatibilidade com dispositivos de páginas de memória de 16 KB. A compatibilidade precisa ser confirmada instalando o APK no aparelho; essa instalação não foi realizada aqui.

Sem `frontend/android/key.properties`, o APK é de teste e usa a chave debug gerada pelo SDK. Para atualizar o mesmo aplicativo ao longo do tempo, mantenha uma chave de assinatura própria. Gere-a com o `keytool` do Java e crie `frontend/android/key.properties`:

```properties
storeFile=../investir-release.jks
storePassword=SUA_SENHA
keyAlias=investir
keyPassword=SUA_SENHA
```

Guarde o keystore e a senha. Os arquivos são ignorados pelo Git. Para publicar na Play Store, use assinatura de produção e gere também o AAB seguindo a [documentação Android do Flutter](https://docs.flutter.dev/deployment/android).

## 6. Gerar os dois aplicativos pelo GitHub Actions

O código está em `VitorSetragni/Investir`. O workflow `.github/workflows/build.yml` já executou com sucesso os testes PostgreSQL, análise e testes Flutter e os builds nativos. Os arquivos ficam nos artifacts da execução por 14 dias e podem ser baixados para entrega. O workflow mantém `contents: read`; não publica Releases automaticamente.

1. Envie esta pasta a um repositório seu, preservando `.github/`.
2. Abra **Actions → Testar e gerar aplicativos → Run workflow**.
3. Informe a URL HTTPS da API, ou deixe vazia para configurar dentro do app.
4. Depois de um build aprovado, baixe os artifacts **Investir-android** e **Investir-macos**.

O workflow executa testes do backend com PostgreSQL 16, análise Dart, testes Flutter e compilação em Linux/Android e macOS. As quotas e disponibilidade dos runners dependem da sua conta GitHub.

Para assinatura Android persistente no workflow, configure os secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD`. Sem eles, o resultado é um APK de teste. Não existe configuração de assinatura/notarização Apple no workflow.

## 7. Importar todo mês

1. Abra o app; a consulta não exige conta.
2. Na primeira abertura, configure o endereço HTTPS do backend em **Servidor**.
3. Toque em **Importar**, entre com a conta autorizada, escolha **Ações** ou **FIIs**, mês e ano.
4. Selecione o XLSX e escolha **Validar e revisar**.
5. Confira as contagens e confirme **Substituir base**.

Se enviar apenas ações, FIIs continuam no mês anterior. Se não enviar nada, ambas permanecem ativas. Cada tela mostra sua própria competência. Uma mensagem avisa quando a planilha é de um mês anterior ao atual. Para corrigir o mesmo mês, importe outro arquivo da mesma competência; um arquivo idêntico não duplica registros.

## 8. Como interpretar a seleção

**Dentro dos filtros**: atende aos filtros quantitativos com os dados disponíveis. **Aceitáveis**: atende aos mínimos, com pelo menos uma regra na faixa tolerada. **A confirmar**: informação necessária ausente, ambígua ou que depende de documento. **Fora dos filtros**: descumpre pelo menos um corte de exclusão ou de filtragem adotado.

Isso é triagem e não uma indicação automática de compra ou cálculo de valor justo. As regras e decisões de implementação estão em `docs/REGRAS.md`.

Na base enviada, há **12 ações selecionadas** (2 preferidas e 10 aceitáveis). Os FIIs possuem muitas informações incompletas de performance/regulamento; por isso ficam em **A confirmar** até conferência. O traço da planilha não é interpretado como comprovação de taxa inexistente. A lista de FIIs pode diferir da triagem exploratória anterior justamente por tornar essa pendência explícita.

Um usuário autorizado pode abrir um ativo e registrar a fonte oficial da conferência. Essa anotação vale só para a base atual, não é transferida automaticamente para o próximo mês e não transforma um critério efetivamente reprovado em aprovado.

## 9. Cotações, gráfico e pagamentos

- Preços: endpoint público de gráficos do Yahoo Finance, com origem e horário do dado. Não é API oficial da B3 nem feed contratado em tempo real. Há cache de 15 minutos no backend.
- Pagamentos: tabelas públicas do Status Invest. Se a página não disponibilizar as datas, o app mostra informação indisponível. A data ex-dividendo do Yahoo **não** é usada como data de pagamento.
- Último pagamento: soma dos proventos informados para a mesma data, excluindo amortizações e pagamentos futuros. Os valores são brutos; JCP pode ter retenção tributária.
- Frequência: requer pelo menos quatro datas distintas e 70% dos intervalos compatíveis. Caso contrário, aparece “Irregular” ou “Dados insuficientes”. O dia habitual é estimado e não constitui promessa de pagamento.
- O gráfico mostra preços da fonte, não retorno total com reinvestimento. Não compara automaticamente preço com valor justo.
- Provedores públicos podem alterar formato ou limitar acesso. Para publicação comercial, verifique as condições de uso/redistribuição e substitua os adaptadores por um provedor licenciado quando necessário. A lógica está isolada em `backend/app/market.py`.

## 10. Testes e estado de verificação

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python -m pytest -q --tb=short
```

Os testes usam SQLite temporário ou `TEST_DATABASE_URL`, e nunca a variável de produção `DATABASE_URL`. Use uma base de teste descartável quando informar `TEST_DATABASE_URL`.

Verificado nesta entrega: **46 testes automatizados de backend aprovados** com SQLite/mocks, leitura das duas planilhas reais, contagens de 374/355, substituição, idempotência, proteção de upload, conflitos e casos de fronteira das regras. Também foram conferidos as contagens, RLS, políticas, permissões e endpoints HTTP no Supabase real. Foram consultados dados reais de B3SA3 e KNCR11: cotação, 497 pontos de histórico por ativo e tabelas de pagamentos.

No GitHub Actions, **os 46 testes do backend com PostgreSQL 16, a análise Flutter, os seis testes Flutter e os builds APK/macOS passaram** na execução de validação. Os testes da nuvem usam dados fictícios. A execução local do SDK, bloqueada anteriormente pela revisão automática, não foi repetida. **Instalação em aparelhos físicos, validação visual nativa, login real e teste ponta a ponta da API publicada com PostgreSQL de produção continuam pendentes.**

O banco Supabase já está criado e carregado. O serviço gratuito do Render também foi criado, mas não iniciou por falta da conexão privada do banco. Falta configurar essa conexão e criar a conta Auth para importação. Nenhuma senha de produção ou chave privilegiada foi incluída no código. O arquivo de configuração específico acompanha apenas a entrega privada e é ignorado pelo Git. Consulte `docs/RENDER.md` para o estado exato.
