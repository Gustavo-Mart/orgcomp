---
tags: [organização-de-computadores, memória, ram, hierarquia-de-memória]
fonte: OrgComp04_Memoria.pdf (slides 2-12) e OrgComp03_MemoriaCache.pdf (slides 3-5, revisão idêntica)
---

# Hierarquia e Tipos de Memória

← [[02 - Barramentos (Buses)]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]]

> [!info] Nota sobre sobreposição de conteúdo
> Os slides 3-5 do deck de Memória Cache repetem quase literalmente os slides 3-5 deste deck, com a mesma tabela de características e a mesma pirâmide de hierarquia. Isso é intencional do professor: é a "aula passada" revisada antes de entrar em cache. Por isso o conteúdo comum está consolidado aqui, e [[05 - Memória Cache - Conceitos e Estrutura]] só referencia esta nota.

## 1. Retomando: o segundo bloco principal da arquitetura von Neumann

Depois de barramentos ([[02 - Barramentos (Buses)]]), o professor passa a analisar o segundo bloco principal do computador: a Memória, com foco em seus tipos.

## 2. Principais características dos sistemas de memória

| Categoria | Opções/valores |
|---|---|
| Localização | Interna (registradores do processador, memória principal, cache) / Externa (discos ópticos, discos magnéticos, fitas) |
| Desempenho | Tempo de acesso / Tempo de ciclo / Taxa de transferência |
| Tipo físico | Semicondutor / Magnético / Óptico / Magneto-óptico |
| Método de acesso | Sequencial / Direto / Aleatório / Associativo |
| Unidade de transferência | Palavra / Bloco |
| Características físicas | Volátil ou não volátil / Apagável ou não apagável |
| Capacidade | Número de palavras / Número de bytes |
| Organização | Módulos de memória |

## 3. Pirâmide de hierarquia de memória

De cima (topo) para baixo (base):

```
                Registradores
             ┌───────────────┐
             │     Cache     │   Memória interna
             ├───────────────┤
             │ Memória       │
             │ principal     │
             ├───────────────┴────────────────────┐
             │  Disco magnético · CD-ROM · DVD-ROM │  Armazenamento
             │  DVD-RW · DVD-RAM · Blu-Ray          │  externo
             ├──────────────────────────────────────┤
             │           Fita magnética              │  Armazenamento
             └────────────────────────────────────────┘  offline

        Maior hierarquia (subindo) ⇒ Maior custo por bit
```

A regra de ouro do slide é: "Maior hierarquia ⇒ Maior custo". Subindo na pirâmide você ganha velocidade, mas paga mais caro por bit e tem menos capacidade. Descendo, você ganha capacidade e barateia o bit, mas perde velocidade.

### Uma segunda pirâmide (específica da memória RAM)

O deck de Memória traz uma segunda pirâmide, focada em variações de tecnologia dentro e ao redor da RAM, incluindo memórias emergentes (não voláteis de próxima geração, citadas ao lado de cada faixa):

```
                    SRAM            (também citada: STT-RAM)
                ───────────
                   DRAM             (também citada: PCRAM)
              ─────────────────
               FLASH NAND
        ───────────────────────
              DISCO RÍGIDO         (também citada: ReRAM)

  topo: desempenho e durabilidade aumentados
  base: custo decrescente por bit, capacidade/densidade crescentes
```

> [!note] Sobre STT-RAM, PCRAM e ReRAM
> Essas siglas aparecem apenas rotulando cada faixa da pirâmide, sem explicação adicional no slide. São memórias não voláteis emergentes (STT-RAM é spin-transfer torque RAM, PCRAM é phase-change RAM, e ReRAM é resistive RAM). Não tenho uma fonte no material do professor detalhando essas tecnologias, então não vou aprofundar além do que está no slide. Se cair em prova, vale perguntar em aula se é só para reconhecer o nome ou se será cobrado o funcionamento.

## 4. Operações na célula de memória

Toda célula de memória suporta duas operações básicas, controladas por um sinal de Controle e um sinal de Selecionar:

- **Escrita**: `Selecionar` aponta a célula, `Controle` indica operação de escrita, e a Entrada de dados é gravada na célula.
- **Leitura**: `Selecionar` aponta a célula, `Controle` indica operação de leitura, e a célula entrega o valor pela Saída de dados.

## 5. Tipos de memória com semicondutor

Tabela completa do slide (memória semicondutora tem a vantagem de integração mais fácil com o processador):

