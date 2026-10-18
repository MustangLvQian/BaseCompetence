---
id: EXP-20261018-0009
title: 小程序运行时代码的现代语法要对照 libVersion，真机可能直接报错
tags: [miniprogram, wechat, syntax, compatibility]
severity: medium
status: active
guard: G-0009
seen: 1
source: YingChuangXingQiu MP-04
created: 2026-10-18
---

# 小程序运行时代码的现代语法要对照 libVersion，真机可能直接报错

**症状**：真机或旧基础库直接抛语法错误，但开发者工具正常。

**根因**：运行时 JS 用了目标基础库不支持的语法（如 `?.`、`??`）。开发者工具版本通常比基础库新。

**规则**：生成运行时代码前，确认 `project.config.json` 的 `libVersion`。不确定时，用传统的 `if` 和 `&&` 写法。

**守卫**：`G-0009`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
