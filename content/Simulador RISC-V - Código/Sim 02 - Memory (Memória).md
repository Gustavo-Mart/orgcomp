---
tags: [projeto-final, simulador, memória, mapa-de-memória, little-endian, csharp]
arquivo: Simulator.core/Memory.cs
bloco-do-enunciado: Memória RAM (2 pts)
---

# Memory.cs: a memória do simulador

← [[Sim 01 - Solução e Projetos (csproj)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 03 - Bus (Barramento)]]

## 1. Para que serve

A classe `Memory` representa **toda a memória endereçável** do computador simulado: RAM, VRAM, área reservada e a faixa de E/S. Por dentro, ela é só um vetor de bytes. Por fora, ela oferece leitura e escrita de **palavras de 32 bits** (o que `lw` e `sw` precisam) e aplica as regras do mapa de memória do enunciado.

O mesmo arquivo também define a `SimuladorException`, o erro que o simulador lança quando algo proibido acontece.

```csharp
using System.Buffers.Binary;

namespace Simulador.Core;
```

- `using System.Buffers.Binary;` importa `BinaryPrimitives`, que converte 4 bytes em um `int` e o contrário.
- `namespace Simulador.Core;` coloca a classe no namespace da biblioteca. O ponto e vírgula no fim quer dizer que vale para o arquivo inteiro.

## 2. As constantes do mapa de memória

```csharp
public const int RamInicio = 0x00000;
public const int RamFim = 0x7FFFF;
public const int VramInicio = 0x80000;
public const int VramFim = 0x8FFFF;
public const int ReservadoInicio = 0x90000;
public const int ReservadoFim = 0x9FBFF;
public const int EsInicio = 0x9FC00;
public const int EsFim = 0x9FFFF;
public const int Tamanho = EsFim + 1; // 0xA0000 bytes = 640 KB
```

| Região    | Início    | Fim       | Tamanho | Uso no projeto                                                                        |
| --------- | --------- | --------- | ------- | ------------------------------------------------------------------------------------- |
| RAM       | `0x00000` | `0x7FFFF` | 512 KB  | programa, dados e pilha                                                               |
| VRAM      | `0x80000` | `0x8FFFF` | 64 KB   | memória de vídeo: o programa escreve caracteres aqui e o simulador mostra no terminal |
| Reservado | `0x90000` | `0x9FBFF` | 63 KB   | não pode ser escrito                                                                  |
| E/S       | `0x9FC00` | `0x9FFFF` | 1 KB    | periféricos mapeados em memória (ainda sem nenhum dispositivo ligado)                 |

`const` quer dizer que o valor é fixo e conhecido na compilação. Como são `public`, outras classes usam esses nomes, por exemplo `Memory.RamFim` no `Reset` da CPU.

`Tamanho` vale `0x9FFFF + 1 = 0xA0000`, que é 655.360 bytes, ou 640 KB. O último endereço válido é `Tamanho - 1`.

## 3. O campo `_bytes`

```csharp
private readonly byte[] _bytes = new byte[Tamanho];
```

É a memória de verdade: um vetor com 655.360 posições, cada uma guardando 1 byte (0 a 255). O índice do vetor é o endereço. Começa tudo zerado.

- `private`: só a própria classe mexe nele. Quem está fora precisa usar `LerPalavra`, `EscreverPalavra` ou `LerByte`, e esses métodos aplicam as regras.
- `readonly`: o vetor não pode ser trocado por outro depois de criado. O conteúdo dele muda, mas a referência não.
- O `_` no começo do nome é só uma convenção de C# para campos privados.

## 4. `LerPalavra(int endereco)`

```csharp
public int LerPalavra(int endereco)
{
    Verificar(endereco);
    return BinaryPrimitives.ReadInt32LittleEndian(_bytes.AsSpan(endereco, 4));
}
```

**O que faz:** lê 4 bytes seguidos a partir de `endereco` e devolve como um número de 32 bits.

