---
tags: [projeto-final, simulador, cpu, risc-v, rv32i, decodificação, ciclo-de-instrução, desvios, csharp]
arquivo: Simulator.core/Cpu.cs
bloco-do-enunciado: CPU (3 pts)
---

# Cpu.cs: o processador

← [[Sim 04 - Alu (ULA)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 14 - Opcodes e Famílias de Instruções]]

## 1. Para que serve

A `Cpu` é o processador RISC-V **de ciclo único**: cada chamada de `Passo()` executa **uma instrução inteira**, do começo ao fim, antes de começar a próxima. Ela executa todas as instruções obrigatórias do enunciado (tipo R, tipo I, `lw`, `sw` e os 6 desvios) e a instrução especial do grupo 4, o **POPCNT**. Ela guarda:

- o **banco de 32 registradores** (`x0` a `x31`);
- o **PC** (contador de programa), que aponta para a próxima instrução;
- se o programa **terminou** (`Parada`);
- quantas instruções já rodaram e a descrição da última (para depuração).

Ela fala com a memória **somente pelo barramento** e faz as contas **somente pela ULA**.

## 2. As constantes de opcode

```csharp
// Opcodes (bits [6:0])
public const int OpR = 0b0110011;
public const int OpI = 0b0010011;
public const int OpLoad = 0b0000011;
public const int OpStore = 0b0100011;
public const int OpBranch = 0b1100011;
public const int OpSystem = 0b1110011;
```

O **opcode** são os 7 bits menores de toda instrução RISC-V. Ele diz o **formato** e o **grupo** da instrução. `0b` no começo indica um número escrito em binário.

| Constante | Binário | Hex | Grupo | Situação no código |
|---|---|---|---|---|
| `OpR` | `0110011` | `0x33` | tipo R: `add`, `sub`, `and`... | tratado |
| `OpI` | `0010011` | `0x13` | tipo I aritmético: `addi`, `slli`... e o `cpop` (POPCNT) | tratado |
| `OpLoad` | `0000011` | `0x03` | `lw` | tratado (só `lw`) |
| `OpStore` | `0100011` | `0x23` | `sw` | tratado (só `sw`) |
| `OpBranch` | `1100011` | `0x63` | `beq`, `bne`, `blt`... | tratado (os 6 desvios) |
| `OpSystem` | `1110011` | `0x73` | `ecall`, `ebreak` | tratado (só esses dois) |

O que cada família faz, com exemplos e o desenho dos bits de cada formato, está em [[Sim 14 - Opcodes e Famílias de Instruções]].

São `public` porque o `Montador` usa os mesmos valores para gerar as instruções. Assim, CPU e montador nunca discordam sobre o opcode.

## 3. `InstEcall` e `InstEbreak`

```csharp
public const int InstEcall = 0x00000073;
public const int InstEbreak = 0x00100073;
```

Diferente das outras instruções, `ecall` e `ebreak` não têm registradores variáveis: cada uma é **um número fixo de 32 bits**. Os dois têm opcode `0x73` (`OpSystem`) e só diferem no bit 20.

No simulador, qualquer uma das duas **encerra o programa**. Num RISC-V real, `ecall` chama o sistema operacional e `ebreak` chama o depurador. Como aqui não existe sistema operacional, usar como "fim" é a escolha mais simples.

### `Funct7Zbb` e `Rs2Cpop`

```csharp
// Instrução especial do grupo 4: POPCNT, que na extensão Zbb se chama cpop.
// Codificação oficial: opcode OpI, funct3 001, funct7 0110000 e o campo rs2 = 00010.
public const int Funct7Zbb = 0b0110000;
public const int Rs2Cpop = 0b00010;
```

Os dois valores que identificam o `cpop`, explicados na seção "Instrução especial do grupo 4" mais abaixo. São `public` porque o `Montador` usa os mesmos números para gerar a instrução.

## 4. `Nomes`: os nomes ABI dos registradores

```csharp
public static readonly string[] Nomes =
{
    "zero","ra","sp","gp","tp","t0","t1","t2","s0","s1","a0","a1","a2","a3","a4","a5",
    "a6","a7","s2","s3","s4","s5","s6","s7","s8","s9","s10","s11","t3","t4","t5","t6"
};
```

Os registradores se chamam `x0` a `x31` no hardware, mas o Assembly usa apelidos que dizem o papel de cada um (a convenção de chamada, ou ABI). O índice do vetor é o número do registrador: `Nomes[10]` é `"a0"`.

