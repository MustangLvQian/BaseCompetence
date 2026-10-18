<#
.SYNOPSIS
  同步经验库：提交本机新增的经验 → 拉取 GitHub 上的新经验 → 推送 → 刷新全局规则和已登记的项目。

.DESCRIPTION
  只提交 experience/、guards/、skills/、AGENTS.base.md 的改动。其他文件有未提交改动时停止。
  拉取冲突时自动中止 rebase，本地内容保留，并在输出里说明。
  每次运行都会追加一行到 %LOCALAPPDATA%\BaseCompetence\sync.log。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\tools\sync-experience.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes'
$env:GIT_TERMINAL_PROMPT = '0'
$kit = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $env:LOCALAPPDATA 'BaseCompetence'
$logFile = Join-Path $logDir 'sync.log'
$boot = Join-Path $kit 'bootstrap.ps1'
$mine = 'experience/|guards/|skills/|AGENTS\.base\.md'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log($m) {
  Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm') $m" -Encoding UTF8
  Write-Host $m
}

# 注意：函数名不能叫 git，否则函数内的 `& git` 会递归调用自己。
function Invoke-Repo {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $out = (& git -C $kit @args 2>&1 | Out-String).Trim()
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  [pscustomobject]@{ Code = $code; Out = $out }
}

$summary = @()
try {
  $lines = (Invoke-Repo status --porcelain).Out -split "`r?`n" | Where-Object { $_ }
  $ours = @($lines | Where-Object { $_ -match "\s($mine)" })
  $foreign = @($lines | Where-Object { $_ -notmatch "\s($mine)" })
  if ($foreign.Count -gt 0) { throw "配置包有其他未提交改动，已停止同步：$($foreign -join '; ')" }

  if ($ours.Count -gt 0) {
    Invoke-Repo add -- experience guards skills AGENTS.base.md | Out-Null
    $c = Invoke-Repo commit -q -m "experience: sync from $env:COMPUTERNAME $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    if ($c.Code -ne 0) { throw "提交失败：$($c.Out)" }
    $summary += "本机提交 $($ours.Count) 项改动"
  }

  $before = (Invoke-Repo rev-parse HEAD).Out
  $p = Invoke-Repo pull --rebase --quiet
  if ($p.Code -ne 0) {
    Invoke-Repo rebase --abort | Out-Null
    throw "拉取冲突，已中止 rebase，本地内容保留：$($p.Out)"
  }
  $after = (Invoke-Repo rev-parse HEAD).Out
  if ($before -ne $after) {
    $changed = @((Invoke-Repo diff --name-only $before $after -- experience).Out -split "`r?`n" | Where-Object { $_ -and $_ -ne '_template.md' -and $_ -ne 'README.md' })
    $summary += "拉取到 $($changed.Count) 条新经验"
    foreach ($f in $changed) { $summary += "    + $f" }
  } else {
    $summary += '拉取：没有新内容'
  }

  $push = Invoke-Repo push --quiet origin HEAD:main
  if ($push.Code -eq 0) { $summary += '推送：完成' } else { $summary += '推送失败（网络？）：本地已提交，下次同步会重试' }
} catch {
  Write-Log "同步失败：$($_.Exception.Message)"
  exit 1
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $boot -Global -NoUpdate *>&1 | Out-Null
$summary += '全局规则：已刷新'

$list = Join-Path $logDir 'projects.txt'
if (Test-Path $list) {
  $ok = 0
  foreach ($proj in @(Get-Content $list | Where-Object { $_ })) {
    if (-not (Test-Path $proj -PathType Container)) { $summary += "    跳过（路径不存在）：$proj"; continue }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $boot -Target $proj -NoUpdate *>&1 | Out-Null
    $ok++
  }
  $summary += "项目：已刷新 $ok 个"
}

foreach ($s in $summary) { Write-Log $s }
Write-Log '同步完成'
