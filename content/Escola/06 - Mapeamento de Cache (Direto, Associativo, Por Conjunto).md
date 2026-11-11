---
tags: [organização-de-computadores, memória-cache, mapeamento-de-cache, cache-hit, cache-miss]
fonte: OrgComp03_MemoriaCache.pdf (slides 13-54)
---

# Mapeamento de Cache: Direto, Associativo e Associativo por Conjunto

← [[05 - Memória Cache - Conceitos e Estrutura]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[09 - Processador e Datapath RISC-V (Microprocessador I)]]

## 1. O problema que o mapeamento resolve

Existem muito menos linhas de cache do que blocos de memória principal ($C \ll M$, ver [[05 - Memória Cache - Conceitos e Estrutura]]). Então é preciso um algoritmo que decida em qual linha da cache cada bloco da memória principal pode ficar. Os slides apresentam 3 algoritmos: Mapeamento Direto, Mapeamento Associativo (totalmente associativo) e Mapeamento Associativo por Conjunto, um meio-termo entre os dois anteriores.

## 2. Mapeamento Direto

Técnica mais simples: mapeia cada bloco da memória principal a uma única linha de cache possível.

$$l = b \bmod m$$

onde $l$ é o número da linha da cache, $b$ é o número do bloco na memória principal, e $m$ é o número de linhas da cache.

Na prática, isso equivale a usar os bits menos significativos (LSBs) do endereço para escolher a linha, e guardar os bits restantes, mais significativos, como Tag, junto de um bit de validade.

### Algoritmo (passo a passo, do slide)

1. Usar os bits menos significativos do endereço para determinar a linha da cache.
2. Se o bit de validade dessa linha for 1: quando a Tag armazenada for diferente da Tag do endereço buscado, é cache miss (busca o dado na memória principal e substitui a linha); quando a Tag for igual, é cache hit (lê direto da cache).
3. Se o bit de validade for 0, a linha nunca foi usada, e é cache miss (busca na memória).

### Exemplo resolvido do slide

Cache com 8 linhas: 3 bits menos significativos definem a linha, e os 2 bits restantes são a Tag (endereços de 5 bits).

Sequência de endereços lidos: `10110, 11010, 10110, 11010, 10000, 00011, 10000, 10010, 10000`

| # | Endereço | Linha ($b \bmod 8$) | Tag do endereço | Situação | Resultado |
|---|---|---|---|---|---|
| 1 | 10110 | 110 → 6 | 10 | linha 6 vazia | miss (grava tag 10 na linha 6) |
| 2 | 11010 | 010 → 2 | 11 | linha 2 vazia | miss (grava tag 11 na linha 2) |
| 3 | 10110 | 110 → 6 | 10 | tag 10 == 10 | hit |
| 4 | 11010 | 010 → 2 | 11 | tag 11 == 11 | hit |
| 5 | 10000 | 000 → 0 | 10 | linha 0 vazia | miss (grava tag 10 na linha 0) |
| 6 | 00011 | 011 → 3 | 00 | linha 3 vazia | miss (grava tag 00 na linha 3) |
| 7 | 10000 | 000 → 0 | 10 | tag 10 == 10 | hit |
| 8 | 10010 | 010 → 2 | 10 | tag guardada é 11, diferente de 10 | miss (substitui: grava tag 10 na linha 2) |
| 9 | 10000 | 000 → 0 | 10 | tag 10 == 10 | hit |

> [!warning] Ajuste em relação ao slide original
> No passo 9, o texto extraído do PDF mostra o símbolo "≠" ("Tag 10 ≠ 10 ⇒ Cache hit"), o que é logicamente contraditório: 10 é igual a 10, e o próprio slide rotula o resultado como hit. Tudo indica que é um erro de OCR ou de símbolo no material de origem (o "≠" correto do slide aparece só no passo 8, onde a tag realmente muda de 11 para 10). Apresentei acima a versão logicamente consistente, tag igual implica hit, que é o que o rótulo final do slide confirma. Vale conferir a imagem original se quiser ver o símbolo exato usado pelo professor.

