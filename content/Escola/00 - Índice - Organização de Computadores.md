---
tags: [MOC, organização-de-computadores, unisantos]
disciplina: Organização de Computadores
professor: Walter Silva Oliveira (UNISANTOS)
---

# Organização de Computadores: Guia de Estudo

Este é o índice (Mapa de Conteúdo) do guia de estudo montado a partir dos slides do professor Walter Silva Oliveira (UNISANTOS). Cada link abaixo abre uma nota-tópico com explicação completa, exemplos resolvidos e exercícios.

> [!info] Sobre este material
> As notas foram escritas a partir de sete decks de slides:
> - `OrgComp01_Introducao.pdf` (2025): **Introdução ao curso**: ementa, avaliação, motivação, linha do tempo histórica, power wall e RISC-V (nota 00b).
> - `OrgComp02_vonNeuman.pdf` (2026): na prática, é a aula sobre **Barramentos**, usando a arquitetura von Neumann como revisão de contexto.
> - `OrgComp03_MemoriaCache.pdf` (2025): **Memória Cache**.
> - `OrgComp04_Memoria.pdf` (2025): **Memória Principal e Secundária**.
> - `OrgComp06_Microprocessador_I.pdf` (2025): **Processador**: ISA, desempenho e datapath RISC-V (nota 09).
> - `OrgComp07_Microprocessador_III.pdf` (2025): **Interrupções e Entrada/Saída** (teoria na nota 10, exercícios na nota 08).
>
> - `ArqComp_Aula4-Revisao.pdf` (Microarquitetura de Ciclo Único, da disciplina Arquitetura de Computadores do mesmo professor): **controle do processador**, usado na nota 09.
>
> A aula sobre a ULA e a de pipeline RISC-V, citadas no resumo do Microprocessador III, não estão neste vault. Última revisão contra os slides: 18/10/2026.
>
> Onde os slides trazem só um diagrama, sem texto de apoio, descrevi o diagrama por extenso. Onde percebi uma inconsistência numérica no slide original, marquei isso com um aviso em vez de simplesmente repetir o número. Trechos marcados como "solução sugerida" são complementos meus, que não estavam resolvidos no slide. Confira com o professor ou a monitoria antes de usá-los para valer nota.

## Conteúdo da prova

Lista passada no quadro, com a nota onde cada item está. Regras: prova no Moodle, pode levar **1 folha A4 de consulta (só a frente)**, **sem exercícios resolvidos** na folha.

- [ ] **1. Arquitetura von Neumann**: [[01 - Arquitetura von Neumann e Estrutura do Computador]] (contexto histórico em [[00b - Introdução e Contexto Histórico]])
- [ ] **2. Barramento**: características, tipos de barramento e gargalos: [[02 - Barramentos (Buses)]]
- [ ] **3. Memória cache**
    - [ ] Localidade temporal e espacial: [[05 - Memória Cache - Conceitos e Estrutura]]
    - [ ] Mapeamento direto (mod), associativo (políticas de substituição) e associativo por conjunto: [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]
