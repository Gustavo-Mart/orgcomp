---
tags: [projeto-final, simulador, ula, alu, operações-de-bits, popcnt, csharp]
arquivo: Simulator.core/Alu.cs
bloco-do-enunciado: CPU (parte da)
---

# Alu.cs: a Unidade Lógica e Aritmética

← [[Sim 03 - Bus (Barramento)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 05 - Cpu (Processador)]]

## 1. Para que serve

A ULA faz as contas. Ela recebe **uma operação** e **dois números de 32 bits** e devolve **um resultado de 32 bits**. Ela não sabe nada de registradores, memória ou instruções. Quem decide qual operação fazer e com quais números é a CPU (o "controle da ULA" da aula).

Essa separação imita o datapath: a ULA é um bloco de hardware isolado, e a unidade de controle só manda o sinal dizendo o que ela deve fazer.

## 2. O enum `AluOp`

```csharp
public enum AluOp { Add, Sub, Sll, Slt, Sltu, Xor, Srl, Sra, Or, And, Cpop }
```

As 10 operações que o RV32I precisa, mais o `Cpop`, que é a instrução especial do grupo 4 (POPCNT). Cada uma das 10 primeiras corresponde a uma instrução do tipo R, e quase todas têm uma versão com imediato no tipo I:

| `AluOp` | Tipo R | Tipo I | O que faz |
|---|---|---|---|
| `Add` | `add` | `addi` | soma |
| `Sub` | `sub` | (não existe `subi`) | subtração |
| `Sll` | `sll` | `slli` | desloca para a esquerda |
| `Slt` | `slt` | `slti` | 1 se `a < b` **com sinal**, senão 0 |
| `Sltu` | `sltu` | `sltiu` | 1 se `a < b` **sem sinal**, senão 0 |
| `Xor` | `xor` | `xori` | OU exclusivo bit a bit |
| `Srl` | `srl` | `srli` | desloca para a direita entrando 0 (lógico) |
| `Sra` | `sra` | `srai` | desloca para a direita repetindo o bit de sinal (aritmético) |
| `Or` | `or` | `ori` | OU bit a bit |
| `And` | `and` | `andi` | E bit a bit |
| `Cpop` | | `cpop` (POPCNT) | conta quantos bits valem 1 em `a`. Usa só um operando |

O RISC-V não tem `subi` porque basta usar `addi` com imediato negativo.

Os nomes do enum foram escolhidos para bater com os mnemônicos. A CPU aproveita isso: `op.ToString().ToLower()` transforma `AluOp.Sltu` em `"sltu"` para a descrição da instrução.

## 3. A classe estática `Alu`

```csharp
public static class Alu
```

`static` quer dizer que não se cria objeto dessa classe. Ela é só um conjunto de funções: chama-se `Alu.Executar(...)` direto. Faz sentido porque a ULA não guarda estado entre uma operação e outra.

## 4. `Executar(AluOp op, int a, int b)`

```csharp
public static int Executar(AluOp op, int a, int b)
{
    int shamt = b & 0x1F; // deslocamento usa só os 5 bits menores
    return op switch
    {
        AluOp.Add => a + b,
        AluOp.Sub => a - b,
        AluOp.Sll => a << shamt,
        AluOp.Slt => a < b ? 1 : 0,               // com sinal
        AluOp.Sltu => (uint)a < (uint)b ? 1 : 0,   // sem sinal
        AluOp.Xor => a ^ b,
        AluOp.Srl => a >>> shamt,                 // lógico: entra 0
        AluOp.Sra => a >> shamt,                  // aritmético: repete o sinal
        AluOp.Or => a | b,
        AluOp.And => a & b,
        AluOp.Cpop => ContarUns(a),               // POPCNT (grupo 4): b não é usado
        _ => throw new ArgumentOutOfRangeException(nameof(op))
    };
}
```

### 4.1 `shamt = b & 0x1F`

