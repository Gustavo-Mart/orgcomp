---
tags: [projeto-final, simulador, console, e-s-programada, csharp]
arquivo: Simulador/Program.cs
bloco-do-enunciado: E/S programada (2 pts) e programa de teste (2 pts), quando estiver pronto
---

# Program.cs: o aplicativo de console

← [[Sim 08 - Testes (MemoriaTeste e CpuTests)]] | [[Sim 00 - Visão Geral do Simulador|Visão geral]] | Próxima: [[Sim 10 - Conceitos de CSharp Usados no Código]]

## 1. Como está hoje

```csharp
Console.WriteLine("Hello, World!");
```

É o código que o Visual Studio cria junto com o projeto de console. **Ainda não usa nada do simulador.**

O arquivo usa **instruções de nível superior** (*top-level statements*): não tem `class Program` nem `static void Main`. O compilador cria essas partes sozinho e coloca o código do arquivo dentro do `Main`. Só pode existir um arquivo assim por projeto.

## 2. O que vai entrar aqui (etapa 4)

O `Program.cs` é onde o simulador vira um programa que se usa de verdade. O plano é:

1. **Montar o computador:** criar `Memory`, `Bus` e `Cpu`, do mesmo jeito que o `Montador.Rodar` faz nos testes.
2. **Carregar o programa:** ler um arquivo `.hex` (uma instrução em hexadecimal por linha) e gravar a partir do endereço 0.
3. **Laço principal:** chamar `cpu.Passo()` até `cpu.Parada`, com um limite de instruções para não travar.
4. **E/S programada:** a cada N instruções, ler a VRAM byte a byte (`Memoria.LerByte`) e mostrar o texto no terminal. É o item "E/S programada" do enunciado.
5. **Modo passo a passo:** opção para imprimir `cpu.UltimaDescricao` depois de cada instrução.
6. **Relatório final:** registradores, número de instruções, leituras e escritas no barramento.
7. **Erros:** capturar `SimuladorException` e mostrar a mensagem, sem derrubar o programa com a tela de exceção do .NET.

Esta nota precisa ser reescrita quando esse código existir.
