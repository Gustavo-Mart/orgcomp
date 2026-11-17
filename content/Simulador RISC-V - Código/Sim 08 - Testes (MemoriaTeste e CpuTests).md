---
tags: [projeto-final, simulador, testes, xunit, csharp]
arquivos: Simulator.test/MemoriaTeste.cs, Simulator.test/CpuTests.cs, Simulator.test/MemoriaEDesviosTests.cs, Simulator.test/PopcntTests.cs, Simulator.test/ComputadorTests.cs
---

# Testes do simulador

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

**Total hoje: 37 testes.**

| Arquivo | O que testa | Testes |
|---|---|---|
| `MemoriaTeste.cs` | memória e barramento | 8 (4 `[Fact]` e 1 `[Theory]` com 4 casos) |
| `CpuTests.cs` | instruções do tipo R e do tipo I | 4 |
| `MemoriaEDesviosTests.cs` | `lw`, `sw`, VRAM e os 6 desvios | 7 |
| `PopcntTests.cs` | a instrução especial do grupo 4 | 10 (3 `[Fact]` e 1 `[Theory]` com 7 casos) |
| `ComputadorTests.cs` | leitura de `.hex`, tela da VRAM e execução completa | 8 |

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

## 5. `MemoriaEDesviosTests.cs`

Testes da etapa 3. Usam os mesmos `using` do `CpuTests.cs`.

### `CodificacaoSwEBeqBateComORiscV`

```csharp
int[] c = new Montador()
    .Sw(T0, 4, Sp)                 // sw  t0, 4(sp)
    .Beq(T0, T1, "pula")           // beq t0, t1, +8
    .Addi(Zero, Zero, 0)
    .Rotulo("pula")
    .Montar();
Assert.Equal(0x00512223, c[0]);
Assert.Equal(0x00628463, c[1]);
```

Mesma ideia do teste de codificação do `CpuTests`: confere os formatos S e B contra valores conhecidos do RISC-V. O `beq` também testa o rótulo: `pula` fica 8 bytes depois do desvio, e o montador precisa calcular esse 8 sozinho.

### `SwELw`

```csharp
.Addi(S0, Zero, 0x400)         // s0 = 0x400 (endereço base)
.Addi(T0, Zero, -1234)
.Sw(T0, 8, S0)                 // mem[0x408] = -1234
.Lw(A0, 8, S0)                 // a0 = mem[0x408]
.Addi(T1, Zero, 0x4B)          // monta 0x4B4F ("OK" em ASCII)
.Slli(T1, T1, 8)
.Ori(T1, T1, 0x4F)
.Sw(T1, -4, S0)                // deslocamento negativo: mem[0x3FC]
.Lw(A1, -4, S0)
```

Grava e lê de volta, com dois cuidados:

- **Número negativo** (-1234), para garantir que nenhum bit se perde na ida e na volta.
- **Deslocamento negativo** (`-4(s0)`), que testa a extensão de sinal do `ImediatoS` e do `ImediatoI`.

No fim, o teste olha a memória byte a byte com `cpu.Barramento.Memoria.LerByte`: `0x4F` (`'O'`) tem que estar em `0x3FC` e `0x4B` (`'K'`) em `0x3FD`. Isso confere o little-endian através de uma instrução de verdade, e não só da classe `Memory`.

O valor `0x4B4F` é montado com `addi` + `slli` + `ori` porque o simulador não tem `lui`, e o `addi` sozinho só aceita até 2047.

### `EscreveNaVram`

```csharp
.Addi(S1, Zero, 1).Slli(S1, S1, 19)   // s1 = 0x80000 (início da VRAM)
.Addi(T0, Zero, 0x4B).Slli(T0, T0, 8).Ori(T0, T0, 0x4F)
.Sw(T0, 0, S1)
```

Um `sw` comum no endereço `0x80000` coloca `'O'` e `'K'` no começo da VRAM. É a base da E/S programada da etapa 4: o programa escreve na VRAM com `sw`, e o simulador lê a VRAM para desenhar a tela.

`1 << 19` é `0x80000` porque `0x80000` é `1000 0000 0000 0000 0000` em binário: só o bit 19 ligado.

### `DesviosTomados`

```csharp
.Addi(T0, Zero, -1).Addi(T1, Zero, 1)
.Beq(T0, T0, "d1").Addi(A0, A0, 1).Rotulo("d1")
.Bne(T0, T1, "d2").Addi(A0, A0, 1).Rotulo("d2")
...
```

