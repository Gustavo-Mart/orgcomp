---
tags: [organização-de-computadores, memória-secundária, disco-rígido, raid, ssd]
fonte: OrgComp04_Memoria.pdf (slides 12-23)
---

# Memória Secundária e Discos (HDD, RAID, SSD)

← [[03 - Hierarquia e Tipos de Memória]] | [[00 - Índice - Organização de Computadores|Índice]] | Próxima: [[05 - Memória Cache - Conceitos e Estrutura]]

## 1. O que é memória secundária

São memórias de armazenamento em massa, em especial os discos rígidos. Servem para armazenamento permanente de dados, que sobrevivem ao desligar o computador. E não são acessadas diretamente pela CPU: o acesso acontece por intermédio da memória principal, já que os dados precisam ser carregados na RAM antes de a CPU trabalhar com eles.

## 2. Layout físico do disco magnético

O disco é dividido em:

- **Trilhas (tracks)**: círculos concêntricos na superfície do disco.
- **Setores (sectors)**: cada trilha é dividida em setores, a menor unidade de endereçamento física do disco.
- **Lacuna intertrilhas e lacuna intersetor**: espaços de separação física entre trilhas e entre setores, respectivamente, que evitam interferência.
- **Cabeça de leitura/gravação**: uma por superfície do prato (disco físico), que se move ao longo do raio do disco.
- **Prato(s), eixo e braço**: os pratos giram (Rotação) em torno do eixo, e o braço move o conjunto de cabeças na direção radial para alcançar a trilha desejada.

O slide mostra ainda duas estratégias de organização das trilhas em setores:

- **Velocidade angular constante**: todas as trilhas têm o mesmo número de setores, e os setores das trilhas externas, mais longas fisicamente, são "maiores" fisicamente que os das trilhas internas, mas armazenam a mesma quantidade de dados. Isso simplifica o controle, já que a velocidade angular é sempre a mesma, mas desperdiça densidade nas trilhas externas.
- **Gravação em múltiplas zonas**: o disco é dividido em zonas de trilhas, e trilhas de zonas mais externas recebem mais setores, para aproveitar melhor a densidade de gravação, à custa de um controle um pouco mais complexo.

## 3. Formato de um setor no disco

Cada setor grava, além do dado em si: bits de sincronismo, que delimitam o início do setor para o hardware; um identificador de trilha, cabeça e setor, que é o endereço físico do setor; um código de correção de erro (ECC); e os dados propriamente ditos.

## 4. Cálculo de capacidade do disco

Fórmula geral: multiplicar bytes/setor × setores/trilha × trilhas/cilindro × cilindros.

### Exemplo resolvido do slide

Um HD com 512 Bytes por setor, 300 Setores por trilha, 24 trilhas por cilindro e 9.801 cilindros:

$$\text{Capacidade trilha} = 300 \times 512\ B = 153.600\ B$$
$$\text{Capacidade cilindro} = 24 \times 153.600\ B = 3.686.400\ B$$
$$\text{Capacidade disco} = 9.801 \times 3.686.400\ B = 36.130.406.400\ B \approx 33{,}65\ GB$$

Confirma-se que o slide usa a convenção 1 GB = $1024^3$ bytes, já que $36.130.406.400 / 1024^3 \approx 33{,}65$.

## 5. Velocidade do disco

Para ler ou escrever um dado, existem 3 tempos envolvidos:

1. **Tempo de busca (seek time)**: tempo para mover a cabeça até a trilha correta.
2. **Latência rotacional**: tempo para o disco girar até que os dados desejados passem sob a cabeça.
3. **Tempo de acesso**: tempo de busca mais latência.

O número de bytes por segundo resultante desse processo é chamado de taxa de transferência.

### 5.1 Complemento de pesquisa: fórmulas de busca, latência e acesso

