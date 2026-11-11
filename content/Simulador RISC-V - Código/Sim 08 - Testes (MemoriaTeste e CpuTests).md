---
tags: [projeto-final, simulador, testes, xunit, csharp]
arquivos: Simulator.test/MemoriaTeste.cs, Simulator.test/CpuTests.cs
---

# Testes: MemoriaTeste.cs e CpuTests.cs

← [[Sim 07 - Montador (Gerador de Instruções)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 09 - Program (Aplicativo de Console)]]

## 1. Para que servem os testes

Cada teste é um pequeno programa que monta uma situação, executa o código do simulador e **confere o resultado automaticamente**. Se alguém mexer na CPU e quebrar o `sub`, por exemplo, o teste correspondente fica vermelho na hora.

Para o projeto, isso também é prova de funcionamento: na apresentação dá para mostrar todos os testes passando.

## 2. O básico do xUnit

| Elemento | O que faz |
|---|---|
| `[Fact]` | marca um método como teste. Ele roda uma vez, sem parâmetros |
| `[Theory]` | marca um teste que roda várias vezes, com dados diferentes |
| `[InlineData(...)]` | cada linha é um conjunto de dados para um `[Theory]` |
| `Assert.Equal(esperado, obtido)` | falha se os dois forem diferentes. **O esperado vem primeiro**, senão a mensagem de erro fica invertida |
| `Assert.Throws<T>(() => ...)` | falha se o código **não** lançar uma exceção do tipo `T` |

Não precisa escrever `using Xunit;` porque o `.csproj` já declara isso como global (ver [[Sim 01 - Solução e Projetos (csproj)]]).

**Como rodar:** no Visual Studio, menu Teste → Executar Todos os Testes, ou pelo Gerenciador de Testes. No terminal, `dotnet test` na pasta da solução.

**Total hoje:** 12 testes. São 4 `[Fact]` e 1 `[Theory]` com 4 casos em `MemoriaTeste.cs` (8 no total), mais 4 em `CpuTests.cs`.

## 3. `MemoriaTeste.cs`

O arquivo se chama `MemoriaTeste.cs`, mas a classe dentro dele se chama `MemoriaTests`. O C# não exige que os nomes sejam iguais. Só fica um pouco confuso na hora de procurar.

### `EscreveELeUmaPalavra`

```csharp
var bus = new Bus(new Memory());
bus.Escrever(0x2000, -123456);
Assert.Equal(-123456, bus.Ler(0x2000));
```

Escreve um número negativo pelo barramento e lê de volta. Testa o caminho completo `Bus → Memory → Bus` e confere que números negativos não se perdem na conversão para bytes.

### `GuardaEmLittleEndian`

```csharp
var mem = new Memory();
mem.EscreverPalavra(0x100, 0x41424344);
Assert.Equal(0x44, mem.LerByte(0x100)); // byte menor no menor endereço
```

