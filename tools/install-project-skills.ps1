<#
.SYNOPSIS
  把某个项目专用的 skill 安装到该项目的 .agents/skills（只对这个项目生效，不占用全局开销）。

.DESCRIPTION
  清单文件格式与 skills/wanted.txt 相同：每行 <GitHub 仓库> <仓库内 skill 目录>。
  已存在的 skill 保留，可以重复运行。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File <配置包路径>\tools\install-project-skills.ps1 -Target D:\LvQian\YingChuangXingQiu -List <配置包路径>\skills\projects\YingChuangXingQiu.txt
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Target,
  [Parameter(Mandatory)][string]$List
)

$ErrorActionPreference = 'Stop'
$sources = Join-Path $env:TEMP 'opencode\agent-skill-sources'
$dest = Join-Path $Target '.agents\skills'

if (-not (Test-Path $Target -PathType Container)) { throw "项目目录不存在：$Target" }
if (-not (Test-Path $List)) { throw "清单不存在：$List" }

$entries = @(Get-Content $List -Encoding UTF8 | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
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
  if (Test-Path (Join-Path $to 'SKILL.md')) { Write-Host "    已存在：$($e.Name)" -ForegroundColor DarkGray; continue }
  $from = Join-Path $sources (Join-Path ($e.Repo -replace '/', '_') $e.Path)
  if (-not (Test-Path (Join-Path $from 'SKILL.md'))) { Write-Warning "上游缺少 $($e.Path)，已跳过"; continue }
  Copy-Item -Recurse $from $to
  Write-Host "    已安装：$($e.Name)" -ForegroundColor Green
}

Write-Host "完成。项目 skill 位于 $dest。" -ForegroundColor Cyan
