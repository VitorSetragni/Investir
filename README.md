# Investir

Aplicativo para macOS e Android, backend FastAPI e banco PostgreSQL no Supabase Free. A consulta dos ativos é pública. Somente contas autorizadas importam e substituem a base mensal.

**Banco e importação:** o Supabase Free mantém os 729 ativos. Veja [o estado atual e como criar o acesso para importar](docs/SUPABASE_PRONTO.md). A senha da conexão PostgreSQL fica somente na configuração privada da hospedagem.

**Atualização de 28/10/2026:** a API está operacional em `https://investir-api.onrender.com`, no plano Free do Render, conectada ao Supabase pelo Session pooler com uma identidade exclusiva do backend. Saúde, catálogo, detalhes e proteção contra importações sem login foram verificados em produção. As compilações Android/macOS e os testes passaram na [execução de validação](https://github.com/VitorSetragni/Investir/actions/runs/40688395379). Veja [docs/RENDER.md](docs/RENDER.md).

## O que está implementado

- Ações organizadas por setor. FIIs separados em tijolo, papel e híbridos, agrupados por segmento.
- Seleções **Dentro dos filtros**, **Aceitáveis**, **A confirmar** e **Fora dos filtros**. Cada ativo mostra quais regras ficaram toleradas e todos os valores usados.
- Duas competências independentes, sempre visíveis. A planilha continua ativa até ser substituída, mesmo após virar o mês.
- Importação XLSX com login, prévia das contagens, confirmação e substituição transacional apenas do tipo escolhido.
- Arquivos inválidos não alteram a base. Importações concorrentes e versões anteriores são recusadas. O upload original não é persistido; apenas a base extraída atual e seus metadados ficam no banco. Registros anteriores desse tipo são apagados na transação.
- Detalhes com gráfico de até dois anos, preço e horário da cotação, último pagamento por cota, frequência e dia habituais quando o histórico permite.
- Evidências documentais registradas por usuário autorizado. São descartadas quando a planilha correspondente é substituída.

**Este repositório contém o código-fonte e os scripts de compilação.** Os instaladores são disponibilizados como arquivos após uma compilação aprovada. Eles incluem o endereço da API. O botão de aparência alterna entre os modos claro e escuro e salva a escolha no aparelho. A disponibilidade do backend é verificada separadamente da compilação nativa. Veja [como instalar](docs/INSTALACAO.md).

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

1. O projeto do aplicativo já está configurado. Acesse sua instalação pelo [painel Supabase](https://supabase.com/dashboard). As instruções seguintes também permitem configurar outra instalação Free.
2. O schema e as políticas já estão aplicados. Para outra instalação, execute `database/schema.sql` no **SQL Editor**. Em produção o backend valida as tabelas e o RLS, sem executar DDL. O app acessa o catálogo pela API.
3. Em **Authentication → Users**, crie a conta de quem poderá importar e confirme o e-mail. Não há cadastro público no aplicativo.
4. Em **Project Settings → API**, obtenha a URL do projeto e a chave **publishable/anon**. A chave `service_role` não é necessária.
5. Em **Connect**, selecione **Session pooler**, porta **5432**, e obtenha a conexão PostgreSQL. Codifique caracteres especiais da senha e use `sslmode=require`.
6. Use `backend/.env.example` como referência. Configure as credenciais somente no ambiente privado da hospedagem. Em `UPLOADER_EMAILS`, informe os e-mails autorizados. Autenticação sem inclusão nessa lista não permite substituir a base pública.

O plano Free consultado inclui 500 MB de banco e autenticação, suficientes para esse catálogo. Pode pausar por baixa atividade após sete dias; a reativação é feita no painel. Confira as condições atuais em [supabase.com/pricing](https://supabase.com/pricing). O custo do JustRunMy.App é separado.

## 3. Backend gratuito no Render

O serviço **investir-api** já está publicado no plano **Free**, usando o Dockerfile de `backend/` e o banco Supabase existente. Não crie outro serviço nem reaplique a carga inicial.

- API: `https://investir-api.onrender.com`
- Saúde e conexão com o banco: [abrir /health](https://investir-api.onrender.com/health)
- Configuração e verificação: [docs/RENDER.md](docs/RENDER.md)

A variável privada `DATABASE_URL` já foi configurada no Render. Ela usa o Session pooler na porta 5432, TLS e uma identidade técnica sem privilégios administrativos. Não copie essa variável para o aplicativo, para o Git ou para arquivos de exemplo.

O serviço gratuito pode pausar por inatividade. O app já aguarda até 120 segundos por solicitação e informa essa possível demora. Nenhum plano pago foi contratado. As implantações continuam manuais.

## 4. Gerar o app para Mac

Requer macOS, Flutter **3.38.5 ou posterior**, Xcode com ferramentas de linha de comando e CocoaPods. O SDK fixado no workflow é 3.38.5. As plataformas nativas são geradas pelo script usando os templates oficiais do SDK, sem sobrescrever `lib/` ou `pubspec.yaml`.

```bash
bash scripts/build.sh macos
```

Também há `Criar-app-Mac.command` para executar no Terminal. Se necessário, dê permissão uma vez com `chmod +x Criar-app-Mac.command`.

Resultado esperado: `dist/Investir-macOS.zip`, contendo `Investir.app`. O endereço da API já acompanha o aplicativo. Para uma instalação com outro backend, configure-o na compilação:

```bash
API_BASE_URL=https://SUA-API.justrunmy.app bash scripts/build.sh macos
```

Esta compilação não faz assinatura de distribuição Apple nem notarização. Para distribuir a terceiros sem o aviso do Gatekeeper, use sua conta Apple Developer e siga a [documentação de publicação macOS](https://docs.flutter.dev/deployment/macos). Para uso próprio, depois de tentar abrir, a compilação local pode exigir **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**.

O build local usa o Chaves clássico do macOS e não declara Keychain Sharing, pois `keychain-access-groups` exige provisionamento Apple e bloqueia a abertura com assinatura ad hoc. Depois de criar o ZIP, `scripts/check-macos.py` extrai o pacote, verifica a assinatura e as arquiteturas e inicia o executável por 20 segundos. No GitHub Actions, há também um teste nativo de gravação, leitura, atualização e exclusão no Chaves.

## 5. Gerar o APK para Android atual

Requer Flutter, Java 17 e SDK Android. Execute:

```bash
bash scripts/build.sh android
```

Resultado esperado para seu aparelho Android moderno: **`dist/Investir-Android-arm64.apk`**. O APK 1.1.0 gerado usa API 36, mínimo API 24, NDK r28 e empacotamento nativo moderno. O alinhamento de 16 KB das bibliotecas arm64 e do ZIP foi conferido no pacote distribuído. A compatibilidade precisa ser confirmada instalando o APK no aparelho; essa instalação não foi realizada aqui.

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
3. Informe a URL HTTPS da API, ou deixe vazia para usar o endereço padrão já incluído.
4. Depois de um build aprovado, baixe os artifacts **Investir-android** e **Investir-macos**.

O workflow executa testes do backend com PostgreSQL 16, análise Dart, testes Flutter e compilação em Linux/Android e macOS. As quotas e disponibilidade dos runners dependem da sua conta GitHub.

Para assinatura Android persistente no workflow, configure os secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD`. Sem eles, o resultado é um APK de teste. Não existe configuração de assinatura/notarização Apple no workflow.

## 7. Importar todo mês

1. Abra o app; a consulta não exige conta.
2. O aplicativo já se conecta à API padrão; não há configuração manual de servidor na interface.
3. Toque em **Importar**, entre com a conta autorizada, escolha **Ações** ou **FIIs**, mês e ano.
4. Selecione o XLSX e escolha **Validar e revisar**.
5. Confira as contagens e confirme **Substituir base**.

Se enviar apenas ações, FIIs continuam no mês anterior. Se não enviar nada, ambas permanecem ativas. Cada tela mostra sua própria competência. Uma mensagem avisa quando a planilha é de um mês anterior ao atual. Para corrigir o mesmo mês, importe outro arquivo da mesma competência; um arquivo idêntico não duplica registros.

## 8. Como interpretar a seleção

**Dentro dos filtros**: atende aos filtros quantitativos com os dados disponíveis. **Aceitáveis**: atende aos mínimos, com pelo menos uma regra na faixa tolerada. **A confirmar**: informação necessária ausente, ambígua ou que depende de documento. **Fora dos filtros**: descumpre pelo menos um corte de exclusão ou de filtragem adotado.

Isso é triagem e não uma indicação automática de compra ou cálculo de valor justo. As regras e decisões de implementação estão em `docs/REGRAS.md`.

Na base enviada, há **12 ações selecionadas** (2 preferidas e 10 aceitáveis). Conforme decisão do usuário em 28/10/2026, traço na taxa de performance passa a significar **0%**, com **benchmark 0 (não aplicável)**. Com essa convenção, a base de outubro/2026 tem **13 FIIs selecionados** (7 preferidos e 6 aceitáveis); 28 continuam em **A confirmar** e 314 fora dos filtros. Campos vazios não são convertidos em zero. O ranking de administradores contém os 11 nomes do PDF fornecido; entidades sem correspondência confirmada continuam pendentes.

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

Na versão **1.1.0 (build 2)**, a [execução 6 do GitHub Actions](https://github.com/VitorSetragni/Investir/actions/runs/40701346736), no commit `b0d87a3`, concluiu com sucesso: **48 testes do backend com PostgreSQL 16, 11 testes Flutter em cada plataforma e os builds APK/macOS**. A análise Dart não teve erros nem warnings; apresentou 19 sugestões informativas de estilo. Os testes da nuvem usam dados fictícios e cobrem substituição, idempotência, proteção de upload, conflitos, fronteiras das regras, apresentação de bases antigas, temas, navegação, glossário e atalhos para Status Invest.

Os pacotes baixados dessa execução tiveram sua integridade e versão conferidas. O Mac contém executáveis Intel e Apple Silicon, com mínimo macOS 10.15. O APK arm64 usa Android API 24 ou posterior e bibliotecas alinhadas para páginas de 16 KB. Ambos contêm o endereço da API de produção. A assinatura Android de teste difere da entrega 1.0.0; veja [como substituir a instalação anterior](docs/INSTALACAO.md).

A API publicada foi novamente verificada: saúde, modo de produção, catálogo com 374 ações/355 FIIs de outubro/2026 e detalhe de ativo sem referências às aulas. As classificações continuam preservadas. Na verificação anterior, importações sem login retornaram 401, credenciais inválidas foram rejeitadas e B3SA3/KNCR11 retornaram cotação, histórico e proventos. **Instalação em aparelhos físicos, validação visual nativa, login de uma conta real e importação autenticada continuam pendentes.**

O banco Supabase e a API gratuita do Render estão operacionais. A identidade técnica do backend foi ativada com autorização do usuário, e sua senha exclusiva foi guardada na configuração privada do Render. Nenhuma senha de produção ou chave privilegiada foi incluída no código. Falta criar a conta Auth pessoal para importar planilhas; a consulta pública já funciona sem login. Consulte `docs/RENDER.md` para repetir a verificação.

## Interface 1.1.0

O botão ao lado de Importar alterna entre modo claro e escuro, com preferência salva no aparelho. A tela Regras mostra apenas os títulos dos grupos; cada um abre seus critérios em uma página própria. Aprenda um pouco mais oferece glossário com busca, incluindo os códigos 3, 4 e 11. O detalhe de cada ativo tem um atalho para sua página no Status Invest.

As referências numeradas de material didático foram substituídas por nomes dos grupos de critérios, inclusive na apresentação de avaliações já salvas. A versão 1.1.0 preservou as classificações e os limites de triagem.

## Regras 1.1.1

A versão `2026.10.28.1` aplica a decisão sobre performance zero e atualiza as avaliações dos FIIs existentes em uma transação na inicialização da API. Os dados originais, as competências e as evidências autorizadas são preservados. Ações, os demais critérios e a lista de administradores permanecem iguais. A página Gestão e taxas explica que performance zero não exige benchmark.

Validação local: **85 testes do backend aprovados**, incluindo valores zero e vazios, taxas positivas, preservação das evidências, reclassificação idempotente e os 11 administradores do PDF. A [execução 7 do GitHub Actions](https://github.com/VitorSetragni/Investir/actions/runs/40706586540), no commit `912c057`, também aprovou os **85 testes com PostgreSQL 16, os 11 testes Flutter em cada plataforma e os builds Mac/Android**. A análise Dart manteve as 19 sugestões informativas de estilo, sem erros ou warnings.

A versão foi implantada no Render gratuito e verificada pela API e no banco: **7 FIIs preferidos, 6 aceitáveis, 28 a confirmar e 314 fora**, com as classificações das ações e as duas competências preservadas. O detalhe de KNCR11 mantém o valor original `-` e mostra performance `0%`, benchmark `0` e critério atendido. Os pacotes 1.1.1/build 3 foram conferidos: integridade, versão, API incluída, Mac Intel/Apple Silicon e alinhamento Android de 16 KB. A assinatura de teste do APK mudou em relação à entrega 1.1.0.

## Rodapé 1.1.2

Somente no modo escuro, o rodapé de navegação usa explicitamente o fundo azul-escuro dos painéis, o verde-menta na seleção e a cor secundária do aplicativo nos demais destinos. A paleta e a configuração do modo claro permanecem iguais. As regras, os dados e o servidor não foram alterados nesta versão.

A [execução 9](https://github.com/VitorSetragni/Investir/actions/runs/40713947453), no commit `5bec4a2`, aprovou os 85 testes do backend, os 11 testes Flutter em cada plataforma e os dois builds. O executor Mac passou a ser o padrão `macos-15-intel`, gratuito para repositórios públicos conforme a [referência do GitHub](https://docs.github.com/en/actions/reference/runners/github-hosted-runners). Foram conferidos integridade, versão 1.1.2/build 4, endereço da API, alinhamento Android de 16 KB e arquiteturas Intel/Apple Silicon em todos os oito binários nativos do Mac. O APK usa assinatura de teste diferente da versão 1.1.1; consulte as instruções de instalação.

## Abertura no macOS 1.1.3

A versão 1.1.3/build 5 corrige a configuração que impedia a abertura da entrega com assinatura local: remove Keychain Sharing, inclusive de projetos já gerados, e configura o armazenamento de sessões no Chaves clássico do macOS. Temas, regras e servidor mantêm o comportamento anterior.

A [execução 10](https://github.com/VitorSetragni/Investir/actions/runs/40759961205), no commit `8eafd5e`, passou nos 85 testes do backend e nos 11 testes Flutter por plataforma. O pacote Mac extraído passou na verificação estrita de assinatura, nas duas arquiteturas dos oito binários e no teste de inicialização de 20 segundos. Um teste nativo adicional gravou, leu, atualizou e excluiu um registro no Chaves usando a configuração do aplicativo. Esses testes foram executados no runner Intel; a instalação física em Apple Silicon precisa ser conferida no aparelho. Veja [as instruções de substituição](docs/INSTALACAO.md).
