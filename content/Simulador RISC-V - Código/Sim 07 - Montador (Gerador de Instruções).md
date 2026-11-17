---
tags: [projeto-final, simulador, montador, assembler, codificação, rótulos, testes, csharp]
arquivo: Simulator.test/Montador.cs
---

# Montador.cs: gerador de instruções para os testes

← [[Sim 06 - Rastreio de uma Instrução Bit a Bit]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 08 - Testes (MemoriaTeste e CpuTests)]]

## 1. Para que serve

A CPU só entende **números de 32 bits**. Escrever esses números à mão para cada teste seria lento e fácil de errar. O `Montador` faz o trabalho de um **montador (assembler)**: você escreve algo parecido com Assembly em C#, e ele gera os códigos de máquina.

```csharp
var cpu = new Montador()
    .Addi(A0, Zero, 0)          // addi a0, zero, 0
    .Addi(T0, Zero, 1)          // addi t0, zero, 1
    .Addi(T1, Zero, 11)         // addi t1, zero, 11
    .Rotulo("laco")             // laco:
    .Add(A0, A0, T0)            //   add  a0, a0, t0
    .Addi(T0, T0, 1)            //   addi t0, t0, 1
    .Blt(T0, T1, "laco")        //   blt  t0, t1, laco
    .Ebreak()
    .Rodar();
```

Ele está no projeto de **testes**, não na biblioteca, porque só os testes precisam dele. O programa final vai carregar código pronto de um arquivo `.hex`.

O montador faz o caminho **contrário** da decodificação da CPU: a CPU separa os campos de um número, o montador junta campos em um número.

Ele monta todas as instruções obrigatórias (tipo R, tipo I, `lw`, `sw` e os 6 desvios, com **rótulos** para os destinos dos desvios) e a instrução especial do grupo 4, o `cpop` (POPCNT).

## 2. Constantes de registradores

```csharp
public const int Zero = 0, Ra = 1, Sp = 2, T0 = 5, T1 = 6, T2 = 7, S0 = 8, S1 = 9,
                 A0 = 10, A1 = 11, A2 = 12, A3 = 13, A4 = 14, A5 = 15, A6 = 16, A7 = 17,
                 S2 = 18, S3 = 19;
```

Nomes para os números dos registradores, para os testes ficarem legíveis (`A0` em vez de `10`). Só estão os registradores que os testes usam. `Sp` aparece no teste de codificação do `sw`, e `S0`/`S1` servem de endereço base nos testes de memória.

Nos arquivos de teste, `using static Simulador.Tests.Montador;` permite escrever `A0` em vez de `Montador.A0`.

## 3. Os campos

```csharp
private readonly List<int> _codigo = new();
private readonly Dictionary<string, int> _rotulos = new();
private readonly List<(int indice, string rotulo, int f3, int rs1, int rs2)> _pendentes = new();
```

| Campo | O que guarda |
|---|---|
| `_codigo` | as instruções já montadas, uma por item, na ordem em que os métodos foram chamados. A posição na lista vezes 4 é o endereço da instrução na memória |
| `_rotulos` | cada rótulo e o endereço onde ele foi marcado. Exemplo: `"laco" → 12` |
| `_pendentes` | os desvios que ainda não sabem o próprio deslocamento: em que posição da lista estão, qual rótulo procuram e os campos da instrução |

`new()` sem o tipo: o C# deduz o tipo pelo lado esquerdo da declaração.

## 4. `R(...)`: codifica uma instrução do tipo R

```csharp
private Montador R(int f7, int rs2, int rs1, int f3, int rd)
{
    _codigo.Add(f7 << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | rd << 7 | Cpu.OpR);
    return this;
}
```

Cada campo é **deslocado para a sua posição** e os resultados são **juntados com OU** (`|`). É o inverso exato da decodificação:

| Campo | Deslocamento | Ocupa os bits |
|---|---|---|
| `f7` (funct7) | `<< 25` | 31-25 |
| `rs2` | `<< 20` | 24-20 |
| `rs1` | `<< 15` | 19-15 |
| `f3` (funct3) | `<< 12` | 14-12 |
| `rd` | `<< 7` | 11-7 |
| `Cpu.OpR` | nenhum | 6-0 |

O OU funciona porque os campos não se sobrepõem: cada um cai em bits que estavam zerados nos outros. Em C#, `<<` tem prioridade maior que `|`, então não precisa de parênteses.

**Exemplo:** `R(0, 6, 5, 0, 7)` (`add t2, t0, t1`):

```
0      << 25 = 0x00000000
6      << 20 = 0x00600000
5      << 15 = 0x00028000
0      << 12 = 0x00000000
7      << 7  = 0x00000380
0x33         = 0x00000033
OU de tudo   = 0x006283B3
```

