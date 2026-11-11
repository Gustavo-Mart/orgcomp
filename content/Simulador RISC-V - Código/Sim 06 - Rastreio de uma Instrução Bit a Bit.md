---
tags: [projeto-final, simulador, cpu, decodificação, exemplo-resolvido]
arquivo: Simulator.core/Cpu.cs (na prática)
---

# Rastreio de uma instrução bit a bit

← [[Sim 05 - Cpu (Processador)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 07 - Montador (Gerador de Instruções)]]

Esta nota segue o começo do teste `InstrucoesTipoR` dentro do simulador, para mostrar o que cada linha de `Cpu.Passo()` faz com números de verdade. É um bom roteiro para explicar o código na apresentação.

## 1. O programa na memória

O teste monta este programa (os primeiros 4 de 13 instruções):

| Endereço | Código (hex) | Assembly |
|---|---|---|
| `0x00000` | `FEC00293` | `addi t0, zero, -20` |
| `0x00004` | `00300313` | `addi t1, zero, 3` |
| `0x00008` | `00628533` | `add a0, t0, t1` |
| `0x0000C` | `406285B3` | `sub a1, t0, t1` |
| ... | ... | ... |
| `0x00030` | `00100073` | `ebreak` |

`Montador.Rodar` grava cada código com `bus.Escrever(4 * k, codigo[k])`, ou seja, nos endereços 0, 4, 8, 12... Depois cria a CPU (PC = 0) e chama `Passo()` até `Parada` ficar `true`.

## 2. Passo 1: `addi t0, zero, -20`

**Busca.** `_bus.Ler(0)`:
- `Enderecos = 0x00000`, `SinalControle = Leitura`
- a memória devolve os bytes `93 02 C0 FE` (little-endian), que viram `0xFEC00293`
- `Dados = 0xFEC00293`, `Leituras` sobe de 0 para 1 (a carga do programa só gerou escritas)
- `proximoPc = 4`

**Decodificação.**

```
0xFEC00293 = 1111111 01100 00000 000 00101 0010011
             funct7  rs2   rs1   f3  rd    opcode
```

| Campo | Bits | Valor | Significado |
|---|---|---|---|
| `opcode` | `0010011` | `0x13` | `OpI` |
| `rd` | `00101` | 5 | `t0` |
| `funct3` | `000` | 0 | `addi` |
| `rs1` | `00000` | 0 | `zero` |
| `rs2`, `funct7` | | | lixo para o tipo I (são bits do imediato) |

`ImediatoI(0xFEC00293)` = `0xFEC00293 >> 20` = `0xFFFFFFEC` = **-20** (o `>>` repetiu o bit 31, que é 1).

**Execução.** `Alu.Executar(Add, _x[0], -20)` = `0 + (-20)` = -20.

**Armazenamento.** `EscreverReg(5, -20)`: `rd` não é 0, então `t0 = -20`.

**Fim.** `UltimaDescricao = "0x00000: FEC00293  addi t0, zero, -20"`, `Pc = 4`, `InstrucoesExecutadas = 1`.

## 3. Passo 2: `addi t1, zero, 3`

Igual ao anterior: `0x00300313` tem imediato `0x003` = 3 e `rd = 6` (`t1`). Resultado: `t1 = 3`, `Pc = 8`.

## 4. Passo 3: `add a0, t0, t1` (o caso completo do tipo R)

**Busca.** `_bus.Ler(8)` devolve `0x00628533`. `proximoPc = 12`.

**Decodificação**, linha por linha do código:

```
0x00628533 = 0000000 00110 00101 000 01010 0110011
             funct7  rs2   rs1   f3  rd    opcode
```

| Linha do código | Conta | Resultado |
|---|---|---|
| `inst & 0x7F` | `0x00628533 & 0x7F` | `0x33` = `0110011` → `OpR` |
| `(inst >>> 7) & 0x1F` | `0xC50A & 0x1F` | `0x0A` = 10 → `a0` |
| `(inst >>> 12) & 0x7` | `0x628 & 0x7` | 0 |
| `(inst >>> 15) & 0x1F` | `0xC5 & 0x1F` | 5 → `t0` |
| `(inst >>> 20) & 0x1F` | `0x6 & 0x1F` | 6 → `t1` |
| `(inst >>> 25) & 0x7F` | `0x0 & 0x7F` | 0 |
| `a = _x[rs1]` | `_x[5]` | -20 |
| `b = _x[rs2]` | `_x[6]` | 3 |

Veja como funciona o deslocamento seguido de máscara no caso do `rd`: `inst >>> 7` "empurra" para fora os 7 bits do opcode, deixando o `rd` nos bits 4-0. Mas ainda sobram os campos de cima (`0xC50A` tem bits além dos 5 primeiros). O `& 0x1F` apaga tudo acima do bit 4.

**Execução.** `opcode` é `OpR`, `funct3` é `000` e `funct7` não é `0100000`, então `op = AluOp.Add`. A ULA faz `-20 + 3 = -17`.

**Armazenamento.** `a0 = -17`.

**Fim.** `UltimaDescricao = "0x00008: 00628533  add a0, t0, t1"`, `Pc = 12`.

## 5. Passo 4: `sub a1, t0, t1` (só o `funct7` muda)

```
0x406285B3 = 0100000 00110 00101 000 01011 0110011
```

Mesmo `opcode`, mesmo `funct3`, mesmos `rs1` e `rs2`. A diferença é `funct7 = 0100000` (o bit 30 ligado) e `rd = 11` (`a1`). O `switch` do tipo R escolhe `AluOp.Sub`: `-20 - 3 = -23`.

Comparando os dois códigos em hexadecimal, `00628533` e `406285B3`, o `4` no começo é exatamente o bit 30, e o `5B3` no fim reflete o `rd` diferente.

## 6. O último passo: `ebreak`

`_bus.Ler(0x30)` devolve `0x00100073`. O opcode é `0x73` (`OpSystem`) e a instrução é igual a `InstEbreak`, então `Parada = true` e o PC fica em `0x30`. O laço do `Rodar` para. O teste então confere os registradores com `cpu[A0]`, `cpu[A1]` etc.

## 7. Estado do barramento no fim

No teste `InstrucoesTipoR`:

- **Escritas:** 13, uma por instrução carregada pelo `Montador.Rodar`. Nenhuma instrução do programa escreve na memória.
- **Leituras:** 13, uma busca por instrução executada (12 instruções mais o `ebreak`).
- **InstrucoesExecutadas:** 13.

