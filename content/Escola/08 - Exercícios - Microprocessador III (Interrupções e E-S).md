---
tags: [organização-de-computadores, interrupção, entrada-saída, dma, exercícios]
fonte: OrgComp07_Microprocessador_III.pdf (slides 4-17)
---

# Microprocessador III: Exercícios sobre Interrupções e E/S

← [[10 - Interrupções e Entrada-Saída (Microprocessador III)]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[07 - Glossário e Fórmulas]]

Respostas dos 3 exercícios do slide 17. Cada resposta indica de qual slide veio a informação. A teoria do deck, slide a slide, está em [[10 - Interrupções e Entrada-Saída (Microprocessador III)]].

> [!note] Sobre estas respostas
> Os exercícios não vêm resolvidos no slide. As respostas abaixo são soluções sugeridas, montadas a partir dos slides 4 a 15 (as figuras parecem ser do livro do Stallings citado nas referências). O que não está no slide aparece marcado como complemento. Confira com o professor antes de usar para valer nota.

## 1. Por que existem interrupções? Quais os tipos de interrupção?

### Por que existem

O processador é muito mais rápido que os dispositivos externos. Uma impressora, um disco ou um teclado levam o tempo de muitas instruções para concluir uma operação. Sem interrupção, o processador tem duas opções ruins: ficar parado esperando o dispositivo terminar, ou ficar perguntando o tempo todo se ele já terminou (E/S programada, slide 13). Nos dois casos ele desperdiça tempo que poderia usar executando outro código.

A interrupção inverte essa lógica: o processador manda o comando para o dispositivo, volta a trabalhar no programa, e é o dispositivo que avisa quando terminou, por meio de um sinal de controle chamado **IRQ (Interrupt Request)** (slide 6). Assim a CPU só para o que está fazendo quando realmente precisa atender alguém.

Em resumo, as interrupções existem para:

- **Melhorar a eficiência do processador**, que executa outras instruções enquanto a E/S acontece. É o motivo principal, ilustrado no slide 7.
- **Tratar situações de erro** que surgem durante a execução: overflow, divisão por zero, instrução ilegal, falha de hardware.
- **Permitir que o sistema operacional retome o controle periodicamente** pelo timer, por exemplo para dividir o tempo da CPU entre vários programas.

### Tipos de interrupção (tabela do slide 6)

| Tipo | Quem gera | Exemplos |
|---|---|---|
| **Programa** | Uma condição que resulta da execução de uma instrução | Overflow aritmético, divisão por zero, tentativa de executar instrução de máquina ilegal, acesso fora do espaço de memória permitido ao usuário |
| **Timer** | Um timer dentro do processador | Permite ao sistema operacional executar certas funções em intervalos regulares |
| **E/S** | Um controlador de E/S | Sinaliza o término normal de uma operação ou uma série de condições de erro |
| **Falha de hardware** | Uma falha física | Falta de energia, erro de paridade de memória |

> [!warning] Ajuste em relação ao slide original
> Na linha do Timer, o slide diz "um timer dentro do **processo**". Pelo contexto deve ser **processador**.

> [!info] Complemento (não está no slide)
> Outros materiais classificam as interrupções de outros jeitos. Por origem: **externas/de hardware** (vêm de dispositivos, como E/S e timer), **internas/exceções** (vêm da própria instrução, como divisão por zero) e **de software** (pedidas de propósito pelo programa, como uma chamada de sistema). Por possibilidade de bloqueio: **mascaráveis** (a CPU pode ignorar ou adiar) e **não mascaráveis** (NMI, para eventos críticos como falha de energia). Se a prova pedir "os tipos", a resposta esperada provavelmente é a tabela do slide 6.

## 2. Ciclo de busca e execução com e sem interrupção

### Sem interrupção

O ciclo é o do slide 4: **Busca → Decodificação → Execução → Armazenamento**, e volta para a busca da próxima instrução. O fluxo só muda por causa de instruções do próprio programa (desvios, chamadas de função).

