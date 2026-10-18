<#
.SYNOPSIS
  注册 Windows 计划任务：登录时同步一次，之后每 N 小时同步一次。重复运行会更新已有任务。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File <配置包路径>\tools\install-sync-task.ps1
  powershell -ExecutionPolicy Bypass -File <配置包路径>\tools\install-sync-task.ps1 -Hours 2
#>

[CmdletBinding()]
param(
  [int]$Hours = 4
)

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$script = Join-Path $kit 'tools\sync-experience.ps1'
$taskName = 'BaseCompetence-Sync'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
$triggers = @(
  (New-ScheduledTaskTrigger -AtLogOn),
  (New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Hours $Hours))
)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Settings $settings `
  -Description '定期同步 BaseCompetence 经验库（提交本机经验、拉取他机经验、推送、刷新全局规则）' `
  -Force | Out-Null

Write-Host "已注册计划任务：$taskName（登录时 + 每 $Hours 小时）" -ForegroundColor Green
Write-Host "日志：$env:LOCALAPPDATA\BaseCompetence\sync.log"