Estado final da cache: linha 0 com tag 10 (bloco 10000); linha 2 com tag 10 (bloco 10010, que substituiu o 11010); linha 3 com tag 00 (bloco 00011); linha 6 com tag 10 (bloco 10110). As linhas 1, 4, 5 e 7 permanecem vazias.

### Exercício (do slide)

Como fica o conteúdo da cache após o acesso aos seguintes endereços: `0000, 0110, 0000, 0110, 1000, 0000`, considerando uma cache de 4 linhas?

> [!example]- Solução sugerida (não estava resolvida no slide, confira antes de valer nota)
> Cache de 4 linhas: 2 bits menos significativos definem a linha, e os 2 bits restantes são a Tag.
>
> | # | Endereço | Linha ($b \bmod 4$) | Tag | Situação | Resultado |
> |---|---|---|---|---|---|
> | 1 | 0000 | 00 → 0 | 00 | vazia | miss (grava tag 00) |
> | 2 | 0110 | 10 → 2 | 01 | vazia | miss (grava tag 01) |
> | 3 | 0000 | 00 → 0 | 00 | tag 00==00 | hit |
> | 4 | 0110 | 10 → 2 | 01 | tag 01==01 | hit |
> | 5 | 1000 | 00 → 0 | 10 | tag guardada 00, diferente de 10 | miss (substitui: grava tag 10) |
> | 6 | 0000 | 00 → 0 | 00 | tag guardada 10, diferente de 00 | miss (substitui: grava tag 00) |
>
> Estado final: linha 0 com tag 00 (bloco 0000); linha 2 com tag 01 (bloco 0110); linhas 1 e 3 vazias. Total de 4 misses e 2 hits. Note como o mapeamento direto faz 0000 e 1000 brigarem, porque os dois caem na mesma linha (0).

## 3. Mapeamento Associativo (totalmente associativo)

O principal problema do mapeamento direto é que seu posicionamento não é flexível: cada bloco só pode ir para uma linha fixa. O mapeamento associativo resolve isso interpretando o endereço inteiro da memória principal como Tag. A lógica de controle precisa verificar toda a cache para saber se o bloco já está lá, já que qualquer bloco pode ir para qualquer linha. Por isso, precisa de uma política de substituição (ver seção 5) para decidir qual linha liberar quando a cache está cheia.

### Exemplo resolvido do slide

Mesma sequência de endereços, cache com 4 linhas, totalmente associativa:

`10110, 11010, 10110, 11010, 10000, 00011, 10000, 10010, 10000`

| # | Endereço | Situação | Resultado |
|---|---|---|---|
| 1 | 10110 | cache vazia | miss → linha 1 = 10110 |
| 2 | 11010 | não encontrado | miss → linha 2 = 11010 |
| 3 | 10110 | encontrado na linha 1 | hit |
| 4 | 11010 | encontrado na linha 2 | hit |
| 5 | 10000 | não encontrado | miss → linha 3 = 10000 |
| 6 | 00011 | não encontrado | miss → linha 4 = 00011 |
| 7 | 10000 | encontrado na linha 3 | hit |
| 8 | 10010 | não encontrado, cache cheia (linhas 1-4 ocupadas) | miss → política aleatória escolhe substituir a linha 1 (10110 vira 10010) |
| 9 | 10000 | encontrado na linha 3 | hit |

Estado final: linha 1 com 10010; linha 2 com 11010; linha 3 com 10000; linha 4 com 00011.

## 4. Comparação: Mapeamento Direto x Associativo

O Mapeamento Associativo é mais eficiente na hora de alocar os blocos na memória cache, já que nunca briga por uma linha fixa como no direto. A desvantagem aparece na hora de buscar um bloco na cache: é preciso comparar contra todas as linhas, o que só compensa quando a cache não é muito grande, pois buscar em uma cache grande, linha por linha, fica caro.

## 5. Políticas de substituição

Quando a cache está cheia e chega um novo bloco (miss), alguma linha precisa ser liberada. Políticas citadas no slide:

- **Randômica**: escolhe uma linha aleatoriamente. Simples, mas aumenta a quantidade de misses.
- **Contador (baseado em relógio)**: um contador aponta ciclicamente a próxima posição a ser substituída, com comportamento parecido com o randômico.
- **LFU (Least Frequently Used)**: substitui a posição menos usada. Precisa de um contador de acessos por linha.
- **LRU (Least Recently Used)**: substitui a posição ocupada há mais tempo sem ser usada. Precisa de uma variável de tempo, ou um "carimbo", por linha, comparada a cada acesso.
- **FIFO (First In First Out)**: substitui a posição que está na cache há mais tempo, independente de uso recente. A primeira que entrou é a primeira que sai.

> [!tip] LRU x FIFO: não confundir
> LRU olha para quando a linha foi usada pela última vez. FIFO olha só para quando ela entrou na cache, ignorando se foi usada de novo depois. Uma linha pode ter entrado há muito tempo mas ser usada toda hora: LRU não a substituiria, FIFO substituiria.

> [!warning] Atenção à frase do slide sobre LRU
> O slide 42 define LRU como "a posição ocupada por mais tempo é a substituída". Lida ao pé da letra, essa frase descreve o FIFO (a linha que está há mais tempo na cache). Na literatura, LRU substitui a linha **há mais tempo sem ser acessada**, que é a definição usada acima e a que o próprio slide sugere quando diz que o LRU precisa de "variável de tempo para cada acesso". Se a prova cobrar a definição, vale confirmar com o professor qual redação ele espera.

### 5.1 Complemento de pesquisa: LRU nem sempre é a escolha óbvia

O slide apresenta LRU como uma política mais "inteligente" que FIFO, e isso costuma ser verdade em caches pequenas e workloads tradicionais. Vale registrar, porém, um contraponto que fugiria do escopo da disciplina, mas é interessante: uma pesquisa da IBM Research sobre caches de armazenamento em nuvem, em larga escala, encontrou que o FIFO teve custo geral melhor que o LRU nesses cenários modernos. Dois motivos aparecem: em caches gigantes, manter os metadados de acesso que o LRU exige (para saber qual linha foi usada por último) fica caro em memória, e os padrões de acesso de cargas de trabalho de nuvem atuais são diferentes dos que motivaram o LRU décadas atrás. A lição para a disciplina não muda (LRU continua sendo a resposta esperada em exercícios como os desta nota), mas é um bom lembrete de que "a política mais sofisticada nem sempre vence" quando a escala e o padrão de acesso mudam.

