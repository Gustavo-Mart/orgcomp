---
tags: [projeto-final, simulador, vram, e-s-programada, video, csharp]
arquivo: Simulator.core/Video.cs
bloco-do-enunciado: E/S programada (2 pts)
---

# Video.cs: a tela da VRAM (E/S programada)

← [[Sim 09 - Program (Aplicativo de Console)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 12 - Computador (Carregar e Executar)]]

## 1. Para que serve

O enunciado pede **E/S programada**: o programa RISC-V escreve caracteres na VRAM com `sw`, e o simulador mostra esse texto no terminal a cada N instruções. A classe `Video` é a parte do simulador que faz isso: ela lê a VRAM e transforma os bytes numa tela de texto.

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
```

Essa é a última tela do programa de demonstração ([[Sim 13 - Programa de Demonstração]]).

## 2. Como o texto fica guardado na VRAM

A tela tem **10 linhas de 40 colunas**. Cada posição é **1 byte** com o código ASCII do caractere, e as posições ficam uma atrás da outra, linha por linha:

```
endereço = 0x80000 + linha × 40 + coluna
```

| Posição na tela | Endereço |
|---|---|
| linha 0, coluna 0 | `0x80000` |
| linha 0, coluna 39 | `0x80027` |
| linha 1, coluna 0 | `0x80028` (= `0x80000 + 40`) |
| linha 9, coluna 39 | `0x8018F` (o último) |

Como o `sw` grava 4 bytes de uma vez, o programa escreve **4 caracteres por instrução**. Por causa do little-endian, o **primeiro** caractere fica no byte **menos significativo** da palavra. Para escrever `"OLA!"`:

| Caractere | `O` | `L` | `A` | `!` |
|---|---|---|---|---|
| ASCII | `0x4F` | `0x4C` | `0x41` | `0x21` |
| Byte da palavra | 0 (menor) | 1 | 2 | 3 (maior) |

A palavra fica `0x21414C4F`, ou seja, os caracteres aparecem **de trás para a frente** quando a palavra é escrita em hexadecimal.

A tela usa só 400 bytes dos 64 KB da VRAM. O resto fica livre.

## 3. Declaração e constantes

```csharp
public class Video(Memory memoria, int intervalo)
{
    public const int Colunas = 40;
    public const int Linhas = 10;
```

- Construtor primário: o vídeo recebe a memória (de onde lê a VRAM) e o intervalo.
- `Colunas` e `Linhas` definem o tamanho da tela. Para uma tela maior, basta mudar esses números (por exemplo, 80 × 25, que era o modo texto dos PCs antigos). O programa RISC-V também teria que usar a nova largura nos endereços.

## 4. Propriedades e campo

```csharp
public int Intervalo { get; } = intervalo;
public bool Ativo => Intervalo > 0;
public bool SoQuandoMudar { get; init; } = true;
private string _ultimaTela = "";
```

| Membro | O que é |
|---|---|
| `Intervalo` | de quantas em quantas instruções a tela é conferida. É o N do enunciado |
| `Ativo` | `false` quando o intervalo é 0. Os testes usam isso para rodar sem tela |
| `SoQuandoMudar` | quando `true` (o padrão), a tela só é devolvida se o texto mudou desde a última vez |
| `_ultimaTela` | o texto da última tela mostrada, para comparar |

`{ get; init; }` quer dizer que o valor só pode ser definido na criação do objeto, por exemplo `new Video(mem, 50) { SoQuandoMudar = false }`. Depois disso, não muda mais.

**Por que `SoQuandoMudar`.** Um programa que passa muito tempo num laço sem mexer na VRAM imprimiria a mesma tela dezenas de vezes e encheria o terminal. Com a comparação, a tela é **conferida** a cada N instruções, mas só **impressa** quando muda. Se o professor quiser ver a tela impressa sempre, basta criar o vídeo com `SoQuandoMudar = false`.

## 5. `Renderizar()`

```csharp
public string Renderizar()
{
    var sb = new StringBuilder();
    for (int linha = 0; linha < Linhas; linha++)
    {
        for (int coluna = 0; coluna < Colunas; coluna++)
        {
            byte ch = memoria.LerByte(Memory.VramInicio + linha * Colunas + coluna);
            sb.Append(ch >= 32 && ch < 127 ? (char)ch : ' ');
        }
        if (linha < Linhas - 1) sb.Append('\n');
    }
    return sb.ToString();
}
```

Lê a VRAM byte a byte, na mesma conta de endereço da seção 2, e monta o texto da tela.

- **`LerByte`** e não `LerPalavra`: cada caractere é um byte, e assim não importa o alinhamento.
- **`ch >= 32 && ch < 127`**: só os caracteres ASCII "imprimíveis" (do espaço até o `~`) aparecem. O resto vira espaço. Isso inclui o byte 0, que é o que existe numa VRAM que ninguém escreveu. Sem esse filtro, bytes de controle (como 10, que pula linha, ou 7, que faz o terminal apitar) bagunçariam a tela.
- **`StringBuilder`**: monta o texto pedaço por pedaço sem criar uma string nova a cada caractere. São 400 caracteres por tela, então juntar com `+` seria lento sem necessidade.
- As linhas são separadas por `'\n'`, menos a última.

O `Renderizar` é `public` porque os testes usam para conferir o que está na tela.

## 6. `TalvezAtualizar(long instrucoesExecutadas, bool ignorarIntervalo = false)`

```csharp
public string? TalvezAtualizar(long instrucoesExecutadas, bool ignorarIntervalo = false)
{
    if (!Ativo) return null;
    if (!ignorarIntervalo && instrucoesExecutadas % Intervalo != 0) return null;

    string tela = Renderizar();
    if (SoQuandoMudar && tela == _ultimaTela) return null;

    _ultimaTela = tela;
    return ComMoldura(tela, instrucoesExecutadas);
}
```

É chamado **depois de cada instrução** pelo `Computador.Executar`. Devolve a tela pronta para imprimir, ou `null` quando não é para mostrar nada. O `?` em `string?` diz justamente isso: o retorno pode ser `null`.

| Situação | Resultado |
|---|---|
| vídeo desligado (intervalo 0) | `null` |
| número de instruções não é múltiplo do intervalo | `null` |
| é múltiplo, mas a tela não mudou | `null` |
| é múltiplo e a tela mudou | a tela com moldura |

`instrucoesExecutadas % Intervalo != 0`: o `%` é o resto da divisão. Com intervalo 50, o resto é 0 em 50, 100, 150..., que são exatamente os momentos de conferir a tela.

**`ignorarIntervalo`** é usado só no fim do programa. O programa pode terminar em 576 instruções, que não é múltiplo de 50. Sem esse parâmetro, as mudanças feitas entre a instrução 550 e a 576 nunca apareceriam.

Repare que a classe **não imprime nada**: ela só devolve o texto. Quem decide onde mostrar é quem chama (o `Program.cs` manda para o terminal, e os testes guardam numa lista). Isso deixa a classe fácil de testar.

## 7. `ComMoldura(string tela, long instrucoes)`

```csharp
private static string ComMoldura(string tela, long instrucoes)
{
    string borda = "+" + new string('-', Colunas) + "+";
    ...
    sb.Append(borda).Append($"  VRAM após {instrucoes} instruções\n");
    foreach (string linha in tela.Split('\n'))
        sb.Append('|').Append(linha).Append("|\n");
    sb.Append(borda);
```

Desenha a borda em volta da tela e coloca, ao lado da borda de cima, depois de quantas instruções aquela tela foi capturada. `new string('-', Colunas)` cria uma string com 40 hífens.

## 8. Ligação com a matéria

- **E/S programada:** na aula, é a forma de E/S em que a **CPU faz toda a transferência**, executando uma instrução para cada dado, sem interrupção e sem DMA. É o que acontece aqui: cada grupo de 4 caracteres que aparece na tela foi colocado lá por um `sw` executado pela CPU. Ver a seção 9 de [[10 - Interrupções e Entrada-Saída (Microprocessador III)]], que compara E/S programada, E/S por interrupção e DMA.
- **E/S mapeada em memória:** a tela não tem instrução própria. Para o programa, a VRAM é só uma faixa de endereços onde ele escreve com o mesmo `sw` que usa para a RAM. Ver [[Sim 02 - Memory (Memória)]].
- **Quem lê a VRAM:** o `Video` lê a memória direto (`memoria.LerByte`), sem passar pelo barramento da CPU, e por isso essas leituras não entram nos contadores `Leituras`/`Escritas`. É parecido com o controlador de vídeo de um computador de verdade, que lê a memória de vídeo por conta própria para desenhar a imagem, sem ocupar a CPU.

## 9. Limitações e diferenças em relação a um computador real

- Num computador real, o controlador de vídeo redesenha a tela muitas vezes por segundo, o tempo todo. Aqui a tela é conferida a cada N **instruções**, porque o simulador não tem uma noção de tempo real. O enunciado pede exatamente esse comportamento.
- Só texto, sem cores e sem cursor.
- Como o simulador só tem `sw` (e não `sb`), o programa precisa escrever 4 caracteres de uma vez, sempre em endereços múltiplos de 4. Para trocar um caractere sozinho, o programa precisa ler a palavra com `lw`, mudar o byte e gravar de volta.