Cada desvio, se for tomado, pula um `addi a0, a0, 1`. Se todos funcionarem, `a0` termina em 0. Se algum falhar, `a0` fica maior que 0 e o teste aponta o problema.

Os valores `-1` e `1` foram escolhidos para separar os desvios com e sem sinal: com sinal, `-1 < 1`; sem sinal, `-1` vira `0xFFFFFFFF`, o maior número possível, e então `1 < 0xFFFFFFFF`.

### `DesviosNaoTomados`

O contrário: cada condição é falsa, então todos os `addi a1, a1, 1` executam e `a1` tem que terminar em 6. Testar os dois lados é importante: um desvio que sempre desvia passaria no teste anterior.

### `LacoSoma1Ate10`

```csharp
.Addi(A0, Zero, 0)             // soma = 0
.Addi(T0, Zero, 1)             // i = 1
.Addi(T1, Zero, 11)            // limite
.Rotulo("laco")
.Add(A0, A0, T0)               // soma += i
.Addi(T0, T0, 1)               // i++
.Blt(T0, T1, "laco")           // se i < 11, volta
```

Um laço de verdade, com **desvio para trás** (deslocamento negativo). Confere o resultado (`a0 = 55`) e também que foram executadas exatamente 34 instruções. Se o desvio voltasse para o lugar errado, o resultado ou a contagem mudariam. O passo a passo deste laço está em [[Sim 06 - Rastreio de uma Instrução Bit a Bit#7. Um desvio para trás no laço|Sim 06, seção 7]].

### `LwDesalinhadoDaErro`

```csharp
var m = new Montador().Addi(S0, Zero, 0x402).Lw(A0, 0, S0).Ebreak();
Assert.Throws<SimuladorException>(() => m.Rodar());
```

Um `lw` em `0x402`, que não é múltiplo de 4, tem que dar erro. Testa o caminho completo: CPU → barramento → `Memory.Verificar`.

## 6. `PopcntTests.cs`

Testes da instrução especial do grupo 4 (POPCNT, `cpop` no Zbb).

### `CodificacaoBateComOZbb`

```csharp
int[] c = new Montador().Cpop(A0, T0).Montar();
Assert.Equal(0x60229513, c[0]);
```

Confere a codificação contra o padrão oficial do Zbb: `funct7 = 0110000`, campo `rs2 = 00010`, `funct3 = 001` e opcode `0010011`. É isso que garante que o simulador entende um `cpop` gerado por um compilador de verdade.

### `UlaContaOsBitsUm` (Theory)

```csharp
[InlineData(0, 0)]
[InlineData(1, 1)]
[InlineData(0xFF, 8)]
[InlineData(0x12345678, 13)]
[InlineData(-1, 32)]                // 0xFFFFFFFF: todos os bits ligados
[InlineData(int.MinValue, 1)]       // 0x80000000: só o bit de sinal
[InlineData(-20, 29)]               // 0xFFFFFFEC
```

Testa a ULA direto, sem a CPU, com 7 valores. Os mais importantes são os negativos: `-1` precisa dar 32, e `int.MinValue` (`0x80000000`) precisa dar 1. Se a `ContarUns` usasse `int` em vez de `uint`, o laço não terminaria nesses casos. O `-20` dá 29 porque `0xFFFFFFEC` tem todos os bits ligados menos 3 (`0x13 = 10011`).

### `CpopNaCpu`

```csharp
.Addi(T0, Zero, -1)            // 0xFFFFFFFF
.Addi(T1, Zero, 0xFF)
.Addi(T2, Zero, -20)
.Cpop(A0, T0)
.Cpop(A1, T1)
.Cpop(A2, T2)
.Cpop(A3, Zero)
.Cpop(Zero, T0)                // x0 continua zero
.Slli(A4, T1, 2)               // mesmo funct3 do cpop: não pode confundir
```

Agora pela CPU, passando por toda a decodificação. Além dos valores, confere duas coisas:

- `cpop zero, t0` não pode mudar o `x0`.
- O `slli` logo depois continua funcionando. Como `slli` e `cpop` têm o mesmo `funct3`, um erro na ordem dos `case` faria um virar o outro.

### `OutrasInstrucoesZbbDaoErro`

```csharp
bus.Escrever(0, 0x60029513); // clz a0, t0 (rs2 = 00000): não implementada
Assert.Throws<SimuladorException>(() => cpu.Passo());
```

O `clz` tem o mesmo `funct7` do `cpop`, mas não faz parte do trabalho. O teste garante que ele dá erro em vez de ser executado como `cpop` ou como `slli`.

## 7. `ComputadorTests.cs`

Testes da etapa 4: as classes [[Sim 11 - Video (E-S Programada)|Video]] e [[Sim 12 - Computador (Carregar e Executar)|Computador]].

### `LeHexComComentariosELinhasVazias`

```csharp
string texto = """
    # comentário de linha inteira
    00500293        # addi t0, zero, 5

    0x006283B3      // add t2, t0, t1
    00100073
    """;
int[] codigo = Computador.LerHexTexto(texto);
Assert.Equal(new[] { 0x00500293, 0x006283B3, 0x00100073 }, codigo);
```

Um `.hex` com tudo o que o formato aceita: comentário de linha inteira, comentário depois da instrução com `#` e com `//`, linha vazia e o prefixo `0x`. Só as 3 instruções podem sobrar. O texto entre `"""` é uma *raw string*: pode ter várias linhas e aspas sem precisar de `\n` ou `\"`.

O `Assert.Equal` com dois vetores compara item por item, e não se são o mesmo objeto.

### `HexInvalidoDizALinha`

```csharp
var erro = Assert.Throws<SimuladorException>(() => Computador.LerHexTexto("00500293\nXYZ\n"));
Assert.Contains("Linha 2", erro.Message);
```

Além de dar erro, a mensagem precisa dizer **qual linha** está errada. `Assert.Throws` devolve a exceção, e o teste olha a mensagem dela.

### `TelaMostraOTextoDaVram`

```csharp
mem.EscreverPalavra(Memory.VramInicio, 0x2141_4C4F);                  // "OLA!"
mem.EscreverPalavra(Memory.VramInicio + Video.Colunas, 0x0000_4B4F);  // "OK" na linha 1
```

Grava duas palavras na VRAM e confere a tela: `"OLA!"` na linha 0 e `"OK"` na linha 1. Testa três coisas de uma vez: a conta de endereço por linha (`+ Video.Colunas`), a ordem little-endian dos caracteres e a troca de bytes 0 por espaço. O `_` no meio dos números hexadecimais só separa os bytes para facilitar a leitura.

### `TelaRespeitaOIntervaloESoRepeteQuandoMuda`

```csharp
Assert.Null(video.TalvezAtualizar(5));      // não é múltiplo de 10
Assert.NotNull(video.TalvezAtualizar(10));  // primeira vez: mostra
Assert.Null(video.TalvezAtualizar(20));     // nada mudou: não repete

mem.EscreverPalavra(Memory.VramInicio, 0x41);  // 'A'
Assert.NotNull(video.TalvezAtualizar(30));  // mudou: mostra de novo
```

Passa pelas quatro situações da tabela do `TalvezAtualizar`, na ordem.

### `VideoDesligadoNuncaMostra`

Com intervalo 0, a tela não aparece nem no fim do programa (`ignorarIntervalo: true`).

### `ProgramaDemoRodaAteOFim`

Roda o [[Sim 13 - Programa de Demonstração|programa de demonstração]] inteiro e confere:

- que terminou com `ebreak`;
- `a0 = 55` e `a1 = 5`;
- cada linha da tela final, inclusive a barra de 40 `#`;
- que a tela foi atualizada mais de 3 vezes durante a execução.

É o teste mais completo: passa por quase tudo o que o simulador tem, do `.hex` à tela. Se ele quebrar depois de uma mudança, alguma parte do caminho mudou de comportamento.

### `LimiteParaUmLacoInfinito`

```csharp
pc.Carregar(0, new Montador().Rotulo("x").Beq(Montador.Zero, Montador.Zero, "x").Montar());
bool terminou = pc.Executar(1000);
```

Um desvio para ele mesmo, sempre tomado: um laço infinito de uma instrução. O `Executar` tem que parar em exatamente 1000 instruções e devolver `false`.

### `CarregarNaoContaNoBarramento`

Confere que o `Carregar` grava sem passar pelo barramento (0 escritas) e que, depois de executar 2 instruções, há exatamente 2 leituras: as duas buscas.

## 8. O que os testes ainda não cobrem

- Leitura fora da memória (endereço negativo ou acima de `0x9FFFF`).
- Escrita na área reservada feita por um `sw` (hoje só é testada direto na classe `Memory`).
- O conteúdo das linhas do barramento (`Enderecos`, `Dados`, `SinalControle`).
- O `Program.cs` (leitura das opções e mensagens). Ele foi conferido rodando à mão, não por teste automático.
- A linha de interrupção, que ainda não está ligada à CPU.
