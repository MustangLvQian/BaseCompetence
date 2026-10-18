---
id: EXP-20261018-0011
title: Playwright 测试动画页面必须设置 reduced_motion，否则定位器永远超时
tags: [playwright, testing, animation, reduced-motion]
severity: high
status: active
guard: G-0011
seen: 2
source: YingChuangXingQiu WEB-03
created: 2026-10-18
---

# Playwright 测试动画页面必须设置 reduced_motion，否则定位器永远超时

**症状**：所有定位器超时，元素看起来永远不稳定。

**根因**：页面上有无限循环动画（如 7 秒一次的漂浮）。Playwright 要求元素静止后才能操作，循环动画使它永远达不到静止。

**规则**：`browser.new_context(reduced_motion="reduce")`。本机没有 Chromium 时，用系统 Edge：`p.chromium.launch(channel="msedge")`。

**守卫**：`G-0011`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
