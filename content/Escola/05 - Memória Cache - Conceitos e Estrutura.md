
# Memória Cache: Conceitos e Estrutura

← [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]

> [!info] Revisão de "aulas passadas"
> Os slides 3-5 deste deck repetem a tabela de características de memória e a pirâmide de hierarquia já cobertas em [[03 - Hierarquia e Tipos de Memória]]. Não vou repetir aqui, vá até lá se precisar revisar.

## 1. O que é memória cache

São memórias de alta velocidade. O objetivo é diminuir o acesso à memória principal, aproveitando o princípio da localidade: dados e instruções acessados recentemente, ou próximos aos acessados recentemente, tendem a ser acessados de novo em breve. O uso de cache começou com processadores, mas hoje vários dispositivos e sistemas a utilizam, não só a CPU.

### 1.1 Localidade temporal e espacial (tópico da prova)

O slide 6 só cita o princípio da localidade, sem definir os dois tipos. As definições abaixo são as usuais de arquitetura de computadores (conhecimento geral, não citação do slide):

- **Localidade temporal**: se um endereço foi acessado agora, é provável que seja acessado de novo em breve. Exemplo: a variável contadora e as instruções de um laço `for`, usadas a cada volta.
- **Localidade espacial**: se um endereço foi acessado, é provável que os endereços vizinhos sejam acessados em breve. Exemplo: percorrer um vetor `v[0], v[1], v[2]...`, ou executar instruções em sequência.

Como a cache aproveita cada uma:

- **Temporal**: mantém na cache o que acabou de ser usado, para o próximo acesso ser hit.
- **Espacial**: num miss, traz o **bloco inteiro** da memória principal (K palavras, seção 3), não só a palavra pedida. As vizinhas já chegam junto.

> [!example] Exemplo rápido (meu, não está no slide)
> Num laço que soma `v[0]` até `v[99]`, com blocos de 4 palavras: o acesso a `v[0]` é miss e traz `v[0]` a `v[3]`, então `v[1]`, `v[2]` e `v[3]` dão hit (espacial). Isso dá 25 misses e 75 hits nos dados, sem contar conflitos. As instruções do laço e a variável `soma` ficam na cache e dão hit a cada volta (temporal).

## 2. Definições de desempenho de memória (contexto de cache)

- **Tempo de acesso (latência)**: tempo desde que um endereço é apresentado à memória até o dado estar disponível para uso.
- **Tempo de ciclo de memória**: tempo de acesso mais qualquer tempo adicional necessário antes que um segundo acesso possa começar.
- **Taxa de transferência**: taxa em que os dados podem entrar ou sair de uma unidade de memória.

## 3. Estrutura da cache e da memória principal

A memória principal tem $2^N$ palavras no total, endereçadas com n bits, e é mapeada em M blocos de K palavras cada (bloco 0 até bloco M-1).

A memória cache é organizada em linhas, cada uma contendo K palavras, o mesmo tamanho de um bloco da memória principal. Cada linha guarda também uma Tag, que identifica qual bloco da memória principal está armazenado ali.

Diagrama do slide: de um lado, a tabela da cache com colunas Número da linha, Tag e Bloco, indo de 0 até $C-1$ linhas, com "largura do bloco = K palavras". Do outro lado, a memória principal, com endereços de 0 até $2^n - 1$, dividida em Bloco 0, Bloco 1, ..., Bloco $M-1$, cada bloco com "largura de K palavras".

> [!tip] A ideia central do mapeamento
> Como $M$ (blocos na memória principal) é sempre muito maior que $C$ (linhas disponíveis na cache), várias posições da memória principal precisam disputar as mesmas linhas de cache. A Tag é o que permite à cache saber, a qualquer momento, qual bloco específico está guardado em cada linha. Esse é exatamente o "problema" que motiva as técnicas de mapeamento (ver [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]).

## 4. Como a cache funciona (fluxograma)