| Registrador | Nome | Papel |
|---|---|---|
| `x0` | `zero` | sempre vale 0 |
| `x1` | `ra` | endereço de retorno de função |
| `x2` | `sp` | ponteiro de pilha |
| `x3` | `gp` | ponteiro global |
| `x4` | `tp` | ponteiro de thread |
| `x5`-`x7` | `t0`-`t2` | temporários |
| `x8`-`x9` | `s0`-`s1` | salvos entre chamadas (`s0` também é o ponteiro de quadro) |
| `x10`-`x17` | `a0`-`a7` | argumentos e retorno de função |
| `x18`-`x27` | `s2`-`s11` | salvos entre chamadas |
| `x28`-`x31` | `t3`-`t6` | temporários |

Para a CPU todos são iguais (menos o `x0`). Os nomes só servem para a descrição da instrução ficar legível: `add a0, t0, t1` em vez de `add x10, x5, x6`.

`static readonly` em vez de `const`: C# não permite `const` em vetor. `static readonly` dá o mesmo efeito prático: um único vetor para todas as CPUs, que não pode ser trocado.

## 5. Campos e propriedades

```csharp
private readonly Bus _bus;
private readonly int[] _x = new int[32]; // banco de registradores

public int Pc { get; private set; }
public bool Parada { get; private set; }
public long InstrucoesExecutadas { get; private set; }
public string UltimaDescricao { get; private set; } = "";
public Bus Barramento => _bus;
```

| Membro | O que é | Equivalente no hardware |
|---|---|---|
| `_bus` | o barramento por onde a CPU acessa a memória | ligação CPU-barramento |
| `_x` | vetor com os 32 registradores de 32 bits | banco de registradores |
| `Pc` | endereço da próxima instrução | registrador PC |
| `Parada` | `true` depois de `ecall`/`ebreak` | sinal de halt |
| `InstrucoesExecutadas` | contador de instruções | contador de desempenho |
| `UltimaDescricao` | texto da última instrução, por exemplo `0x00008: 00628533  add a0, t0, t1` | não existe no hardware, é para depuração |
| `Barramento` | o mesmo barramento de `_bus`, só para leitura | não existe no hardware: serve para os testes olharem a memória com `cpu.Barramento.Memoria` |

Os registradores são `int` (com sinal, 32 bits). Quando uma instrução precisa tratar o valor como sem sinal (`sltu`, `srl`), a ULA converte na hora.

`{ get; private set; }`: quem está fora lê, mas só a CPU altera. Ninguém de fora "pula" o PC sem passar por uma instrução.

## 6. O construtor `Cpu(Bus bus)`

```csharp
public Cpu(Bus bus)
{
    _bus = bus;
    Reset(0);
}
```

Recebe o barramento já ligado a uma memória e guarda em `_bus`. Depois chama `Reset(0)`, então toda CPU nova começa com o PC em 0, que é onde o programa é carregado.

Aqui foi usado o construtor comum (e não o construtor primário, como em `Bus`) porque o construtor precisa fazer mais do que guardar o parâmetro: ele também chama `Reset`.

## 7. `Reset(int pcInicial)`

```csharp
public void Reset(int pcInicial)
{
    Array.Clear(_x);
    Pc = pcInicial;
    _x[2] = Memory.RamFim - 15; // sp no topo da RAM
    Parada = false;
    InstrucoesExecutadas = 0;
}
```

Coloca a CPU no estado inicial, como apertar o botão de reset:

1. `Array.Clear(_x)` zera os 32 registradores.
2. O PC vai para o endereço de início do programa.
3. O **`sp`** (`x2`) recebe `0x7FFFF - 15 = 0x7FFF0`, perto do fim da RAM. A pilha cresce "para baixo" (para endereços menores), então começa no topo. O `- 15` deixa o valor múltiplo de 16, que é o alinhamento de pilha que a convenção do RISC-V pede.
4. Limpa `Parada` e o contador.

`Reset` não apaga a memória, só a CPU. O programa carregado continua lá.

## 8. O indexador `this[int registrador]`

```csharp
public int this[int registrador] => _x[registrador];
```

Um **indexador** deixa usar o objeto como se fosse um vetor. Com ele, os testes escrevem `cpu[A0]` para ler o registrador `a0`, em vez de `cpu.LerRegistrador(10)`.

Só tem leitura (não tem `set`). De fora, não dá para alterar registrador diretamente, só por instrução. Se mais tarde for necessário (por exemplo, para a interface gráfica editar registradores), é preciso acrescentar um `set`.

## 9. `Passo()`: o ciclo de instrução

É o método principal. Cada chamada executa uma instrução inteira.

```csharp
public void Passo()
{
    if (Parada) return;
```

Se o programa já terminou, não faz nada. Assim quem chama `Passo()` em laço não precisa se preocupar em parar exatamente na hora.

### 9.1 Busca

```csharp
    // 1. BUSCA
    int inst = _bus.Ler(Pc);
    int proximoPc = Pc + 4;
```

