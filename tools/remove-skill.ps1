<#
.SYNOPSIS
  删除一个 skill：从 ~/.agents/skills 删除，并从 skills/wanted.txt 移除登记。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File <配置包路径>\tools\remove-skill.ps1 -Name pdf
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Name
)

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$list = Join-Path $kit 'skills\wanted.txt'
$to = Join-Path $HOME ".agents\skills\$Name"

if (Test-Path $to) { Remove-Item -Recurse -Force $to; Write-Host "已删除：$to" }
else { Write-Host "本机没有该 skill：$Name" }

$kept = @(Get-Content $list -Encoding UTF8 | Where-Object { -not ($_ -match '^\S+\s+(\S+)$' -and (Split-Path $Matches[1] -Leaf) -eq $Name) })
Set-Content -Path $list -Value $kept -Encoding UTF8
Write-Host "已从清单移除：$Name。运行 sync-experience.ps1 同步到 GitHub。" -ForegroundColor Green