| Tipo de memória | Categoria | Apagamento | Mecanismo de gravação | Volatilidade |
|---|---|---|---|---|
| RAM (Random Access Memory) | Leitura-gravação | Eletricamente, em nível de byte | Eletricamente | Volátil |
| ROM (Read-Only Memory) | Somente leitura | Não é possível | Máscaras (gravada na fabricação) | Não volátil |
| PROM (Programmable ROM) | Somente leitura | Não é possível | Eletricamente | Não volátil |
| EPROM (Erasable PROM) | Principalmente leitura | Luz UV, em nível de chip | Eletricamente | Não volátil |
| EEPROM (Electrically Erasable PROM) | Principalmente leitura | Eletricamente, em nível de byte | Eletricamente | Não volátil |
| Memória Flash | Principalmente leitura | Eletricamente, em nível de bloco | Eletricamente | Não volátil |

> [!note] Tabela conferida com o slide 6 (revisão de 18/10/2026)
> A versão anterior desta nota tinha um erro meu na coluna "Mecanismo de gravação". No slide, só a ROM é gravada por **máscaras**. PROM, EPROM, EEPROM e Flash são todas gravadas **eletricamente** (é uma célula mesclada no slide). O que diferencia essas quatro é o apagamento: não é possível (PROM), luz UV no chip inteiro (EPROM), elétrico por byte (EEPROM) ou elétrico por bloco (Flash).

### 5.1 Complemento de pesquisa: como PROM, EPROM e EEPROM realmente diferem na gravação

A tabela acima já mostra o essencial, mas vale detalhar o mecanismo físico de cada uma, algo que o slide não descreve. Segundo material aberto sobre o assunto: a PROM é gravada uma única vez, com um dispositivo específico que queima matrizes de diodo dentro do chip (uma reação física irreversível). A EPROM permite regravação, mas o apagamento exige um dispositivo específico de luz ultravioleta que apaga o chip inteiro através de uma janela de quartzo visível no encapsulamento, antes de uma nova gravação ser possível. Existe ainda a EAROM (Electrically Alterable ROM), não citada no slide do professor, que permite alteração eletrônica parcial dos dados, sem luz UV, mas de forma lenta. A EEPROM é a evolução dessa ideia: apaga e regrava eletricamente, sem equipamento especial, byte a byte, e foi essa linha de evolução que deu origem à memória Flash.

