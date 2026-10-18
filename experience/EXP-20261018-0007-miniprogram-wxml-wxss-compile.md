---
id: EXP-20261018-0007
title: 小程序 WXML/WXSS 只有开发者工具才会编译，node --check 看不见
tags: [miniprogram, wxml, wxss, lint]
severity: medium
status: active
guard: G-0007
seen: 2
source: YingChuangXingQiu MP-02
created: 2026-10-18
---

# 小程序 WXML/WXSS 只有开发者工具才会编译，node --check 看不见

**症状**：开发者工具报编译错误，而 `node --check` 通过。已经出过两次：
- WXSS 粘连：`}.选择器{`
- WXML 少闭合：编辑时吞掉了 `</view>`

**根因**：WXML 和 WXSS 不是 JavaScript，Node 无法解析。

**规则**：改完 wxml 或 wxss 后，必须跑模板检查脚本，不要等开发者工具才发现。

**守卫**：`G-0007`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
