---
id: EXP-20261018-0011
title: Playwright 测试动画页面必须设置 reduced_motion，否则定位器永远超时
tags: [playwright, testing, animation, reduced-motion]
severity: high
status: active
seen: 2
source: YingChuangXingQiu WEB-03
created: 2026-10-18
---

# Playwright 测试动画页面必须设置 reduced_motion，否则定位器永远超时

**症状**：所有定位器超时，元素看起来永远不稳定。

**根因**：页面上有无限循环动画（如 7 秒一次的漂浮）。Playwright 要求元素静止后才能操作，循环动画使它永远达不到静止。

**规则**：`browser.new_context(reduced_motion="reduce")`。本机没有 Chromium 时，用系统 Edge：`p.chromium.launch(channel="msedge")`。

**守卫**：`✅ 自动`（YingChuangXingQiu）`ycx-verify` skill 和 `tools/shoot_screens.py` 已经固定这两个参数。在新项目里，把它写进测试的公共 fixture。
