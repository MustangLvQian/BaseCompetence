<#
.SYNOPSIS
  按 skills/wanted.txt 安装缺失的 skill 到 ~/.agents/skills。已存在的保留。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File <配置包路径>\tools\install-skills.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $HOME '.agents\skills'
$sources = Join-Path $env:TEMP 'opencode\agent-skill-sources'
$list = Join-Path $kit 'skills\wanted.txt'

function Write-Done($m) { Write-Host "    $m" -ForegroundColor Green }
function Write-Skip($m) { Write-Host "    $m" -ForegroundColor DarkGray }

$entries = @(Get-Content $list -Encoding UTF8 | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
  $parts = $_.Trim() -split '\s+'
  [pscustomobject]@{ Repo = $parts[0]; Path = $parts[1]; Name = Split-Path $parts[1] -Leaf }
})

New-Item -ItemType Directory -Force -Path $sources, $dest | Out-Null
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
foreach ($repo in ($entries.Repo | Sort-Object -Unique)) {
  $dir = Join-Path $sources ($repo -replace '/', '_')
  if (Test-Path (Join-Path $dir '.git')) { continue }
  git clone --depth 1 --quiet "git@github.com:$repo.git" $dir 2>&1 | Out-Null
  if (-not (Test-Path (Join-Path $dir '.git'))) { $ErrorActionPreference = $prev; throw "无法克隆 $repo（请确认 ssh -T git@github.com 可用）" }
}
$ErrorActionPreference = $prev

foreach ($e in $entries) {
  $to = Join-Path $dest $e.Name
  if (Test-Path (Join-Path $to 'SKILL.md')) { Write-Skip "已存在：$($e.Name)"; continue }
  $from = Join-Path $sources (Join-Path ($e.Repo -replace '/', '_') $e.Path)
  if (-not (Test-Path (Join-Path $from 'SKILL.md'))) { Write-Warning "上游缺少 $($e.Path)，已跳过"; continue }
  Copy-Item -Recurse $from $to
  Write-Done "已安装：$($e.Name)"
}

Write-Host '完成。skill 在 opencode 启动时加载，需要重启 opencode 生效。' -ForegroundColor Cyan
