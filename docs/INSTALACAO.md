# Instalar os aplicativos

Versão **1.1.0 (build 2)**. O botão de aparência alterna o tema e lembra sua escolha.

Os instaladores são gerados pelo GitHub Actions e disponibilizados como arquivos para download. Não há publicação automática em Releases nem permissão de escrita adicional na CI.

- Android atual: instale `Investir-Android-arm64.apk`.
- Mac: extraia `Investir-macOS.zip` e mova `Investir.app` para Aplicativos.
- O servidor padrão é `https://investir-api.onrender.com` e já vem configurado no aplicativo.

O servidor padrão já está operacional e conectado ao Supabase, com 374 ações e 355 FIIs da base de outubro/2026. A consulta pública funciona sem login. Para importar planilhas, crie a conta Auth autorizada conforme [SUPABASE_PRONTO.md](SUPABASE_PRONTO.md).

A versão Mac usa assinatura local, sem notarização Apple, e pode exigir liberação em Privacidade e Segurança na primeira abertura. O APK usa a assinatura de teste do SDK enquanto não for configurada uma chave de distribuição persistente.

As compilações executam testes do backend com PostgreSQL, análise Flutter e testes da interface. A instalação nos aparelhos físicos e o login real precisam ser conferidos separadamente.
