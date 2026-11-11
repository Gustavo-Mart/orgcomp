---
tags: [organização-de-computadores, introdução, história-da-computação, desempenho, risc-v]
fonte: OrgComp01_Introducao.pdf (slides 1-18)
---

# Introdução ao Curso e Contexto Histórico

← [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[01 - Arquitetura von Neumann e Estrutura do Computador]]

Esta nota cobre o deck de introdução, a "aula anterior" que os outros decks retomam quando dizem que "vimos o contexto histórico que culminou no surgimento do computador". A linha do tempo histórica está na seção 7.

## 1. Ementa e conteúdo programático (slide 2)

**Ementa**: estudo de conceitos básicos de organização de computadores e dos componentes que formam a organização computacional, desde a estrutura e organização de processadores até barramentos e tipos de memória.

Conteúdo programático:

1. História do computador e estrutura básica dos computadores e periféricos, como AD/DA.
2. Arquitetura de von Neumann.
3. Unidade Central de Processamento: execução das instruções; rotas de dados.
4. Unidades de controle; conceitos básicos de microprogramação.
5. Operações de hardware do computador: memória, hierarquia de memória, posição de memória, modo de acesso, volatilidade, estrutura básica da memória.
6. Microcontroladores e minicomputadores (SoC).

> [!note] O que não tem deck no vault
> AD/DA (conversores analógico-digital e digital-analógico), microprogramação em detalhe e microcontroladores/SoC aparecem na ementa, mas nenhum dos decks que tenho trata desses assuntos. A prova do quadro também não lista esses itens.

## 2. Avaliação (slide 3)

| Atividade | Peso | Detalhe |
|---|---|---|
| Projeto da disciplina | 50% | Em grupo: projetar um computador com a arquitetura **SAP (Simple as Possible)**. Cada grupo recebe uma ISA diferente para desenvolver o sistema de controle |
| Prova | 50% | |
| PCG | Pontos extras no projeto | Em conjunto com a disciplina de Inteligência Artificial |

O que o professor espera que vocês entendam para serem aprovados:

1. O surgimento e o funcionamento de um computador.
2. A arquitetura von Neumann e as partes de um computador.
3. O funcionamento da memória e seus tipos de acesso.

## 3. Bibliografia (slide 4)