**Passo a passo:**
1. `Verificar(endereco)` confere se o endereço existe e se é múltiplo de 4. Se não for, lança erro e nada é lido.
2. `_bytes.AsSpan(endereco, 4)` cria uma "janela" sobre os 4 bytes `[endereco, endereco+1, endereco+2, endereco+3]`, sem copiar nada.
3. `ReadInt32LittleEndian` monta o `int` em **little-endian**: o byte do menor endereço é o menos significativo.

**Quem usa:** o `Bus.Ler`, que é chamado pela CPU na busca de instrução.

### Little-endian com um exemplo

Se a palavra `0x41424344` for escrita no endereço `0x100`, a memória fica assim:

| Endereço | `0x100` | `0x101` | `0x102` | `0x103` |
|---|---|---|---|---|
| Byte | `0x44` | `0x43` | `0x42` | `0x41` |

O RISC-V é little-endian, então o simulador também precisa ser. Isso importa na VRAM: se o programa grava `0x0000214F` com `sw`, o caractere `'O'` (`0x4F`) aparece primeiro na tela e o `'!'` (`0x21`) depois.

## 5. `EscreverPalavra(int endereco, int valor)`

```csharp
public void EscreverPalavra(int endereco, int valor)
{
    Verificar(endereco);
    if (endereco >= ReservadoInicio && endereco <= ReservadoFim)
        throw new SimuladorException($"Escrita na área reservada: 0x{endereco:X5}");
    BinaryPrimitives.WriteInt32LittleEndian(_bytes.AsSpan(endereco, 4), valor);
}
```

**O que faz:** grava um número de 32 bits em 4 bytes seguidos, em little-endian.

**Passo a passo:**
1. Mesma verificação de existência e alinhamento.
2. Se o endereço cair na área reservada, lança erro. Isso aplica a regra do enunciado de que essa faixa não é usada.
3. `WriteInt32LittleEndian` quebra o `int` em 4 bytes e grava na ordem little-endian.

`{endereco:X5}` na mensagem formata o número em hexadecimal maiúsculo com pelo menos 5 dígitos, por exemplo `0x90000`.

**Quem usa:** `Bus.Escrever`. Hoje é chamado pelo `Montador.Rodar` para carregar o programa, e depois vai ser chamado pelo `sw`.

> [!note] Só a escrita no reservado é bloqueada
> Ler a área reservada é permitido (devolve zero). Escrever na VRAM e na faixa de E/S também é permitido, porque é justamente assim que o programa vai mostrar texto na tela e conversar com periféricos.

## 6. `LerByte(int endereco)`

```csharp
public byte LerByte(int endereco)
{
    if (endereco < 0 || endereco >= Tamanho)
        throw new SimuladorException($"Endereço fora da memória: 0x{endereco:X}");
    return _bytes[endereco];
}
```

**O que faz:** devolve um único byte, de qualquer endereço válido, **sem exigir alinhamento**.

**Por que existe se o RV32I do projeto só tem `lw`/`sw`:** não é para a CPU. É para o próprio simulador e para os testes olharem a memória byte a byte. O uso principal vai ser a tela: para desenhar a VRAM, o simulador lê caractere por caractere. Hoje ele aparece no teste `GuardaEmLittleEndian`.

## 7. `Regiao(int endereco)`

```csharp
public static string Regiao(int endereco) => endereco switch
{
    >= RamInicio and <= RamFim => "RAM",
    >= VramInicio and <= VramFim => "VRAM",
    >= ReservadoInicio and <= ReservadoFim => "RESERVADO",
    >= EsInicio and <= EsFim => "E/S",
    _ => "FORA DA MEMÓRIA"
};
```

**O que faz:** diz em qual região do mapa um endereço cai.

