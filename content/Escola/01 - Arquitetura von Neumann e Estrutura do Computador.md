---
tags: [organização-de-computadores, von-neumann, cpu, arquitetura]
fonte: OrgComp02_vonNeuman.pdf (slides 1-9)
---

# Arquitetura von Neumann e Estrutura do Computador

← [[00 - Índice - Organização de Computadores|Índice]] | Próxima nota: [[02 - Barramentos (Buses)]]

Esta nota cobre a parte de revisão do slide "Arquitetura von Neumann": os primeiros slides antes de o professor entrar de fato no assunto do dia, que é barramento (ver [[02 - Barramentos (Buses)]]).

## 1. Contexto histórico (retomada da aula anterior)

O slide apenas cita que, na aula anterior, foi visto "o contexto histórico que culminou no surgimento do computador". Essa aula é o deck de Introdução, resumido em [[00b - Introdução e Contexto Histórico]]. A linha do tempo do slide 11 de lá vai de Babbage e Lovelace (Máquina Analítica) e Boole (álgebra da lógica), passa pelas perguntas de Hilbert sobre os fundamentos da matemática e pelas respostas de Gödel, Turing e Church (1936), por Shannon ligando lógica a circuitos (1938), e chega a von Neumann com o relatório do EDVAC (1945), que define a arquitetura desta nota.

## 2. A arquitetura dominante: von Neumann

A arquitetura de von Neumann é o modelo estrutural adotado pela grande maioria dos computadores modernos de uso geral. Ela é composta por 4 blocos principais:

- **CPU (Processador)**: contém a Unidade de Controle, a ULA (Unidade Lógica e Aritmética) e o Acumulador.
- **Memória**: guarda instruções e dados no mesmo espaço de endereçamento. Essa é a marca registrada de von Neumann.
- **Barramento**: a interconexão que liga CPU, memória e E/S.
- **Entrada/Saída (E/S)**: comunica o computador com o ambiente externo.

Fluxo conceitual mostrado no diagrama do slide: a Memória troca "Instrução & Dados" com o bloco do Processador (Unidade de Controle, ULA e Acumulador). A Entrada e a Saída também se conectam a esse mesmo bloco processador.

> [!tip] Por que isso importa
> No modelo von Neumann, instruções e dados compartilham a mesma memória e o mesmo barramento. Isso é justamente o que motiva a comparação com a arquitetura Harvard na seção 5, e é a raiz do chamado "gargalo de von Neumann" (von Neumann bottleneck): a CPU não pode buscar uma instrução e um dado ao mesmo tempo pelo mesmo barramento.

## 3. Estrutura de um computador: os 4 componentes estruturais

Retomando a aula passada, os slides listam os 4 componentes estruturais de qualquer computador:

- **CPU (Unidade Central de Processamento)**: controla a operação do computador e realiza as funções de processamento de dados. Normalmente chamada apenas de "processador".
- **Memória Principal**: armazena dados (no modelo von Neumann, as instruções ficam nessa mesma memória).
- **E/S (Entrada/Saída)**: move dados entre o computador e o ambiente externo.
- **Interconexão do sistema**: o mecanismo que permite a comunicação entre CPU, memória principal e E/S. O exemplo mais comum é um barramento do sistema, uma série de fios condutores aos quais todos os outros componentes se conectam.

### Diagrama "visão funcional do computador" (Figura 1.1 do slide)

O slide representa isso como um fluxo entre quatro elementos:

```
Ambiente operacional  ⇄  Aparato de movimentação de dados  ⇄  Mecanismo de controle  ⇄  Capacidade de processamento de dados
    (origem e destino                                                                  ⇄  Capacidade de armazenamento de dados
        dos dados)
```

O "ambiente operacional" é de onde os dados vêm e para onde vão. O "aparato de movimentação de dados" corresponde à E/S e ao barramento. O "mecanismo de controle" é a CPU, na parte de unidade de controle, e ela se conecta tanto à capacidade de processamento (ULA) quanto à capacidade de armazenamento (memória).

## 4. Estrutura de alto nível da CPU

O slide detalha a CPU em duas camadas de zoom.

No nível do computador como um todo, aparecem E/S, Memória principal e CPU, ligados via Barramento do sistema.

Dentro da CPU, aparecem Registradores, ULA (ALU, a Unidade Lógica e Aritmética), um Barramento interno (que conecta registradores, ULA e unidade de controle dentro da própria CPU) e a Unidade de controle.

