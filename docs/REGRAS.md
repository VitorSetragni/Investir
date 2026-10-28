# Especificação das regras

Os critérios estão organizados em Sociedade, Lucro e negócio, FIIs de tijolo, FIIs de papel e Gestão e taxas. Os valores e o ranking adotados na triagem permanecem preservados. O glossário do aplicativo explica os termos em Aprenda um pouco mais.

## Estados de cada regra

| Estado | Significado |
|---|---|
| Atende | Valor na faixa preferida ou requisito satisfeito pela base |
| Aceitável | Faixa intermediária explicitamente tolerada ou mínimo de histórico |
| A confirmar | Ausência, ambiguidade ou necessidade de julgamento/documento |
| Não atende | Corte de exclusão ou filtragem não atingido |
| Não se aplica | Critério inaplicável ou não comparável à coluna disponível, com explicação |

Classificação geral: qualquer reprovação coloca o ativo fora dos filtros; sem reprovações, pendência necessária coloca em “A confirmar”; sem pendências necessárias, pelo menos uma regra tolerada coloca em “Aceitáveis”; demais em “Dentro dos filtros”. Pendências gerais não comprováveis pela planilha (como a série anual de lucros) continuam explicitadas nas notas e não recebem falsa confirmação.

## Ações

| Critério | Preferido | Tolerado / intermediário | Fora / revisão |
|---|---|---|---|
| Classe | ON | — | PN/UNIT fora |
| Tag along | 100% | ≥80% e <100% | <80% fora |
| Free float | >35% | 15–35% inclusive | <15% fora |
| Listagem | Novo Mercado | Demais segmentos | Dado vazio deve ser conferido |
| Controlador | Sem governo | — | Estatal direto/indireto fora |
| Anos de lucro | ≥11 consistentes e tendência crescente | 6–10 | <6 fora; a contagem não comprova consistência |
| Tempo de bolsa | ≥10 anos | 5–9 | <5 fora |
| DL/EBITDA | <3x | 3–4x inclusive | >4x fora |
| ROE/ROIC | ≥10% | — | Abaixo da referência fora do filtro; indicador financeiro inaplicável fica a confirmar |
| Patrimônio líquido | ≥R$ 1 bilhão | — | Abaixo fora do filtro |
| Liquidez diária | ≥R$ 10 milhões | — | Abaixo fora do filtro |
| Margens EBIT e líquida | ≥4% | — | Abaixo fora do filtro |
| Setor | Sem exposição identificada a commodities | — | Setores amplos de materiais básicos/petróleo exigem análise do subsetor |

Os limites de eficiência, escala e margem são usados como cortes da seleção quantitativa, sem a afirmação de que descumpri-los prova que a empresa é ruim. “Cerca de 10%” foi operacionalizado como ≥10% para ser reproduzível.

**Histórico não é apenas contagem:** a planilha não contém lucros anuais. O app sinaliza essa limitação e permite uma conferência documental por base. As correções conhecidas da análise de outubro/2026 se aplicam somente àquela competência: CEAB3 e MILS3 têm cinco anos completos positivos após prejuízo em 2020; VULC3 tem dez após prejuízo em 2015; JHSF3 tem oito após prejuízo em 2017. Em competências futuras, a nova planilha deve ser novamente conferida. CPFE3 permanece com ressalva de controle estatal indireto pela State Grid.

Fontes de conferência histórica: [C&A](https://www.dadosdemercado.com.br/acoes/ceab3), [Mills](https://www.dadosdemercado.com.br/acoes/mils3), [Vulcabras](https://www.dadosdemercado.com.br/acoes/vulc3), [JHSF](https://www.dadosdemercado.com.br/acoes/jhsf3). Controle CPFL: [site institucional](https://grupocpfl.com.br/institucional/state-grid). Esses registros não são uma atualização automática dos resultados futuros.

**DY e CAGR não são somados:** as escalas da coluna “Soma Div. + CAGR” da planilha não são confiáveis. O app não usa essa coluna para ordenar ou estimar retorno. DY/CAGR não são critérios de exclusão desta triagem.

## FIIs

| Critério | Preferido | Aceitável | Fora / revisão |
|---|---|---|---|
| Tipo | Tijolo/papel | Híbrido | FOF, desenvolvimento e outros mandatos fora |
| Segmento | Lajes, logística, shopping, TVM | Residencial, varejo e outros | Hospital/hotel fora |
| Vacância | <25% | 25–30% | >30% fora |
| Imóveis | ≥10 | 8–9 | <8 fora pelo pedido do usuário |
| Inquilinos | Multi-inquilino | — | Mono fora; desconhecido a confirmar |
| Tempo de listagem | ≥5 anos | >4 e <5 | ≤4 fora pelo pedido do usuário |
| Papel: CRIs | >75% de alocação, ≥50 CRIs | ≥50% e ≥30 CRIs | Abaixo desses mínimos fora |
| PL | ≥R$ 300 milhões | Abaixo, sem veto automático | — |
| Número de negócios | Referência 7 mil/dia | — | Não verificável pela coluna de volume em R$ |

A vacância financeira é priorizada quando disponível. A planilha não identifica o tipo de vacância, e isso aparece no detalhe. Imóveis, inquilinos e vacância não se aplicam aos FIIs de papel.

### Administradores

- Primeiro grupo: Banco Genial e Intrag.
- Segundo: Banco Fator e BRL Trust **Inv.**
- Terceiro: XP.
- Outros viáveis: Coinvalores, Rio Bravo, BTG Pactual, Votorantim Asset, CM Capital e Safra.

Não equiparar automaticamente BR-Capital, Apex Group, BRL Trust DTVM e BRL Trust Inv. Uma entidade não identificada fica a confirmar, sem concluir que sua gestão é ruim. Escala e histórico qualitativo dos administradores continuam exigindo conferência. O ranking é o do arquivo do usuário e não um ranking de mercado permanentemente atualizado.

### Taxas

| Tipo | Administração | Performance |
|---|---|---|
| Papel | Referência próxima de 1% a.a. | Inexistente |
| Tijolo passivo | Referência próxima de 0,2% a.a. | Inexistente |
| Tijolo ativo | Referência próxima de **2% a.a.** | Até 20% do excedente de IPCA+X, somente com ótimos resultados |

A referência de **2%** para tijolo ativo foi definida pelo usuário. Não foi adotada uma tolerância numérica adicional acima das referências de taxas. Acima da referência fica a confirmar. Taxa zero, traço e fórmula truncada também exigem conferência. “Gestão definida” não é sinônimo automático de passiva; exige verificar o mandato.

Para papel/passivo, performance expressamente presente reprova. Para tijolo ativo, performance >20% reprova; identificação de IPCA e percentual ≤20% ainda depende de verificar fórmula e histórico. Traço não significa “Não há”.

## Evidências

O responsável pode registrar URL HTTPS, data e nota de conferência. O sistema não visita URLs arbitrárias fornecidas pelo usuário. As evidências são atestados do responsável, não uma auditoria automatizada. Aplicam-se à planilha vigente e são apagadas na troca mensal. Não tornam admissível uma performance expressamente proibida ou outro corte reprovado.

## Preço de bolsa

O preço atual, a média de seis meses e o valor justo não são requisitos desta triagem. O aplicativo mostra a cotação e o gráfico separadamente. Estar nos filtros de fundamentos não significa que é hora de comprar. A periodicidade dos pagamentos é estimada, nunca garantida.
