---
id: EXP-20261018-0014
title: Windows PowerShell 5.1 解析无 BOM 的 UTF-8 脚本时，中文字符串会错位
tags: [powershell, windows, encoding, utf8, bom]
severity: high
status: active
seen: 1
source: 本次发现（BaseCompetence bootstrap.ps1 测试）
created: 2026-10-18
---

# Windows PowerShell 5.1 解析无 BOM 的 UTF-8 脚本时，中文字符串会错位

**症状**：脚本里的中文字符串被截断或拼错，`$(...)` 等表达式显示成 `System.Collections.Hashtable.To` 这类乱码，`Write-Host` 的字符串被拆开。

**根因**：Windows PowerShell 5.1 读取无 BOM 的文件时按系统 ANSI 代码页解析。UTF-8 的中文多字节被拆坏，引号和括号一起错位。PowerShell 7 默认按 UTF-8 读，所以不会出现。

**规则**：所有含中文的 `.ps1` 文件保存为 **UTF-8 with BOM**，行尾用 CRLF。写完后用 Windows PowerShell（不是 pwsh）实际运行一次验证。

注意：控制台里显示的 `�?` 是控制台编码问题，不代表文件损坏。判断文件内容是否正确，用编辑器或 Read 工具看原文。

**守卫**：`manual`：新建或修改含中文的 `.ps1` 后，用 Windows PowerShell 运行一次；必要时检查文件前三个字节是否为 `EF BB BF`。
