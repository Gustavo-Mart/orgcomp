# Site das notas de Organização de Computadores

Este projeto transforma o cofre do Obsidian (`C:\Obsidian\Organização de Computadores`) em um site, usando o [Quartz](https://quartz.jzhao.xyz) (versão 5). O GitHub gera e hospeda o site de graça, pelo GitHub Pages.

O que já vem pronto:

- `content/`: uma cópia das notas (pasta `Escola` e pasta `Simulador RISC-V - Código`).
- `pagina-inicial.md`: a página de entrada do site. Ela não existe no cofre, então fica aqui.
- `quartz.config.yaml`: título, idioma português e as opções do site.
- `.github/workflows/deploy.yml`: gera e publica o site sozinho a cada envio para o GitHub. O endereço do site é calculado a partir do nome do repositório, então não é preciso editar nada.
- `atualizar-site.bat`: copia as notas do cofre e publica a nova versão.

## Publicar pela primeira vez

**1. Coloque esta pasta em um lugar fixo**, **fora** do cofre do Obsidian. Por exemplo, `C:\Users\gusta\Projetos\site-orgcomp`.

**2. Crie o repositório no GitHub.** Em <https://github.com/new>:

- Nome: por exemplo `orgcomp`. O site vai ficar em `https://SEU-USUARIO.github.io/orgcomp`.
- Visibilidade: **Public**. No plano gratuito, o GitHub Pages só publica repositórios públicos.
- **Não** marque as opções de README, .gitignore ou licença, porque este projeto já tem esses arquivos.

**3. Envie o projeto.** Abra o Git Bash (ou o terminal) dentro desta pasta e rode, trocando `SEU-USUARIO`:

```bash
git init -b main
git add .
git commit -m "Primeira versão do site"
git remote add origin https://github.com/SEU-USUARIO/orgcomp.git
git push -u origin main
```

**4. Ligue o GitHub Pages.** No repositório, vá em **Settings > Pages** e, em **Build and deployment > Source**, escolha **GitHub Actions**.

**5. Rode a publicação.** Vá na aba **Actions**, clique em **Publicar site no GitHub Pages** e depois em **Run workflow**. Esse passo é necessário só na primeira vez, porque o envio do passo 3 aconteceu antes de o Pages estar ligado. Em 1 ou 2 minutos o site aparece em `https://SEU-USUARIO.github.io/orgcomp`. Esse é o link para mandar aos amigos.

## Atualizar o site depois de mexer nas notas

Clique duas vezes em **`atualizar-site.bat`**. Ele:

1. copia o cofre para `content/` (sem a pasta `.obsidian`, sem `_arquivo` e sem as pastas de backup `.backup-...`);
2. repõe a página inicial;
3. faz o commit e envia para o GitHub, que publica a nova versão em 1 ou 2 minutos.

Se o cofre mudar de lugar, rode assim no PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\atualizar-site.ps1 -Cofre "D:\outro\lugar\Organização de Computadores"
```

## Ver o site no seu computador antes de publicar (opcional)

Precisa do [Node.js](https://nodejs.org) 22 ou mais novo.

```bash
npm ci
npx quartz build --serve
```

Depois abra <http://localhost:8080>.

## Se algo der errado

- **Erro de "environment protection rules" na aba Actions**: em **Settings > Environments**, apague o ambiente `github-pages` e rode a publicação de novo. O próprio GitHub recria o ambiente.
- **Página 404 logo depois de publicar**: espere alguns minutos. A primeira publicação costuma demorar mais.
- **O site continua com a versão antiga**: recarregue com Ctrl+F5.
- **O `atualizar-site.bat` pede usuário e senha do GitHub**: o GitHub não aceita a senha da conta no terminal. Faça o login pelo Git Credential Manager (a janela que abre) ou use um token de acesso.

## Bom saber

- O site é **público**: qualquer pessoa com o link consegue ler.
- Os diagramas em Mermaid (como o da visão geral do simulador) aparecem desenhados no site, como no Obsidian.
- As caixas de aviso (`[!info]`, `[!warning]` etc.) aparecem com o mesmo estilo do Obsidian.

O Quartz é um projeto de código aberto de Jacky Zhao, com licença MIT (veja `LICENSE.txt`).