- HENNESSY, John L.; PATTERSON, David A. *Arquitetura de computadores: uma abordagem quantitativa*. 3. ed. Rio de Janeiro: Campus, 2003.
- PATTERSON, David A.; HENNESSY, John L. *Computer organization and design: the hardware/software interface*. 3. ed. Boston: Morgan Kaufmann, 2005.
- TANENBAUM, Andrew S. *Organização estruturada de computadores*. 4. ed. Rio de Janeiro: LTC, 2001.
- HARRIS, Sarah; HARRIS, David. *Digital Design and Computer Architecture, RISC-V Edition*. Morgan Kaufmann, 2021.
- *Guia Prático RISC-V: Atlas de uma Arquitetura Aberta*, versão em português: [riscvbook.com/portuguese](http://riscvbook.com/portuguese/)

O slide também traz os números de chamada da biblioteca (ex.: 681.3:004.2 H515a 2003); não copiei aqui, confira no PDF se for procurar na biblioteca.

## 4. Roadmap (slide 5)

O diagrama mostra onde a disciplina fica na sequência do curso:

```
Lógica Matemática (A + AB = A)      Fundamentos de Eletricidade e Eletrônica
          └──────────────┬──────────────┘
                 Circuitos Digitais (HDL: Verilog, VHDL)
                         │
      Organização de Computadores ──► Arquitetura de Computadores ──► Programação de
      (CPU, memória, E/S; Assembly, C, C++)  (RISC x CISC)               Sistemas Embarcados
```

Ao lado, uma seta vermelha marcada "Abstração" desce de cima para baixo. As faixas do lado esquerdo indicam a linguagem de cada nível: Aritmética, HDL (Verilog, VHDL) e Assembly, C, C++.

## 5. Por que estudar organização de computadores (slides 6-9)

Perguntas que a disciplina vai responder (slide 6):

1. Como analisar o desempenho de um programa?
2. O mesmo programa tem o mesmo desempenho em computadores diferentes?
3. Implementações diferentes, com a mesma complexidade, têm a mesma performance?
4. Como lidamos com as novas tecnologias?

**Slide 7, mesma busca binária, outra organização na memória**: o gráfico compara quatro versões da mesma busca binária (padrão, Eytzinger, Eytzinger sem desvios e Eytzinger sem desvios com prefetch), mudando só o jeito de guardar a árvore na memória. O eixo x é o tamanho dos dados e há linhas tracejadas marcando os tamanhos de L1, L2 e L3. Enquanto os dados cabem nas caches, todas ficam abaixo de uns 100 ns; depois do L3, o tempo dispara e as versões se separam bastante (lendo o gráfico, de uns 450 ns a uns 800 ns no maior tamanho; valores aproximados). A complexidade é a mesma, O(log n), mas o uso da cache muda o desempenho. Ligação direta com [[05 - Memória Cache - Conceitos e Estrutura]]. Fonte citada no slide: [bazhenov.me](https://www.bazhenov.me/posts/faster-binary-search-in-rust/).

**Slide 8, nem toda operação custa igual** (infográfico do [ithare.com](http://ithare.com/infographics-operation-costs-in-cpu-clock-cycles/), em ciclos de CPU). Alguns valores que conversam com a hierarquia de memória:

| Operação | Custo aproximado (ciclos) |
|---|---|
| Operação simples registrador-registrador (ADD, OR) | menos de 1 |
| Leitura na L1 | 3-4 |
| Leitura na L2 | 10-12 |
| Leitura na L3 | 30-70 |
| Leitura na memória principal (RAM) | 100-150 |
| Chamada ao kernel | 1.000-1.500 |
| Troca de contexto de thread (custo direto) | 2.000 |
| Troca de contexto de thread (total, incluindo invalidação de cache) | 10.000 a 1 milhão |

É a pirâmide de [[03 - Hierarquia e Tipos de Memória]] em números: cada nível para baixo custa cerca de uma ordem de grandeza a mais.

**Slide 9**: "Entender como o hardware funciona nos permite escrever códigos mais eficientes". O desenho mostra três círculos: hardware no centro, software de sistema em volta e software de aplicação por fora.

## 6. Ferramentas da disciplina (slide 10)

1. [RISC-V Simulator (BRISC-V)](https://ascslab.org/research/briscv/simulator/simulator.html)
2. [GodBolt Compiler Explorer](https://godbolt.org/): mostra o Assembly gerado por um código em C
3. [RV32I Instructions](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html): referência das instruções
4. [Simulador Venus](https://venus.cs61c.org/)
5. [Custo das instruções (uops.info)](https://www.uops.info/table.html)

Os links vêm do próprio PDF (os nomes no slide são clicáveis). As descrições curtas dos itens 2 e 3 são minhas.

## 7. Por que surgiu o computador? (slide 11)

O slide pergunta: "normalmente vemos a linha do tempo da evolução dos computadores, mas de onde veio a ideia?" A resposta é uma linha do tempo que mistura matemática, lógica e engenharia:

| Pessoa (vida) | O que aparece no slide | O que é |
|---|---|---|
| Charles Babbage (1791-1871) | Máquina Analítica (1820), com foto de uma máquina | Projeto de um computador mecânico de uso geral, nunca construído |
| Ada Lovelace (1815-1852) | Só o retrato, ligado à linha do tempo perto da Máquina Analítica | Escreveu notas sobre a Máquina Analítica (1843) com o que é considerado o primeiro algoritmo pensado para uma máquina |
| George Boole (1815-1864) | *The Laws of Thought* (1854), com tabelas-verdade e portas lógicas | Álgebra booleana: lógica escrita como álgebra de verdadeiro/falso |
| Georg Cantor (1845-1918) | *On a Property of the Collection of All Real Algebraic Numbers* (1874), com diagramas de conjuntos | Início da teoria dos conjuntos e da comparação entre infinitos |
| David Hilbert (1862-1943) | "Formalismo da Matemática: decidível, completa, consistente"; *Entscheidungsproblem* (1928) | O "problema da decisão": existe um procedimento mecânico que decida se qualquer afirmação matemática é verdadeira? |
| Kurt Gödel (1906-1978) | Teoremas da Incompletude, com a frase "nenhum sistema consistente de axiomas consegue provar todas as verdades sobre os números naturais, e esse sistema não consegue demonstrar a própria consistência" | Mostrou que a matemática não pode ser ao mesmo tempo completa e consistente (o slide não dá o ano; pelo que sei, 1931) |
| Alan Turing (1912-1954) | *On Computable Numbers, with an Application to the Entscheidungsproblem* (1936), com um diagrama de estados (S0, S1, Stop) lendo e escrevendo numa fita | Máquina de Turing: definição formal do que é "computável"; mostrou que o problema da decisão não tem solução |
| Alonzo Church (1903-1995) | *An Unsolvable Problem of Elementary Number Theory* (1936), com `0 := λf.λx.x`, `1 := λf.λx.f x`, `2 := λf.λx.f (f x)` | Cálculo lambda; chegou à mesma conclusão de Turing por outro caminho, no mesmo ano |
| Claude Shannon (1916-2001) | *A Symbolic Analysis of Relay and Switching Circuits* (1938), com as portas AND, NAND, OR, NOR, NOT, XOR e XNOR | Mostrou que a álgebra booleana descreve circuitos de relés e chaves: a base dos circuitos digitais |
| John von Neumann (1903-1957) | *First Draft of a Report on the EDVAC* (1945), com o diagrama entrada → CPU (unidade de controle e ULA) ↔ memória → saída; foto do ENIAC (1945) | A arquitetura von Neumann, com programa e dados na mesma memória (ver [[01 - Arquitetura von Neumann e Estrutura do Computador]]) |

As duas primeiras colunas são do slide. A terceira coluna é complemento meu, de conhecimento geral de história da computação; o slide só mostra nomes, datas, títulos e figuras.

> [!warning] Data da Máquina Analítica
> O slide diz "Máquina Analítica (1820)". Pelo que encontrei, por volta de 1822 Babbage trabalhava na **Máquina Diferencial**; os documentos da Máquina Analítica são de cerca de 1837, e as notas de Ada Lovelace são de 1843. A foto do slide parece ser de uma Máquina Diferencial, não da Analítica, mas não tenho certeza. Para a prova, vale a data do slide; só não use 1820 fora daqui sem conferir.

> [!tip] Leitura da linha do tempo (complemento meu)
> A ideia de computador veio de uma pergunta de matemática. Hilbert perguntou se a matemática era decidível, completa e consistente. Gödel mostrou que não é completa. Turing e Church, em 1936, mostraram que não é decidível e, para isso, precisaram definir o que é um procedimento mecânico: a máquina de Turing virou o modelo teórico do computador. Boole deu a álgebra da lógica, e Shannon mostrou que ela pode ser montada com circuitos elétricos. Von Neumann juntou tudo numa arquitetura prática em 1945.

Sources:
- [Imagining AI: Babbage & Lovelace (History of Science Museum, Oxford)](https://hsm.ox.ac.uk/imagining-ai): datas da Máquina Diferencial (c. 1822), dos documentos da Máquina Analítica (c. 1837) e das notas de Lovelace (1843)
- [The Analytical Engine: 28 Plans and Counting (Computer History Museum)](https://computerhistory.org/blog/the-analytical-engine-28-plans-and-counting/): trabalho de Babbage a partir de 1822 e notas de Lovelace de 1843

## 8. Von Neumann, power wall e paralelismo (slides 12-14)

**Slide 12**: toda a arquitetura de computadores atual usa a máquina de von Neumann (1945), de microcontroladores a supercomputadores. Como ganhar desempenho? Com novos núcleos (paralelismo), o que traz um novo paradigma para quem desenvolve software: sistemas paralelos e heterogêneos. O diagrama é o mesmo bloco Memória / Unidade de Controle / ULA / Acumulador / Entrada / Saída que abre os outros decks.

**Slide 13, Power Wall**: "para melhorar o desempenho, basta aumentar o clock, certo?" O gráfico mostra clock (MHz) e potência (W) dos processadores Intel:

| Processador (ano) | Clock (MHz) | Potência (W) |
|---|---|---|
| 80286 (1982) | 12,5 | 3,3 |
| 80386 (1985) | 16 | 4,1 |
| 80486 (1989) | 25 | 4,9 |
| Pentium (1993) | 66 | 10,1 |
| Pentium Pro (1997) | 200 | 29,1 |
| Pentium 4 Willamette (2001) | 2.000 | 75,3 |
| Pentium 4 Prescott (2004) | 3.600 | 103 |
| Core 2 Kentsfield (2007) | 2.667 | 95 |
| Core i5 Clarkdale (2010) | 3.300 | 87 |
| Core i5 Haswell (2013) | 3.500 | 84 |
| Core i5 Skylake (2016) | 3.500 | 91 |
| Core i5 Coffee Lake (2018) | 3.600 | 95 |

Clock e potência subiram juntos até 2004 (Pentium 4 Prescott, 3,6 GHz e 103 W). Depois disso o clock parou perto de 3,5 GHz: subir mais esquentaria demais o chip. Essa barreira de potência e calor é a **power wall**. O porquê físico (potência dinâmica proporcional à frequência e ao quadrado da tensão) não está no slide; é o argumento usual do Patterson e Hennessy.

**Slide 14, evolução da performance** (relativa ao VAX-11/780, de 1978 a 2018). As faixas do gráfico mostram o crescimento por ano:

| Período | Crescimento da performance |
|---|---|
| 1978-1986 | 25% ao ano |
| 1986-2003 | 52% ao ano |
| 2003-2011 | 23% ao ano |
| 2011-2015 | 12% ao ano |
| 2015-2018 | 3,5% ao ano |

Conclusão do slide: **usamos técnicas de paralelismo e pipeline**. Como o clock não sobe mais, o ganho vem de fazer mais coisas ao mesmo tempo (vários núcleos, pipeline). Isso conversa com a seção 4 de [[09 - Processador e Datapath RISC-V (Microprocessador I)]]: clock mais rápido não é a única alavanca do desempenho.

## 9. O que é o RISC-V e por que usá-lo (slides 15-17)

**RISC-V** (slide 15):

- ISA aberta, modular e extensível, licenciada em padrões open source.
- Criada na Universidade da Califórnia, Berkeley, por David Patterson e Krste Asanovic, para suprir as limitações das ISAs proprietárias.
- Comunidade: [community.riscv.org](https://community.riscv.org/)
- O Brasil faz parte da RISC-V International como membro premium ([notícia do MCTI, 2024](https://www.gov.br/mcti/pt-br/acompanhe-o-mcti/noticias/2024/03/brasil-se-torna-membro-da-alianca-risc-v-international)).

**Por que RISC-V** (slide 16): sem royalties ou patentes; personalizável para aplicações diversas; simples para aprender; escalável de microcontroladores a supercomputadores.

| Característica | RISC-V | ARM | x86 |
|---|---|---|---|
| Licenciamento | Aberto | Proprietário | Proprietário |
| Modularidade | Alta | Média | Baixa |
| Complexidade | Baixa | Média | Alta |
| Mercado-alvo | Amplo | Mobile/IoT | PCs/servidores |

**Padrões da computação** (slide 17):

| Área | Padrão | Open source | Proprietário |
|---|---|---|---|
| Redes | Ethernet, TCP/IP | Várias | Várias |
| Sistemas operacionais | POSIX | Linux | Windows |
| Compiladores | C | gcc, LLVM, clang | Intel icc, ARMcc |
| Banco de dados | SQL | PostgreSQL, MySQL | Oracle, MSDB |
| ISA | ?????? | (nenhum) | x86, ARM |

A ideia do slide: toda área tem um padrão aberto, menos a ISA. O RISC-V surge como opção para padronizar a ISA, corrigindo problemas de implementações anteriores, como o MIPS.

## Referências (do slide 18)

- David Patterson e Andrew Waterman. *Guia Prático RISC-V: Atlas de uma Arquitetura Aberta*. Strawberry Canyon LLC, 2019.
- Sarah Harris e David Harris. *Digital design e computer architecture*. Morgan Kaufmann, 2015.
- David Patterson e John Hennessy. *Computer Organization and Design RISC-V Edition: The Hardware Software Interface*. Morgan Kaufmann, 2018.