- Lê a palavra de 32 bits no endereço do PC **pelo barramento**. Essa palavra é a instrução.
- Calcula o próximo PC como `Pc + 4`, porque cada instrução ocupa 4 bytes. É o somador `PC + 4` do datapath.
- O PC **ainda não muda** aqui. Ele só é atualizado no fim do método. Isso é importante para os desvios: eles precisam calcular o destino a partir do PC da instrução atual.

### 9.2 Decodificação

```csharp
    // 2. DECODIFICAÇÃO
    int opcode = inst & 0x7F;
    int rd = (inst >>> 7) & 0x1F;
    int funct3 = (inst >>> 12) & 0x7;
    int rs1 = (inst >>> 15) & 0x1F;
    int rs2 = (inst >>> 20) & 0x1F;
    int funct7 = (inst >>> 25) & 0x7F;
    int a = _x[rs1];
    int b = _x[rs2];
    string d;
```

Cada campo é extraído do mesmo jeito: **desloca para a direita** até o campo chegar no bit 0, depois **aplica uma máscara** que guarda só a quantidade de bits do campo.

| Campo | Bits na instrução | Deslocamento | Máscara | Bits |
|---|---|---|---|---|
| `opcode` | 6-0 | nenhum | `0x7F` = `1111111` | 7 |
| `rd` | 11-7 | `>>> 7` | `0x1F` = `11111` | 5 |
| `funct3` | 14-12 | `>>> 12` | `0x7` = `111` | 3 |
| `rs1` | 19-15 | `>>> 15` | `0x1F` | 5 |
| `rs2` | 24-20 | `>>> 20` | `0x1F` | 5 |
| `funct7` | 31-25 | `>>> 25` | `0x7F` | 7 |

```
 31      25 24   20 19   15 14  12 11    7 6       0
┌──────────┬───────┬───────┬──────┬───────┬─────────┐
│  funct7  │  rs2  │  rs1  │funct3│  rd   │ opcode  │   formato R
└──────────┴───────┴───────┴──────┴───────┴─────────┘
```

Usa-se `>>>` (lógico) para não trazer bits de sinal para dentro do campo. Como depois vem a máscara, `>>` também funcionaria, mas `>>>` deixa a intenção clara.

Repare que **todos os campos são extraídos sempre**, mesmo quando a instrução não usa algum deles (o tipo I não tem `rs2` nem `funct7` de verdade; ali estão bits do imediato). É assim no hardware também: os fios sempre existem, e o controle decide quais valores importam.

- `a` e `b` são os valores lidos do banco de registradores (as duas portas de leitura do datapath).
- `d` vai receber o texto da instrução para `UltimaDescricao`.

O exemplo completo, com os bits de uma instrução de verdade, está em [[Sim 06 - Rastreio de uma Instrução Bit a Bit]].

### 9.3 Execução: o `switch` pelo opcode

```csharp
    // 3, 4 e 5. EXECUÇÃO, ACESSO À MEMÓRIA E ARMAZENAMENTO
    switch (opcode)
    {
```

O opcode escolhe o "caminho". Esse `switch` faz o papel da **unidade de controle principal** do datapath.

#### Tipo R (`case OpR`)

```csharp
        case OpR:
            {
                AluOp op = funct3 switch
                {
                    0b000 => funct7 == 0b0100000 ? AluOp.Sub : AluOp.Add,
                    0b001 => AluOp.Sll,
                    0b010 => AluOp.Slt,
                    0b011 => AluOp.Sltu,
                    0b100 => AluOp.Xor,
                    0b101 => funct7 == 0b0100000 ? AluOp.Sra : AluOp.Srl,
                    0b110 => AluOp.Or,
                    _ => AluOp.And
                };
                EscreverReg(rd, Alu.Executar(op, a, b));
                d = $"{op.ToString().ToLower()} {Nomes[rd]}, {Nomes[rs1]}, {Nomes[rs2]}";
                break;
            }
```

Instruções do tipo R operam **registrador com registrador**: `rd = rs1 (operação) rs2`.

O `funct3` diz a operação. Em dois casos ele sozinho não basta, e o `funct7` desempata:

| `funct3` | `funct7 = 0000000` | `funct7 = 0100000` |
|---|---|---|
| `000` | `add` | `sub` |
| `001` | `sll` | |
| `010` | `slt` | |
| `011` | `sltu` | |
| `100` | `xor` | |
| `101` | `srl` | `sra` |
| `110` | `or` | |
| `111` | `and` | |

Esse `switch` interno é o **controle da ULA** da aula: recebe `funct3` e `funct7` e gera a operação da ULA.

Depois: a ULA calcula com os valores de `rs1` e `rs2`, e `EscreverReg` guarda em `rd`.