- [ ] **4. Processador**
    - [ ] Ciclo de busca e execução: versão curta em [[09 - Processador e Datapath RISC-V (Microprocessador I)]], versão detalhada em [[10 - Interrupções e Entrada-Saída (Microprocessador III)]]
    - [ ] Funcionamento do circuito de controle: [[09 - Processador e Datapath RISC-V (Microprocessador I)#10. Funcionamento do circuito de controle|nota 09, seção 10]]
    - [ ] Execução dos 3 tipos de instrução vistos (`add`, `lw`, `beq`): [[09 - Processador e Datapath RISC-V (Microprocessador I)#11. Execução dos 3 tipos de instrução (slides 18-20; slides 18-23 do deck de ciclo único)|nota 09, seção 11]]
- [ ] **5. Memória principal**: hierarquia de memória e diferenças entre os níveis: [[03 - Hierarquia e Tipos de Memória]] (a seção 6 tem a tabela de diferenças)
- [ ] **6. Entrada e saída**: conceito de interrupção, tipos de E/S, DMA: [[10 - Interrupções e Entrada-Saída (Microprocessador III)]] e [[08 - Exercícios - Microprocessador III (Interrupções e E-S)]]

> [!note] E a nota 04 (discos, RAID, SSD)?
> A memória secundária aparece como base da pirâmide no tópico 5, mas RAID, cálculo de capacidade de disco e SSD não estão na lista do quadro. Vale uma revisão rápida de [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]] só pela parte da hierarquia.

## Trilha de estudo sugerida

1. [[00b - Introdução e Contexto Histórico]]
2. [[01 - Arquitetura von Neumann e Estrutura do Computador]]
3. [[02 - Barramentos (Buses)]]
4. [[03 - Hierarquia e Tipos de Memória]]
5. [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]]
6. [[05 - Memória Cache - Conceitos e Estrutura]]
7. [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]]
8. [[09 - Processador e Datapath RISC-V (Microprocessador I)]]
9. [[10 - Interrupções e Entrada-Saída (Microprocessador III)]]
10. [[08 - Exercícios - Microprocessador III (Interrupções e E-S)]], exercícios resolvidos sobre interrupções, E/S programada e DMA
11. [[07 - Glossário e Fórmulas]], para consulta rápida de termos e fórmulas

## Mapa mental da disciplina

```
Computador (von Neumann)
├── Origem: Babbage, Boole, Hilbert, Gödel, Turing, Church, Shannon, von Neumann (1945)
├── CPU (Unidade de Controle + ULA + Registradores)
│   ├── ISA x microarquitetura; desempenho (CPI, tempo de CPU)
│   ├── Datapath RISC-V (PC, memória de instrução, banco de registradores, ULA, memória de dados)
│   ├── Controle (RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, PCSrc)
│   └── Ciclo: busca → decodificação → execução → armazenamento (+ verificação de interrupção)
├── Memória
│   ├── Hierarquia (Registrador → Cache → RAM → Disco → Fita)
│   ├── Principal (RAM: DRAM/SRAM, SDRAM/DDR; ROM/PROM/EPROM/EEPROM/Flash)
│   ├── Cache (Direto, Associativo, Associativo por Conjunto)
│   └── Secundária (HD, RAID, SSD)
├── Barramento (Dados, Endereço, Controle: Local, Sistema, Alta Velocidade, Expansão)
└── Entrada/Saída
    ├── Módulo de E/S
    ├── Interrupções (programa, timer, E/S, falha de hardware; IRQ)
    └── Acesso: programada, por interrupção, DMA (cycle stealing)
```

## Referências citadas nos slides

- William Stallings. *Arquitetura e Organização de Computadores*. Pearson, 2017 (Capítulos 3 e 5).
- David Patterson e John Hennessy. *Computer Organization and Design, RISC-V Edition*. Morgan Kaufmann, 2018.
- Sarah Harris e David Harris. *Digital Design and Computer Architecture*. Morgan Kaufmann, 2015.
- Material produzido com base nas notas de aula do Prof. Dr. Thiago Ferauche.

Não tenho como confirmar edições, páginas exatas ou ISBNs desses livros além do que aparece nos próprios slides. Se precisar citar formalmente, verifique os dados na edição física ou no catálogo da editora. Também não tive acesso direto ao conteúdo desses três livros, então os complementos de pesquisa abaixo vêm de outras fontes abertas na web que cobrem o mesmo conteúdo padrão da disciplina, não desses livros específicos.

## Fontes de pesquisa complementar

Cada nota-tópico tem uma ou mais seções marcadas como "Complemento de pesquisa", deixando claro o que veio do slide do professor e o que foi acrescentado depois via busca na web para aprofundar o assunto. As fontes usadas foram:

- [Imagining AI: Babbage & Lovelace - History of Science Museum, Oxford](https://hsm.ox.ac.uk/imagining-ai): datas da Máquina Diferencial, da Máquina Analítica e das notas de Lovelace (ver [[00b - Introdução e Contexto Histórico]])
- [The Analytical Engine: 28 Plans and Counting - Computer History Museum](https://computerhistory.org/blog/the-analytical-engine-28-plans-and-counting/): trabalho de Babbage a partir de 1822 (ver [[00b - Introdução e Contexto Histórico]])
- [Difference between Von Neumann and Harvard Architecture - GeeksforGeeks](https://www.geeksforgeeks.org/computer-organization-architecture/difference-between-von-neumann-and-harvard-architecture/): gargalo de von Neumann (ver [[01 - Arquitetura von Neumann e Estrutura do Computador]])
- [Unidade de controle - Wikipédia](https://pt.wikipedia.org/wiki/Unidade_de_controle): unidade de controle cabeada vs. microprogramada (ver [[01 - Arquitetura von Neumann e Estrutura do Computador]])
- [BUS Arbitration in Computer Organization - GeeksforGeeks](https://www.geeksforgeeks.org/bus-arbitration-in-computer-organization/): técnicas de arbitração centralizada (ver [[02 - Barramentos (Buses)]])
- [O que é o PCI Express (PCIe): guia completo - 4infra](https://4infra.com.br/o-que-e-o-pci-express-2025/): lanes e gerações do PCIe (ver [[02 - Barramentos (Buses)]])
- [SRAM vs DRAM | Comparison, Basic Structures and Differences - ElectronicsHub](https://www.electronicshub.org/sram-vs-dram/): contagem de transistores por célula (ver [[03 - Hierarquia e Tipos de Memória]])
- [PROM, EPROM, EAROM, EEPROM: o que significam esses termos? - Maxieduca](https://blog.maxieduca.com.br/prom-eprom-earom-eeprom/): mecanismo de gravação/apagamento de cada tipo (ver [[03 - Hierarquia e Tipos de Memória]])
- [Difference between Rotational Latency and Disk Access Time - GeeksforGeeks](https://www.geeksforgeeks.org/operating-systems/difference-between-rotational-latency-and-disk-access-time-in-disk-scheduling/): fórmulas de tempo de busca, latência e acesso (ver [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]])
- [Comparing RAID levels: 0, 1, 5, 6, 10 and 50 explained - TechTarget](https://www.techtarget.com/it-infrastructure/feature/Comparing-RAID-levels-0-1-5-6-10-and-50-explained): RAID 10 (ver [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]])
- [What is NAND Flash Memory? - IBM](https://www.ibm.com/think/topics/nand-flash): funcionamento da célula NAND e da porta flutuante (ver [[04 - Memória Secundária e Discos (HDD, RAID, SSD)]])
- [What is Memory Management Unit (MMU)? - GeeksforGeeks](https://www.geeksforgeeks.org/computer-organization-architecture/what-is-memory-management-unit/): tradução de endereço virtual em físico (ver [[05 - Memória Cache - Conceitos e Estrutura]])
- [Difference between Direct-mapping, Associative Mapping & Set-Associative Mapping - GeeksforGeeks](https://www.geeksforgeeks.org/difference-between-direct-mapping-associative-mapping-set-associative-mapping/): resumo de trade-offs por campos de endereço (ver [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]])
- [It's Time to Revisit LRU vs. FIFO - IBM Research](https://research.ibm.com/publications/its-time-to-revisit-lru-vs-fifo): pesquisa recente questionando quando LRU realmente vale mais que FIFO (ver [[06 - Mapeamento de Cache (Direto, Associativo, Por Conjunto)]])

> [!note] Por que não citei diretamente Stallings, Patterson e Hennessy, ou Harris e Harris nos complementos
> Não tenho como abrir ou pesquisar o conteúdo desses livros específicos para confirmar o que cada um diz literalmente. Em vez de arriscar atribuir uma afirmação a um livro que não pude conferir, usei fontes abertas da web (todas linkadas acima) que tratam do mesmo conteúdo padrão de Organização de Computadores. Para aprofundar exatamente pelos livros indicados pelo professor, vale consultá-los diretamente na biblioteca da UNISANTOS.
