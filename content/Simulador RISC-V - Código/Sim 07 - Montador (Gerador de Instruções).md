---
tags: [projeto-final, simulador, montador, assembler, codificação, testes, csharp]
arquivo: Simulator.test/Montador.cs
---

# Montador.cs: gerador de instruções para os testes

← [[Sim 06 - Rastreio de uma Instrução Bit a Bit]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 08 - Testes (MemoriaTeste e CpuTests)]]

## 1. Para que serve

A CPU só entende **números de 32 bits**. Escrever esses números à mão para cada teste seria lento e fácil de errar. O `Montador` faz o trabalho de um **montador (assembler)**: você escreve algo parecido com Assembly em C#, e ele gera os códigos de máquina.

```csharp
var cpu = new Montador()
    .Addi(T0, Zero, -20)   // addi t0, zero, -20
    .Addi(T1, Zero, 3)     // addi t1, zero, 3
    .Add(A0, T0, T1)       // add  a0, t0, t1
    .Ebreak()
    .Rodar();
```

Ele está no projeto de **testes**, não na biblioteca, porque só os testes precisam dele. O programa final vai carregar código pronto de um arquivo `.hex`.

O montador faz o caminho **contrário** da decodificação da CPU: a CPU separa os campos de um número, o montador junta campos em um número.

## 2. Constantes de registradores

```csharp
public const int Zero = 0, T0 = 5, T1 = 6, T2 = 7, A0 = 10, A1 = 11, A2 = 12, A3 = 13,
                 A4 = 14, A5 = 15, A6 = 16, A7 = 17, S2 = 18, S3 = 19;
```

Nomes para os números dos registradores, para os testes ficarem legíveis (`A0` em vez de `10`). Só estão os registradores que os testes usam até agora. A etapa 3 acrescenta `Sp`, `S0`, `S1` e outros.

Nos arquivos de teste, `using static Simulador.Tests.Montador;` permite escrever `A0` em vez de `Montador.A0`.

## 3. O campo `_codigo`

```csharp
private readonly List<int> _codigo = new();
```

Uma lista que vai crescendo, uma instrução por item, na ordem em que os métodos são chamados. A posição na lista vezes 4 é o endereço onde a instrução vai ficar na memória.

`new()` sem o tipo: o C# deduz que é `new List<int>()` pelo tipo declarado do campo.

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

O OU funciona porque os campos não se sobrepõem: cada um cai em bits que estavam zerados nos outros.

Em C#, `<<` tem prioridade maior que `|`, então não precisa de parênteses.

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
private Montador I(int imm, int rs1, int f3, int rd)
{
    _codigo.Add((imm & 0xFFF) << 20 | rs1 << 15 | f3 << 12 | rd << 7 | Cpu.OpI);
    return this;
}
```

Igual ao tipo R, mas os bits 31-20 recebem o imediato.

O `imm & 0xFFF` guarda só os 12 bits menores do imediato. Para `-20` (`0xFFFFFFEC`), sobra `0xFEC`, que é exatamente o que o RISC-V guarda na instrução. A CPU depois recupera o -20 com a extensão de sinal do `ImediatoI`.

Neste formato, na verdade, a máscara nem é obrigatória. Como o imediato é deslocado 20 posições, os bits acima do bit 11 já "caem para fora" dos 32 bits sozinhos (`-20 << 20` também dá `0xFEC00000`). A máscara deixa a intenção clara e evita surpresa se alguém mudar o código. Nos formatos S e B (etapa 3), em que o imediato é quebrado em pedaços no meio da instrução, as máscaras passam a ser necessárias de verdade.

O imediato precisa estar entre -2048 e 2047 (12 bits com sinal). O montador **não confere** isso: um valor fora da faixa é cortado em silêncio.

## 6. Métodos do tipo R

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

## 7. Métodos do tipo I

```csharp
public Montador Addi(int rd, int rs1, int imm) => I(imm, rs1, 0b000, rd);
...
public Montador Slli(int rd, int rs1, int sh) => I(sh, rs1, 0b001, rd);
public Montador Srli(int rd, int rs1, int sh) => I(sh, rs1, 0b101, rd);
public Montador Srai(int rd, int rs1, int sh) => I(0x400 | sh, rs1, 0b101, rd);
```

O único detalhe é o `Srai`. `srli` e `srai` têm o mesmo `funct3` (`101`). O que diferencia é o bit 30 da instrução. Como o imediato começa no bit 20, o bit 30 é o bit 10 do imediato, e `0x400` é justamente `1 << 10`. Então `0x400 | sh` liga esse bit e coloca a quantidade de deslocamento nos 5 bits menores.

## 8. `Ebreak()`

```csharp
public Montador Ebreak() { _codigo.Add(Cpu.InstEbreak); return this; }
```

Acrescenta o código fixo do `ebreak`. Todo programa de teste termina com ele, senão a CPU continuaria buscando instruções na memória zerada e daria "Instrução desconhecida 0x00000000".

## 9. `Montar()`

```csharp
public int[] Montar() => _codigo.ToArray();
```

Devolve as instruções como vetor. Usado pelo teste de codificação, que compara os números gerados com valores conhecidos do RISC-V.

## 10. `Rodar(int limite = 10_000)`

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
2. Grava cada instrução no endereço `4 * k` (0, 4, 8...) **pelo barramento**.
3. Cria a CPU, que já começa com PC = 0.
4. Chama `Passo()` até a CPU parar.
5. Devolve a CPU para o teste conferir os registradores.

O **`limite`** é uma trava de segurança. Se um teste tiver um laço infinito (por exemplo, um desvio com destino errado), o teste para depois de 10.000 instruções em vez de travar o Visual Studio. `int limite = 10_000` é um parâmetro opcional: quem não passar nada usa 10.000. O `_` no número é só para facilitar a leitura.

## 11. Ligação com a matéria

- **Do Assembly ao binário:** é o passo do montador na cadeia compilador → montador → ligador → carregador. O `Rodar` ainda faz o papel do **carregador**, que coloca o programa na memória. Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#3. Do alto nível ao binário (slide 5)|nota 09, seção 3]].
- **Formatos de instrução:** os métodos `R` e `I` mostram que o formato é só uma regra de onde cada campo fica nos 32 bits.

## 12. O que vai mudar na etapa 3

- Novas constantes de registrador (`Ra`, `Sp`, `S0`, `S1`).
- O método `I` ganha um parâmetro `opcode`, para servir também ao `lw`.
- Um método `S` para o formato do `sw`.
- Rótulos (`Rotulo("laco")`) e os 6 desvios, com o deslocamento calculado no `Montar()`.