O `_` no fim cobre `111` (`and`). Como `funct3` tem 3 bits, só existem 8 valores, e os outros 7 já foram listados.

As chaves `{ }` em volta do `case` criam um bloco próprio. Sem elas, a variável `op` deste caso entraria em conflito com a `op` do caso do tipo I.

#### Instrução especial do grupo 4: POPCNT (`cpop`)

```csharp
        case OpI when funct3 == 0b001 && funct7 == Funct7Zbb: // clz, ctz e cpop (Zbb)
            {
                // Tem o mesmo funct3 do slli: precisa vir antes do case OpI.
                if (rs2 != Rs2Cpop) // só o cpop (POPCNT) está implementado
                    throw new SimuladorException($"Instrução Zbb não implementada 0x{inst:X8} em PC=0x{Pc:X5}");
                EscreverReg(rd, Alu.Executar(AluOp.Cpop, a, 0));
                d = $"cpop {Nomes[rd]}, {Nomes[rs1]}  (POPCNT)";
                break;
            }
```

O enunciado manda cada grupo implementar uma instrução extra. A do grupo 4 é o **POPCNT** (*population count*): `rd` recebe **quantos bits valem 1** em `rs1`. Exemplo: `rs1 = 0xFF` dá 8, e `rs1 = -1` (`0xFFFFFFFF`) dá 32.

Essa instrução existe de verdade no RISC-V, na extensão **Zbb** (manipulação de bits), com o nome **`cpop`**. O simulador usa a **codificação oficial** em vez de inventar uma. Assim, um programa compilado com a extensão Zbb ligada (por exemplo, `-march=rv32i_zbb` no compilador) pode gerar `cpop` para a função `__builtin_popcount` do C, e o simulador entende.

**Como a instrução é codificada.** O `cpop` usa o formato I com opcode `OpI` e `funct3 = 001`, o mesmo do `slli`. A diferença está nos bits 31-20:

| Bits | `slli` | `cpop` |
|---|---|---|
| 31-25 (`funct7`) | `0000000` | `0110000` |
| 24-20 (`rs2`) | quantidade de deslocamento | `00010` (fixo) |
| 19-15 | `rs1` | `rs1` |
| 14-12 | `001` | `001` |
| 11-7 | `rd` | `rd` |
| 6-0 | `0010011` | `0010011` |

O campo onde ficaria o `rs2` não é registrador aqui: ele diferencia três instruções irmãs do Zbb com o mesmo `funct7`: `clz` (`00000`), `ctz` (`00001`) e `cpop` (`00010`).

**Por que o `case` vem antes do `case OpI`.** Se o `cpop` caísse no `case OpI`, o `funct3 = 001` faria a CPU executar um `slli` com deslocamento 2, sem nenhum aviso. O `when funct3 == 0b001 && funct7 == Funct7Zbb` separa o `cpop` antes. Em C#, os `case` são testados em ordem, e o compilador nem aceita um `case OpI when ...` depois de um `case OpI:` sem condição.

**`clz` e `ctz`** têm o mesmo `funct7`, mas não fazem parte do trabalho do grupo. Em vez de executar errado, a CPU lança "Instrução Zbb não implementada".

A contagem em si fica na ULA (`AluOp.Cpop`), como as outras operações. Ver [[Sim 04 - Alu (ULA)]].

#### Tipo I aritmético (`case OpI`)

```csharp
        case OpI:
            {
                int imm = ImediatoI(inst);
                (AluOp op, string nome) = funct3 switch
                {
                    0b000 => (AluOp.Add, "addi"),
                    0b010 => (AluOp.Slt, "slti"),
                    0b011 => (AluOp.Sltu, "sltiu"),
                    0b100 => (AluOp.Xor, "xori"),
                    0b110 => (AluOp.Or, "ori"),
                    0b111 => (AluOp.And, "andi"),
                    0b001 => (AluOp.Sll, "slli"),
                    _ => funct7 == 0b0100000 ? (AluOp.Sra, "srai") : (AluOp.Srl, "srli")
                };
                if (funct3 is 0b001 or 0b101) imm &= 0x1F; // shamt
                EscreverReg(rd, Alu.Executar(op, a, imm));
                d = $"{nome} {Nomes[rd]}, {Nomes[rs1]}, {imm}";
                break;
            }
```

Instruções do tipo I operam **registrador com constante**: `rd = rs1 (operação) imediato`. O imediato são os 12 bits mais altos da instrução, com sinal.

```
 31                 20 19   15 14  12 11    7 6       0
┌─────────────────────┬───────┬──────┬───────┬─────────┐
│     imm[11:0]       │  rs1  │funct3│  rd   │ opcode  │   formato I
└─────────────────────┴───────┴──────┴───────┴─────────┘
```

Diferenças em relação ao tipo R:

- A ULA recebe `imm` no lugar de `b`. No datapath, é o multiplexador `ALUSrc` escolhendo o imediato em vez do registrador.
- O `switch` devolve uma **tupla** `(operação, nome)`. O nome é necessário porque aqui não dá para usar `op.ToString()`: `AluOp.Add` viraria `"add"`, mas a instrução é `addi`.
- **Deslocamentos (`slli`, `srli`, `srai`):** a quantidade de deslocamento cabe em 5 bits (`imm[4:0]`). Os bits de cima do campo imediato funcionam como um `funct7`. Para `srai`, o bit 30 vem ligado (`funct7 = 0100000`), o que faz o imediato "bruto" valer `0x400 + shamt`. Por isso a linha `imm &= 0x1F` limpa tudo menos os 5 bits menores antes de usar.
- `funct3 is 0b001 or 0b101` é um padrão: "funct3 é 001 **ou** 101".

| `funct3` | Instrução | Observação |
|---|---|---|
| `000` | `addi` | |
| `010` | `slti` | |
| `011` | `sltiu` | o imediato é estendido com sinal e **depois** comparado sem sinal |
| `100` | `xori` | |
| `110` | `ori` | |
| `111` | `andi` | |
| `001` | `slli` | usa só `imm[4:0]` |
| `101` | `srli` ou `srai` | `funct7` decide |

#### Leitura da memória: `lw` (`case OpLoad`)

```csharp
        case OpLoad when funct3 == 0b010: // lw
            {
                int imm = ImediatoI(inst);
                int endereco = Alu.Executar(AluOp.Add, a, imm); // ULA calcula o endereço
                EscreverReg(rd, _bus.Ler(endereco));             // lê pelo barramento
                d = $"lw {Nomes[rd]}, {imm}({Nomes[rs1]})  [0x{endereco:X5}]";
                break;
            }
```

`lw rd, imm(rs1)` lê uma palavra da memória: `rd = memória[rs1 + imm]`. Usa o mesmo formato I do `addi` (o imediato está nos bits 31-20). Só o opcode muda.

1. **Execução:** a ULA soma o registrador base com o deslocamento. Aqui ela não faz uma conta do programa, só calcula o endereço. Exemplo: `lw a0, 8(s0)` com `s0 = 0x400` lê o endereço `0x408`.
2. **Acesso à memória:** `_bus.Ler(endereco)` usa o barramento pela segunda vez na mesma instrução (a primeira foi a busca). A memória confere limites e alinhamento, e um endereço inválido lança `SimuladorException`.
3. **Armazenamento:** o valor lido vai para `rd`, pelo mesmo `EscreverReg` das outras instruções.

O `when funct3 == 0b010` deixa entrar só o `lw`. O mesmo opcode também é usado por `lb`, `lh`, `lbu` e `lhu`, que o projeto não pede. Com outro `funct3`, a instrução cai no `default` e dá erro.

A descrição mostra o endereço calculado entre colchetes, por exemplo `lw a0, 8(s0)  [0x00408]`. Isso ajuda a depurar.

#### Escrita na memória: `sw` (`case OpStore`)

```csharp
        case OpStore when funct3 == 0b010: // sw
            {
                int imm = ImediatoS(inst);
                int endereco = Alu.Executar(AluOp.Add, a, imm);
                _bus.Escrever(endereco, b);                      // escreve pelo barramento
                d = $"sw {Nomes[rs2]}, {imm}({Nomes[rs1]})  [0x{endereco:X5}]";
                break;
            }
```

`sw rs2, imm(rs1)` grava o valor de `rs2` na memória: `memória[rs1 + imm] = rs2`.

- O endereço é calculado igual ao do `lw`, mas o imediato vem de outro lugar da instrução (formato S, ver a seção 11 desta nota).
- `_bus.Escrever(endereco, b)`: `b` é o valor de `rs2`. Se o endereço cair na VRAM, os caracteres vão para a tela. Se cair na área reservada, a memória lança erro.
- **Não chama `EscreverReg`**: o `sw` não altera nenhum registrador. No formato S, os bits 11-7, onde ficaria o `rd`, guardam parte do imediato. Usar `rd` aqui estaria errado.

```
 31      25 24   20 19   15 14  12 11      7 6       0
┌──────────┬───────┬───────┬──────┬─────────┬─────────┐
│imm[11:5] │  rs2  │  rs1  │funct3│imm[4:0] │ opcode  │   formato S
└──────────┴───────┴───────┴──────┴─────────┴─────────┘
```

Por que o RISC-V parte o imediato em dois? Para que `rs1` e `rs2` fiquem sempre nas mesmas posições, em todos os formatos. Assim o hardware pode ler o banco de registradores antes de saber qual é a instrução.

#### Desvios condicionais (`case OpBranch`)