```
                         INÍCIO
                           │
              Recebe endereço RA da CPU
                           │
              O bloco que contém RA
                está na cache?
             ┌─────Sim───────────Não─────┐
             │                            │
    Busca a palavra RA           Acessa a memória principal
    e envia à CPU                para o bloco que contém RA
             │                            │
             │                  Aloca linha da cache para
             │                  o bloco da memória principal
             │                            │
             │                  Carrega o bloco da memória
             │                  principal na linha de cache
             │                            │
             │                  Envia a palavra RA à CPU
             │                            │
             └──────────────┬─────────────┘
                           FIM
```

Este fluxo já introduz os termos que você vai usar o tempo todo em [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]: cache hit é quando o bloco já está na cache (caminho da esquerda), e cache miss é quando o bloco não está (caminho da direita, mais lento, porque envolve acessar a memória principal).

## 5. Organização da cache no sistema

Diagrama do slide: o Processador troca sinais de Controle e Dados diretamente com a Cache. A Cache, por sua vez, se conecta ao Barramento do sistema através de um buffer de endereço e um buffer de dados, além de sinais de Controle para o barramento. A cache fica fisicamente no meio do caminho entre o processador e o barramento que leva à memória principal.

## 6. Cache Lógica vs. Cache Física

A cache pode ficar fisicamente em duas posições diferentes no caminho processador → memória: entre o processador e a MMU (Unidade de Gerenciamento de Memória), ou entre a MMU e a memória principal. Isso dá origem a dois tipos de cache:

- **Cache Lógica (ou virtual)**: fica entre o processador e a MMU. Armazena endereços virtuais, e o processador acessa a cache diretamente, sem esperar a tradução da MMU. Vantagem: velocidade de acesso maior, já que não espera a tradução de endereço virtual para físico. Desvantagem: problemas de troca de contexto, já que cada processo tem seu próprio espaço de endereços virtuais, e endereços virtuais iguais de processos diferentes podem apontar para dados diferentes, exigindo cuidado extra (invalidar ou marcar a cache) a cada troca de contexto.
- **Cache Física**: fica entre a MMU e a memória principal. Armazena os dados usando endereços físicos da memória principal, já que a tradução de endereço acontece antes de chegar à cache.

Diagrama comparativo: na cache lógica, o Processador se liga à MMU por um endereço lógico, e a MMU se liga à Memória Principal por um endereço físico, com a Cache posicionada dentro do processador, antes da MMU. Na cache física, o mesmo caminho processador → MMU → memória existe, mas a Cache fica depois da MMU, já trabalhando com o endereço físico.

### 6.1 Complemento de pesquisa: o que a MMU faz, de forma mais ampla

O slide usa a MMU só como referência de posição da cache, sem explicar o que ela faz. Em termos gerais: a MMU é a peça de hardware que converte os endereços virtuais gerados pelos programas em execução em endereços físicos reais da RAM. Essa tradução automática permite que cada programa rode como se tivesse a memória inteira só para si, sem precisar saber onde os dados realmente estão fisicamente, e é também o que permite isolar a memória de processos diferentes (um não consegue acessar a memória do outro por acidente). Além da tradução em si, a MMU também cuida de proteção de memória e viabiliza a memória virtual, que deixa programas usarem mais memória do que existe fisicamente na RAM.

Sources:
- [What is Memory Management Unit (MMU)? - GeeksforGeeks](https://www.geeksforgeeks.org/computer-organization-architecture/what-is-memory-management-unit/)

## 7. Exemplo real: Intel Haswell (4ª geração)

O slide mostra o *floorplan* (leiaute físico do chip) de um processador Intel Haswell: múltiplos núcleos (Core) organizados em duas colunas, uma L3 Cache compartilhada entre todos os núcleos no centro, um bloco de Queue, Uncore, I/O no topo, e um Memory Controller integrado na base do chip. Isso ilustra na prática o conceito de cache multinível com um nível compartilhado entre núcleos (ver também a seção de Cache Multinível em [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]).

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 3. Pearson, 2017.
- David Patterson e John Hennessy. *Computer Organization and Design, RISC-V Edition*. Morgan Kaufmann, 2018.
- Sarah Harris e David Harris. *Digital design e computer architecture*. Morgan Kaufmann, 2015.
