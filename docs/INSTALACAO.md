# Instalar os aplicativos

Mac: **1.1.3 (build 5)**. Último APK entregue: **1.1.2 (build 4)**. O rodapé do modo escuro usa a paleta azul-escura e verde-menta do aplicativo. O modo claro foi preservado. O botão de aparência alterna o tema e lembra sua escolha.

Os instaladores são gerados pelo GitHub Actions e disponibilizados como arquivos para download. Não há publicação automática em Releases nem permissão de escrita adicional na CI.

- Android atual (Android 7.0/API 24 ou posterior, arm64): instale `Investir-Android-arm64.apk`.
- Mac: extraia `Investir-macOS.zip` e mova `Investir.app` para Aplicativos.
- O servidor padrão é `https://investir-api.onrender.com` e já vem configurado no aplicativo.

O servidor padrão já está operacional e conectado ao Supabase, com 374 ações e 355 FIIs da base de outubro/2026. A consulta pública funciona sem login. Para importar planilhas, crie a conta Auth autorizada conforme [SUPABASE_PRONTO.md](SUPABASE_PRONTO.md).

A versão Mac usa assinatura local, sem notarização Apple, e pode exigir liberação em Privacidade e Segurança na primeira abertura. O APK usa a assinatura de teste do SDK enquanto não for configurada uma chave de distribuição persistente.

Para substituir a versão Mac que não abria, encerre o Investir, extraia o novo ZIP e mova o novo `Investir.app` para Aplicativos, substituindo a cópia anterior. Tente abrir. Se o macOS mostrar um aviso de desenvolvedor não identificado, acesse Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim. Não é necessário desativar a proteção global do Mac.

O APK 1.1.2 usa uma assinatura de teste diferente da entrega 1.1.1. Para substituir aquela instalação, desinstale-a antes de instalar o novo APK. A sessão e as preferências locais serão apagadas; o catálogo e as planilhas da base central permanecem preservados. Para permitir atualizações futuras sobre a mesma instalação, configure uma chave persistente conforme o README.

As compilações executam testes do backend com PostgreSQL, análise Flutter e testes da interface. A instalação nos aparelhos físicos e o login real precisam ser conferidos separadamente.

A [compilação 1.1.2 aprovada](https://github.com/VitorSetragni/Investir/actions/runs/40713947453) concluiu os 85 testes do backend e os 11 testes Flutter em Android e macOS. Foram conferidos a integridade e a versão dos pacotes, as duas arquiteturas nos oito binários nativos do Mac, o alinhamento de 16 KB no APK e o endereço da API incluído nos dois aplicativos.

A classificação atualizada é calculada no servidor e já funciona ao tocar em Atualizar base nas versões anteriores compatíveis. A versão 1.1.2 mantém a explicação da convenção de performance na página Gestão e taxas e atualiza somente as cores do rodapé no tema escuro. Para receber a mudança visual, instale o novo aplicativo.

A correção Mac 1.1.3 remove `keychain-access-groups` dos projetos nativos, inclusive daqueles gerados anteriormente. Esse entitlement restrito exige um perfil de provisionamento e não é compatível com a assinatura ad hoc usada na entrega. O app continua guardando sessões no Chaves do macOS, configurado sem o Data Protection Keychain e sem compartilhamento entre aplicativos. A [documentação da Apple](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles) explica a exigência de provisionamento para Keychain Sharing.

A [execução 10](https://github.com/VitorSetragni/Investir/actions/runs/40759961205), no commit `8eafd5e`, aprovou os 85 testes do backend, os 11 testes Flutter em cada plataforma e um teste nativo de gravação, leitura, atualização e exclusão no Chaves. O ZIP foi extraído no runner Mac Intel: a assinatura foi verificada com `codesign --verify --deep --strict`, todos os oito binários contêm Intel e Apple Silicon, e o executável permaneceu ativo durante o teste de 20 segundos. Também foram conferidos a versão 1.1.3/build 5, a integridade do ZIP, a ausência da permissão restrita nas duas arquiteturas e o endereço da API. A instalação física em um Mac M3 com macOS 26 ainda depende de validação no aparelho.
