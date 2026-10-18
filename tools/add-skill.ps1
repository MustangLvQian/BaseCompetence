<#
.SYNOPSIS
  从 GitHub 仓库安装一个 skill 到 ~/.agents/skills，校验后登记到 skills/wanted.txt，让其他电脑也能同步到。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\tools\add-skill.ps1 -Repo anthropics/skills -Path skills/pdf
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Repo,
  [Parameter(Mandatory)][string]$Path
)

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$sources = Join-Path $env:TEMP 'opencode\agent-skill-sources'
$dir = Join-Path $sources ($Repo -replace '/', '_')
$name = Split-Path $Path -Leaf
$list = Join-Path $kit 'skills\wanted.txt'

New-Item -ItemType Directory -Force -Path $sources | Out-Null
if (-not (Test-Path (Join-Path $dir '.git'))) {
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  git clone --depth 1 --quiet "git@github.com:$Repo.git" $dir 2>&1 | Out-Null
  $ErrorActionPreference = $prev
  if (-not (Test-Path (Join-Path $dir '.git'))) { throw "无法克隆 $Repo" }
}

$from = Join-Path $dir $Path
$skillFile = Join-Path $from 'SKILL.md'
if (-not (Test-Path $skillFile)) { throw "$Repo 中不存在 $Path\SKILL.md" }

# 校验：frontmatter 必须有 name 和 description，否则 opencode 不会自动选中它
$head = (Get-Content $skillFile -TotalCount 30) -join "`n"
if ($head -notmatch '(?m)^name:\s*\S' -or $head -notmatch '(?m)^description:') {
  throw "$name 的 SKILL.md 缺少 name 或 description，已放弃安装"
}

$to = Join-Path $HOME ".agents\skills\$name"
if (Test-Path $to) { Remove-Item -Recurse -Force $to }
Copy-Item -Recurse $from $to

$entry = "$Repo $Path"
$existing = @(Get-Content $list -Encoding UTF8)
if ($existing -notcontains $entry) { Add-Content -Path $list -Value $entry -Encoding UTF8 }

Write-Host "已安装并登记：$name（来源 $Repo/$Path）。需要重启 opencode 生效。" -ForegroundColor Green
