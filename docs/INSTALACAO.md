# Instalar os aplicativos

Versão **1.1.2 (build 4)**. O rodapé do modo escuro usa a paleta azul-escura e verde-menta do aplicativo. O modo claro foi preservado. O botão de aparência alterna o tema e lembra sua escolha.

Os instaladores são gerados pelo GitHub Actions e disponibilizados como arquivos para download. Não há publicação automática em Releases nem permissão de escrita adicional na CI.

- Android atual (Android 7.0/API 24 ou posterior, arm64): instale `Investir-Android-arm64.apk`.
- Mac: extraia `Investir-macOS.zip` e mova `Investir.app` para Aplicativos.
- O servidor padrão é `https://investir-api.onrender.com` e já vem configurado no aplicativo.

O servidor padrão já está operacional e conectado ao Supabase, com 374 ações e 355 FIIs da base de outubro/2026. A consulta pública funciona sem login. Para importar planilhas, crie a conta Auth autorizada conforme [SUPABASE_PRONTO.md](SUPABASE_PRONTO.md).

A versão Mac usa assinatura local, sem notarização Apple, e pode exigir liberação em Privacidade e Segurança na primeira abertura. O APK usa a assinatura de teste do SDK enquanto não for configurada uma chave de distribuição persistente.

O APK 1.1.2 usa uma assinatura de teste diferente da entrega 1.1.1. Para substituir aquela instalação, desinstale-a antes de instalar o novo APK. A sessão e as preferências locais serão apagadas; o catálogo e as planilhas da base central permanecem preservados. Para permitir atualizações futuras sobre a mesma instalação, configure uma chave persistente conforme o README.

As compilações executam testes do backend com PostgreSQL, análise Flutter e testes da interface. A instalação nos aparelhos físicos e o login real precisam ser conferidos separadamente.

A [compilação 1.1.2 aprovada](https://github.com/VitorSetragni/Investir/actions/runs/40713947453) concluiu os 85 testes do backend e os 11 testes Flutter em Android e macOS. Foram conferidos a integridade e a versão dos pacotes, as duas arquiteturas nos oito binários nativos do Mac, o alinhamento de 16 KB no APK e o endereço da API incluído nos dois aplicativos.

A classificação atualizada é calculada no servidor e já funciona ao tocar em Atualizar base nas versões anteriores compatíveis. A versão 1.1.2 mantém a explicação da convenção de performance na página Gestão e taxas e atualiza somente as cores do rodapé no tema escuro. Para receber a mudança visual, instale o novo aplicativo.