É o valor que o teste `CodificacaoBateComORiscV` confere.

`return this` devolve o próprio montador. É isso que permite encadear `.Addi(...).Add(...).Ebreak()` (interface fluente).

O método é `private` porque quem usa o montador chama os métodos com nome de instrução, não o formato cru.

## 5. `I(...)`: codifica uma instrução do tipo I

```csharp
private Montador I(int imm, int rs1, int f3, int rd, int opcode = Cpu.OpI)
{
    _codigo.Add((imm & 0xFFF) << 20 | rs1 << 15 | f3 << 12 | rd << 7 | opcode);
    return this;
}
```

Igual ao tipo R, mas os bits 31-20 recebem o imediato.

O parâmetro `opcode` tem valor padrão `Cpu.OpI`. As instruções aritméticas (`addi`, `slli`...) não passam nada e usam o padrão. O `lw` usa o mesmo formato com outro opcode, e passa `Cpu.OpLoad`.

O `imm & 0xFFF` guarda só os 12 bits menores do imediato. Para `-20` (`0xFFFFFFEC`), sobra `0xFEC`, que é exatamente o que o RISC-V guarda na instrução. A CPU depois recupera o -20 com a extensão de sinal do `ImediatoI`.

Neste formato, na verdade, a máscara nem é obrigatória. Como o imediato é deslocado 20 posições, os bits acima do bit 11 já "caem para fora" dos 32 bits sozinhos (`-20 << 20` também dá `0xFEC00000`). A máscara deixa a intenção clara. Nos formatos S e B, em que o imediato é quebrado em pedaços no meio da instrução, as máscaras passam a ser necessárias de verdade.

O imediato precisa estar entre -2048 e 2047 (12 bits com sinal). O montador **não confere** isso: um valor fora da faixa é cortado em silêncio.

## 6. `S(...)`: codifica o `sw`

```csharp
private Montador S(int imm, int rs2, int rs1, int f3)
{
    _codigo.Add(((imm >> 5) & 0x7F) << 25 | rs2 << 20 | rs1 << 15 | f3 << 12
                | (imm & 0x1F) << 7 | Cpu.OpStore);
    return this;
}
```

No formato S, o imediato é dividido em dois pedaços:

| Pedaço | Conta | Vai para os bits |
|---|---|---|
| `imm[11:5]` | `(imm >> 5) & 0x7F` | 31-25 |
| `imm[4:0]` | `imm & 0x1F` | 11-7 |

A máscara que realmente importa aqui é a do pedaço de baixo, `imm & 0x1F`. Sem ela, um imediato negativo carregaria bits de sinal ligados que, depois do `<< 7`, cairiam em cima do `funct3`, do `rs1` e do `rs2`, estragando a instrução. Já no pedaço de cima, o `& 0x7F` seria dispensável pelo mesmo motivo do formato I (o `<< 25` empurra o resto para fora dos 32 bits), mas fica por clareza.

**Exemplo:** `sw t0, 4(sp)` dá `0x00512223`, valor conferido no teste `CodificacaoSwEBeqBateComORiscV`.

## 7. `CodificarB(...)`: codifica um desvio

```csharp
public static int CodificarB(int imm, int rs2, int rs1, int f3) =>
      ((imm >> 12) & 0x1) << 31
    | ((imm >> 5) & 0x3F) << 25
    | rs2 << 20 | rs1 << 15 | f3 << 12
    | ((imm >> 1) & 0xF) << 8
    | ((imm >> 11) & 0x1) << 7
    | Cpu.OpBranch;
```

É o inverso do `Cpu.ImediatoB`: pega o deslocamento em bytes e espalha os bits nas posições embaralhadas do formato B.

| Pedaço | Conta | Vai para o(s) bit(s) |
|---|---|---|
| `imm[12]` | `(imm >> 12) & 0x1` | 31 |
| `imm[10:5]` | `(imm >> 5) & 0x3F` | 30-25 |
| `imm[4:1]` | `(imm >> 1) & 0xF` | 11-8 |
| `imm[11]` | `(imm >> 11) & 0x1` | 7 |

O `imm[0]` não entra, porque o deslocamento é sempre par.

É `public static` porque também é útil fora do montador, por exemplo para conferir uma codificação conhecida: `beq t0, t1, +8` dá `0x00628463`.

## 8. Métodos do tipo R

```csharp
public Montador Add(int rd, int rs1, int rs2) => R(0, rs2, rs1, 0b000, rd);
public Montador Sub(int rd, int rs1, int rs2) => R(0b0100000, rs2, rs1, 0b000, rd);
...
public Montador And(int rd, int rs1, int rs2) => R(0, rs2, rs1, 0b111, rd);
```

