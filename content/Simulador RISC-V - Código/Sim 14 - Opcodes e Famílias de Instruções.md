---
tags: [projeto-final, simulador, risc-v, rv32i, opcode, formatos-de-instrução, lw, sw, desvios]
---

# Opcodes e famílias de instruções (R, I, Load, Store, Branch)

← [[Sim 05 - Cpu (Processador)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 06 - Rastreio de uma Instrução Bit a Bit]]

Esta nota explica o que são os opcodes que aparecem no começo do `Cpu.cs` e as cinco famílias de instruções que o simulador executa. É a base para entender o `switch (opcode)` do `Passo()`, explicado em [[Sim 05 - Cpu (Processador)]].

## 1. O que é o opcode

Toda instrução do RISC-V tem 32 bits. Os **7 bits mais à direita** (bits 6 a 0) são sempre o **opcode**: o código que diz **que tipo de instrução** é aquela. É a primeira coisa que a CPU olha na decodificação.

```csharp
public const int OpR      = 0b0110011;
public const int OpI      = 0b0010011;
public const int OpLoad   = 0b0000011;
public const int OpStore  = 0b0100011;
public const int OpBranch = 0b1100011;
public const int OpSystem = 0b1110011;
```

Os valores ao lado de cada nome são esses 7 bits escritos em **binário**. O `0b` na frente avisa o C# que o número está em binário, do mesmo jeito que o `0x` avisa que está em hexadecimal. Então `0b0110011` é o número 51, ou `0x33`.

Esses números não foram inventados para o projeto: vêm da especificação oficial do RISC-V, e qualquer processador ou compilador RISC-V usa os mesmos.

Na decodificação, a CPU separa o opcode com uma máscara:

```csharp
int opcode = inst & 0x7F;   // 0x7F = 1111111: fica só com os 7 bits de baixo
```

Depois, o `switch (opcode)` escolhe o caminho.

> [!important] O opcode diz a família, não a instrução exata
> `add` e `sub` têm o mesmo opcode (`OpR`). O que separa uma da outra são outros campos: o `funct3` (3 bits) e o `funct7` (7 bits).
> ```
>  funct7   rs2   rs1  funct3  rd    opcode
> 0000000  00110 00101  000  00111  0110011   → add t2, t0, t1
> 0100000  00110 00101  000  00111  0110011   → sub t2, t0, t1
> ```

A ideia que liga tudo: **o opcode diz a família, a família diz o formato, e o formato diz onde está cada campo nos 32 bits.**

## 2. Tipo R: conta entre dois registradores

**O que faz:** pega dois registradores, faz uma operação e guarda o resultado num terceiro.

```
add t2, t0, t1      # t2 = t0 + t1
```

Em C, seria algo como `c = a + b;`, com as três variáveis já dentro da CPU.

**Os bits:**

```
 funct7   rs2    rs1  funct3   rd    opcode
0000000  00110  00101  000   00111  0110011
         (t1)   (t0)         (t2)    (OpR)
```

| Campo | Para que serve |
|---|---|
| `rs1`, `rs2` | os dois registradores de origem (5 bits cada, de 0 a 31) |
| `rd` | o registrador de destino |
| `funct3` e `funct7` | qual operação, entre as 10 da família |

**Instruções da família:** `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`.

O "R" vem de *register*: os dois operandos são registradores.

## 3. Tipo I: conta com uma constante

**O que faz:** igual ao tipo R, mas o segundo operando é um **número fixo escrito dentro da própria instrução**, chamado de **imediato**.

```
addi t0, t0, 1      # t0 = t0 + 1
```

Em C: `i = i + 1;`. O `1` não está em nenhum registrador: ele faz parte da instrução.

**Os bits:**

```
  imediato (12 bits)   rs1  funct3   rd    opcode
 000000000001         00101  000   00101  0010011
     (1)              (t0)         (t0)    (OpI)
```

