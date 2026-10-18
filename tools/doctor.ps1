<#
.SYNOPSIS
  检查这台电脑是否已经具备配置包的全部功能。只读，不修改任何东西。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\tools\doctor.ps1

  退出码：有 FAIL 时为 1；只有 WARN 或全部 PASS 时为 0。
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$kit = Split-Path -Parent $PSScriptRoot
$script:fails = 0
$script:warns = 0

function Pass($m) { Write-Host "[PASS] $m" -ForegroundColor Green }
function Warn($m) { $script:warns++; Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m) { $script:fails++; Write-Host "[FAIL] $m" -ForegroundColor Red }

# 1. git
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) { Pass "git：$((git --version) -replace 'git version ', '')" } else { Fail '未安装 git。安装：winget install --id Git.Git -e' }

# 2. node
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) { Pass "node：$(node --version)" } else { Warn '未安装 node：skill 路由检查会跳过。安装：winget install --id OpenJS.NodeJS.LTS -e' }

# 3. python（Windows 的 python.exe 可能只是商店占位符，要真的执行一次）
$pyOk = $false
if (Get-Command python -ErrorAction SilentlyContinue) {
  $pyOut = python -c "import sys; print(sys.version.split()[0])" 2>$null
  if ($LASTEXITCODE -eq 0 -and $pyOut) { $pyOk = $true; Pass "python：$pyOut" }
}
if (-not $pyOk) { Warn '未检测到可用的 python：Playwright 测试不可用（不影响 skill 与规则）' }

# 4. GitHub SSH
$sshOut = (ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1) | Out-String
if ($sshOut -match 'successfully authenticated') {
  Pass 'GitHub SSH 已认证'
} else {
  Fail "GitHub SSH 未认证。需要用户把公钥加到 https://github.com/settings/keys。输出：$($sshOut.Trim())"
}

# 5. 全局规则
$gfile = Join-Path $HOME '.config\opencode\AGENTS.md'
$rendered = ([IO.File]::ReadAllText((Join-Path $kit 'AGENTS.base.md'), [Text.Encoding]::UTF8)).Replace('{{KIT_PATH}}', $kit)
if (-not (Test-Path $gfile)) {
  Fail "全局规则未安装：$gfile。运行 bootstrap.ps1 -Global"
} elseif ([IO.File]::ReadAllText($gfile, [Text.Encoding]::UTF8) -eq $rendered) {
  Pass '全局规则与配置包一致'
} else {
  Warn "全局规则与配置包不一致：$gfile。运行 bootstrap.ps1 -Global 更新（会先备份）"
}

# 5b. 经验同步计划任务
if (Get-ScheduledTask -TaskName 'BaseCompetence-Sync' -ErrorAction SilentlyContinue) {
  Pass '经验同步计划任务已注册'
} else {
  Warn '经验同步计划任务未注册。运行 tools\install-sync-task.ps1 以每 4 小时自动同步'
}

# 6. skill：清单中的每个名字都要在 ~/.agents/skills 下有有效的 SKILL.md
$installScript = Join-Path $kit 'tools\install-skills.ps1'
$wantedText = Get-Content $installScript -Raw
$wanted = [regex]::Matches($wantedText, '(?s)Skills = @\((.*?)\)') | ForEach-Object {
  [regex]::Matches($_.Groups[1].Value, "'([a-z][a-z0-9-]+)'") | ForEach-Object { $_.Groups[1].Value }
}
$skillRoot = Join-Path $HOME '.agents\skills'
$missing = @($wanted | Where-Object { -not (Test-Path (Join-Path $skillRoot "$_\SKILL.md")) })
if ($missing.Count -eq 0) {
  Pass "skill 清单全部就位：$($wanted.Count) 个"
} else {
  Fail "缺少 $($missing.Count) 个 skill：$($missing -join ', ')。运行 tools\install-skills.ps1"
}

# 7. skill 路由检查（依赖 node）
if ($node) {
  $chk = (node (Join-Path $kit 'tools\check-skills.cjs') 2>&1) | Out-String
  if ($LASTEXITCODE -eq 0) { Pass 'skill 元数据全部有效' } else { Warn "skill 元数据有问题，运行 node tools\check-skills.cjs 查看详情" }
}

# 8. Playwright 与浏览器（可选）
if ($pyOk) {
  python -c "import playwright" 2>$null
  if ($LASTEXITCODE -eq 0) { Pass 'Python Playwright 已安装' } else { Warn 'Python Playwright 未安装。安装：python -m pip install playwright' }
}
$edge = @("$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($edge) { Pass 'Microsoft Edge 可用（Playwright 用 channel="msedge"）' } else { Warn '未找到 Microsoft Edge：浏览器测试需要其他浏览器' }

Write-Host ''
Write-Host "结果：$script:fails 项失败，$script:warns 项警告" -ForegroundColor Cyan
if ($script:fails -gt 0) { exit 1 } else { exit 0 }
