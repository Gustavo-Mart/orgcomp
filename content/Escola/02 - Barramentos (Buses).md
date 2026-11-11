
# Barramentos (Buses)

← [[01 - Arquitetura von Neumann e Estrutura do Computador]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[03 - Hierarquia e Tipos de Memória]]

## 1. O que é um barramento

Um barramento é um caminho de conexão que liga dois ou mais dispositivos entre si. Características gerais: normalmente faz comunicação em broadcast, ou seja, todo mundo conectado ao barramento "ouve" o sinal. Barramentos costumam ser agrupados, então pode haver várias linhas (canais) dentro de um mesmo barramento. E as linhas de alimentação (energia) geralmente não aparecem nos diagramas, que mostram só as linhas de sinal e dados.

## 2. Linhas do barramento: 3 grupos funcionais

Apesar de existirem muitos projetos de barramento diferentes, suas linhas sempre se dividem em três grupos funcionais:

1. **Linhas de dados**: caminho para mover dados entre os módulos. Um barramento de dados tem várias linhas, e cada linha carrega 1 bit por vez. O número de linhas de dados é chamado de largura do barramento (bus width).
2. **Linhas de endereço**: definem a origem e o destino no barramento de dados. O tamanho da linha de endereço limita a capacidade máxima de memória que o sistema consegue endereçar. Esse mesmo barramento de endereço também é usado para endereçar portas de E/S.
3. **Linhas de controle**: controlam o uso e o acesso às linhas de dados e endereço. Podem transmitir temporização (clock) dos módulos, sinalizar leitura ou escrita, requisitar interrupção, entre outras funções.

> [!tip] Regra prática
> Largura do barramento de dados: quantos bits você move por vez, o que afeta desempenho.
> Largura do barramento de endereço: quantas posições de memória você consegue endereçar, o que afeta a capacidade máxima de memória. Ver seção 8.

## 3. Tipos de barramento (por escopo físico)

- **Barramento Local**: interno ao processador.
- **Barramento de Sistema**: interconecta o processador e os demais módulos à memória principal.
- **Barramento de Alta Velocidade**: interconecta dispositivos de E/S que exigem altas taxas de transferência, como gráficos e rede.
- **Barramento de Expansão**: interconecta os demais dispositivos de E/S, mais lentos ou menos críticos.

### Modelo físico (exemplo do slide)

```
Processador -- Barramento local -- Cache/ponte -- Barramento do Sistema -- Memória principal
                                        |
                          Barramento de alta velocidade
                    (SCSI, FireWire, Gráfico, Vídeo, LAN)
                                        |
                          Barramento de expansão
                    (FAX, Interface do barramento de expansão -- Modem, Serial)
```

O Chipset/ponte é o elemento que liga o barramento local, rápido e próximo do processador, ao barramento de sistema, e este aos barramentos de alta velocidade e de expansão, mais distantes e lentos.

## 4. Gargalos: por que usar múltiplos barramentos

Na prova, o tópico "gargalos" junta duas ideias. A primeira é o gargalo de von Neumann: instruções e dados disputam o mesmo barramento, então não podem ser buscados ao mesmo tempo (ver seção 5.1 de [[01 - Arquitetura von Neumann e Estrutura do Computador]]). A segunda é o gargalo físico de pendurar muitos dispositivos num barramento só, descrito abaixo.

Colocar muitos dispositivos em um único barramento causa atrasos de propagação: há mais distância a ser percorrida pelos dados, e uma taxa de transferência maior exige mais controle sobre o barramento.

Por isso, a maioria dos sistemas atuais usa múltiplos barramentos para contornar esse problema. Cada barramento tem sua própria taxa de transferência e pode usar protocolos diferentes. O Chipset é quem conecta o processador e o subsistema de memória ao dispositivo de comutação do PCI Express.

Exemplo do slide, de uma arquitetura típica com PCIe: dois núcleos de CPU (Cores) se conectam ao Chipset, que também liga a Gigabit Ethernet (via PCIe), a Memória (2 módulos) e uma Ponte PCIe-PCI. O Chipset se conecta a um Comutador PCIe, que distribui para múltiplos terminais PCIe, incluindo terminais "legado".

### 4.1 Complemento de pesquisa: como o PCI Express evoluiu o conceito de barramento

O slide cita o PCI Express só como o barramento usado no exemplo do Chipset, sem detalhar por que ele existe. Pesquisando fora do material do professor: o PCI tradicional usava um barramento paralelo compartilhado, onde a velocidade total era dividida entre todos os dispositivos conectados. O PCI Express substitui isso por conexões seriais ponto a ponto, organizadas em "lanes" (pistas), identificadas como x1, x4, x8 e x16. Um slot x16, por exemplo, tem mais lanes e por isso mais banda, o que é o motivo de placas de vídeo usarem esse tipo de slot. Cada geração do padrão dobrou a velocidade da anterior (o PCIe 3.0 chega a cerca de 16 GB/s, o PCIe 4.0 a cerca de 32 GB/s, e assim por diante), sempre mantendo conexões dedicadas por dispositivo em vez de dividir um barramento compartilhado.