Como não precisa de `rs2` nem de `funct7`, esses 12 bits de cima viram o imediato, que vai de **-2048 a 2047**. É por isso que, sem a instrução `lui`, o programa não consegue carregar `0x80000` com um `addi` só.

**Instruções da família:** `addi`, `andi`, `ori`, `xori`, `slti`, `sltiu`, `slli`, `srli`, `srai`. O `cpop` (POPCNT, instrução do grupo 4) também usa esse opcode.

O "I" vem de *immediate*. Não existe `subi`, porque `addi` com número negativo faz o mesmo.

## 4. Load (`lw`): ler da memória

**O que faz:** calcula um endereço (registrador + imediato), lê 4 bytes da memória nesse endereço e coloca num registrador. `lw` vem de *load word*, "carregar palavra", e palavra aqui quer dizer 32 bits.

```
lw a0, 8(s0)        # a0 = memória[s0 + 8]
```

Em C: `x = v[2];`, em que `s0` aponta para o começo do vetor `v` e cada `int` ocupa 4 bytes.

**Os bits:** usa o **mesmo formato do tipo I**. Só muda o opcode:

```
  imediato (12 bits)   rs1  funct3   rd    opcode
 000000001000         01000  010   01010  0000011
     (8)              (s0)  (lw)   (a0)   (OpLoad)
```

Aqui o imediato não é somado a um número: ele é o **deslocamento** do endereço. A ULA faz `s0 + 8`, e o resultado vai para a memória como endereço.

## 5. Store (`sw`): gravar na memória

**O que faz:** calcula um endereço (registrador + imediato) e grava nesse endereço o valor de **outro** registrador. `sw` vem de *store word*, "guardar palavra".

```
sw t0, 4(sp)        # memória[sp + 4] = t0
```

Em C: `v[1] = x;`.

**Os bits:** aqui aparece um formato novo, o **tipo S**. O `sw` precisa de **dois** registradores (o do endereço e o do valor) e **não tem** registrador de destino, porque não escreve em nenhum. Então o lugar onde ficaria o `rd` passa a guardar parte do imediato:

```
 imm[11:5]  rs2    rs1  funct3  imm[4:0]  opcode
 0000000   00101  00010  010    00100    0100011
           (t0)   (sp)  (sw)    (4)     (OpStore)
```

O imediato fica **partido em dois pedaços**: 7 bits em cima e 5 embaixo. O RISC-V faz isso para que `rs1` e `rs2` fiquem **sempre na mesma posição** em todos os formatos. Assim o hardware pode ler os registradores antes mesmo de saber qual é a instrução.

## 6. Por que `lw` e `sw` são especiais

A CPU só faz contas com registradores, e são só 32 deles. Tudo o que não cabe ali fica na memória: vetores, textos, variáveis que não estão em uso no momento, a pilha. O padrão é sempre o mesmo:

1. `lw` traz o dado para um registrador;
2. as instruções de conta (`add`, `sub`...) trabalham com ele;
3. `sw` devolve o resultado para a memória.

Por isso o RISC-V é chamado de arquitetura **load/store**: só essas instruções acessam a memória. Em outras arquiteturas, como o x86, um `add` pode somar direto com um valor que está na memória.

O endereço sempre tem a forma **registrador base + deslocamento** (`8(s0)`). É o jeito natural de acessar vetores e estruturas: o registrador aponta para o começo, e o deslocamento diz qual posição.

**Regras no simulador:**
- o endereço precisa ser **múltiplo de 4**, senão dá o erro "Acesso desalinhado";
- os bytes ficam em **little-endian**: com `sw` de `0x41424344` no endereço `0x100`, o byte `0x44` fica em `0x100` e o `0x41` em `0x103`;
- não dá para escrever na **área reservada** (`0x90000` a `0x9FBFF`).

**No ciclo da instrução**, `lw` e `sw` são as únicas que usam o barramento **duas vezes**: uma na busca da própria instrução e outra para o dado.

