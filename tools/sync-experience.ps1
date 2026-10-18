<#
.SYNOPSIS
  同步经验库：提交本机新增的经验 → 拉取 GitHub 上的新经验 → 推送 → 刷新全局规则和已登记的项目。

.DESCRIPTION
  只提交 experience/ 和 AGENTS.base.md 的改动。其他文件有未提交改动时停止，避免误提交别的东西。
  拉取冲突时自动中止 rebase，本地内容保留，并在输出里说明。
  每次运行都会追加一行到 %LOCALAPPDATA%\BaseCompetence\sync.log。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\tools\sync-experience.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $env:LOCALAPPDATA 'BaseCompetence'
$logFile = Join-Path $logDir 'sync.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log($m) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm') $m"
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host $m
}

# git 会把进度写到 stderr，这里统一收集输出并以退出码判断成败
function Git {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $out = (& git -C $kit @args 2>&1 | Out-String).Trim()
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  [pscustomobject]@{ Code = $code; Out = $out }
}

$summary = @()
try {
  # 1. 检查工作区：只允许 experience/ 和 AGENTS.base.md 有改动
  $status = (Git status --porcelain).Out -split "`r?`n" | Where-Object { $_ }
  $mine = @($status | Where-Object { $_ -match '\s(experience/|AGENTS\.base\.md)' })
  $foreign = @($status | Where-Object { $_ -notmatch '\s(experience/|AGENTS\.base\.md)' })
  if ($foreign.Count -gt 0) {
    throw "配置包有其他未提交改动，已停止同步，请先处理：`n$($foreign -join "`n")"
  }

  # 2. 提交本机新增的经验
  if ($mine.Count -gt 0) {
    Git add -- experience AGENTS.base.md | Out-Null
    $msg = "experience: sync from $env:COMPUTERNAME $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    $c = Git commit -q -m $msg
    if ($c.Code -ne 0) { throw "提交失败：$($c.Out)" }
    $summary += "本机提交 $($mine.Count) 项改动"
  }

  # 3. 拉取
  $before = (Git rev-parse HEAD).Out
  $p = Git pull --rebase --quiet
  if ($p.Code -ne 0) {
    Git rebase --abort | Out-Null
    throw "拉取时冲突，已中止 rebase，本地内容保留。请人工处理：`n$($p.Out)"
  }
  $after = (Git rev-parse HEAD).Out
  if ($before -ne $after) {
    $changed = (Git diff --name-only $before $after -- experience).Out -split "`r?`n" | Where-Object { $_ }
    $summary += "拉取到 $($changed.Count) 条新经验"
    foreach ($f in $changed) { $summary += "    + $f" }
  } else {
    $summary += '拉取：没有新内容'
  }

  # 4. 推送
  $push = Git push --quiet origin HEAD:main
  if ($push.Code -eq 0) { $summary += '推送：完成' } else { $summary += "推送失败（网络？）：本地已提交，下次同步会重试" }
} catch {
  Write-Log "同步失败：$($_.Exception.Message)"
  exit 1
}

# 5. 刷新全局规则（AGENTS.base.md 可能已更新）
$boot = Join-Path $kit 'bootstrap.ps1'
& powershell -NoProfile -ExecutionPolicy Bypass -File $boot -Global -NoUpdate *>&1 | Out-Null
$summary += '全局规则：已刷新'

# 6. 刷新已登记的项目（只更新托管文件，用户文件不动）
$list = Join-Path $logDir 'projects.txt'
if (Test-Path $list) {
  $projects = @(Get-Content $list | Where-Object { $_ })
  $ok = 0
  foreach ($proj in $projects) {
    if (-not (Test-Path $proj -PathType Container)) { $summary += "    跳过（路径不存在）：$proj"; continue }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $boot -Target $proj -NoUpdate *>&1 | Out-Null
    $ok++
  }
  $summary += "项目：已刷新 $ok 个"
}

foreach ($s in $summary) { Write-Log $s }
Write-Log '同步完成'