Cada método só fixa o `funct7` e o `funct3` daquela instrução e repassa para `R`. A ordem dos parâmetros segue o Assembly (`add rd, rs1, rs2`), mesmo que `R` receba em outra ordem.

| Método | `funct7` | `funct3` |
|---|---|---|
| `Add` | `0000000` | `000` |
| `Sub` | `0100000` | `000` |
| `Sll` | `0000000` | `001` |
| `Slt` | `0000000` | `010` |
| `Sltu` | `0000000` | `011` |
| `Xor` | `0000000` | `100` |
| `Srl` | `0000000` | `101` |
| `Sra` | `0100000` | `101` |
| `Or` | `0000000` | `110` |
| `And` | `0000000` | `111` |

## 9. Métodos do tipo I

```csharp
public Montador Addi(int rd, int rs1, int imm) => I(imm, rs1, 0b000, rd);
...
public Montador Slli(int rd, int rs1, int sh) => I(sh, rs1, 0b001, rd);
public Montador Srli(int rd, int rs1, int sh) => I(sh, rs1, 0b101, rd);
public Montador Srai(int rd, int rs1, int sh) => I(0x400 | sh, rs1, 0b101, rd);
```

O único detalhe é o `Srai`. `srli` e `srai` têm o mesmo `funct3` (`101`). O que diferencia é o bit 30 da instrução. Como o imediato começa no bit 20, o bit 30 é o bit 10 do imediato, e `0x400` é justamente `1 << 10`. Então `0x400 | sh` liga esse bit e coloca a quantidade de deslocamento nos 5 bits menores.

### `Cpop`: a instrução especial do grupo 4

```csharp
/// <summary>cpop rd, rs1: POPCNT, conta os bits 1 de rs1 (extensão Zbb).</summary>
public Montador Cpop(int rd, int rs1) => I(Cpu.Funct7Zbb << 5 | Cpu.Rs2Cpop, rs1, 0b001, rd);
```

O `cpop` usa o formato I com o mesmo `funct3` do `slli`. O que muda são os 12 bits do "imediato", que aqui não são um número: `Funct7Zbb << 5 | Rs2Cpop` monta `0110000` seguido de `00010`, que é `0x602`. Com isso, `cpop a0, t0` vira `0x60229513`, o valor conferido no teste `CodificacaoBateComOZbb`.

Os valores vêm das constantes da `Cpu`, então montador e CPU usam exatamente os mesmos números. Ver [[Sim 05 - Cpu (Processador)]].

## 10. Memória: `Lw` e `Sw`

```csharp
/// <summary>lw rd, imm(rs1)</summary>
public Montador Lw(int rd, int imm, int rs1) => I(imm, rs1, 0b010, rd, Cpu.OpLoad);
/// <summary>sw rs2, imm(rs1)</summary>
public Montador Sw(int rs2, int imm, int rs1) => S(imm, rs2, rs1, 0b010);
```

A ordem dos parâmetros imita o Assembly: `lw a0, 8(s0)` vira `.Lw(A0, 8, S0)`, e `sw t0, 4(sp)` vira `.Sw(T0, 4, Sp)`. O registrador base vem por último, como dentro dos parênteses.

## 11. Desvios e rótulos

```csharp
public Montador Beq(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b000, rotulo);
public Montador Bne(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b001, rotulo);
public Montador Blt(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b100, rotulo);
public Montador Bge(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b101, rotulo);
public Montador Bltu(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b110, rotulo);
public Montador Bgeu(int rs1, int rs2, string rotulo) => B(rs1, rs2, 0b111, rotulo);
```

Os desvios recebem um **nome de rótulo** em vez de um número. Isso deixa os testes legíveis e evita erro de conta: ninguém precisa calcular à mão que o laço volta 8 bytes.

### O problema do rótulo que ainda não existe

Num desvio **para frente**, o rótulo aparece **depois** do desvio:

```csharp
.Beq(T0, T1, "pula")   // ainda não se sabe onde "pula" fica
.Addi(A0, A0, 1)
.Rotulo("pula")        // só aqui o endereço fica conhecido
```

Na hora de montar o `beq`, o deslocamento ainda é desconhecido. A solução é a mesma de um montador de verdade: **duas passagens**.

### `B(...)`: guarda o desvio para depois

```csharp
private Montador B(int rs1, int rs2, int f3, string rotulo)
{
    _pendentes.Add((_codigo.Count, rotulo, f3, rs1, rs2));
    _codigo.Add(0); // lugar reservado, preenchido no Montar()
    return this;
}
```