*shamt* vem de *shift amount* (quantidade de deslocamento). Um registrador tem 32 bits, então só faz sentido deslocar de 0 a 31 posições, e 31 cabe em 5 bits. `0x1F` é `11111` em binário, então `b & 0x1F` mantém só os 5 bits menores de `b`.

Isso segue a especificação do RISC-V: em `sll`, `srl` e `sra`, só os 5 bits menores de `rs2` contam. Exemplo: deslocar por 33 é o mesmo que deslocar por 1.

### 4.2 Cada operação, com `a = -20` e `b = 3`

Em 32 bits, `-20` é `0xFFFFFFEC` (complemento de 2) e `3` é `0x00000003`.

| Operação | Conta em C# | Resultado | Por quê |
|---|---|---|---|
| `Add` | `-20 + 3` | `-17` | soma normal |
| `Sub` | `-20 - 3` | `-23` | subtração normal |
| `Sll` | `3 << 3` (teste usa `t1, t1`) | `24` | `011` vira `011000` |
| `Slt` | `-20 < 3` | `1` | com sinal, -20 é menor |
| `Sltu` | `0xFFFFFFEC < 3` | `0` | sem sinal, `0xFFFFFFEC` vale mais de 4 bilhões |
| `Xor` | `-20 ^ 3` | `-17` (`0xFFFFFFEF`) | inverte os 2 bits menores |
| `Srl` | `-20 >>> 3` | `536870909` (`0x1FFFFFFD`) | entram três zeros à esquerda, o número fica positivo |
| `Sra` | `-20 >> 3` | `-3` (`0xFFFFFFFD`) | entram três uns à esquerda, continua negativo |
| `Or` | `-20` OU `3` | `-17` (`0xFFFFFFEF`) | liga os 2 bits menores |
| `And` | `-20 & 3` | `0` | `...1100 & ...0011 = ...0000` |

### 4.3 Com sinal e sem sinal

Os registradores são `int` (com sinal) no simulador. O mesmo padrão de 32 bits pode ser lido de dois jeitos, e é aí que as instruções diferem:

- **`Slt`** compara `a < b` com `int`, ou seja, com sinal.
- **`Sltu`** converte os dois para `uint` (inteiro sem sinal de 32 bits) antes de comparar. A conversão `(uint)a` **não muda nenhum bit**, só muda como o número é interpretado.

### 4.4 Os dois deslocamentos para a direita

- **`>>>` (Srl, lógico):** sempre entra 0 pela esquerda. Serve para números sem sinal ou para separar campos de bits.
- **`>>` (Sra, aritmético):** em um `int`, repete o bit de sinal. Um negativo continua negativo. Serve para dividir por potência de 2 mantendo o sinal (com arredondamento para baixo: `-20 >> 3` dá `-3`, que é o piso de `-2,5`).

O operador `>>>` só existe em C# a partir da versão 11. Em versões antigas seria preciso escrever `(int)((uint)a >> shamt)`.

### 4.5 E o estouro (overflow)?

`a + b` em `int` dá a volta quando passa do limite: `int.MaxValue + 1` vira `int.MinValue`. Em C# isso não gera erro por padrão (o projeto não liga a checagem de overflow). É exatamente o comportamento do RISC-V: `add` não detecta estouro, só descarta o bit que sobra.

### 4.6 `Cpop`: uma operação de um operando só

`Cpop` ignora o `b`. A CPU chama `Alu.Executar(AluOp.Cpop, a, 0)`, passando 0 só para preencher o parâmetro. Num hardware de verdade seria a mesma coisa: a ULA tem as duas entradas, e para essa operação a de baixo simplesmente não importa. A contagem é feita pela função `ContarUns` (seção 6).

### 4.7 O caso `_`

Se chegar um valor de `AluOp` fora da lista, o `switch` lança `ArgumentOutOfRangeException`. Na prática isso não acontece, porque a CPU só passa valores válidos, mas o compilador exige que o `switch` cubra todos os casos possíveis de um `enum`.