```csharp
        case OpBranch:
            {
                int imm = ImediatoB(inst);
                // A ULA compara: beq/bne olham a flag Zero da subtração,
                // blt/bge usam slt e bltu/bgeu usam sltu.
                (bool tomar, string nome) = funct3 switch
                {
                    0b000 => (Alu.Zero(Alu.Executar(AluOp.Sub, a, b)), "beq"),
                    0b001 => (!Alu.Zero(Alu.Executar(AluOp.Sub, a, b)), "bne"),
                    0b100 => (Alu.Executar(AluOp.Slt, a, b) == 1, "blt"),
                    0b101 => (Alu.Executar(AluOp.Slt, a, b) == 0, "bge"),
                    0b110 => (Alu.Executar(AluOp.Sltu, a, b) == 1, "bltu"),
                    0b111 => (Alu.Executar(AluOp.Sltu, a, b) == 0, "bgeu"),
                    _ => throw new SimuladorException($"Desvio inválido 0x{inst:X8} em PC=0x{Pc:X5}")
                };
                if (tomar) proximoPc = Pc + imm;
                d = $"{nome} {Nomes[rs1]}, {Nomes[rs2]}, {imm}  ({(tomar ? "tomado" : "não tomado")})";
                break;
            }
```

Os 6 desvios comparam `rs1` com `rs2`. Se a condição for verdadeira, o desvio é **tomado** e o programa pula para `PC + imm`. Se for falsa, segue para `PC + 4`, como qualquer outra instrução.

| `funct3` | Instrução | Desvia se | Como a ULA decide |
|---|---|---|---|
| `000` | `beq` | `rs1 == rs2` | `Sub` dá zero (flag Zero ligada) |
| `001` | `bne` | `rs1 != rs2` | `Sub` não dá zero |
| `100` | `blt` | `rs1 < rs2`, com sinal | `Slt` dá 1 |
| `101` | `bge` | `rs1 >= rs2`, com sinal | `Slt` dá 0 |
| `110` | `bltu` | `rs1 < rs2`, sem sinal | `Sltu` dá 1 |
| `111` | `bgeu` | `rs1 >= rs2`, sem sinal | `Sltu` dá 0 |

Pontos importantes:

- **Quem compara é a ULA.** O `beq` da aula faz exatamente isso: subtrai os dois registradores e olha a saída Zero. Os outros desvios seguem a mesma ideia com `slt` e `sltu`.
- **Não existe "maior que".** O `bge` cobre o "maior ou igual". Para "maior que", o montador troca a ordem dos registradores: `a > b` é o mesmo que `b < a`, então vira `blt b, a`.
- **O destino é relativo ao PC da própria instrução do desvio**, e não ao `PC + 4`. É por isso que o `Pc` só muda no fim do `Passo()`. Um imediato negativo volta no programa, e é assim que os laços funcionam.
- `if (tomar) proximoPc = Pc + imm;` faz o papel do multiplexador `PCSrc` da aula: escolhe entre `PC + 4` e o destino do desvio.
- `funct3` `010` e `011` não existem nos desvios, por isso o `_ =>` lança erro. Repare que um `throw` pode aparecer dentro de um `switch` de expressão.
- O desvio também não escreve em registrador: os bits 11-7 são parte do imediato.