Confere a ordem dos bytes: o byte menos significativo (`0x44`) precisa estar no menor endereço (`0x100`). Ver [[Sim 02 - Memory (Memória)#Little-endian com um exemplo|exemplo na nota da memória]].

### `BloqueiaAreaReservada`

```csharp
Assert.Throws<SimuladorException>(() => mem.EscreverPalavra(0x90000, 1));
```

Escrever no início da área reservada tem que dar erro.

`() => mem.EscreverPalavra(...)` é uma **lambda**: um pedaço de código passado como valor. O `Assert.Throws` executa esse código e verifica se a exceção aparece. Se o código fosse executado direto, sem a lambda, a exceção derrubaria o teste antes do `Assert` conseguir conferir.

### `BloqueiaAcessoDesalinhado`

```csharp
Assert.Throws<SimuladorException>(() => mem.LerPalavra(0x102));
```

`0x102` não é múltiplo de 4, então a leitura de palavra tem que dar erro.

### `IdentificaRegiao` (Theory)

```csharp
[Theory]
[InlineData(0x7FFFC, "RAM")]
[InlineData(0x80000, "VRAM")]
[InlineData(0x90000, "RESERVADO")]
[InlineData(0x9FC00, "E/S")]
public void IdentificaRegiao(int endereco, string esperado)
{
    Assert.Equal(esperado, Memory.Regiao(endereco));
}
```

Um teste só, rodado 4 vezes. Cada `InlineData` preenche os parâmetros `endereco` e `esperado`. Os endereços escolhidos são limites: `0x7FFFC` é a última palavra da RAM, e os outros são o primeiro endereço de cada região. Erros de "menor que" no lugar de "menor ou igual" costumam aparecer justamente nos limites.

## 4. `CpuTests.cs`

```csharp
using Simulador.Core;
using static Simulador.Tests.Montador;
```

O `using static` traz as constantes do montador (`T0`, `A0`, `Zero`...) para serem usadas sem o prefixo `Montador.`.

### `CodificacaoBateComORiscV`

```csharp
int[] c = new Montador().Addi(T0, Zero, 5).Add(T2, T0, T1).Sub(T1, T0, T1).Montar();
Assert.Equal(0x00500293, c[0]); // addi t0, zero, 5
Assert.Equal(0x006283B3, c[1]); // add  t2, t0, t1
Assert.Equal(0x40628333, c[2]); // sub  t1, t0, t1
```

Este teste não roda a CPU. Ele confere se o **montador** gera os mesmos códigos que um montador RISC-V de verdade geraria. É importante porque, se o montador e a CPU tivessem o mesmo erro (por exemplo, campos trocados de lugar), todos os outros testes passariam e o simulador mesmo assim não rodaria programas reais. Esses três valores amarram o simulador à codificação oficial.

### `InstrucoesTipoR`

```csharp
var cpu = new Montador()
    .Addi(T0, Zero, -20).Addi(T1, Zero, 3)
    .Add(A0, T0, T1).Sub(A1, T0, T1).Sll(A2, T1, T1)
    .Slt(A3, T0, T1).Sltu(A4, T0, T1).Xor(A5, T0, T1)
    .Srl(A6, T0, T1).Sra(A7, T0, T1).Or(S2, T0, T1).And(S3, T0, T1)
    .Ebreak().Rodar();
```

Carrega `t0 = -20` e `t1 = 3` e executa as 10 instruções do tipo R, cada uma com o resultado em um registrador diferente.

O valor `-20` foi escolhido de propósito: com um número negativo, as diferenças entre `slt` e `sltu` e entre `srl` e `sra` aparecem. Com números positivos, essas instruções dariam o mesmo resultado e o teste não pegaria um erro de sinal.

| Registrador | Instrução | Esperado | O que prova |
|---|---|---|---|
| `a0` | `add` | -17 | soma com negativo |
| `a1` | `sub` | -23 | `funct7` escolhe subtração |
| `a2` | `sll` | 24 | `3 << 3` |
| `a3` | `slt` | 1 | comparação com sinal |
| `a4` | `sltu` | 0 | comparação sem sinal |
| `a5` | `xor` | `-20 ^ 3` | |
| `a6` | `srl` | `-20 >>> 3` | deslocamento lógico |
| `a7` | `sra` | `-20 >> 3` | deslocamento aritmético |
| `s2` | `or` | `-20` OU `3` | |
| `s3` | `and` | `-20 & 3` | |

Os valores esperados de `xor`, `srl`, `sra`, `or` e `and` foram escritos como contas em C# (`-20 ^ 3` em vez de `-17`). Isso documenta o que cada instrução deveria fazer e deixa o próprio compilador calcular o número.

### `InstrucoesTipoI`

```csharp
var cpu = new Montador()
    .Addi(T0, Zero, -20)
    .Addi(A0, T0, 100).Slti(A1, T0, -5).Sltiu(A2, T0, 5)
    .Xori(A3, T0, 0xFF).Ori(A4, T0, 7).Andi(A5, T0, 0xF0)
    .Slli(A6, T0, 4).Srli(A7, T0, 28).Srai(S2, T0, 2)
    .Addi(Zero, Zero, 99) // x0 não pode mudar
    .Ebreak().Rodar();
```

Mesma ideia para as 9 instruções do tipo I, com alguns cuidados:

- `slti t0, -5`: imediato **negativo**, testa a extensão de sinal (`-20 < -5` dá 1).
- `sltiu t0, 5`: compara `0xFFFFFFEC` com 5 sem sinal, dá 0.
- `srli t0, 28`: sobra só `0xF` = 15. Testa deslocamento grande.
- `srai t0, 2`: dá -5. Testa o `0x400` do montador e o `imm &= 0x1F` da CPU juntos.
- `addi zero, zero, 99` e depois `Assert.Equal(0, cpu[Zero])`: confere que **`x0` continua zero** mesmo depois de uma escrita.

### `InstrucaoDesconhecidaDaErro`

```csharp
var bus = new Bus(new Memory());
bus.Escrever(0, 0x0000007F); // opcode inválido
var cpu = new Cpu(bus);
Assert.Throws<SimuladorException>(() => cpu.Passo());
```

Coloca na memória um número com opcode `1111111`, que não existe no RV32I, e confere que a CPU lança erro em vez de fazer algo aleatório. Monta o computador "na mão", sem o `Montador`, porque o montador só gera instruções válidas.

## 5. O que os testes ainda não cobrem

- `lw`, `sw` e desvios (entram com a etapa 3, junto com 7 testes novos).
- Leitura fora da memória (endereço negativo ou acima de `0x9FFFF`).
- O conteúdo das linhas do barramento (`Enderecos`, `Dados`, `SinalControle`) e os contadores.
- A linha de interrupção.