O problema aparece na E/S (slide 7, figura a). Quando o programa do usuário chega num `WRITE`, ele chama o programa de E/S, que prepara a operação (segmento 4), envia o comando ao dispositivo e fica esperando o dispositivo terminar. Durante toda essa espera, o programa do usuário fica parado. Só depois que o programa de E/S chega no `END` (segmento 5) o processador volta ao código do usuário.

### Com interrupção

O ciclo ganha uma etapa extra no final: a **verificação de interrupção** (slide 10). A figura de baixo do slide 8 mostra que essa verificação só acontece com as interrupções habilitadas; com elas desabilitadas, o processador volta direto para a busca. Depois de terminar uma instrução, o processador olha se existe algum pedido de interrupção (IRQ) pendente:

- **Sem interrupção pendente:** segue normal e busca a próxima instrução.
- **Com interrupção pendente:** entra no ciclo de interrupção (slide 8):
  1. Suspende o programa atual e **salva o contexto**: o conteúdo do PC (endereço da próxima instrução) e os outros dados relevantes, como os registradores.
  2. Carrega no PC o **endereço inicial da rotina de tratamento de interrupção**.
  3. Executa a rotina. Ao terminar, restaura o contexto salvo e o programa continua exatamente de onde parou. (Esse passo 3 não está escrito no texto do slide 8, mas aparece na figura do próprio slide 8, em que o controle volta do tratador para a instrução i + 1, e na figura do slide 7.)

Na E/S (slide 7, figuras b e c), o programa de E/S só prepara e envia o comando (segmento 4) e devolve o controle ao programa do usuário, que continua executando enquanto o dispositivo trabalha. Quando o dispositivo termina, ele interrompe o programa (o "X" no meio do segmento 2) e o tratador de interrupção (segmento 5) finaliza a operação.

- **(b) Espera curta de E/S:** a operação termina antes do próximo `WRITE`, então a espera do processador some por completo.
- **(c) Espera longa de E/S:** o programa chega no segundo `WRITE` antes de o primeiro terminar. Aí ele precisa esperar mesmo assim, mas parte do tempo de E/S já foi aproveitada executando o segmento 2.

> [!warning] Detalhe: "no meio" de quê?
> O slide 7 diz que "a interrupção pode interromper o ciclo de busca no meio". Pela figura, o "X" fica no meio do **programa do usuário**, ou seja, entre duas instruções dele. O slide 10 mostra que a verificação só acontece **no fim do ciclo de cada instrução**: a instrução atual termina primeiro e só depois a CPU desvia para a rotina. Quem consegue pausar a CPU no meio de uma instrução é o DMA (slide 15), que é outro mecanismo (ver exercício 3).

### Múltiplas interrupções (slide 9)

Uma interrupção pode chegar enquanto outra está sendo tratada. Com prioridades, uma rotina de prioridade maior pode interromper uma de prioridade menor (interrupções aninhadas). No exemplo do slide:

- t = 10: a impressora interrompe o programa do usuário.
- t = 15: a comunicação interrompe a rotina da impressora.
- t = 25: a rotina de comunicação termina. Antes de a rotina da impressora voltar a rodar, a rotina do disco é atendida.
- t = 35: o disco termina e a rotina da impressora continua.
- t = 40: a impressora termina e o controle volta ao programa do usuário.

Pela figura dá para ver que comunicação e disco têm prioridade maior que impressora. No exemplo original do Stallings, se não me engano, o pedido do disco chega em t = 20, durante a rotina de comunicação, e fica esperando porque o disco tem prioridade menor que a comunicação. Esse instante não aparece no slide, então vale conferir no livro.

### Comparação direta

| | Sem interrupção | Com interrupção |
|---|---|---|
| Etapas do ciclo | Busca → Decodificação → Execução → Armazenamento | As mesmas, mais a verificação de interrupção no fim de cada instrução |
| Durante a E/S | CPU fica esperando o dispositivo | CPU continua executando outras instruções |
| O que desvia o fluxo | Só instruções do programa (desvios, chamadas) | Também eventos externos ou de erro, entre quaisquer duas instruções |
| Custo extra | Nenhum, ciclo mais simples | Salvar e restaurar contexto a cada interrupção, mais o hardware que verifica IRQ e prioridades |
| Aproveitamento da CPU | Baixo quando há muita E/S | Alto: o tempo de E/S se sobrepõe ao processamento |

