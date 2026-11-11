---
tags: [projeto-final, simulador, cpu, risc-v, rv32i, decodificação, ciclo-de-instrução, csharp]
arquivo: Simulator.core/Cpu.cs
bloco-do-enunciado: CPU (3 pts)
---

# Cpu.cs: o processador

← [[Sim 04 - Alu (ULA)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 06 - Rastreio de uma Instrução Bit a Bit]]

## 1. Para que serve

A `Cpu` é o processador RISC-V **de ciclo único**: cada chamada de `Passo()` executa **uma instrução inteira**, do começo ao fim, antes de começar a próxima. Ela guarda:

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
| `OpI` | `0010011` | `0x13` | tipo I aritmético: `addi`, `slli`... | tratado |
| `OpLoad` | `0000011` | `0x03` | `lw` | **declarado, ainda não tratado** |
| `OpStore` | `0100011` | `0x23` | `sw` | **declarado, ainda não tratado** |
| `OpBranch` | `1100011` | `0x63` | `beq`, `bne`, `blt`... | **declarado, ainda não tratado** |
| `OpSystem` | `1110011` | `0x73` | `ecall`, `ebreak` | tratado (só esses dois) |

São `public` porque o `Montador` usa os mesmos valores para gerar as instruções. Assim, CPU e montador nunca discordam sobre o opcode.

## 3. `InstEcall` e `InstEbreak`

```csharp
public const int InstEcall = 0x00000073;
public const int InstEbreak = 0x00100073;
```

Diferente das outras instruções, `ecall` e `ebreak` não têm registradores variáveis: cada uma é **um número fixo de 32 bits**. Os dois têm opcode `0x73` (`OpSystem`) e só diferem no bit 20.

No simulador, qualquer uma das duas **encerra o programa**. Num RISC-V real, `ecall` chama o sistema operacional e `ebreak` chama o depurador. Como aqui não existe sistema operacional, usar como "fim" é a escolha mais simples.

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
```

| Membro | O que é | Equivalente no hardware |
|---|---|---|
| `_bus` | o barramento por onde a CPU acessa a memória | ligação CPU-barramento |
| `_x` | vetor com os 32 registradores de 32 bits | banco de registradores |
| `Pc` | endereço da próxima instrução | registrador PC |
| `Parada` | `true` depois de `ecall`/`ebreak` | sinal de halt |
| `InstrucoesExecutadas` | contador de instruções | contador de desempenho |
| `UltimaDescricao` | texto da última instrução, por exemplo `0x00008: 00628533  add a0, t0, t1` | não existe no hardware, é para depuração |

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
    // 3 e 4. EXECUÇÃO E ARMAZENAMENTO
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

Hoje `lw`, `sw` e os desvios também caem aqui.

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

## 11. `EscreverReg(int rd, int valor)`

```csharp
private void EscreverReg(int rd, int valor)
{
    if (rd != 0) _x[rd] = valor; // x0 é sempre zero
}
```

Toda escrita em registrador passa por aqui. A regra do RISC-V é que **`x0` sempre vale zero**: qualquer escrita nele é descartada. Como `_x[0]` nunca é alterado, ele fica 0 para sempre (o `Reset` zerou).

Isso permite truques do Assembly, como `addi x0, x0, 0` servir de `nop` (não faz nada) e `add rd, rs, zero` servir para copiar um registrador.

## 12. Ligação com a matéria

| Parte do `Passo()` | Etapa da aula | Bloco do datapath |
|---|---|---|
| `_bus.Ler(Pc)` | busca | memória de instruções |
| `Pc + 4` | busca | somador do PC |
| deslocamentos e máscaras | decodificação | fios saindo da instrução para cada bloco |
| `_x[rs1]`, `_x[rs2]` | decodificação | portas de leitura do banco de registradores |
| `switch (opcode)` | controle | unidade de controle principal |
| `switch` de `funct3`/`funct7` | controle | controle da ULA |
| `Alu.Executar` | execução | ULA |
| `imm` no lugar de `b` | execução | multiplexador `ALUSrc` |
| `EscreverReg` | armazenamento (write-back) | porta de escrita do banco, com `RegWrite` |
| `Pc = proximoPc` | atualização do PC | multiplexador `PCSrc` (hoje sempre `PC + 4`) |

Ver [[09 - Processador e Datapath RISC-V (Microprocessador I)#9. Datapath básico completo (slide 17)|nota 09, seção 9]] e a seção 11.1 da mesma nota (execução do `add`).

O ciclo da aula de interrupções tem mais uma etapa no final, a **verificação de interrupção**. Ela ainda não existe no `Passo()`.

## 13. Limitações conhecidas

- **`lw`, `sw` e desvios ainda não existem.** Os opcodes estão declarados, mas caem no `default`.
- **`funct7` não é validado.** No tipo R, qualquer `funct7` diferente de `0100000` é tratado como `0000000`. Por exemplo, `mul` (da extensão M, `funct7 = 0000001`) seria executado como `add` sem aviso. O mesmo vale para `slli`/`srli` com bits altos errados. Para o projeto isso não atrapalha, porque o montador só gera instruções válidas, mas um `.hex` gerado por compilador com extensões ativadas poderia dar resultado errado em silêncio.
- **Sem verificação de interrupção** no fim do ciclo.
- **Sem a instrução especial do grupo.**