| Etapa | `lw` | `sw` |
|---|---|---|
| Busca | lê a instrução | lê a instrução |
| Execução | a ULA soma `rs1 + deslocamento` para achar o endereço | igual |
| Acesso à memória | lê o dado pelo barramento | grava o dado pelo barramento |
| Armazenamento | guarda o dado em `rd` | nada (não muda registrador) |

**Na E/S programada**, o `sw` é o que coloca texto na tela: `sw t0, 0(s1)` com `s1 = 0x80000` grava 4 caracteres no começo da VRAM. O mesmo `sw` que guarda um número na RAM coloca letras na tela, só mudando o endereço. Ver [[Sim 11 - Video (E-S Programada)]].

## 7. Branch (desvio): pular se a condição for verdadeira

**O que faz:** compara dois registradores. Se a condição for verdadeira, o programa **pula** para outro ponto. Se for falsa, segue para a próxima instrução normalmente.

```
blt t0, t1, laco    # se t0 < t1, volta para "laco"
```

Em C, é o que existe por trás de `if`, `while` e `for`:

```c
for (i = 1; i < 11; i++) soma += i;
```

Esse laço vira um `add`, um `addi` e um `blt` que volta para o começo enquanto `i < 11`.

**Os bits:** é o **tipo B**, parecido com o tipo S (dois registradores, sem destino). O imediato agora é a **distância do salto em bytes**, contada a partir da própria instrução do desvio. Ele pode ser negativo, e é assim que um laço volta.

```
 imm   rs2    rs1  funct3  imm  opcode
 ...  00110  00101  100    ...  1100011
      (t1)   (t0)  (blt)       (OpBranch)
```

Os bits do imediato vêm embaralhados, pelo mesmo motivo do tipo S: manter `rs1`, `rs2` e o bit de sinal sempre no mesmo lugar. Como montar e desmontar esse imediato está em [[Sim 05 - Cpu (Processador)]] (`ImediatoB`).

| Instrução | Pula se | Comparação |
|---|---|---|
| `beq` | `rs1 == rs2` | igual |
| `bne` | `rs1 != rs2` | diferente |
| `blt` | `rs1 < rs2` | menor, com sinal |
| `bge` | `rs1 >= rs2` | maior ou igual, com sinal |
| `bltu` | `rs1 < rs2` | menor, sem sinal |
| `bgeu` | `rs1 >= rs2` | maior ou igual, sem sinal |

## 8. System: `ecall` e `ebreak`

```csharp
public const int InstEcall  = 0x00000073;
public const int InstEbreak = 0x00100073;
```

Essas duas constantes não são opcodes: são **instruções inteiras**, escritas em hexadecimal. `ecall` e `ebreak` não têm registradores nem constantes variáveis, então cada uma é sempre o mesmo número de 32 bits. As duas terminam em `73`, que é o opcode `OpSystem`, e só diferem no bit 20. No simulador, qualquer uma das duas encerra o programa.

## 9. Resumo lado a lado

| Família | Opcode | Formato | Lê | Escreve | Para que serve |
|---|---|---|---|---|---|
| Tipo R | `0110011` | R | 2 registradores | 1 registrador | contas |
| Tipo I | `0010011` | I | 1 registrador + constante | 1 registrador | contas com número fixo |
| Load | `0000011` | I | memória | 1 registrador | trazer dado da memória |
| Store | `0100011` | S | 2 registradores | memória | guardar dado na memória |
| Branch | `1100011` | B | 2 registradores | o PC (se pular) | `if` e laços |
| System | `1110011` | (fixo) | nada | nada | fim do programa no simulador |

## 10. Ligação com a matéria

Na aula, essas famílias aparecem no datapath pelos três tipos de instrução executados: `add` (tipo R), `lw` (load) e `beq` (branch). Ver as seções 8 e 11 de [[09 - Processador e Datapath RISC-V (Microprocessador I)]]. O `sw` usa o mesmo caminho do `lw`, só que grava em vez de ler: na aula, é a diferença entre os sinais `MemRead` e `MemWrite`.