## 5. `Zero(int resultado)`

```csharp
public static bool Zero(int resultado) => resultado == 0;
```

Representa a **saída Zero** da ULA do datapath: um sinal de 1 bit que fica ligado quando o resultado é zero.

**É usada pelos desvios** `beq` e `bne`: a CPU faz `a - b` na ULA e olha o `Zero`. Se for verdadeiro, os dois registradores são iguais e o `beq` desvia. O `bne` desvia quando é falso. É a porta `PCSrc = Branch AND Zero` da aula. Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#10.5 PCSrc = Branch AND Zero (slide 17)|nota 09, seção 10.5]].

## 6. `ContarUns(int valor)`: o POPCNT

```csharp
/// <summary>Conta quantos bits valem 1 no valor (POPCNT, chamada de cpop no RISC-V).</summary>
public static int ContarUns(int valor)
{
    uint v = (uint)valor; // sem sinal: o deslocamento traz zeros pela esquerda
    int uns = 0;
    while (v != 0)
    {
        uns += (int)(v & 1); // soma o bit menos significativo
        v >>= 1;             // e descarta esse bit
    }
    return uns;
}
```

A ideia é olhar os bits um por um, da direita para a esquerda:

1. `v & 1` isola o bit menos significativo: dá 1 se ele estiver ligado e 0 se não estiver. Esse valor é somado ao contador.
2. `v >>= 1` desloca tudo uma casa para a direita. O bit que acabou de ser contado sai, e o próximo vira o menos significativo.
3. Repete até `v` virar zero, ou seja, até não sobrar nenhum bit 1.

**Por que converter para `uint`.** Com `int`, o `>>` repete o bit de sinal. Num número negativo, entraria um 1 pela esquerda a cada volta, e `v` nunca chegaria a zero: o laço não terminaria. Com `uint`, o `>>` sempre traz zeros (é o deslocamento lógico, igual ao `srl`).

**Exemplo com `0b1011` (11):**

| Volta | `v` (binário) | `v & 1` | `uns` |
|---|---|---|---|
| 1 | `1011` | 1 | 1 |
| 2 | `101` | 1 | 2 |
| 3 | `10` | 0 | 2 |
| 4 | `1` | 1 | 3 |
| fim | `0` | | **3** |

O laço dá no máximo 32 voltas, uma por bit. O .NET também tem uma função pronta para isso (`BitOperations.PopCount`), mas aqui o laço foi escrito à mão para a contagem ficar visível no código, o que ajuda na apresentação.

**Para que serve contar bits.** Alguns usos comuns: calcular o bit de paridade (se a quantidade de uns é par ou ímpar), contar quantas opções estão ligadas num conjunto de *flags* guardado como bits, e calcular a distância de Hamming entre dois valores (`popcount(a XOR b)` diz em quantos bits eles diferem).

## 7. Ligação com a matéria

- **Controle da ULA:** na aula, um bloco de controle recebe `ALUOp` (2 bits) mais `funct3`/`funct7` e gera a operação da ULA. Aqui o `enum AluOp` é essa operação final, e quem traduz os campos da instrução para ela é o `switch` dentro de `Cpu.Passo()`. Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#10.2 Controle da ULA (slide 13)|nota 09, seção 10.2]].
- **Uma ULA para tudo:** no datapath de ciclo único, a mesma ULA soma para `add`, calcula endereço para `lw`/`sw` e compara para `beq`. No simulador é igual: o `lw` e o `sw` usam `Alu.Executar(AluOp.Add, ...)` para o endereço, `beq`/`bne` usam `AluOp.Sub` com a saída `Zero`, e `blt`/`bge`/`bltu`/`bgeu` usam `Slt`/`Sltu`.
- **Instrução especial:** acrescentar o POPCNT foi acrescentar uma operação na ULA e um caso na decodificação. É assim também no hardware: uma instrução nova pede um circuito novo dentro da ULA e um código novo no controle.
