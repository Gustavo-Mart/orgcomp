---
tags: [organização-de-computadores, glossário, fórmulas, revisão]
---

# Glossário e Fórmulas: Consulta Rápida

← [[08 - Exercícios - Microprocessador III (Interrupções e E-S)]] | [[00 - Índice - Organização de Computadores|Índice]]

Resumo de bolso para revisão de véspera de prova. Cada termo linka de volta para a nota onde é explicado com contexto e exemplos.

## Introdução e história (ver [[00b - Introdução e Contexto Histórico]])

- **Linha do tempo do slide 11**: Babbage (Máquina Analítica) e Lovelace; Boole, *The Laws of Thought* (1854), álgebra booleana; Cantor (1874), conjuntos; Hilbert, Entscheidungsproblem (1928); Gödel, incompletude; Turing e Church (1936), computabilidade; Shannon (1938), lógica em circuitos; von Neumann, relatório do EDVAC (1945); ENIAC (1945).
- **Power wall**: desde 2004 o clock parou perto de 3,5 GHz porque potência e calor subiam junto. O ganho de desempenho passou a vir de paralelismo (vários núcleos) e pipeline.
- **RISC-V**: ISA aberta, modular e extensível, criada em Berkeley, sem royalties.
- **SAP (Simple as Possible)**: arquitetura do computador do projeto da disciplina (50% da nota).

## Barramento (ver [[02 - Barramentos (Buses)]])

- **Largura do barramento**: nº de linhas de dados transmitidas em paralelo.
- **Período**: $T = \dfrac{1}{f}$
- **Velocidade (bps)**: $v = \dfrac{n_b}{T}$, onde $n_b$ é a largura do barramento em bits
- **Taxa de transferência / largura de banda (bytes/s)**: $T_x = \dfrac{n_b \times f}{8}$
- **Barramento Dedicado**: linhas separadas para dados e endereço (mais rápido, mais espaço).
- **Barramento Multiplexado**: linhas compartilhadas (menos espaço, controle mais complexo).
- **Arbitração Centralizada**: um único módulo decide quem usa o barramento (por daisy chaining, polling ou prioridade fixa).
- **Arbitração Distribuída**: cada módulo tem lógica própria de acesso.
- **Síncrona**: eventos ditados por um clock comum. **Assíncrona**: eventos dependem do evento anterior (handshake).
- **PCI Express**: conexões seriais ponto a ponto organizadas em lanes (x1, x4, x8, x16), sucessor do PCI paralelo compartilhado.

## Memória (ver [[03 - Hierarquia e Tipos de Memória]] e [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]])

- **Hierarquia (topo → base)**: registradores → cache (SRAM) → memória principal (DRAM) → secundária (disco, SSD) → offline (fita). Subindo: mais rápido e mais caro por bit. Descendo: mais capacidade e mais barato. Só a secundária e a offline são não voláteis, e a CPU só chega nelas pela memória principal.
- **Tempo de acesso (latência)**: do pedido de endereço até o dado disponível.
- **Tempo de ciclo**: tempo de acesso mais tempo extra antes de o próximo acesso poder começar.
- **Taxa de transferência**: quantidade de dados movida por unidade de tempo.
- **DRAM**: barata, simples, célula de 1 transistor e 1 capacitor (1T1C), precisa de refresh, usada na memória principal.
- **SRAM**: rápida, célula de 6 transistores (6T), sem refresh, usada em cache.
- **SDRAM**: DRAM síncrona (clock externo). **DDR**: transfere 2x por ciclo de clock. Do DDR1 ao DDR4, a tensão cai (2,5 V → 1,2 V) e a taxa de dados sobe.
- **RAM**: leitura-gravação, volátil. **ROM**: só leitura, gravada por máscara. **PROM**: ROM programável uma vez, por queima de diodos. **EPROM**: apagável com luz UV (chip inteiro). **EAROM**: alterável eletricamente, de forma lenta e parcial. **EEPROM**: apagável eletricamente, byte a byte, sem equipamento especial. **Flash**: apagável eletricamente em blocos, guarda a carga no gate flutuante do transistor.
- **Capacidade do disco** = bytes/setor × setores/trilha × trilhas/cilindro × cilindros.
- **Tempo de acesso ao disco** = tempo de busca (seek) + latência rotacional (+ tempo de transferência, em versões mais detalhadas da fórmula).
- **RAID 0**: striping, sem redundância. **RAID 1**: espelhamento. **RAID 3**: paridade por bit dedicada. **RAID 4**: paridade por bloco dedicada. **RAID 5**: paridade por bloco distribuída. **RAID 6**: dupla paridade, aguenta 2 falhas. **RAID 10**: espelhamento + striping (não citado no slide do professor).