- `static`: não precisa de um objeto `Memory` para chamar. Basta `Memory.Regiao(0x80000)`, que devolve `"VRAM"`.
- O `switch` de expressão testa cada faixa em ordem. `>= RamInicio and <= RamFim` é um padrão relacional: "maior ou igual ao início **e** menor ou igual ao fim".
- `_` é o caso padrão, para qualquer endereço fora das faixas (negativo ou acima de `0x9FFFF`).

**Para que vai servir:** mensagens de erro e a tela de depuração (mostrar "lendo da VRAM", por exemplo). Hoje só os testes usam.

## 8. `Verificar(int endereco)`

```csharp
private static void Verificar(int endereco)
{
    if (endereco < 0 || endereco + 3 >= Tamanho)
        throw new SimuladorException($"Endereço fora da memória: 0x{endereco:X}");
    if ((endereco & 3) != 0)
        throw new SimuladorException($"Acesso desalinhado: 0x{endereco:X} (lw/sw precisam de múltiplo de 4)");
}
```

**O que faz:** a checagem comum de leitura e escrita de palavra. É `private`, então só a própria classe usa.

**As duas regras:**

1. **O endereço precisa existir, e os 4 bytes também.** Por isso a conta é `endereco + 3 >= Tamanho`: uma palavra começando em `0x9FFFE` teria bytes em `0xA0000` e `0xA0001`, que não existem.
2. **O endereço precisa ser múltiplo de 4.** O truque `(endereco & 3) != 0` olha os 2 bits menores do endereço. Em um múltiplo de 4 eles são sempre `00`.

| Endereço | Binário (final) | `endereco & 3` | Resultado |
|---|---|---|---|
| `0x100` | `...0000` | 0 | ok |
| `0x102` | `...0010` | 2 | erro: desalinhado |
| `0x104` | `...0100` | 0 | ok |

No RISC-V real, um `lw` desalinhado pode gerar uma exceção ou ser tratado pelo hardware, dependendo da implementação. Aqui foi escolhido o caminho mais simples e mais fácil de depurar: dar erro.

## 9. `SimuladorException`

```csharp
public class SimuladorException(string mensagem) : Exception(mensagem);
```

Uma classe de erro própria do simulador, em uma linha só.

- `: Exception(mensagem)` quer dizer que ela **herda** de `Exception` (a classe base de erros do .NET) e repassa a mensagem para ela.
- `(string mensagem)` logo depois do nome é um **construtor primário**: o construtor é declarado junto com a classe.
- O `;` no fim, em vez de `{ }`, indica que a classe não tem corpo. Ela não precisa de nada além do que herda.

**Por que ter uma exceção própria:** assim os testes podem conferir exatamente esse tipo de erro com `Assert.Throws<SimuladorException>`, e o `Program.cs` pode capturar só os erros do simulador e mostrar uma mensagem amigável, sem esconder bugs de outro tipo.

## 10. Ligação com a matéria

- **Mapa de memória e E/S mapeada em memória:** a VRAM e a faixa de E/S são endereços comuns. A CPU fala com o vídeo e com periféricos usando as mesmas instruções `lw`/`sw` que usa para a RAM. É a E/S mapeada em memória da [[10 - Interrupções e Entrada-Saída (Microprocessador III)]].
- **Palavra de 32 bits e endereçamento por byte:** cada endereço aponta para 1 byte, mas `lw`/`sw` movem 4 bytes. Por isso as instruções ficam em endereços `0, 4, 8, 12...`.
- **Hierarquia de memória:** este simulador ainda não tem cache. Toda leitura vai direto à "RAM". A cache de 256 linhas é um extra do enunciado. Ver [[05 - Memória Cache - Conceitos e Estrutura]].

## 11. Limitações conhecidas

- Não existe leitura ou escrita de **byte** ou **meia palavra** pela CPU (`lb`, `lh`, `sb`, `sh`). O enunciado só pede `lw` e `sw`, mas programas gerados no godbolt.org podem usar essas instruções.
- A faixa de E/S aceita escrita, mas ainda não há nenhum dispositivo respondendo a ela.
