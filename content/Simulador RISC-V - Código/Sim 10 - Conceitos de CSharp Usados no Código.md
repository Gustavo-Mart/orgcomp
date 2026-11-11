---
tags: [projeto-final, simulador, csharp, glossário]
---

# Conceitos de C# usados no código

← [[Sim 09 - Program (Aplicativo de Console)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]]

Glossário dos recursos da linguagem que aparecem no simulador, com um exemplo tirado do próprio código e onde ele aparece. Alguns recursos são recentes; ao lado deles está a versão do C# em que surgiram, até onde sei. Se precisar citar isso em algum trabalho, confira na documentação da Microsoft.

## 1. Organização do código

### Namespace com escopo de arquivo
```csharp
namespace Simulador.Core;
```
O `;` no fim faz o namespace valer para o arquivo todo, sem precisar de chaves em volta de tudo. Surgiu no C# 10. Aparece em todos os arquivos `.cs` do projeto.

### `using` e `using static`
```csharp
using System.Buffers.Binary;            // importa um namespace
using static Simulador.Tests.Montador;  // importa os membros estáticos de uma classe
```
O `using static` deixa escrever `A0` em vez de `Montador.A0`. Em `CpuTests.cs`.

### Usings implícitos e globais
Com `ImplicitUsings` ligado no `.csproj`, namespaces comuns (`System`, `System.Collections.Generic`...) já vêm importados. O `<Using Include="Xunit" />` do projeto de testes faz o mesmo com o xUnit. Ver [[Sim 01 - Solução e Projetos (csproj)]].

### Instruções de nível superior
`Program.cs` tem só `Console.WriteLine(...)`, sem `class` nem `Main`. O compilador gera o resto.

## 2. Tipos

### `class`, `static class` e `enum`
- `class Memory`, `class Bus`, `class Cpu`: viram objetos com `new` e guardam estado.
- `static class Alu`: não vira objeto, é só um grupo de funções.
- `enum AluOp { Add, Sub, ... }` e `enum Controle { Nenhum, Leitura, Escrita }`: lista fechada de valores com nome.

### Herança
```csharp
public class SimuladorException(string mensagem) : Exception(mensagem);
```
O `:` diz que `SimuladorException` é um tipo de `Exception`. Em `Memory.cs`.

### Construtor primário
```csharp
public class Bus(Memory memoria)
```
O construtor é declarado junto com o nome da classe. O parâmetro fica visível na classe inteira. Para classes comuns, surgiu no C# 12. Em `Bus.cs` e `SimuladorException`.

### Construtor comum
```csharp
public Cpu(Bus bus) { _bus = bus; Reset(0); }
```
Usado em `Cpu.cs` porque o construtor faz mais do que guardar o parâmetro.

## 3. Membros de classe

### `const`, `readonly` e `static readonly`
| Palavra | Quando o valor é definido | Exemplo |
|---|---|---|
| `const` | na compilação, só números, texto e similares | `public const int OpR = 0b0110011;` |
| `readonly` | na criação do objeto, depois não troca | `private readonly int[] _x = new int[32];` |
| `static readonly` | uma vez para o programa todo | `public static readonly string[] Nomes` |

Vetor não pode ser `const`, por isso `Nomes` é `static readonly`.

### Propriedades
```csharp
public int Pc { get; private set; }
public Memory Memoria { get; } = memoria;
public string UltimaDescricao { get; private set; } = "";
```
Parecem campos, mas controlam o acesso. `{ get; private set; }` deixa ler de fora e alterar só de dentro. `{ get; }` só deixa definir na criação. O `= ...` no fim dá o valor inicial.

### Indexador
```csharp
public int this[int registrador] => _x[registrador];
```
Permite escrever `cpu[A0]` como se a CPU fosse um vetor. Em `Cpu.cs`.

### Métodos com corpo de expressão (`=>`)
```csharp
public static bool Zero(int resultado) => resultado == 0;
public void PedirInterrupcao() => Irq = true;
```
Atalho para métodos de uma linha: o que vem depois da seta é o retorno (ou a única ação).

### Parâmetro opcional
```csharp
public Cpu Rodar(int limite = 10_000)
```
Quem chamar `Rodar()` sem nada usa 10.000. Em `Montador.cs`.

### Interface fluente (`return this`)
Cada método do `Montador` devolve o próprio objeto, então as chamadas podem ser encadeadas: `new Montador().Addi(...).Add(...).Ebreak()`.

### Modificadores de acesso
- `public`: visível de qualquer lugar (inclusive de outro projeto, como os testes).
- `private`: visível só dentro da classe. Por padrão, membros sem modificador são `private`.

## 4. Literais numéricos

| Escrita | Significado | Exemplo no código |
|---|---|---|
| `0x7FFFF` | hexadecimal | constantes de `Memory` |
| `0b0110011` | binário | opcodes em `Cpu` |
| `10_000` | o `_` só separa dígitos | `Rodar(int limite = 10_000)` |

## 5. Operadores de bits