## Cache (ver [[05 - Memória Cache - Conceitos e Estrutura]] e [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]])

- **Cache hit**: dado já está na cache. **Cache miss**: dado não está, é preciso buscar na memória principal.
- **Localidade temporal**: o que foi usado agora tende a ser usado de novo logo. **Localidade espacial**: os vizinhos do que foi usado tendem a ser usados logo, por isso a cache traz o bloco inteiro.
- **Cache Lógica**: antes da MMU, endereços virtuais, mais rápida, com problema de troca de contexto.
- **Cache Física**: depois da MMU, endereços físicos.
- **Mapeamento Direto**: $l = b \bmod m$, cada bloco só cabe em 1 linha. Simples, mas sofre misses de conflito.
- **Mapeamento Associativo**: bloco pode ir para qualquer linha, precisa buscar tudo e ter uma política de substituição.
- **Mapeamento Associativo por Conjunto ($k$-vias)**: meio-termo, com conjunto fixo (como no mapeamento direto) mas $k$ vias livres dentro do conjunto (como no associativo). $k=1$ via equivale ao mapeamento direto, $k$ igual ao total de linhas equivale ao totalmente associativo.
- **Políticas de substituição**: Randômica, Contador (relógio), LFU (menos frequente), LRU (menos usado recentemente), FIFO (o mais antigo entra e sai primeiro).
- **Cache multinível (L1/L2/L3)**: mais hits sem ir à memória principal, ao custo do tempo extra quando precisa consultar o próximo nível.
- **Bits de endereço em cache**: total de bits = $\log_2(\text{nº de palavras endereçáveis})$; bits de bloco = $\log_2(\text{nº de blocos})$; bits de Tag = total menos bloco (menos índice, se houver conjunto).

## Processador (ver [[09 - Processador e Datapath RISC-V (Microprocessador I)]])

- **ISA (Arquitetura de Conjunto de Instruções)**: define as instruções e como operam nos registradores. É a fronteira entre software e hardware.
- **Arquitetura**: qual ISA o processador usa. **Microarquitetura**: como aquele processador implementa a ISA (vários processadores Intel, todos x86).
- **Operandos**: as operações da ULA usam registradores como operandos.
- **Performance** $= \dfrac{1}{\text{Tempo de execução}}$. **Throughput** $= \dfrac{\text{tarefas executadas}}{\text{tempo}}$.
- **Tempo de CPU** $= \text{ciclos} \times \text{período} = \dfrac{\text{ciclos}}{\text{taxa de clock}}$
- **Nº de ciclos** $= \text{Nº de instruções} \times \text{CPI}$
- **Equação clássica**: $\text{Tempo de CPU} = \dfrac{\text{Nº de instruções} \times \text{CPI}}{\text{Taxa de clock}}$
- **Assembly RISC-V**: `{instrução} {destino} {fontes}`, ex.: `add x5, x6, x7` faz x5 = x6 + x7. Registradores x0 a x31 (x0 = zero, x1 = ra, x2 = sp, x10-x17 = argumentos).
- **Formatos**: R (`add`, `sub`, `and`, `or`), I (`lw`), S (`sw`), SB (`beq`).
- **Datapath**: componentes que fazem as operações (PC, memória de instrução, somador PC + 4, banco de registradores, ULA, gerador de imediato, memória de dados, somador do desvio, MUXes). **Controle**: comanda o datapath conforme a instrução.
- **Sinais de controle**: RegWrite (escreve no banco), ALUSrc (2º operando da ULA: registrador ou imediato), MemRead/MemWrite (lê/escreve memória de dados), MemtoReg (valor escrito vem da ULA ou da memória), PCSrc (PC + 4 ou desvio). PCSrc = Branch AND Zero.
- **Controle em dois blocos**: a unidade principal lê o opcode (bits 6-0) e gera Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite; o controle da ULA usa ALUOp + bits 30 e 14-12.
- **ALUOp**: 00 = soma (`lw`/`sw`, endereço), 01 = subtração (`beq`), 10 = olha funct7/funct3 (tipo R). **Linhas da ULA**: 0000 AND, 0001 OR, 0010 soma, 0110 subtração.
- **Sinais por instrução** (ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch): tipo R = 0 0 1 0 0 0; `lw` = 1 1 1 1 0 0; `sw` = 1 X 0 0 1 0; `beq` = 0 X 0 0 0 1.
- **Ciclo básico**: busca → decodificação → execução → armazenamento.
- **add**: lê 2 registradores, ULA opera, escreve no registrador. **lw**: ULA soma registrador + offset = endereço, lê a memória, escreve no registrador. **beq**: ULA subtrai; se deu 0, PC = PC + offset.

