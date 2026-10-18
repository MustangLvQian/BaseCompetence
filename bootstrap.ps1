<#
.SYNOPSIS
  把通用 Agent 配置拉到项目里。已存在的文件不覆盖。可选安装到全局 opencode。

.EXAMPLE
  # 在项目目录里直接运行（-Target 默认为当前目录）
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1

.EXAMPLE
  # 指定项目，并安装全局规则（所有项目生效；已有的全局文件会先备份）
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Target D:\LvQian\新项目 -Global
#>

[CmdletBinding()]
param(
  [string]$Target = (Get-Location).Path,
  [switch]$Global,
  [switch]$NoUpdate
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Done($m) { Write-Host "    $m" -ForegroundColor Green }
function Write-Skip($m) { Write-Host "    $m" -ForegroundColor DarkGray }

# 1. 更新配置包本身（它是 git 仓库且网络可达时）。失败不影响使用本地版本。
if (-not $NoUpdate -and (Test-Path (Join-Path $kit '.git'))) {
  Write-Step '更新配置包'
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  git -C $kit pull --rebase --quiet 2>$null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  if ($code -eq 0) { Write-Done '已是最新' } else { Write-Warning '更新失败（网络或本地改动冲突），继续使用本地版本' }
}

# 2. 检查目标项目
Write-Step "写入项目：$Target"
if (-not (Test-Path $Target -PathType Container)) { throw "目标目录不存在：$Target" }

$files = @(
  @{ From = 'AGENTS.base.md';        To = 'AGENTS.base.md' },
  @{ From = 'templates\pitfalls.md'; To = 'docs\pitfalls.md' },
  @{ From = 'templates\handoff.md';  To = 'docs\handoff.md' },
  @{ From = 'templates\task-log.md'; To = 'docs\task-log.md' },
  @{ From = 'tools\check-skills.cjs'; To = 'tools\check-skills.cjs' }
)

foreach ($f in $files) {
  $src = Join-Path $kit $f.From
  $dst = Join-Path $Target $f.To
  if (Test-Path $dst) { Write-Skip "已存在，跳过：$($f.To)"; continue }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  Copy-Item $src $dst
  Write-Done "已创建：$($f.To)"
}

# 3. 项目 AGENTS.md：不存在则创建引用；已存在则只提示，不擅自改用户文件
$agents = Join-Path $Target 'AGENTS.md'
$ref = '通用规则见 `AGENTS.base.md`，项目专属规则写在本文件下方。'
if (-not (Test-Path $agents)) {
  Set-Content -Path $agents -Encoding UTF8 -Value @("# Agent 指令", '', $ref, '', '## 项目专属规则', '', '（在这里填写技术栈、硬约束、路由表）')
  Write-Done '已创建：AGENTS.md（含通用规则引用）'
} elseif (-not (Select-String -Path $agents -Pattern 'AGENTS\.base\.md' -Quiet)) {
  Write-Warning "AGENTS.md 已存在但未引用通用规则，请在开头加一行：$ref"
} else {
  Write-Skip 'AGENTS.md 已引用通用规则'
}

# 4. 全局安装（可选）：写入 ~/.config/opencode/AGENTS.md，所有项目都会加载
if ($Global) {
  Write-Step '安装全局规则'
  $gdir = Join-Path $HOME '.config\opencode'
  $gfile = Join-Path $gdir 'AGENTS.md'
  $gsrc = Join-Path $kit 'AGENTS.base.md'
  New-Item -ItemType Directory -Force -Path $gdir | Out-Null
  if ((Test-Path $gfile) -and ((Get-FileHash $gfile).Hash -ne (Get-FileHash $gsrc).Hash)) {
    $bak = "$gfile.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $gfile $bak
    Write-Skip "已备份原全局文件：$bak"
  }
  Copy-Item $gsrc $gfile -Force
  Write-Done "已写入：$gfile"
}

# 5. 检查 skill 路由表（只报告，不中断）
Write-Step '检查 skill 路由'
if (Get-Command node -ErrorAction SilentlyContinue) {
  if (Test-Path $agents) {
    Push-Location $Target
    try { node (Join-Path $Target 'tools\check-skills.cjs') --file AGENTS.md } finally { Pop-Location }
  }
} else {
  Write-Warning '未找到 node，跳过 skill 检查。安装 Node.js 后运行：node tools/check-skills.cjs'
}

Write-Host ''
Write-Host '完成。下一步：在项目 docs\pitfalls.md 里填写守卫命令，并在 AGENTS.md 填写项目专属规则。' -ForegroundColor Cyan