| Operador | Nome | Uso no simulador |
|---|---|---|
| `&` | E bit a bit | máscaras: `inst & 0x7F`, `b & 0x1F`, `(endereco & 3) != 0` |
| barra vertical (veja abaixo) | OU bit a bit | juntar campos no `Montador`; instrução `or` |
| `^` | OU exclusivo | instrução `xor` |
| `<<` | deslocamento à esquerda | posicionar campos no `Montador`; `sll` |
| `>>` | deslocamento à direita **aritmético** em `int` (repete o sinal) | `sra`; extensão de sinal em `ImediatoI` |
| `>>>` | deslocamento à direita **lógico** (entra 0) | separar campos em `Passo()`; `srl`. Surgiu no C# 11 |

O operador de OU é o caractere `|` (barra vertical). Ele aparece escrito por extenso na tabela porque o Obsidian usa esse caractere para separar colunas.

### Conversão `(uint)`
```csharp
(uint)a < (uint)b
```
Reinterpreta os mesmos 32 bits como número sem sinal. Nenhum bit muda. Em `Alu.Sltu`.

### Estouro sem erro
Por padrão, contas com `int` em C# "dão a volta" quando passam do limite, sem lançar erro. Isso imita o `add` do RISC-V.

## 6. `switch` e padrões

### `switch` de expressão
```csharp
AluOp op = funct3 switch
{
    0b000 => funct7 == 0b0100000 ? AluOp.Sub : AluOp.Add,
    0b001 => AluOp.Sll,
    _ => AluOp.And
};
```
Escolhe um **valor** conforme o caso. `_` é o caso padrão. Em `Alu`, `Cpu` e `Memory.Regiao`.

### `switch` de comando com `case ... when`
```csharp
case OpSystem when inst is InstEcall or InstEbreak:
```
O `when` acrescenta uma condição extra ao caso. Em `Cpu.Passo()`.

### Padrões relacionais e lógicos
```csharp
>= RamInicio and <= RamFim => "RAM",
if (funct3 is 0b001 or 0b101) ...
```
`and`, `or` e `is` montam condições de forma mais legível do que `&&` e `||` repetindo a variável. Em `Memory.Regiao` e `Cpu.Passo()`.

### Operador ternário
```csharp
a < b ? 1 : 0
```
"Se a condição for verdadeira, 1, senão 0." Em `Alu`.

## 7. Tuplas e desconstrução

```csharp
(AluOp op, string nome) = funct3 switch
{
    0b000 => (AluOp.Add, "addi"),
    ...
};
```
Uma tupla junta dois valores (`(AluOp.Add, "addi")`). A desconstrução separa de volta em duas variáveis (`op` e `nome`). Em `Cpu.Passo()`, tipo I.

## 8. Texto

### Interpolação com formato
```csharp
$"Instrução desconhecida 0x{inst:X8} em PC=0x{Pc:X5}"
```
O `$` permite colocar valores entre `{}`. Depois do `:` vem o formato: `X8` é hexadecimal maiúsculo com pelo menos 8 dígitos. `X5`, com pelo menos 5.

### `ToString().ToLower()`
`AluOp.Sltu.ToString()` dá `"Sltu"`, e `ToLower()` transforma em `"sltu"`. Em `Cpu.Passo()`, tipo R.

## 9. Coleções e memória

### Vetor (`array`)
`new byte[Tamanho]`, `new int[32]`: tamanho fixo, começa zerado.

### `List<int>`
Lista que cresce com `Add`. `ToArray()` copia para um vetor. Em `Montador`.

### `new()` com tipo deduzido
```csharp
private readonly List<int> _codigo = new();
```
O compilador deduz o tipo pelo lado esquerdo. Surgiu no C# 9.

### `Array.Clear(_x)`
Zera todas as posições do vetor. Em `Cpu.Reset`.

### `Span` e `BinaryPrimitives`
```csharp
BinaryPrimitives.ReadInt32LittleEndian(_bytes.AsSpan(endereco, 4))
```
`AsSpan(endereco, 4)` é uma "janela" sobre 4 posições do vetor, sem copiar. `BinaryPrimitives` converte entre bytes e números na ordem pedida (little-endian aqui). Em `Memory.cs`.

## 10. Exceções e lambdas

### `throw`
```csharp
throw new SimuladorException($"Escrita na área reservada: 0x{endereco:X5}");
```
Interrompe o método e sobe o erro até alguém tratar (ou até derrubar o programa).

### Lambda
```csharp
Assert.Throws<SimuladorException>(() => mem.LerPalavra(0x102));
```
`() => ...` é um pedaço de código passado como valor, para ser executado depois por quem recebeu. Nos testes.

## 11. Atributos

```csharp
[Fact]
[Theory]
[InlineData(0x80000, "VRAM")]
```
Etiquetas colocadas em cima de métodos. O código não muda, mas outras ferramentas leem essas etiquetas. Aqui, o xUnit usa para descobrir quais métodos são testes.
