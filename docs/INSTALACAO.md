# Instalar os aplicativos

Os instaladores são gerados pelo GitHub Actions e disponibilizados como arquivos para download. Não há publicação automática em Releases nem permissão de escrita adicional na CI.

- Android atual: instale `Investir-Android-arm64.apk`.
- Mac: extraia `Investir-macOS.zip` e mova `Investir.app` para Aplicativos.
- O servidor padrão é `https://investir-api.onrender.com` e pode ser alterado em **Servidor**.

A implantação do servidor ainda precisa receber a conexão privada do banco para ficar operacional. O download dos instaladores não comprova que o backend já esteja disponível.

A versão Mac usa assinatura local, sem notarização Apple, e pode exigir liberação em Privacidade e Segurança na primeira abertura. O APK usa a assinatura de teste do SDK enquanto não for configurada uma chave de distribuição persistente.

As compilações executam testes do backend com PostgreSQL, análise Flutter e testes da interface. A instalação nos aparelhos físicos e o login real precisam ser conferidos separadamente.
