---
tags: [projeto-final, simulador, assembly, risc-v, e-s-programada, popcnt]
arquivos: Simulator.core/ProgramaDemo.cs, exemplos/demo.hex
---

# Programa de demonstração

← [[Sim 12 - Computador (Carregar e Executar)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 10 - Conceitos de CSharp Usados no Código]]

## 1. Para que serve

É o programa RISC-V que o simulador roda quando nenhum arquivo `.hex` é informado. Ele foi feito para mostrar, numa execução só, tudo o que o simulador já sabe fazer:

- escrever texto na VRAM com `sw` (E/S programada);
- um laço com desvio para trás (soma de 1 a 10);
- a instrução especial do grupo 4 (`cpop`, o POPCNT);
- a tela mudando durante a execução (uma barra de progresso);
- resultados calculados aparecendo em decimal na tela.

O mesmo programa está em dois lugares:

| Arquivo | Uso |
|---|---|
| `Simulator.core/ProgramaDemo.cs` | dentro do código, numa constante de texto. É o que o aplicativo roda por padrão e o que o teste `ProgramaDemoRodaAteOFim` confere |
| `exemplos/demo.hex` | o mesmo conteúdo como arquivo, para testar a leitura de `.hex`: `Simulador exemplos\demo.hex` |

São **189 instruções** na memória, e a execução completa leva **576 instruções**.

## 2. A tela no final

```
linha 0  SIMULADOR RISC-V
linha 1  GRUPO 4 - POPCNT
linha 2
linha 3  ########################################
linha 4
linha 5  SOMA DE 1 A 10: 55
linha 6  POPCNT DA SOMA: 5
linha 7
linha 8  FIM.
```

Cada linha começa no endereço `0x80000 + linha × 40`. Por isso os `sw` usam deslocamentos como `40(s1)` (linha 1), `120(s1)` (linha 3) e `200(s1)` (linha 5), com `s1 = 0x80000`.

## 3. Como o programa funciona, parte por parte

O formato de cada linha do `.hex` é: o código da instrução, o endereço dela (em hexadecimal) e o Assembly correspondente, depois do `#`.

### 3.1 Apontar para a VRAM

```
00100493  # 000          addi s1, zero, 1
01349493  # 004          slli s1, s1, 19      # s1 = 0x80000
```

`0x80000` não cabe no imediato de 12 bits do `addi` (o máximo é 2047). Sem `lui`, o jeito é carregar 1 e deslocar 19 casas: `1 << 19 = 0x80000`.

### 3.2 Escrever um texto: 4 caracteres por palavra

```
05500293  # 008          addi t0, zero, 0x55   # 'U'
00829293  # 00C          slli t0, t0, 8
04D2E293  # 010          ori  t0, t0, 0x4D   # 'M'
00829293  # 014          slli t0, t0, 8
0492E293  # 018          ori  t0, t0, 0x49   # 'I'
00829293  # 01C          slli t0, t0, 8
0532E293  # 020          ori  t0, t0, 0x53   # 'S'
0054A023  # 024          sw   t0, 0(s1)     # escreve "SIMU"
```

Para escrever `"SIMU"`, o programa monta a palavra `0x554D4953` em `t0` e grava com um `sw`. Como o primeiro caractere precisa ficar no byte de baixo (little-endian), a montagem começa pelo **último** caractere (`U`) e vai empurrando para cima com `slli 8`, colocando cada caractere novo no byte de baixo com `ori`.

| Depois de | `t0` |
|---|---|
| `addi 'U'` | `0x00000055` |
| `slli` + `ori 'M'` | `0x0000554D` |
| `slli` + `ori 'I'` | `0x00554D49` |
| `slli` + `ori 'S'` | `0x554D4953` |

São 8 instruções para cada 4 caracteres. Com `lui` seriam só 3, mas o simulador não tem essa instrução. As duas primeiras linhas da tela (16 caracteres cada) usam 8 palavras.

### 3.3 Soma de 1 a 10

```
00000513  # 108          addi a0, zero, 0     # soma = 0
00100313  # 10C          addi t1, zero, 1     # i = 1
00B00393  # 110          addi t2, zero, 11    # limite
00650533  # 114  soma:   add  a0, a0, t1      # soma += i
00130313  # 118          addi t1, t1, 1       # i++
FE734CE3  # 11C          blt  t1, t2, soma    # repete enquanto i < 11
```

O mesmo laço explicado em [[Sim 06 - Rastreio de uma Instrução Bit a Bit]]. No fim, `a0 = 55`.

### 3.4 A instrução do grupo 4

```
60251593  # 120          cpop a1, a0          # POPCNT(55) = 5
```

`55` em binário é `110111`, com 5 bits ligados. Então `a1 = 5`.

### 3.5 Barra de progresso

```
07848693  # 140          addi a3, s1, 120     # a3 = início da linha 3
00A00713  # 144          addi a4, zero, 10    # 10 blocos
00F00813  # 148          addi a6, zero, 15    # tamanho da espera
00C6A023  # 14C  barra:  sw   a2, 0(a3)       # desenha um bloco
00468693  # 150          addi a3, a3, 4
00000793  # 154          addi a5, zero, 0
00178793  # 158  espera: addi a5, a5, 1
FF07CEE3  # 15C          blt  a5, a6, espera  # gasta instruções para a tela mostrar a barra crescendo
FFF70713  # 160          addi a4, a4, -1
FE0714E3  # 164          bne  a4, zero, barra
```