Sources:
- [O que é o PCI Express (PCIe): guia completo sobre funcionamento, versões e aplicações - 4infra](https://4infra.com.br/o-que-e-o-pci-express-2025/)

## 5. Projeto de um barramento: características a analisar

| Aspecto | Opções |
|---|---|
| Tipo | Dedicado / Multiplexado |
| Largura do barramento | Endereço / Dados |
| Método de arbitração | Centralizado / Distribuído |
| Tipo de transferência de dados | Leitura / Escrita / Ler-modificar-escrever / Leitura-após-escrita / Bloco |
| Sincronização | Síncrona / Assíncrona |

As próximas seções detalham cada uma dessas linhas da tabela.

## 6. Controle do barramento: Dedicado vs. Multiplexado

- **Dedicado**: linhas separadas para dados e para endereço. Vantagem: controle simplificado e velocidade maior. Desvantagem: ocupa mais espaço físico (mais fios e pinos).
- **Multiplexado**: as mesmas linhas físicas carregam ora endereço, ora dados, e uma linha de controle indica o que está passando no momento. Vantagem: menos linhas físicas. Desvantagem: controle mais complexo.

## 7. Arbitragem do barramento

Mecanismo que decide qual módulo assume o controle do barramento em um dado momento. Exemplo motivador: um dispositivo de E/S pode querer gravar dados direto na memória, sem passar pelo processador. Essa é a ideia por trás de DMA.

- **Arbitração Centralizada**: um único dispositivo, seja um módulo separado ou o próprio processador, é responsável por alocar o tempo de uso do barramento.
- **Arbitração Distribuída**: cada módulo tem sua própria lógica de controle de acesso, e os dispositivos agem em conjunto para compartilhar o barramento.

Em ambos os métodos, o objetivo final é o mesmo: designar um dispositivo (processador ou módulo de E/S) como mestre. O mestre inicia uma transferência (leitura ou escrita) com outro dispositivo, que atua como escravo naquela troca específica.

### 7.1 Complemento de pesquisa: técnicas concretas de arbitração centralizada

O slide cita "Arbitração Centralizada" só como conceito geral. Pesquisando em material complementar, fora do slide do professor, existem três técnicas clássicas de arbitração centralizada que costumam aparecer detalhadas em outros materiais de Organização de Computadores:

- **Daisy chaining (encadeamento em cadeia)**: o sinal de concessão do barramento passa sequencialmente de dispositivo em dispositivo. O primeiro que estiver pedindo acesso "segura" o sinal e impede que ele continue adiante. É simples e escalável, mas sofre com atraso de propagação e cria uma prioridade fixa baseada na posição física de cada dispositivo na cadeia.
- **Polling, ou prioridade rotativa**: um controlador gera endereços para cada mestre em sequência. Quando um dispositivo reconhece seu próprio endereço sendo chamado, ele assume o barramento. É mais justo entre os dispositivos e continua funcionando mesmo se um deles falhar, mas adicionar novos mestres exige mais linhas de endereço.
- **Prioridade fixa, ou requisição independente**: cada mestre tem seu próprio par de linhas de requisição e concessão, com prioridades pré-definidas, e um decodificador de prioridade escolhe a requisição de maior prioridade. Responde rápido, mas exige bastante hardware dedicado (um par de linhas por dispositivo).

Sources:
- [BUS Arbitration in Computer Organization - GeeksforGeeks](https://www.geeksforgeeks.org/bus-arbitration-in-computer-organization/)

## 8. Tipos de transferência de dados do barramento

O slide mostra 6 padrões de temporização de transferência, usando o eixo "Tempo →":

1. **Escrita (multiplexada)**: 1º ciclo transmite o Endereço, 2º ciclo transmite os Dados, nas mesmas linhas físicas, reaproveitadas.
2. **Escrita (não multiplexada)**: Endereço e Dados são enviados no mesmo ciclo, mas por linhas de barramento separadas.
3. **Leitura (multiplexada)**: 1º ciclo é o Endereço, depois um tempo de acesso, e então os Dados chegam.
4. **Leitura (não multiplexada)**: a linha de Endereço fica estável por mais tempo enquanto, em paralelo, a linha de Dados entrega o valor.
5. **Leitura-modificação-escrita**: sequência Endereço, Leitura de dados, Escrita de dados, tudo em relação ao mesmo endereço. É uma operação atômica de ler, alterar e escrever de volta.
6. **Leitura-após-escrita**: Endereço, Escrita de dados, Leitura de dados. Útil para verificar se a escrita realmente ocorreu.
7. **Transferência em bloco**: 1 Endereço seguido de vários Dados consecutivos. É mais eficiente para mover blocos grandes, pois não é preciso reenviar o endereço a cada palavra.

## 9. Tipos de temporização (sincronização)

- **Síncrona**: a ocorrência dos eventos no barramento é determinada por um clock incluído no próprio barramento. Vantagem: mais simples, já que outros sinais podem mudar apenas na transição do clock. Desvantagem: a taxa de clock é fixa, então o sistema não aproveita avanços de desempenho de dispositivos mais rápidos.
- **Assíncrona**: a ocorrência de um evento depende da ocorrência do evento anterior, em um esquema de handshake, sem um clock global. Vantagem: dispositivos lentos e rápidos, de tecnologias antigas e novas, podem compartilhar o mesmo barramento. Desvantagem: maior complexidade de controle.

### Exemplo: temporização síncrona (ciclo de leitura e de escrita)

O diagrama mostra, ao longo de 3 períodos de clock (T1, T2, T3), o Clock alternando, as linhas de estado carregando "sinais de estado", as linhas de endereço com "endereço estável" e a ativação de endereço subindo brevemente. Dependendo do ciclo: no ciclo de leitura, a linha de "Leitura" fica ativa e "entrada de dados válida" aparece nas linhas de dados; no ciclo de escrita, a linha de "Escrita" fica ativa e "saída de dados válida" aparece nas linhas de dados.

### Exemplo: temporização assíncrona (ciclo de leitura e de escrita do barramento do sistema)

Sem clock global, usa-se um protocolo de handshake. No ciclo de leitura: sinais de estado, depois endereço estável, depois sinal de Leitura ativado, depois dados tornam-se válidos, depois um sinal de Confirmação (acknowledge) é enviado de volta. No ciclo de escrita, o mesmo padrão se repete trocando "Leitura" por "Escrita".

## 10. Largura do barramento

É a capacidade de transmissão de sinais em paralelo. No barramento de dados, quanto maior a largura, maior a quantidade de bits transmitidos por vez. No barramento de endereços, quanto mais largo, maior o número de posições de memória que podem ser acessadas, em relação direta com a capacidade máxima endereçável (ver [[07 - Glossário e Fórmulas]]).

## 11. Velocidade do barramento e taxa de transferência

A velocidade é medida pela frequência de operação do barramento: mede o tempo ($T$) que o barramento leva para transmitir uma quantidade $n_b$ de bits, a largura do barramento, onde:

$$T = \frac{1}{f}$$

E a velocidade em bits por segundo:

$$v = \frac{n_b}{T}$$

A taxa de transferência (ou largura de banda), em bytes por segundo, é:

$$T_x = \frac{n_b \times f}{8}$$

### Exemplo resolvido do slide

> Um barramento PCI 2.0 permite o uso de até 64 linhas de dados a 66 MHz. Qual a taxa de transferência do barramento?

$$T = \frac{1}{f} = \frac{1}{66 \times 10^6} \approx 1{,}515 \times 10^{-8}\ \text{s} \approx 15{,}15\ \text{ns}$$

> [!warning] Inconsistência no slide original
> O slide escreve esse resultado como "T = 1,51 · 10⁻⁸ = 151,15 µs". Isso está inconsistente: $1{,}51\times10^{-8}$ segundos equivale a aproximadamente 15,15 nanossegundos (ns), não a 151,15 microssegundos (µs). Parece um erro de digitação de unidade no material original, provavelmente trocando "ns" por "µs" e deslocando a vírgula. Não tenho como confirmar a intenção exata do professor aqui, então sinalizo a inconsistência em vez de repassá-la como certa. O valor numérico $1{,}51\times10^{-8}$, em segundos, usado no passo seguinte, está correto e é o que efetivamente gera a resposta final.

Continuando com $T \approx 1{,}51\times10^{-8}$ s:

$$v = \frac{n_b}{T} = \frac{64}{1{,}51\times10^{-8}} \approx 4{,}22\times10^{9}\ \text{bps} \Rightarrow \approx 4{,}2\ \text{Gbps}$$

$$T_x = \frac{n_b \times f}{8} = \frac{64 \times 66\times10^6}{8} = 528\ \text{MBps}$$

## 12. Exercícios de fixação (do slide)

1. Qual a função de um barramento? Quais os tipos de barramento?
2. Quais os tipos de controle de barramento?
3. O que é a temporização e a largura do barramento?
4. Qual a velocidade em bps, e qual a taxa de transferência de um barramento que possui 32 bits de largura e uma frequência de 33 MHz?

> [!example]- Solução sugerida para o exercício 4 (não estava resolvida no slide, confira antes de usar para valer nota)
> $$T = \frac{1}{f} = \frac{1}{33\times10^6} \approx 3{,}03\times10^{-8}\ \text{s} \approx 30{,}3\ \text{ns}$$
> $$v = \frac{n_b}{T} = \frac{32}{3{,}03\times10^{-8}} \approx 1{,}056\times10^{9}\ \text{bps} \approx 1{,}056\ \text{Gbps}$$
> $$T_x = \frac{n_b \times f}{8} = \frac{32 \times 33\times10^6}{8} = 132\times10^6 = 132\ \text{MBps}$$

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 3. Pearson, 2017.
- Material produzido com base nas notas de aula do Prof. Dr. Thiago Ferauche.
