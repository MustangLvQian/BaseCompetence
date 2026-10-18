---
id: EXP-20261018-0015
title: Windows PowerShell 5.1 会吞掉传给原生程序的空字符串参数（如 ssh-keygen -N ""）
tags: [powershell, windows, ssh, native-command]
severity: medium
status: active
seen: 1
source: 本次发现（BaseCompetence AGENTS.md 第 2 步测试）
created: 2026-10-18
---

# Windows PowerShell 5.1 会吞掉传给原生程序的空字符串参数

**症状**：`ssh-keygen -t ed25519 -f $f -N ""` 报 `option requires an argument -- N`。改成 `-N '""'` 又会把两个引号当成口令。

**根因**：PowerShell 5.1 向原生程序传参时，空字符串会被丢弃，后面的参数就错位了。`cmd /c` 的多层转义也不稳定。

**规则**：需要精确控制命令行时，用 `System.Diagnostics.ProcessStartInfo`，把 `Arguments` 设为完整的命令行字符串，例如：

```powershell
$psi = New-Object System.Diagnostics.ProcessStartInfo 'ssh-keygen'
$psi.Arguments = "-t ed25519 -C 邮箱 -f `"$f`" -N `"`""
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi); $p.WaitForExit()
```

**守卫**：`manual`：写含空参数的原生命令时，先在 `Windows PowerShell` 里实际跑一次，并确认产物。
