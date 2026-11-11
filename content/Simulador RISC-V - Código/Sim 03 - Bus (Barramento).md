---
tags: [projeto-final, simulador, barramento, interrupção, csharp]
arquivo: Simulator.core/Bus.cs
bloco-do-enunciado: Barramento (1 pt)
---

# Bus.cs: o barramento

← [[Sim 02 - Memory (Memória)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 04 - Alu (ULA)]]

## 1. Para que serve

O `Bus` fica **entre a CPU e a memória**. A CPU não tem acesso à `Memory`: ela só conhece o barramento. Cada leitura ou escrita passa por aqui, e o barramento guarda o estado das suas três linhas, como na aula:

| Grupo de linhas (aula) | No código | Largura |
|---|---|---|
| Barramento de endereços | `Enderecos` | 32 bits (`int`) |
| Barramento de dados | `Dados` | 32 bits (`int`) |
| Barramento de controle | `SinalControle` (Leitura/Escrita) e `Irq` | sinais |

Isso cumpre o item do enunciado: dados de 32 bits, endereços de 32 bits e controle de leitura/escrita. Ver [[02 - Barramentos (Buses)]], seção 2 (linhas do barramento).

## 2. A declaração da classe

```csharp
public class Bus(Memory memoria)
```

`(Memory memoria)` é um **construtor primário**. Para criar um barramento você passa a memória que ele vai controlar:

```csharp
var bus = new Bus(new Memory());
```

O parâmetro `memoria` fica disponível dentro da classe inteira. Aqui ele é guardado na propriedade `Memoria`.

## 3. O enum `Controle`

```csharp
public enum Controle { Nenhum, Leitura, Escrita }
```

Um `enum` é uma lista fechada de valores com nome. Representa o que o barramento de controle está sinalizando:

- `Nenhum`: nada aconteceu ainda (valor inicial).
- `Leitura`: a última operação foi uma leitura (busca de instrução ou `lw`).
- `Escrita`: a última operação foi uma escrita (`sw` ou carga do programa).

Como foi declarado dentro de `Bus`, o nome completo é `Bus.Controle.Leitura`.

## 4. As propriedades

```csharp
public Memory Memoria { get; } = memoria;

public int Enderecos { get; private set; }
public int Dados { get; private set; }
public Controle SinalControle { get; private set; } = Controle.Nenhum;

public bool Irq { get; private set; }

public long Leituras { get; private set; }
public long Escritas { get; private set; }
```

| Propriedade | O que guarda | Quem pode mudar |
|---|---|---|
| `Memoria` | a memória ligada a este barramento | ninguém (só `get`, definida na criação) |
| `Enderecos` | o último endereço colocado no barramento | só a própria classe |
| `Dados` | o último valor que passou pelo barramento | só a própria classe |
| `SinalControle` | se a última operação foi leitura ou escrita | só a própria classe |
| `Irq` | se algum dispositivo está pedindo interrupção | só a própria classe, pelos métodos |
| `Leituras` | quantas leituras já passaram | só a própria classe |
| `Escritas` | quantas escritas já passaram | só a própria classe |

`{ get; private set; }` quer dizer: qualquer um pode **ler** o valor, mas só o código dentro de `Bus` pode **alterar**. Assim ninguém de fora coloca um endereço no barramento sem fazer a operação de verdade.

`Memoria` é pública de propósito: os testes e, mais tarde, a tela da VRAM precisam olhar a memória diretamente.

`Leituras` e `Escritas` são `long` (64 bits) porque um programa longo pode passar de 2 bilhões de acessos, o limite do `int`.

## 5. `Ler(int endereco)`

```csharp
public int Ler(int endereco)
{
    Enderecos = endereco;
    SinalControle = Controle.Leitura;
    Dados = Memoria.LerPalavra(endereco);
    Leituras++;
    return Dados;
}
```

Imita um **ciclo de leitura do barramento**, na ordem em que acontece no hardware:

1. A CPU coloca o endereço na linha de endereços (`Enderecos = endereco`).
2. Ativa o sinal de leitura na linha de controle (`SinalControle = Controle.Leitura`).
3. A memória responde, colocando o valor na linha de dados (`Dados = Memoria.LerPalavra(...)`).
4. O contador de leituras sobe.
5. O valor volta para a CPU.

Se o endereço for inválido, `LerPalavra` lança `SimuladorException` e o contador não sobe.

**Quem chama:** `Cpu.Passo()` na busca de cada instrução. Depois da etapa 3, também o `lw`.

## 6. `Escrever(int endereco, int valor)`

```csharp
public void Escrever(int endereco, int valor)
{
    Enderecos = endereco;
    Dados = valor;
    SinalControle = Controle.Escrita;
    Memoria.EscreverPalavra(endereco, valor);
    Escritas++;
}
```

Imita um **ciclo de escrita**: a CPU coloca o endereço e o dado no barramento, ativa o sinal de escrita e a memória grava.

**Quem chama hoje:** o `Montador.Rodar` (para carregar o programa na memória) e o teste `EscreveELeUmaPalavra`. Depois da etapa 3, o `sw`.

## 7. `PedirInterrupcao()` e `LimparInterrupcao()`

```csharp
public void PedirInterrupcao() => Irq = true;
public void LimparInterrupcao() => Irq = false;
```

Representam a **linha de pedido de interrupção (IRQ)**, que faz parte do barramento de controle:

- Um dispositivo (teclado, temporizador) chama `PedirInterrupcao()` para avisar a CPU que precisa de atenção.
- Quando a CPU aceitar a interrupção, ela chama `LimparInterrupcao()` para baixar a linha.

O `=>` aqui é um método de uma linha só (corpo de expressão).

> [!warning] Ainda não ligado à CPU
> A linha existe, mas `Cpu.Passo()` ainda não olha para `Irq`. Falta a etapa de "verificação de interrupção" no fim do ciclo: se `Irq` estiver ligada, salvar o PC, pular para a rotina de tratamento e depois voltar com `mret`. Ver [[10 - Interrupções e Entrada-Saída (Microprocessador III)#7. Ciclo de busca com interrupção (slide 10)|nota 10, seção 7]].

## 8. Ligação com a matéria

- **Por que um barramento separado:** em von Neumann, CPU, memória e E/S se comunicam por um caminho compartilhado. Ter a classe `Bus` no meio deixa isso visível no código e permite contar o tráfego.
- **Gargalo de von Neumann:** os contadores mostram isso na prática. Toda instrução gera pelo menos 1 leitura (a busca). Com `lw`/`sw`, algumas geram 2 acessos. Em um programa de 1.000 instruções, o barramento é usado pelo menos 1.000 vezes. Ver [[02 - Barramentos (Buses)]], seção 4 (gargalos).
- **Barramento dedicado:** aqui endereço e dados têm linhas separadas (propriedades separadas). Não há multiplexação. Ver [[02 - Barramentos (Buses)]], seção 6 (dedicado x multiplexado).

## 9. Observações

- `SinalControle` não volta para `Nenhum` depois de uma operação. Ele guarda o tipo da última operação feita, o que é suficiente para mostrar na tela de depuração.
- Não existe arbitragem (só a CPU usa o barramento). Se um dia entrar DMA, aí sim seria preciso decidir quem usa o barramento em cada momento.
