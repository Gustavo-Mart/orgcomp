---
tags: [projeto-final, simulador, console, e-s-programada, csharp]
arquivo: Simulador/Program.cs
bloco-do-enunciado: E/S programada (2 pts)
---

# Program.cs: o aplicativo de console

← [[Sim 08 - Testes (MemoriaTeste e CpuTests)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 11 - Video (E-S Programada)]]

## 1. Para que serve

É o programa que você roda para usar o simulador e que vai ser mostrado na apresentação. Ele lê as opções, carrega um programa RISC-V na memória, executa mostrando a tela da VRAM de tempos em tempos e, no fim, imprime um relatório com os registradores.

Quase todo o trabalho fica nas classes da biblioteca ([[Sim 12 - Computador (Carregar e Executar)|Computador]] e [[Sim 11 - Video (E-S Programada)|Video]]). O `Program.cs` só cuida da conversa com o usuário: ler opções, mostrar mensagens e erros.

## 2. Como rodar

**Sem nada:** roda o [[Sim 13 - Programa de Demonstração|programa de demonstração]]. É só apertar F5 (ou Ctrl+F5) no Visual Studio, com o projeto `Simulador` como projeto de inicialização.

**Com um arquivo `.hex` e opções:**

```
Simulador programa.hex [--passo] [--video=N] [--limite=N]
```

| Opção | O que faz | Padrão |
|---|---|---|
| `programa.hex` | arquivo com o programa, uma instrução hexadecimal por linha | o programa de demonstração |
| `--passo` | imprime cada instrução executada (endereço, código e Assembly) | desligado |
| `--video=N` | confere a tela da VRAM a cada N instruções. Com 0, desliga a tela | 50 |
| `--limite=N` | para depois de N instruções, para não travar num laço infinito | 1.000.000 |

**Pelo terminal**, na pasta da solução:

```
dotnet run --project Simulador -- exemplos\demo.hex --passo
```

O `--` separa as opções do `dotnet run` das opções do simulador.

**Pelo Visual Studio:** as opções vão nos argumentos de linha de comando do perfil de depuração do projeto `Simulador`, nas propriedades do projeto, na parte de Depurar. O nome exato do menu muda um pouco entre as versões do Visual Studio. Ao rodar pelo VS, a pasta de trabalho costuma ser a pasta de saída da compilação (`bin\...`), então é mais seguro usar o **caminho completo** do `.hex`.

## 3. O código, parte por parte

O arquivo usa **instruções de nível superior**: não tem `class Program` nem `Main`, e o código roda de cima para baixo. O compilador cria o `Main` sozinho.

### 3.1 Terminal em UTF-8

```csharp
Console.OutputEncoding = Encoding.UTF8; // acentos certos no terminal do Windows
```

Sem essa linha, o terminal do Windows pode mostrar "instruções" com caracteres estranhos no lugar dos acentos.

### 3.2 Leitura das opções

```csharp
bool passoAPasso = false;
int intervaloVideo = 50;
long limite = 1_000_000;
string? arquivo = null;

foreach (string arg in args)
{
    if (arg == "--passo") passoAPasso = true;
    else if (arg.StartsWith("--video=") && int.TryParse(arg["--video=".Length..], out int n) && n >= 0) intervaloVideo = n;
    else if (arg.StartsWith("--limite=") && long.TryParse(arg["--limite=".Length..], out long l) && l > 0) limite = l;
    else if (arg.StartsWith("--"))
    {
        Console.WriteLine($"Opção desconhecida ou valor inválido: {arg}");
        Console.WriteLine("Opções: --passo  --video=N  --limite=N");
        return 1;
    }
    else arquivo = arg;
}
```

- `args` é o vetor com o que foi digitado depois do nome do programa. Nas instruções de nível superior, ele já existe sem precisar declarar.
- `arg["--video=".Length..]` pega o texto **depois** do `=`. Em `--video=100`, sobra `"100"`.
- `TryParse` tenta converter para número e devolve `false` se não conseguir, sem lançar exceção. Junto com `n >= 0` e `l > 0`, recusa valores sem sentido.
- Qualquer outra coisa que comece com `--` é erro. O programa avisa e **termina com código 1**. Por convenção, 0 quer dizer "deu certo" e qualquer outro número quer dizer "deu errado". Scripts e outras ferramentas usam esse código.
- O que não começa com `--` é o nome do arquivo.

### 3.3 Parte 1: carregar o programa

```csharp
var computador = new Computador(intervaloVideo);

try
{
    int[] programa;
    if (arquivo is null)
    {
        Console.WriteLine("Nenhum arquivo .hex informado: rodando o programa de demonstração.");
        programa = Computador.LerHexTexto(ProgramaDemo.Hex);
    }
    else
    {
        programa = Computador.LerHex(arquivo);
        Console.WriteLine($"Carregado: {arquivo}");
    }
    computador.Carregar(0, programa);
    ...
}
catch (Exception e) when (e is SimuladorException or IOException)
{
    Console.WriteLine($"ERRO ao carregar o programa: {e.Message}");
    return 1;
}
```