Sources:
- [It's Time to Revisit LRU vs. FIFO - IBM Research](https://research.ibm.com/publications/its-time-to-revisit-lru-vs-fifo)

## 6. Mapeamento Associativo por Conjunto

Um meio-termo entre o mapeamento direto e o associativo: os blocos da memória principal são divididos em conjuntos (o número dos primeiros $v$ blocos da memória principal é igual ao número de conjuntos, e o padrão se repete ciclicamente, de forma parecida ao mapeamento direto, mas em nível de conjunto em vez de linha única).

O slide mostra duas formas equivalentes de visualizar a mesma estrutura:

1. **Como $v$ pequenas caches totalmente associativas**: cada conjunto (0 até $v-1$) tem $k$ linhas internas, e dentro de um conjunto o bloco pode ir para qualquer uma das $k$ linhas, em busca associativa dentro do conjunto.
2. **Como $k$ caches mapeadas diretamente, em paralelo**: existem $k$ "vias" (memória cache via 1 até via $k$), e o mesmo índice de conjunto é comparado simultaneamente em todas as $k$ vias.

Essas duas visões descrevem a mesma cache "k-vias associativa por conjunto", só mudando a forma de explicar o hardware.

### Configurações possíveis (do "1 via" ao "totalmente associativo")

O slide mostra a família completa de configurações, todas para uma cache de 8 linhas totais:

| Configuração | Nº de conjuntos | Vias por conjunto |
|---|---|---|
| One-way set associative (= mapeamento direto) | 8 conjuntos | 1 via cada |
| Two-way set associative | 4 conjuntos | 2 vias cada |
| Four-way set associative | 2 conjuntos | 4 vias cada |
| Eight-way set associative (= totalmente associativo) | 1 conjunto | 8 vias |

> [!tip] Como enxergar o espectro
> Mapeamento Direto é associativo por conjunto de 1 via. Mapeamento Totalmente Associativo é associativo por conjunto onde o número de vias é igual ao número total de linhas, um único conjunto "gigante". É a mesma família de técnica, variando só o quão "livre" o bloco é para escolher sua linha dentro do conjunto.

### Exemplo comparativo entre as três técnicas (do slide)

Considere três caches pequenas, cada uma com 4 blocos de uma palavra: uma totalmente associativa, uma associativa por conjunto de 2 vias, e uma mapeada diretamente. Sequência de endereços de bloco: `0, 8, 0, 6, 8`.

**Caso mapeado diretamente** (linha = bloco mod 4):

| Acesso | Hit/Miss | Linha 0 | Linha 1 | Linha 2 | Linha 3 |
|---|---|---|---|---|---|
| 0 | miss | Memory[0] | | | |
| 8 | miss | Memory[8] | | | |
| 0 | miss | Memory[0] | | | |
| 6 | miss | Memory[0] | | Memory[6] | |
| 8 | miss | Memory[8] | | Memory[6] | |

Total de 5 misses e 0 hits. O bloco 0 e o bloco 8 caem sempre na mesma linha (0 mod 4 = 8 mod 4 = 0), então ficam se expulsando o tempo todo.

**Caso associativo por conjunto de 2 vias** (2 conjuntos, conjunto = bloco mod 2; note que 0, 8 e 6 são todos pares, então todos caem no Conjunto 0, e o Conjunto 1 nunca é usado nesta sequência):

| Acesso | Hit/Miss | Set 0 (via A) | Set 0 (via B) |
|---|---|---|---|
| 0 | miss | Memory[0] | |
| 8 | miss | Memory[0] | Memory[8] |
| 0 | hit | Memory[0] | Memory[8] |
| 6 | miss | Memory[0] | Memory[6] |
| 8 | miss | Memory[8] | Memory[6] |

Total de 4 misses e 1 hit, melhor que o direto, porque agora o conjunto tem 2 vias e pode guardar tanto o bloco 0 quanto o 8 ao mesmo tempo, até precisar substituir de novo no acesso ao bloco 6.

**Caso totalmente associativo** (4 linhas livres):

| Acesso | Hit/Miss | Bloco 0 | Bloco 1 | Bloco 2 | Bloco 3 |
|---|---|---|---|---|---|
| 0 | miss | Memory[0] | | | |
| 8 | miss | Memory[0] | Memory[8] | | |
| 0 | hit | Memory[0] | Memory[8] | | |
| 6 | miss | Memory[0] | Memory[8] | Memory[6] | |
| 8 | hit | Memory[0] | Memory[8] | Memory[6] | |

Total de 3 misses e 2 hits, o melhor resultado dos três, já que qualquer bloco pode ir para qualquer linha. Aqui nem precisou substituir nada, pois a cache tem 4 linhas para só 3 blocos distintos usados: 0, 8 e 6.

> [!tip] Lição desse exemplo
> Quanto mais "associativa" a cache, com mais vias por conjunto, menos ela sofre de misses de conflito, que são dois endereços diferentes competindo pela mesma linha. Em troca, precisa de mais comparadores de hardware e lógica de busca mais cara. É exatamente o trade-off da seção 4.

### Configurações da cache: diagrama de referência

O slide traz um diagrama-resumo mostrando visualmente as 4 configurações lado a lado: One-way (8 linhas, cada uma com 1 par Tag/Data), Two-way (4 conjuntos, cada um com 2 pares Tag/Data), Four-way (2 conjuntos, cada um com 4 pares Tag/Data) e Eight-way, totalmente associativo (1 conjunto só, com 8 pares Tag/Data em sequência).

### Exemplo de circuito: Cache associativa de 4 vias

O slide mostra o diagrama de hardware de uma cache real de 4 vias: o endereço (bits 31 a 0) é dividido em Tag (22 bits), Index (8 bits) e offset de bloco (2 bits). O Index seleciona uma linha (0 a 255) em cada uma das 4 vias simultaneamente, cada via compara sua Tag armazenada com a Tag do endereço usando comparadores, os resultados combinados geram o sinal de Hit, e um multiplexador 4-para-1 seleciona qual das 4 vias entrega o Data de saída, a via que deu hit.

### 6.1 Complemento de pesquisa: divisão do endereço e resumo de trade-offs

O slide não nomeia explicitamente os "campos" em que o endereço é dividido em cada técnica de mapeamento. Isso é uma forma padrão, fora do slide, de resumir a mesma ideia usada nas seções 2, 3 e 6:

| Técnica | Campos do endereço | Ponto forte | Ponto fraco |
|---|---|---|---|
| Direto | Tag, Linha, Palavra | Simples, rápido, barato, com poucos comparadores | Muitos misses de conflito, dois blocos que caem na mesma linha brigam entre si |
| Associativo | Tag, Palavra (sem campo de linha, qualquer linha serve) | Resolve os misses de conflito, mais flexível | Hardware caro, precisa comparar contra todas as linhas ao mesmo tempo |
| Associativo por Conjunto | Tag, Conjunto, Palavra | Bom equilíbrio, com menos conflito que o direto e mais barato que o associativo | Ainda mais caro que o mapeamento direto puro, e o custo cresce com o número de vias |

É o mesmo trade-off que a seção 4 já descrevia qualitativamente, de que o associativo aloca melhor mas busca pior, só que formalizado em termos dos campos do endereço.

Sources:
- [Difference between Direct-mapping, Associative Mapping & Set-Associative Mapping - GeeksforGeeks](https://www.geeksforgeeks.org/difference-between-direct-mapping-associative-mapping-set-associative-mapping/)

## 7. Cache Multinível

Usar mais de um nível de cache (L1, L2, L3...) permite aumentar o número de cache hits sem precisar acessar a memória principal: se um dado não está na L1, ainda pode estar na L2, mais lenta que L1, mas bem mais rápida que a memória principal. A desvantagem é o tempo de acesso à segunda cache quando a primeira falha, já que um miss em L1 que vira hit em L2 ainda é mais lento que um hit direto em L1.

### Exemplo real: Intel Pentium 4

O diagrama do slide mostra a organização de cache do Pentium 4: Cache de instrução L1 (12K µops) já decodificada, um "trace cache", Cache de dados L1 (16 kB), depois Cache L2 (512 kB) e Cache L3 (1 MB) compartilhada, conectada ao barramento do sistema (64 bits). Internamente, o processador tem bancos de registradores de inteiros e de ponto flutuante, unidades de ALU (simples e complexas), unidades de load/store, e lógica de execução fora de ordem, tudo isso alimentado pela hierarquia de caches.

## 8. Cálculo de tamanho de cache: exemplo resolvido do slide

> Considerando um espaço de endereçamento de 256 Mega palavras, como fica a divisão de bits de endereço para uma cache de 2048 posições, trabalhando com 8 blocos? Qual o tamanho da memória associativa (de Tags)?

Passo 1, bits de endereço totais:
$$256 \times 2^{20} \Rightarrow \log_2(256 \times 2^{20}) = 28\ \text{bits de endereço}$$

Passo 2, bits para selecionar o bloco (offset dentro do bloco):
$$8\ \text{blocos} \Rightarrow \log_2(8) = 3\ \text{bits}$$

Logo, dos 28 bits de endereço totais, 25 bits são de Tag e 3 bits são de seleção de Bloco.

Passo 3, tamanho da memória associativa (só as Tags, uma por linha):
$$2048 \times 25\ \text{bits} = 51.200\ \text{bits} = 6.400\ \text{bytes} = 6{,}25\ \text{KB}$$

> [!warning] Possível divergência numérica no slide
> O slide escreve o resultado intermediário como "$2048 \cdot 25 = 512000$ bits". Multiplicando diretamente, $2048 \times 25 = 51.200$, não $512.000$: parece haver um zero a mais digitado no slide. O valor final em bytes que o slide apresenta ($6.400$ bytes, ou $6{,}25$ KB) é consistente com $51.200$ bits ($51.200 / 8 = 6.400$), e não seria consistente com $512.000$ bits, que daria $64.000$ bytes, ou 62,5 KB. Ou seja, o resultado final do slide parece correto, e o número "512000" no meio do cálculo é que aparenta ser um erro de digitação. Não tenho como confirmar a intenção exata do professor. Se cair em prova, vale confirmar com ele qual dos dois números é o "oficial".

## 9. Exercício de fixação (do slide, para praticar)

Assuma três caches pequenas, cada uma com 8 blocos de uma palavra, nas organizações: totalmente associativa, associativa por conjunto de 4 vias, e mapeada diretamente. Encontre o número de misses para cada organização, dada a sequência de endereços de palavras:

$$\{0, 1, 2, 3, 8, 9, 0, 1, 16, 17, 24, 25, 2, 3, 8, 9, 32, 0, 1\}$$

Assuma a política de substituição LRU.

> [!example]- Solução sugerida (não estava resolvida no slide; conferi as contagens com uma simulação, mas confira antes de usar para valer nota)
> Com blocos de 1 palavra, o endereço da palavra é o próprio número do bloco. São 19 acessos a 11 blocos diferentes: 0, 1, 2, 3, 8, 9, 16, 17, 24, 25 e 32.
>
> **Mapeamento direto** (8 linhas, linha = endereço mod 8)
> Os blocos 0, 8, 16, 24 e 32 caem todos na linha 0; 1, 9, 17 e 25 na linha 1; 2 na linha 2; 3 na linha 3. As linhas 0 e 1 ficam trocando de bloco o tempo todo. Só os segundos acessos a 2 e a 3 dão hit.
> Resultado: **17 misses e 2 hits**.
>
> **Associativo por conjunto de 4 vias** (8 linhas / 4 vias = 2 conjuntos, conjunto = endereço mod 2, LRU)
> Pares vão para o conjunto 0 e ímpares para o conjunto 1. O conjunto 0 recebe 0, 2, 8, 0, 16, 24, 2, 8, 32, 0:
>
> | Acesso | Resultado | Conjunto 0 depois (do menos para o mais recente) |
> |---|---|---|
> | 0 | miss | 0 |
> | 2 | miss | 0, 2 |
> | 8 | miss | 0, 2, 8 |
> | 0 | hit | 2, 8, 0 |
> | 16 | miss | 2, 8, 0, 16 |
> | 24 | miss, sai o 2 | 8, 0, 16, 24 |
> | 2 | miss, sai o 8 | 0, 16, 24, 2 |
> | 8 | miss, sai o 0 | 16, 24, 2, 8 |
> | 32 | miss, sai o 16 | 24, 2, 8, 32 |
> | 0 | miss, sai o 24 | 2, 8, 32, 0 |
>
> O conjunto 1 recebe 1, 3, 9, 1, 17, 25, 3, 9, 1 e se comporta do mesmo jeito, com 1 hit (o segundo acesso ao 1).
> Resultado: **17 misses e 2 hits**.
>
> **Totalmente associativo** (8 linhas, LRU)
> Os 6 primeiros acessos (0, 1, 2, 3, 8, 9) são misses; 0 e 1 dão hit; 16 e 17 são misses e enchem a cache. A partir daí, cada bloco novo expulsa justamente o que vai ser pedido logo depois: 24 tira o 2, 25 tira o 3, 2 tira o 8, 3 tira o 9, 8 tira o 0, 9 tira o 1, 32 tira o 16, 0 tira o 17 e 1 tira o 24.
> Resultado: **17 misses e 2 hits**.
>
> **Conclusão**: as três organizações dão o mesmo número de misses. São 11 blocos diferentes para 8 linhas, e a sequência volta a blocos antigos logo depois de o LRU tê-los expulsado. Nesse padrão, mais associatividade não ajuda. É um contraexemplo útil para a lição da seção 6: mais vias reduzem misses de conflito, mas não resolvem falta de capacidade.

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 3. Pearson, 2017.
- David Patterson e John Hennessy. *Computer Organization and Design, RISC-V Edition*. Morgan Kaufmann, 2018.
- Sarah Harris e David Harris. *Digital design e computer architecture*. Morgan Kaufmann, 2015.
