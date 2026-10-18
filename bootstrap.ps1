<#
.SYNOPSIS
  把通用 Agent 配置拉到项目里，或安装全局规则。

  托管文件（AGENTS.base.md、tools/check-skills.cjs）每次都会更新到最新版。
  用户文件（docs/pitfalls.md、docs/handoff.md、docs/task-log.md、AGENTS.md）已存在时不覆盖。

.EXAMPLE
  # 接入项目（会登记到同步列表，之后 sync-experience.ps1 会自动更新它）
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Target D:\某个项目

.EXAMPLE
  # 安装或更新全局规则（所有项目生效）
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Global
#>

[CmdletBinding()]
param(
  [string]$Target,
  [switch]$Global,
  [switch]$NoUpdate
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Done($m) { Write-Host "    $m" -ForegroundColor Green }
function Write-Skip($m) { Write-Host "    $m" -ForegroundColor DarkGray }

# AGENTS.base.md 里的 {{KIT_PATH}} 替换为本配置包的绝对路径，让 Agent 知道去哪里找经验库
function Get-RenderedBase {
  $text = [IO.File]::ReadAllText((Join-Path $kit 'AGENTS.base.md'), [Text.Encoding]::UTF8)
  return $text.Replace('{{KIT_PATH}}', $kit)
}

function Write-Managed($src, $dst, $rendered) {
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  if ($rendered -ne $null) {
    [IO.File]::WriteAllText($dst, $rendered, $utf8)
  } else {
    Copy-Item $src $dst -Force
  }
}

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

$rendered = Get-RenderedBase

# 2. 项目接入。只给 -Global 时跳过这一步；什么都不给时，默认接入当前目录。
$doProject = $PSBoundParameters.ContainsKey('Target') -or -not $Global
if ($doProject) {
  if (-not $Target) { $Target = (Get-Location).Path }
  Write-Step "写入项目：$Target"
  if (-not (Test-Path $Target -PathType Container)) { throw "目标目录不存在：$Target" }
  $Target = (Resolve-Path $Target).Path
  if ($Target -eq (Resolve-Path $kit).Path) { throw '目标不能是配置包自己，请指定项目目录' }

  # 托管文件：总是更新
  Write-Managed $null (Join-Path $Target 'AGENTS.base.md') $rendered
  Write-Done '已更新（托管）：AGENTS.base.md'
  Write-Managed (Join-Path $kit 'tools\check-skills.cjs') (Join-Path $Target 'tools\check-skills.cjs') $null
  Write-Done '已更新（托管）：tools/check-skills.cjs'

  # 用户文件：只在缺失时创建
  $userFiles = @(
    @{ From = 'templates\pitfalls.md';  To = 'docs\pitfalls.md' },
    @{ From = 'templates\handoff.md';   To = 'docs\handoff.md' },
    @{ From = 'templates\task-log.md';  To = 'docs\task-log.md' }
  )
  foreach ($f in $userFiles) {
    $dst = Join-Path $Target $f.To
    if (Test-Path $dst) { Write-Skip "已存在，保留：$($f.To)"; continue }
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item (Join-Path $kit $f.From) $dst
    Write-Done "已创建：$($f.To)"
  }

  # 项目 AGENTS.md：不存在则创建引用；已存在则只提示，不擅自改用户文件
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

  # 登记到同步列表，sync-experience.ps1 会据此更新这个项目
  $listDir = Join-Path $env:LOCALAPPDATA 'BaseCompetence'
  $list = Join-Path $listDir 'projects.txt'
  New-Item -ItemType Directory -Force -Path $listDir | Out-Null
  $known = if (Test-Path $list) { @(Get-Content $list) } else { @() }
  if ($known -notcontains $Target) {
    Add-Content -Path $list -Value $Target -Encoding UTF8
    Write-Done "已登记到同步列表：$list"
  }
}

# 3. 全局规则（可选）：写入 ~/.config/opencode/AGENTS.md，所有项目都会加载它
if ($Global) {
  Write-Step '安装全局规则'
  $gdir = Join-Path $HOME '.config\opencode'
  $gfile = Join-Path $gdir 'AGENTS.md'
  New-Item -ItemType Directory -Force -Path $gdir | Out-Null
  $current = if (Test-Path $gfile) { [IO.File]::ReadAllText($gfile, [Text.Encoding]::UTF8) } else { $null }
  if ($current -eq $rendered) {
    Write-Skip '全局规则已是最新'
  } else {
    if ($current -ne $null) {
      $bak = "$gfile.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
      Copy-Item $gfile $bak
      Write-Skip "已备份原全局文件：$bak"
    }
    [IO.File]::WriteAllText($gfile, $rendered, $utf8)
    Write-Done "已写入：$gfile"
  }
}

# 4. 检查 skill 路由表（只报告，不中断）
if ($doProject) {
  Write-Step '检查 skill 路由'
  if (Get-Command node -ErrorAction SilentlyContinue) {
    if (Test-Path $agents) {
      Push-Location $Target
      try { node (Join-Path $Target 'tools\check-skills.cjs') --file AGENTS.md } finally { Pop-Location }
    }
  } else {
    Write-Warning '未找到 node，跳过 skill 检查。安装 Node.js 后运行：node tools/check-skills.cjs'
  }
}

Write-Host ''
if ($doProject) {
  Write-Host '完成。下一步：在项目 docs\pitfalls.md 里填写守卫命令，并在 AGENTS.md 填写项目专属规则。' -ForegroundColor Cyan
} else {
  Write-Host '完成。全局规则已安装，对所有项目生效。' -ForegroundColor Cyan
}