Monta o computador e coloca o programa na memória a partir do endereço 0.

O `catch ... when (...)` é um **filtro**: só captura a exceção se a condição for verdadeira. Aqui entram dois tipos de erro: `SimuladorException` (linha inválida no `.hex`, programa grande demais para a memória) e `IOException` (arquivo que não existe ou não pode ser lido). Erros de carga encerram o programa com código 1, porque não há nada para executar.

### 3.4 Parte 2: executar

```csharp
try
{
    bool terminou = computador.Executar(
        limite,
        aoExecutar: passoAPasso ? Console.WriteLine : null,
        aoAtualizarTela: tela =>
        {
            Console.WriteLine(tela);
            Console.WriteLine();
        });

    Console.WriteLine(terminou
        ? "Programa terminou (ecall/ebreak)."
        : $"Limite de {limite} instruções atingido sem ecall/ebreak.");
}
catch (SimuladorException e)
{
    Console.WriteLine();
    Console.WriteLine($"ERRO durante a execução, na instrução do PC 0x{computador.Cpu.Pc:X5}: {e.Message}");
}
```

- **`aoExecutar`**: no modo `--passo`, passa o próprio `Console.WriteLine`, e cada instrução executada é impressa. Fora desse modo, passa `null` e nada é impresso.
- **`aoAtualizarTela`**: uma função curta (lambda) que imprime a tela e uma linha em branco para separar uma tela da outra.
- Os nomes antes dos dois-pontos (`aoExecutar:`, `aoAtualizarTela:`) são **argumentos nomeados**: deixam claro qual valor vai para qual parâmetro.
- Um erro durante a execução (por exemplo, `lw` desalinhado) **não** encerra o programa na hora: a mensagem mostra o PC da instrução que falhou, e o relatório ainda aparece, o que ajuda a entender o que aconteceu.

Exemplo de erro:

```
ERRO durante a execução, na instrução do PC 0x00000: Acesso desalinhado: 0x2 (lw/sw precisam de múltiplo de 4)
```

### 3.5 Parte 3: relatório

```csharp
MostrarRelatorio(computador);
return 0;

static void MostrarRelatorio(Computador c)
{
    Console.WriteLine($"Instruções executadas: {c.Cpu.InstrucoesExecutadas}");
    Console.WriteLine($"Barramento: {c.Barramento.Leituras} leituras, {c.Barramento.Escritas} escritas");
    Console.WriteLine($"PC final: 0x{c.Cpu.Pc:X5}");
    ...
    for (int r = 0; r < 32; r++)
    {
        string nome = $"x{r} ({Cpu.Nomes[r]})";
        Console.Write($"  {nome,-10} = 0x{c.Cpu[r]:X8} {c.Cpu[r],11}");
        if (r % 2 == 1) Console.WriteLine();
    }
}
```

`MostrarRelatorio` é uma **função local**: declarada dentro do próprio arquivo, depois do `return`. Mesmo vindo depois, ela pode ser chamada antes, porque o compilador junta tudo.

Os 32 registradores saem em duas colunas, cada um em hexadecimal e em decimal. `{nome,-10}` ocupa 10 posições alinhado à esquerda e `{c.Cpu[r],11}` ocupa 11 alinhado à direita, para as colunas ficarem certinhas.

## 4. Exemplo de saída (programa de demonstração, final)

```
+----------------------------------------+  VRAM após 576 instruções
|SIMULADOR RISC-V                        |
|GRUPO 4 - POPCNT                        |
|                                        |
|########################################|
|                                        |
|SOMA DE 1 A 10: 55                      |
|POPCNT DA SOMA: 5                       |
|                                        |
|FIM.                                    |
|                                        |
+----------------------------------------+

Programa terminou (ecall/ebreak).

Instruções executadas: 576
Barramento: 576 leituras, 29 escritas
PC final: 0x002F0

Registradores:
  x0 (zero)  = 0x00000000           0  x1 (ra)    = 0x00000000           0
  x2 (sp)    = 0x0007FFF0      524272  x3 (gp)    = 0x00000000           0
  ...
  x10 (a0)   = 0x00000037          55  x11 (a1)   = 0x00000005           5
  ...
```

## 5. Ligação com a matéria

- **E/S programada:** é este aplicativo que mostra o resultado no terminal a cada N instruções, como o enunciado pede. Os detalhes estão em [[Sim 11 - Video (E-S Programada)]].
- **O relatório** mostra o estado da máquina no fim: o PC, o banco de registradores e o uso do barramento.