## Interrupções e E/S (ver [[10 - Interrupções e Entrada-Saída (Microprocessador III)]] e [[08 - Exercícios - Microprocessador III (Interrupções e E-S)]])

- **Interrupção**: evento especial que interrompe o ciclo normal de busca e execução. Pedido por um sinal de controle, o **IRQ** (Interrupt Request).
- **Tipos**: programa (overflow, divisão por zero, instrução ilegal, acesso fora da memória permitida), timer, E/S, falha de hardware.
- **Atendimento**: termina a instrução atual, salva o contexto (PC e dados relevantes), carrega no PC o endereço da rotina de tratamento, executa e volta para a instrução seguinte.
- **Verificação de interrupção**: etapa no fim de cada instrução, só quando as interrupções estão habilitadas.
- **Interrupções aninhadas**: uma rotina de prioridade maior interrompe outra de prioridade menor.
- **Módulo de E/S**: controle e temporização, comunicação com o processador e com o dispositivo, buffering de dados, detecção de erro.
- **E/S programada**: CPU verifica o dispositivo sem parar (perda de tempo). Ex.: sensor simples.
- **E/S por interrupção**: CPU manda o comando e continua; o dispositivo interrompe quando fica pronto. Ex.: teclado e mouse.
- **DMA**: módulo de E/S e memória trocam dados direto, sem a CPU; uma interrupção no fim do bloco. Ex.: placa de vídeo, disco.
- **Cycle stealing**: o DMA rouba ciclos de barramento entre os ciclos do processador, no meio da instrução, sem salvar contexto.

## Prefixos binários usados nos exemplos

| Unidade | Valor usado nos slides |
|---|---|
| 1 KB | $2^{10}$ = 1.024 bytes |
| 1 MB | $2^{20}$ bytes |
| 1 GB | $2^{30}$ = 1.073.741.824 bytes |

> [!note] Atenção
> Nem toda documentação técnica usa base 2 para KB/MB/GB (discos comerciais costumam anunciar capacidade em base 10). Os exemplos numéricos destas notas seguem a convenção usada pelos próprios slides do professor (base 2), que foi a que bateu com os resultados finais mostrados no material. Não é uma regra universal da indústria.

## Pontos sinalizados como possível erro no material original

Para referência rápida, os pontos onde os slides originais parecem ter uma inconsistência, todos documentados com mais detalhe na nota de origem:

1. [[02 - Barramentos (Buses)]]: "T = 1,51·10⁻⁸ = 151,15 µs" (a unidade deveria ser aproximadamente 15,15 ns).
2. [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]: passo 9 do exemplo de mapeamento direto, símbolo "≠" onde o contexto indica igualdade (cache hit).
3. [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]: "2048 · 25 = 512000 bits" (a conta direta dá 51.200; o resultado final em bytes do próprio slide é consistente com 51.200, não com 512.000).
4. [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]: o slide 42 define LRU como "a posição ocupada por mais tempo", frase que descreve o FIFO; a definição usual é "a posição há mais tempo sem ser acessada".
5. [[10 - Interrupções e Entrada-Saída (Microprocessador III)]]: "timer dentro do processo" (deveria ser processador).
6. [[09 - Processador e Datapath RISC-V (Microprocessador I)]]: notação `lw x1, (offset)x2` e `beq, x1, x2, offset`, fora da forma usual do Assembly RISC-V (`lw x1, offset(x2)` e `beq x1, x2, offset`); e o exemplo `swap` do slide 5 usa `slli ..., 3` com deslocamentos de 4 bytes.
7. [[00b - Introdução e Contexto Histórico]]: "Máquina Analítica (1820)"; por volta de 1822 Babbage trabalhava na Máquina Diferencial, e os documentos da Analítica são de cerca de 1837.

Se você confirmar com o professor qual é a versão correta de cada um, vale atualizar estas notas.