O exemplo completo de um laço, com o desvio voltando 8 bytes, está em [[Sim 06 - Rastreio de uma Instrução Bit a Bit#7. Um desvio para trás no laço|Sim 06, seção 7]].

#### Fim de programa (`case OpSystem`)

```csharp
        case OpSystem when inst is InstEcall or InstEbreak:
            Parada = true;
            proximoPc = Pc;
            d = "ebreak/ecall (fim do programa)";
            break;
```

- `case OpSystem when ...`: só entra aqui se o opcode for `0x73` **e** a instrução inteira for exatamente `ecall` ou `ebreak`. Outras instruções com o mesmo opcode (como `mret`, que vai ser usada na interrupção) caem no `default` por enquanto.
- `Parada = true` faz os próximos `Passo()` não fazerem nada.
- `proximoPc = Pc`: o PC fica parado em cima do `ebreak`. Assim, depois que o programa termina, `cpu.Pc` mostra onde ele parou.

#### Instrução desconhecida (`default`)

```csharp
        default:
            throw new SimuladorException($"Instrução desconhecida 0x{inst:X8} em PC=0x{Pc:X5}");
    }
```

Qualquer opcode não tratado gera erro com a instrução em hexadecimal (`X8`: 8 dígitos) e o PC. Isso ajuda muito a depurar: se o PC sair do programa e cair em memória zerada, aparece "Instrução desconhecida 0x00000000", porque `0` não é uma instrução válida.

Instruções que o simulador não implementa, como `lb`, `jal` ou `lui`, também caem aqui.

### 9.4 Finalização

```csharp
    UltimaDescricao = $"0x{Pc:X5}: {inst:X8}  {d}";
    Pc = proximoPc;
    InstrucoesExecutadas++;
}
```

1. Monta o texto da instrução executada, com o PC **antigo** (o endereço da instrução que acabou de rodar), o código em hexadecimal e a instrução legível.
2. **Só agora** o PC recebe o próximo endereço.
3. Conta a instrução. O `ebreak` também é contado.

Se uma exceção acontecer no meio (endereço inválido, instrução desconhecida), essas três linhas não rodam. O PC continua apontando para a instrução que deu erro, o que facilita achar o problema.

## 10. `ImediatoI(int i)`

```csharp
// Imediatos com extensão de sinal (>> em int repete o bit de sinal)
public static int ImediatoI(int i) => i >> 20;
```

O imediato do tipo I está nos bits 31-20. Deslocar a instrução 20 posições para a direita traz esses 12 bits para o fim do número.

O detalhe importante é que aqui se usa `>>` (aritmético) e não `>>>`. Como `i` é `int`, o `>>` **repete o bit 31** em todas as posições que ficaram vazias. O bit 31 é o bit de sinal do imediato, então o resultado já sai com **extensão de sinal**, sem precisar de máscara nem de conta extra.

Exemplo com `addi t0, zero, -20`:

```
instrução:      1111 1110 1100 0000 0000 0010 1001 0011   (0xFEC00293)
                └───── imm = 0xFEC ───┘
inst >> 20:     1111 1111 1111 1111 1111 1111 1110 1100   (0xFFFFFFEC = -20)
                └─ copiado do bit 31 ─┘
```

Se fosse `>>>`, o resultado seria `0x00000FEC` = 4076, que está errado.

É `public static` para os testes e outras partes poderem usar sem criar uma CPU.

## 11. `ImediatoS(int i)`

```csharp
/// <summary>Tipo S: [31:25] e [11:7] juntos.</summary>
public static int ImediatoS(int i) => ((i >> 25) << 5) | ((i >>> 7) & 0x1F);
```

Junta os dois pedaços do imediato do formato S (usado pelo `sw`):

- `i >> 25` traz os bits 31-25 (`imm[11:5]`) para baixo. Como é `>>` em `int`, o bit de sinal se espalha. Depois, `<< 5` abre espaço para os 5 bits de baixo.
- `(i >>> 7) & 0x1F` pega os bits 11-7 (`imm[4:0]`).
- O `|` junta os dois.

Exemplo com `sw t1, -4(s0)`, que vira `0xFE642E23`:

```
1111111  00110  01000  010  11100  0100011
imm[11:5] rs2   rs1    f3  imm[4:0] opcode
```

`imm[11:5] = 1111111` vira `...11111111` com o sinal espalhado e, deslocado 5 casas, `...1111100000`. `imm[4:0] = 11100`. Juntando: `...1111111100`, que é **-4**.

## 12. `ImediatoB(int i)`

```csharp
/// <summary>Tipo B: bits embaralhados, o bit 0 é sempre 0 (desvio de 2 em 2 bytes).</summary>
public static int ImediatoB(int i) =>
      ((i >> 31) << 12)             // imm[12]   vem do bit 31 (com sinal)
    | (((i >>> 7) & 0x1) << 11)     // imm[11]   vem do bit 7
    | (((i >>> 25) & 0x3F) << 5)    // imm[10:5] vem dos bits 30:25
    | (((i >>> 8) & 0xF) << 1);     // imm[4:1]  vem dos bits 11:8
```

O imediato dos desvios tem 13 bits (`imm[12]` até `imm[0]`), mas só 12 ficam guardados na instrução. O `imm[0]` não precisa ser guardado porque é sempre 0: as instruções ficam em endereços pares. Com esse truque, o alcance do desvio dobra, indo de -4096 a +4094 bytes.

Os bits vêm embaralhados, e cada linha do código pega um pedaço e coloca na posição certa:

| Pedaço | Está no(s) bit(s) da instrução | Vai para |
|---|---|---|
| `imm[12]` (sinal) | 31 | 12, com extensão de sinal |
| `imm[11]` | 7 | 11 |
| `imm[10:5]` | 30-25 | 10-5 |
| `imm[4:1]` | 11-8 | 4-1 |

Só a primeira linha usa `>>` (aritmético), porque é ela que carrega o sinal. As outras usam `>>>` com máscara, porque só querem os bits do pedaço.

Exemplo com o `blt t0, t1, laco` do teste `LacoSoma1Ate10`, que volta 8 bytes e vira `0xFE62CCE3`:

```
bit 31      = 1       → imm[12] = 1 (número negativo)
bits 30-25  = 111111  → imm[10:5]
bits 11-8   = 1100    → imm[4:1]
bit 7       = 1       → imm[11]

imm = 1 1 111111 1100 0  (13 bits) = 1111111111000 = -8
```

O embaralhamento parece estranho, mas segue a mesma lógica do formato S: deixar `rs1`, `rs2` e o bit de sinal sempre no mesmo lugar, o que simplifica o hardware.

## 13. `EscreverReg(int rd, int valor)`

```csharp
private void EscreverReg(int rd, int valor)
{
    if (rd != 0) _x[rd] = valor; // x0 é sempre zero
}
```

Toda escrita em registrador passa por aqui. A regra do RISC-V é que **`x0` sempre vale zero**: qualquer escrita nele é descartada. Como `_x[0]` nunca é alterado, ele fica 0 para sempre (o `Reset` zerou).

Isso permite truques do Assembly, como `addi x0, x0, 0` servir de `nop` (não faz nada) e `add rd, rs, zero` servir para copiar um registrador.

## 14. Ligação com a matéria

| Parte do `Passo()` | Etapa da aula | Bloco do datapath |
|---|---|---|
| `_bus.Ler(Pc)` | busca | memória de instruções |
| `Pc + 4` | busca | somador do PC |
| deslocamentos e máscaras | decodificação | fios saindo da instrução para cada bloco |
| `_x[rs1]`, `_x[rs2]` | decodificação | portas de leitura do banco de registradores |
| `switch (opcode)` | controle | unidade de controle principal |
| `switch` de `funct3`/`funct7` | controle | controle da ULA |
| `case` do `cpop` | execução | uma operação a mais na ULA, a instrução especial do grupo |
| `Alu.Executar` | execução | ULA |
| `ImediatoI`, `ImediatoS`, `ImediatoB` | decodificação | gerador de imediato |
| `Alu.Executar(AluOp.Add, a, imm)` no `lw`/`sw` | execução | ULA calculando o endereço |
| `_bus.Ler(endereco)` e `_bus.Escrever(endereco, b)` | acesso à memória | memória de dados, com os sinais `MemRead` e `MemWrite` |
| `imm` no lugar de `b` | execução | multiplexador `ALUSrc` |
| `EscreverReg` | armazenamento (write-back) | porta de escrita do banco, com `RegWrite`. No `lw`, o valor vem da memória e não da ULA (o sinal `MemtoReg`) |
| `if (tomar) proximoPc = Pc + imm` e `Pc = proximoPc` | atualização do PC | somador do desvio e multiplexador `PCSrc` (`Branch AND Zero`) |

Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#9. Datapath básico completo (slide 17)|nota 09, seção 9]] e as seções 11.1 a 11.3 da mesma nota, que mostram a execução de `add`, `lw` e `beq` no datapath.

O ciclo da aula de interrupções tem mais uma etapa no final, a **verificação de interrupção**. Ela ainda não existe no `Passo()`.

## 15. Limitações conhecidas

- **Só `lw` e `sw` acessam a memória.** `lb`, `lh`, `lbu`, `lhu`, `sb` e `sh` não existem e caem no `default`. O enunciado não pede essas instruções, mas programas gerados por compilador (por exemplo, no godbolt.org) costumam usar, principalmente quando mexem com texto (`char`).
- **Sem `lui`, `auipc`, `jal` e `jalr`.** Também não são pedidas. Mas sem `lui` não dá para colocar uma constante maior que 12 bits num registrador com uma instrução só (por isso os testes montam `0x80000` com `addi` seguido de `slli`), e sem `jal`/`jalr` não existe chamada de função. Isso vai pesar na hora do programa de teste.
- **`funct7` não é validado.** No tipo R, qualquer `funct7` diferente de `0100000` é tratado como `0000000`. Por exemplo, `mul` (da extensão M, `funct7 = 0000001`) seria executado como `add` sem aviso. O mesmo vale para `slli`/`srli` com bits altos errados. Para o projeto isso não atrapalha, porque o montador só gera instruções válidas, mas um `.hex` gerado por compilador com extensões ativadas poderia dar resultado errado em silêncio.
- **Desvio para um endereço que não é múltiplo de 4:** o desvio em si funciona, mas a busca seguinte falha com "Acesso desalinhado". No RISC-V sem a extensão C (instruções comprimidas), isso também é um erro, então o comportamento é coerente.
- **Sem verificação de interrupção** no fim do ciclo.
- **Do Zbb, só o `cpop` existe.** As outras instruções da extensão (como `clz`, `ctz`, `andn`, `min`) não são pedidas para o grupo 4. As que usam o mesmo `funct7` do `cpop` dão erro, e as outras caem nos casos já descritos acima.