O slide define os três tempos, mas não dá fórmulas. Em material aberto sobre o assunto, a latência rotacional média costuma ser estimada como metade do tempo de uma rotação completa do disco: $\text{Latência rotacional média} = \frac{1}{2} \times \text{tempo de uma rotação}$. O tempo de busca é considerado o fator mais crítico de desempenho, e sua média costuma ser estimada como um terço do tempo do curso completo do braço: $\text{Tempo de busca médio} = \frac{1}{3} \times \text{tempo do curso completo}$. E o tempo de acesso completo, incluindo a transferência dos dados em si, fica: $\text{Tempo de acesso} = \text{tempo de busca} + \text{latência rotacional} + \text{tempo de transferência de dados}$. Essa última fórmula é uma versão um pouco mais detalhada da que aparece no slide do professor (que já soma busca e latência), acrescentando o tempo de transferência como uma terceira parcela explícita.

Sources:
- [Difference between Rotational Latency and Disk Access Time in Disk Scheduling - GeeksforGeeks](https://www.geeksforgeeks.org/operating-systems/difference-between-rotational-latency-and-disk-access-time-in-disk-scheduling/)

## 6. Exercícios (do slide)

1. O que é uma memória secundária?
2. Quais os principais tipos de dispositivos para memória de armazenamento permanente?
3. Em um HD com 1 KByte por setor, 200 setores por trilha, 50 trilhas por cilindro e 1.200 cilindros, qual a capacidade de armazenamento físico deste disco?
4. O que é RAID? Quais os tipos de RAID?

> [!example]- Solução sugerida para o exercício 3 (não estava resolvida no slide, confira antes de valer nota)
> Seguindo a mesma convenção do exemplo do slide (1 KB = 1024 B):
> $$\text{Capacidade trilha} = 200 \times 1024\ B = 204.800\ B$$
> $$\text{Capacidade cilindro} = 50 \times 204.800\ B = 10.240.000\ B$$
> $$\text{Capacidade disco} = 1.200 \times 10.240.000\ B = 12.288.000.000\ B \approx 11{,}44\ GB$$

## 7. RAID (Redundant Array of Independent/Inexpensive Disks)

Um conjunto de discos visto como uma única unidade lógica pelo sistema operacional. Pode usar capacidade redundante para armazenar informação de paridade, permitindo recuperar dados mesmo se um disco falhar.

Níveis de RAID mostrados nos slides:

| Nível  | Nome                                   | Ideia central                                                                                                                                             |
| ------ | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RAID 0 | Não redundante (striping)              | Dados divididos em *strips* espalhadas por todos os discos, sem paridade. Ganha desempenho, mas não tem tolerância a falhas: perder um disco perde dados. |
| RAID 1 | Espelhado (mirroring)                  | Cada bloco de dados é duplicado em dois discos (espelho). Tolerante a falhas, mas usa o dobro do espaço físico.                                           |
| RAID 2 | Redundância por Código de Hamming      | *Striping* em nível de bit, com bits de paridade calculados via Código de Hamming em discos dedicados. Pouco usado na prática.                            |
| RAID 3 | Paridade intercalada por bit           | *Striping* em nível de bit ($b_0, b_1, b_2, b_3$) mais um disco dedicado de paridade $P(b)$.                                                              |
| RAID 4 | Paridade em nível de bloco             | *Striping* em nível de bloco, com um disco dedicado guardando a paridade de cada faixa de blocos (por exemplo, $P(0\text{-}3)$, $P(4\text{-}7)$...).      |
| RAID 5 | Paridade distribuída em nível de bloco | Como o RAID 4, mas a paridade é distribuída entre todos os discos, e não fica concentrada em um único disco "gargalo".                                    |
| RAID 6 | Redundância dupla                      | Guarda dois blocos de paridade/síndrome independentes por faixa ($P$ e $Q$), tolerando a falha de até 2 discos simultaneamente.                           |

> [!tip] Como lembrar a progressão
> RAID 0 é velocidade, sem redundância nenhuma. RAID 1 é o espelho simples. RAID 3, 4 e 5 têm uma paridade, e diferem em onde ela fica (bit, bloco, ou distribuída). RAID 6 tem duas paridades e aguenta 2 falhas. RAID 2 é o irmão pouco usado, que troca a paridade simples pelo Código de Hamming.

### 7.1 Complemento de pesquisa: RAID 10

Não aparece nos slides do professor, mas é comum em provas e no mercado: RAID 10 (ou 1+0) combina espelhamento (RAID 1) com *striping* (RAID 0). Os dados são espelhados em pares de discos, e esses pares são então distribuídos em *stripes*. Precisa de no mínimo 4 discos e perde metade da capacidade total para a redundância, mas entrega boa performance de leitura e escrita junto com tolerância a falhas, o que o torna popular em aplicações com uso intenso de E/S.

Sources:
- [Comparing RAID levels: 0, 1, 5, 6, 10 and 50 explained - TechTarget](https://www.techtarget.com/it-infrastructure/feature/Comparing-RAID-levels-0-1-5-6-10-and-50-explained)

## 8. SSD (Solid State Drive)

Utiliza memória flash (ver [[03 - Hierarquia e Tipos de Memória]]) para realizar armazenamento não volátil, sem partes móveis. Diferente do HD magnético, não tem tempo de busca ou latência rotacional no mesmo sentido mecânico.

O slide 22 traz duas figuras:

- **Arquitetura do SSD**: do lado do sistema hospedeiro ficam o software do sistema operacional, o software do sistema de arquivos, o software de driver de E/S e a interface. Do lado do SSD ficam a interface, o controlador, o bloco de endereçamento, um buffer de dados/cache, a correção de erro e vários componentes de memória flash.
- **Tabela SSD x HD**:

| | Drives de flash NAND | HDD interno de laptop (Seagate) |
|---|---|---|
| Cópia de arquivo / velocidade de leitura | 200-550 Mbps | 50-120 Mbps |
| Consumo de energia / bateria | Menor, média de 2-3 watts, mais de 30 minutos a mais de bateria | Maior, média de 6-7 watts |
| Capacidade | Geralmente até 512 GB em notebook; 1 TB no máximo em desktop | Cerca de 500 GB a 2 TB em notebook; 4 TB no máximo em desktop |
| Custo | Cerca de US$ 0,50 por GB (drive de 1 TB) | Cerca de US$ 0,15 por GB (drive de 4 TB) |

> [!warning] Números desatualizados
> A tabela vem do livro de 2017. Capacidade e preço de SSD mudaram muito desde então, então use esses números só como estão no slide, não como dado atual de mercado (não conferi valores atuais). Outro detalhe: o slide escreve "Mbps", mas não tenho certeza se a fonte original queria dizer megabytes por segundo (MB/s), que é a unidade em que essas velocidades costumam aparecer.

### 8.1 Complemento de pesquisa: como a memória NAND Flash guarda o bit

Detalhe que não está nos slides: cada célula de memória NAND Flash, a tecnologia flash mais usada em SSDs, tem um control gate e um floating gate (porta flutuante), separados por uma fina camada de óxido isolante. Para gravar, elétrons são empurrados para dentro da porta flutuante por efeito túnel (Fowler-Nordheim) e ficam presos ali, representando o valor binário armazenado. É por isso que o dado persiste mesmo sem energia. SSDs modernos usam 3D NAND, empilhando várias camadas verticais de células no mesmo chip, o que aumenta densidade e reduz custo por bit.

Sources:
- [What is NAND Flash Memory? - IBM](https://www.ibm.com/think/topics/nand-flash)

## Referências

- William Stallings. *Arquitetura e organização de computadores*, Capítulo 5. Pearson, 2017.
- David Patterson e John Hennessy. *Computer Organization and Design, RISC-V Edition*. Morgan Kaufmann, 2018.
- Sarah Harris e David Harris. *Digital design e computer architecture*. Morgan Kaufmann, 2015.