E dentro da própria Unidade de Controle, o slide ainda mostra Lógica de sequência, Registradores da unidade de controle e codificadores, e Memória de controle.

Essa estrutura em camadas mostra que a "Unidade de Controle" não é uma caixa-preta simples: ela própria tem registradores, lógica de sequenciamento e, em implementações microprogramadas, uma memória de controle e decodificadores que traduzem instruções em sinais de controle.

### 4.1 Complemento de pesquisa: unidade de controle cabeada vs. microprogramada

O slide não detalha como a Unidade de Controle gera esses sinais internamente. Pesquisando fora do material do professor, existem duas formas clássicas de implementar isso:

- **Unidade cabeada (hardwired)**: usa lógica sequencial fixa, com portas lógicas ligadas fisicamente para gerar cada sinal de controle. É rápida, mas pouco flexível: mudar a arquitetura exige mexer na fiação.
- **Unidade microprogramada**: guarda microinstruções em uma memória de controle (exatamente o bloco "Memória de controle" citado acima). A vantagem é a simplicidade estrutural e a possibilidade de depurar e ajustar o comportamento quase como se fosse software, sem redesenhar o hardware.

Isso ajuda a explicar por que o diagrama do slide já separa "Memória de controle" e "Registradores da unidade de controle e codificadores" como blocos distintos dentro da Unidade de Controle: são peças típicas de uma implementação microprogramada.

Sources:
- [Unidade de controle - Wikipédia](https://pt.wikipedia.org/wiki/Unidade_de_controle)

## 5. Von Neumann vs. Harvard

Os slides comparam as duas arquiteturas lado a lado.

No diagrama Von Neumann, há um único bloco de Memória (Instrução & Dados) ligado ao bloco Processador (Unidade de Controle, ULA e Acumulador), que por sua vez se liga à Entrada e à Saída.

No diagrama Harvard, existem dois blocos de memória separados, Memória de Instrução e Memória de Dados, cada um com seu próprio caminho até o Processador (Unidade de Controle, ULA e Acumulador), que se conecta à Entrada e Saída.

### Tabela comparativa (como no slide)

| Característica | Von Neumann | Harvard |
|---|---|---|
| Memória | Bloco único compartilhado | Blocos separados (instrução / dados) |
| Barramentos | Compartilhados (gargalo) | Independentes |
| Desempenho | Acesso sequencial | Acesso paralelo |
| Complexidade | Controle e roteamento mais simples | Hardware de roteamento mais complexo |
| Aplicações | Processadores de uso geral | Microcontroladores e DSPs |

> [!note] Interpretação
> Harvard ganha em desempenho, pois a busca de instrução e o acesso a dado podem acontecer ao mesmo tempo, em barramentos separados, mas paga esse ganho com mais complexidade de hardware. Por isso ela é mais comum em microcontroladores e DSPs (Digital Signal Processors), onde o padrão de acesso é mais previsível, e não em CPUs de propósito geral.

### 5.1 Complemento de pesquisa: o "gargalo de von Neumann"

O termo técnico para o problema citado na tabela acima, "Barramentos compartilhados = gargalo", é von Neumann bottleneck (gargalo de von Neumann). Não é um termo usado literalmente no slide, mas ajuda a entender por que a linha "Barramentos" da tabela diz "gargalo": como CPU e memória compartilham o mesmo barramento para instruções e dados, eles não podem ser buscados ao mesmo tempo. O acesso precisa alternar entre buscar instrução e ler ou escrever dado, o que limita o desempenho mesmo que o processador em si seja rápido. É exatamente esse gargalo que a arquitetura Harvard evita, ao dar caminhos físicos separados para instrução e dado.

Sources:
- [Difference between Von Neumann and Harvard Architecture - GeeksforGeeks](https://www.geeksforgeeks.org/computer-organization-architecture/difference-between-von-neumann-and-harvard-architecture/)

## 6. Transição para o tema do dia

O próprio slide encerra essa revisão dizendo: *"Hoje vamos analisar o primeiro bloco principal, o barramento"*. A partir daqui (slide 3 em diante do PDF), o conteúdo é inteiramente sobre barramentos. Veja a continuação em [[02 - Barramentos (Buses)]].

A CPU, que nesta nota aparece só como bloco, é detalhada em [[09 - Processador e Datapath RISC-V (Microprocessador I)]].

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 3. Pearson, 2017.
- Material produzido com base nas notas de aula do Prof. Dr. Thiago Ferauche.