## 3. Tipos de acesso a E/S: vantagens e desvantagens

O slide 13 lista três técnicas, e o slide 14 mostra cada uma lendo um bloco de dados.

### E/S programada

A CPU envia o comando de leitura ao módulo de E/S e fica num laço lendo o registrador de estado até o dispositivo ficar pronto. Aí lê a palavra do módulo (E/S → CPU), grava na memória (CPU → memória) e repete até terminar o bloco (slide 14a). Exemplo do slide: sensor simples.

- **Vantagens:** é a técnica mais simples; não precisa de lógica de interrupção nem de controlador extra; o comportamento é previsível.
- **Desvantagens:** a CPU fica presa em espera ocupada (busy waiting), testando o estado sem fazer nada útil. É a "perda de tempo" que o slide aponta, e piora quanto mais lento for o dispositivo.

### E/S controlada por interrupção

A CPU envia o comando e vai "fazer algo mais". Quando o módulo fica pronto, ele interrompe a CPU, que então lê o estado, lê a palavra e grava na memória (slide 14b). Exemplo do slide: teclado e mouse.

- **Vantagens:** acaba com a espera ocupada, a CPU trabalha enquanto o dispositivo se prepara; boa para eventos que acontecem em momentos imprevisíveis, como uma tecla pressionada.
- **Desvantagens:** cada palavra ainda passa pela CPU (E/S → CPU → memória), então ela continua envolvida em toda a transferência. Cada interrupção custa salvar e restaurar contexto, o que fica caro para blocos grandes ou dispositivos rápidos.

### DMA (Direct Memory Access)

A CPU só passa o pedido ao módulo de DMA e segue com outro trabalho. O DMA transfere o bloco inteiro direto entre o dispositivo e a memória, sem passar pela CPU, e gera **uma única interrupção** no final (slide 14c). Exemplos do slide: placa de vídeo, disco.

- **Vantagens:** a CPU quase não participa da transferência; ideal para grandes volumes de dados em alta velocidade.
- **Desvantagens:** precisa de hardware extra (o controlador de DMA) e disputa o barramento com a CPU. Pela técnica de **cycle stealing** (slide 15), o DMA "rouba" ciclos de barramento e a CPU pode ficar parada esperando durante esses ciclos.

> [!info] Cycle stealing não é interrupção
> No slide 15, os pontos de parada do DMA ficam **nas divisões entre os ciclos do processador, dentro de uma mesma instrução** (a figura aponta, por exemplo, a divisão entre a decodificação e a busca do operando e a divisão entre a execução e o armazenamento). O ponto de interrupção fica só **no fim da instrução**, depois do armazenamento do resultado. Na parada do DMA a CPU não salva contexto, só espera o barramento ficar livre.

> [!info] Complemento (não está no slide)
> No pedido ao DMA, a CPU costuma informar se é leitura ou escrita, o endereço do dispositivo, o endereço inicial na memória e a quantidade de palavras a transferir.

### Tabela comparativa

| | E/S programada | Por interrupção | DMA |
|---|---|---|---|
| Quem move os dados | CPU | CPU | Módulo de DMA |
| CPU espera o dispositivo? | Sim (espera ocupada) | Não | Não |
| Interrupções por bloco | Nenhuma | Uma por palavra | Uma no fim do bloco |
| Hardware extra | Nenhum | Lógica de interrupção | Controlador de DMA |
| Melhor uso | Dispositivo simples, pouco dado | Eventos imprevisíveis, pouco dado | Blocos grandes, alta velocidade |
| Exemplo do slide | Sensor simples | Teclado e mouse | Placa de vídeo, disco |

> [!tip] Resumo para prova
> Programada: a CPU espera e move os dados. Interrupção: a CPU não espera, mas ainda move. DMA: a CPU não espera nem move, só é avisada no fim.
