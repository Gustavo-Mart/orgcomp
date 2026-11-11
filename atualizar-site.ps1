# Atualiza o site com as notas do Obsidian e publica no GitHub.
# Uso: clique duas vezes em atualizar-site.bat
#   ou: powershell -ExecutionPolicy Bypass -File .\atualizar-site.ps1
param([string]$Cofre = "C:\Obsidian\Organização de Computadores")

$Repo = $PSScriptRoot
$Content = Join-Path $Repo "content"

if (-not (Test-Path $Cofre)) { Write-Host "Pasta do cofre nao encontrada: $Cofre"; exit 1 }

Write-Host "Copiando as notas de $Cofre ..."
# /MIR espelha a pasta; .obsidian (configuracoes), _arquivo (notas antigas) e .backup-* (copias de seguranca) ficam de fora.
robocopy $Cofre $Content /MIR /XD .obsidian _arquivo .trash .backup* /XF .DS_Store /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Host "Erro ao copiar as notas (robocopy $LASTEXITCODE)"; exit 1 }

# A pagina inicial do site nao existe no cofre; ela vem deste arquivo.
Copy-Item (Join-Path $Repo "pagina-inicial.md") (Join-Path $Content "index.md") -Force

git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Nenhuma nota mudou desde a ultima publicacao."; exit 0 }

git -C $Repo commit -m ("Atualiza notas " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
git -C $Repo push
if ($LASTEXITCODE -ne 0) { Write-Host "O envio para o GitHub falhou. Veja a mensagem acima."; exit 1 }

Write-Host "Pronto! Em 1 ou 2 minutos o site estara atualizado."