`a2` já tem `0x23232323` (`"####"`), montado do mesmo jeito da seção 3.2. O laço `barra` grava um bloco de 4 caracteres, avança o ponteiro `a3` em 4 bytes e repete 10 vezes, enchendo os 40 caracteres da linha 3.

O laço `espera` não faz nada de útil: só conta até 15. Ele existe para "gastar" instruções entre um bloco e outro. Cada bloco leva 35 instruções, então com a tela conferida a cada 50 instruções dá para ver a barra crescendo de tela em tela. Sem a espera, a barra inteira seria desenhada em poucas instruções e apareceria pronta de uma vez.

Este trecho mostra dois laços, um dentro do outro, e usa `bne` com `zero` para "repetir até o contador chegar a zero".

### 3.6 Mostrar a soma em decimal

O registrador tem o número 55, mas a tela precisa dos caracteres `'5'` e `'5'`. Para separar dezenas e unidades seria natural dividir por 10, mas **o RV32I não tem instrução de divisão** (ela fica na extensão M). A saída é subtrair 10 até sobrar menos de 10:

```
00050913  # 1E8          addi s2, a0, 0       # s2 = soma (vai virar as unidades)
00000993  # 1EC          addi s3, zero, 0     # s3 = dezenas
00A00893  # 1F0          addi a7, zero, 10
01194863  # 1F4  dezena: blt  s2, a7, achou   # sem divisão no RV32I: subtrai 10 até sobrar menos de 10
FF690913  # 1F8          addi s2, s2, -10
00198993  # 1FC          addi s3, s3, 1
FE000AE3  # 200          beq  zero, zero, dezena  # desvio sempre tomado (o simulador não tem jal)
03098993  # 204  achou:  addi s3, s3, 48      # '0' + dezenas
```

| Volta | `s2` | `s3` (dezenas) |
|---|---|---|
| início | 55 | 0 |
| 1 | 45 | 1 |
| 2 | 35 | 2 |
| 3 | 25 | 3 |
| 4 | 15 | 4 |
| 5 | 5 | 5 |
| `5 < 10` | sai do laço | |

Dois truques aparecem aqui:

- **`beq zero, zero, dezena`** é um desvio que **sempre** é tomado, porque `zero` é sempre igual a `zero`. Funciona como um "vá para" incondicional. Num programa normal se usaria `jal`, que o simulador ainda não tem.
- **Número para caractere:** os dígitos ASCII vão de `'0'` (48) a `'9'` (57), em sequência. Então o caractere de um dígito `d` é `48 + d`. Por isso o `addi s3, s3, 48`.

Depois, o programa junta os dois dígitos numa palavra com dois espaços em cima (`"55  "`) e grava logo depois do texto `"SOMA DE 1 A 10: "`.

### 3.7 Resultado do POPCNT e fim

O resultado do `cpop` (5) vira o caractere `'5'` do mesmo jeito (`5 + 48`), numa palavra `"5   "`. Por fim, o programa escreve `"FIM."` na linha 8 e executa `ebreak`.

## 4. Números da execução

Rodando com o intervalo padrão de 50 instruções:

| Medida | Valor | Explicação |
|---|---|---|
| Instruções na memória | 189 | o tamanho do programa |
| Instruções executadas | 576 | os laços repetem instruções: a barra sozinha executa 350 |
| Leituras no barramento | 576 | uma busca por instrução (o programa não usa `lw`) |
| Escritas no barramento | 29 | os 29 `sw` (a carga do programa não conta, ver [[Sim 12 - Computador (Carregar e Executar)]]) |
| Telas impressas | 12 | uma a cada 50 instruções (de 50 a 550, a tela sempre tinha mudado) e a tela final, na instrução 576 |

Registradores principais no fim: `a0 = 55` (soma), `a1 = 5` (POPCNT), `s1 = 0x80000`.

## 5. Como o programa foi gerado

O `.hex` foi gerado a partir do [[Sim 07 - Montador (Gerador de Instruções)|Montador]], escrevendo o programa como uma sequência de chamadas (`.Addi(...)`, `.Sw(...)`, `.Rotulo(...)`) e imprimindo cada código com o Assembly ao lado. Como o mesmo montador passa nos testes de codificação, os códigos batem com o padrão do RISC-V.

Para mudar o programa (outro texto, por exemplo), o jeito mais seguro é gerar de novo com o montador. Editar os números do `.hex` à mão funciona para mudanças pequenas, como trocar um caractere num `ori`, mas é fácil errar um bit.

## 6. Ligação com a matéria

- **E/S programada:** cada caractere na tela foi colocado por uma instrução da CPU. Ver [[Sim 11 - Video (E-S Programada)]].
- **Limitações do conjunto de instruções:** o programa mostra na prática o que faz falta no RV32I mínimo do enunciado: sem `lui`, constantes grandes custam várias instruções; sem `jal`, o salto incondicional vira `beq zero, zero`; sem divisão, a conversão para decimal vira um laço de subtrações. É o lado prático da discussão de ISA da [[09 - Processador e Datapath RISC-V (Microprocessador I)|nota 09]].
