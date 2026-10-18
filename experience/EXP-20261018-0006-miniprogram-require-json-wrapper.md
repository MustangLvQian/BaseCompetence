---
id: EXP-20261018-0006
title: 微信小程序 require() 不能直接加载 .json，需要 .json.js 包装
tags: [miniprogram, wechat, require, json]
severity: high
status: active
guard: G-0006
seen: 1
source: YingChuangXingQiu MP-01
created: 2026-10-18
---

# 微信小程序 require() 不能直接加载 .json，需要 .json.js 包装

**症状**：整个小程序起不来，报 `module ... is not defined`。

**根因**：小程序的 `require()` 按 `<name>.json.js` 查找，加载不了裸 `.json`。Node 可以直接 require `.json`，所以本地测试全绿也发现不了。

**规则**：每个被 `require` 的 JSON 都要有同名的 `.json.js` 包装文件。

**守卫**：`G-0006`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