Sources:
- [PROM, EPROM, EAROM, EEPROM: o que significam esses termos? - Maxieduca](https://blog.maxieduca.com.br/prom-eprom-earom-eeprom/)

### DRAM vs. SRAM

| | DRAM (Dinâmica) | SRAM (Estática) |
|---|---|---|
| Construção | Mais simples e menor | Mais complexa |
| Custo | Mais barata | Mais cara |
| Refresh | Precisa de sinal de *refresh* periódico | Não precisa, a célula mantém o valor sozinha enquanto energizada |
| Capacidade | Permite memórias maiores | Menor densidade |
| Velocidade | Mais lenta | Mais rápida |
| Uso típico | Memória principal | Memória Cache |

> [!tip] Por que DRAM precisa de refresh e SRAM não
> A célula de DRAM guarda o bit como carga em um capacitor, que vaza aos poucos, por isso precisa ser "relembrada" (refresh) periodicamente. A célula de SRAM guarda o bit em um par de portas lógicas realimentadas, um latch, que mantém o estado estável enquanto houver energia, sem vazamento. Daí ela ser mais rápida, mas também maior e mais cara por bit, com mais transistores por célula.

### 5.2 Células de DRAM e SRAM (figura do slide 7)

A figura do slide 7 mostra as duas células lado a lado. A **célula de DRAM** tem 1 transistor e 1 capacitor de armazenamento, ligados à linha de endereço e à linha de bit B. A **célula de SRAM** tem 6 transistores (T1 a T6), alimentados pela voltagem cc, com uma linha de endereço e duas linhas de bit (B e B negado). Por isso a DRAM é menor e mais barata por bit, e a SRAM é maior e mais cara. O texto do slide resume a SRAM como "mais rápida, todas as células precisam estar energizadas" e "utilizada para memórias cache".

Complemento de pesquisa sobre o funcionamento (não está no slide): os 6 transistores da SRAM formam um circuito biestável, parecido com um flip-flop, que mantém o dado sozinho enquanto há energia. Na DRAM (1T1C), a carga do capacitor vaza mesmo com a alimentação ligada, o que exige os ciclos de refresh.

Sources:
- [SRAM vs DRAM | Comparison, Basic Structures and Differences - ElectronicsHub](https://www.electronicshub.org/sram-vs-dram/)

### Matriz de memória

Diagrama do slide: uma grade de células de memória organizada em linhas (`Row Select 0`, `Row Select 1`, `Row Select 2`, ..., `Row Select n`) e colunas de bits de dados (`Data I/O Bit 0` a `Bit 3`), com um bloco de "Data Input/Output Buffers and Control" na base coordenando a leitura e a escrita, e um detalhe ampliado de uma célula de memória (Memory cell) individual no canto.

### DDR-SDRAM

SDRAM (Synchronous DRAM) é usada na memória principal. Seu acesso é síncrono, com um clock externo: o endereço é apresentado à RAM, a RAM localiza os dados, e como a SDRAM move dados em sincronia com o clock do sistema, a CPU sabe exatamente quando os dados estarão prontos. Ela não precisa ficar esperando no escuro e pode fazer outra coisa enquanto aguarda.

DDR (Double Data Rate) SDRAM envia dados duas vezes por ciclo de clock, aproveitando tanto a transição de subida quanto a de descida do sinal de clock, dobrando a taxa de transferência efetiva sem dobrar a frequência do clock.

Tabela do slide 9 com as gerações de DDR:

| | DDR1 | DDR2 | DDR3 | DDR4 |
|---|---|---|---|---|
| Buffer de pré-busca (bits) | 2 | 4 | 8 | 8 |
| Nível de voltagem (V) | 2,5 | 1,8 | 1,5 | 1,2 |
| Taxa de dados do barramento frontal (Mbps) | 200-400 | 400-1.066 | 800-2.133 | 2.133-4.266 |

A cada geração a tensão cai (menos consumo) e a taxa de dados sobe. A tabela do slide para no DDR4. O DDR5 já é vendido, mas não aparece no slide e não conferi os números dele.

O slide inclui um diagrama de blocos de um chip SDRAM de 256 Mb, mostrando os principais componentes internos: decodificador de comando e gerador de clock, registrador de modo, controlador de *refresh* e contador de *refresh*, latch/decodificador de endereço de linha, multiplexador, array de células de memória (4 Mb × 16, Banco 0 DRAM), buffer/contador de endereço de coluna, decodificador de coluna e buffers de entrada/saída de dados (DQ 0-15). É um exemplo de como a arquitetura interna de um chip de memória real coordena refresh, endereçamento e transferência de dados.

### Memória Flash

Armazena a informação da célula de memória diretamente no gate do transistor, em uma célula de porta flutuante, o que permite reter o dado sem energia (memória não volátil).

A figura do slide 11 tem três desenhos: (a) um transistor comum, com a porta de controle sobre o substrato P, entre o dreno e a fonte (N+); (b) a célula flash no **estado 1**, com uma **porta flutuante** entre a porta de controle e o substrato, sem carga; (c) a célula flash no **estado 0**, com elétrons presos na porta flutuante. Resumindo: elétrons presos = 0, sem carga = 1. O mecanismo físico está no complemento 8.1 de [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]].

## 6. Diferenças entre os níveis da hierarquia (síntese para a prova)

A prova pede a hierarquia e as diferenças entre os níveis. O slide não traz uma tabela pronta; montei esta juntando os slides 3, 4, 7, 12 e 13 deste deck e o slide 4 do Microprocessador I.

| Nível (topo → base) | Tecnologia | Volátil? | Como a CPU acessa | Onde fica |
|---|---|---|---|---|
| Registradores | Circuitos dentro da CPU | Sim | Direto: são os operandos das instruções (ver [[09 - Processador e Datapath RISC-V (Microprocessador I)]]) | Memória interna |
| Cache (L1, L2, L3) | SRAM | Sim | Direto: a CPU pede a palavra à cache | Memória interna |
| Memória principal | DRAM (SDRAM, DDR) | Sim | Direto, pelo barramento do sistema | Memória interna |
| Secundária | Disco magnético, CD/DVD/Blu-Ray, flash NAND (SSD) | Não | Só por intermédio da memória principal | Armazenamento externo |
| Offline | Fita magnética | Não | Só por intermédio da memória principal | Armazenamento offline |

Regra geral dos slides 4 e 12: **subindo** na pirâmide, mais desempenho e mais custo por bit ("Maior hierarquia ⇒ Maior custo"); **descendo**, custo por bit menor e capacidade (densidade) maior. A cache, por exemplo, guarda cópias de blocos da memória principal (ver [[05 - Memória Cache - Conceitos e Estrutura]]), e a memória principal guarda o que a CPU vai usar da memória secundária.

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 5. Pearson, 2017.
- David Patterson e John Hennessy. *Computer Organization and Design, RISC-V Edition*. Morgan Kaufmann, 2018.
- Sarah Harris e David Harris. *Digital design e computer architecture*. Morgan Kaufmann, 2015.
