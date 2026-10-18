<#
.SYNOPSIS
  安装本套配置依赖的 skill 到 ~/.agents/skills。已存在的 skill 不覆盖。

.DESCRIPTION
  opencode 会自动加载 ~/.agents/skills 下每个合法的 SKILL.md。
  这里的清单来自英创星球项目已经确认的集合。要增删 skill，只改下面的 $Wanted。
  仓库通过 SSH 克隆（国内网络 https 常超时）。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\tools\install-skills.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$dest = Join-Path $HOME '.agents\skills'
$sources = Join-Path $env:TEMP 'opencode\agent-skill-sources'

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Done($m) { Write-Host "    $m" -ForegroundColor Green }
function Write-Skip($m) { Write-Host "    $m" -ForegroundColor DarkGray }

# 仓库、子目录、需要的 skill 名（与目录名一致）
$Wanted = @(
  @{ Repo = 'emilkowalski/skills'; Sub = 'skills'; Skills = @(
      'emil-design-eng', 'animate', 'review-animations', 'improve-animations',
      'find-animation-opportunities', 'animation-performance',
      'animation-vocabulary', 'apple-design', 'mobile-native', 'break-ui',
      'pick-ui-library'
  ) },
  @{ Repo = 'anthropics/skills'; Sub = 'skills'; Skills = @(
      'webapp-testing', 'skill-creator'
  ) }
)

Write-Step "准备源码：$sources"
New-Item -ItemType Directory -Force -Path $sources | Out-Null
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
foreach ($entry in $Wanted) {
  $target = Join-Path $sources ($entry.Repo -replace '/', '_')
  if (Test-Path (Join-Path $target '.git')) { Write-Skip "已有源码：$($entry.Repo)"; continue }
  git clone --depth 1 --quiet "git@github.com:$($entry.Repo).git" $target 2>&1 | Out-Null
  if (-not (Test-Path (Join-Path $target '.git'))) {
    $ErrorActionPreference = $prev
    throw "无法克隆 $($entry.Repo)。请确认 SSH 已能访问 github.com（ssh -T git@github.com）。"
  }
  Write-Done "已克隆：$($entry.Repo)"
}
$ErrorActionPreference = $prev

Write-Step "安装到 $dest"
foreach ($entry in $Wanted) {
  $src = Join-Path $sources ($entry.Repo -replace '/', '_')
  foreach ($name in $entry.Skills) {
    $from = Join-Path $src (Join-Path $entry.Sub $name)
    $to = Join-Path $dest $name
    if (-not (Test-Path (Join-Path $from 'SKILL.md'))) { Write-Warning "上游缺少 $name，已跳过"; continue }
    if (Test-Path $to) { Write-Skip "已存在，保留：$name"; continue }
    Copy-Item -Recurse $from $to
    Write-Done "已安装：$name"
  }
}

Write-Host ''
Write-Host '完成。skill 在 opencode 启动时加载，请重启 opencode 后生效。' -ForegroundColor Cyan