1. Anota em `_pendentes` em que posição o desvio está, qual rótulo ele procura e os campos que já são conhecidos.
2. Coloca um `0` provisório no lugar da instrução, só para guardar a posição. Assim as instruções seguintes continuam com o endereço certo.

### `Rotulo(string nome)`: marca a posição

```csharp
public Montador Rotulo(string nome)
{
    if (!_rotulos.TryAdd(nome, _codigo.Count * 4))
        throw new ArgumentException($"Rótulo repetido: {nome}");
    return this;
}
```

Guarda o endereço da **próxima** instrução que será montada (`_codigo.Count * 4`). O rótulo não ocupa espaço na memória: é só um nome para um endereço.

`TryAdd` tenta incluir no dicionário e devolve `false` se o nome já existir. Nesse caso o montador lança erro, porque dois rótulos com o mesmo nome deixariam o destino ambíguo.

### `Montar()`: segunda passagem

```csharp
public int[] Montar()
{
    int[] codigo = _codigo.ToArray();
    foreach (var (indice, rotulo, f3, rs1, rs2) in _pendentes)
    {
        if (!_rotulos.TryGetValue(rotulo, out int destino))
            throw new ArgumentException($"Rótulo não existe: {rotulo}");
        int deslocamento = destino - indice * 4; // relativo ao PC do desvio
        codigo[indice] = CodificarB(deslocamento, rs2, rs1, f3);
    }
    return codigo;
}
```

Quando o programa inteiro já foi escrito, todos os rótulos são conhecidos. Para cada desvio pendente:

1. Procura o endereço do rótulo. Se não existir (erro de digitação, por exemplo), lança erro.
2. Calcula o deslocamento: **endereço do rótulo menos o endereço do próprio desvio**. É relativo ao PC do desvio, igual à regra da CPU.
3. Codifica o desvio e coloca no lugar do `0` provisório.

O `foreach (var (indice, rotulo, f3, rs1, rs2) in _pendentes)` desmonta cada tupla da lista em 5 variáveis de uma vez.

**Exemplo** do laço da seção 1: `laco` foi marcado em `12` (`0x0C`) e o `blt` está na posição 5 da lista, ou seja, no endereço `20` (`0x14`). Deslocamento: `12 - 20 = -8`.

## 12. `Ebreak()`

```csharp
public Montador Ebreak() { _codigo.Add(Cpu.InstEbreak); return this; }
```

Acrescenta o código fixo do `ebreak`. Todo programa de teste termina com ele, senão a CPU continuaria buscando instruções na memória zerada e daria "Instrução desconhecida 0x00000000".

## 13. `Rodar(int limite = 10_000)`

```csharp
public Cpu Rodar(int limite = 10_000)
{
    var bus = new Bus(new Memory());
    int[] codigo = Montar();
    for (int k = 0; k < codigo.Length; k++) bus.Escrever(4 * k, codigo[k]);
    var cpu = new Cpu(bus);
    while (!cpu.Parada && cpu.InstrucoesExecutadas < limite) cpu.Passo();
    return cpu;
}
```

Monta um computador inteiro do zero, carrega o programa e roda:

1. Cria uma memória nova e um barramento ligado a ela.
2. Chama `Montar()` (que resolve os rótulos) e grava cada instrução no endereço `4 * k` (0, 4, 8...) **pelo barramento**.
3. Cria a CPU, que já começa com PC = 0.
4. Chama `Passo()` até a CPU parar.
5. Devolve a CPU para o teste conferir os registradores. A memória continua acessível por `cpu.Barramento.Memoria`.

O **`limite`** é uma trava de segurança. Se um teste tiver um laço infinito (por exemplo, um desvio com a condição errada), o teste para depois de 10.000 instruções em vez de travar o Visual Studio. `int limite = 10_000` é um parâmetro opcional: quem não passar nada usa 10.000. O `_` no número é só para facilitar a leitura.

## 14. Ligação com a matéria

- **Do Assembly ao binário:** é o passo do montador na cadeia compilador → montador → ligador → carregador. O `Rodar` ainda faz o papel do **carregador**, que coloca o programa na memória. Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#3. Do alto nível ao binário (slide 5)|nota 09, seção 3]].
- **Formatos de instrução:** os métodos `R`, `I`, `S` e `CodificarB` mostram que o formato é só uma regra de onde cada campo fica nos 32 bits. O `Cpop` mostra que o mesmo formato pode guardar outra coisa nos bits do imediato.
- **Rótulos e duas passagens:** montadores de verdade também resolvem os rótulos numa segunda passagem (ou guardando pendências, como aqui), porque um desvio para frente aponta para um endereço que ainda não foi visto.
