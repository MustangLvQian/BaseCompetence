---
id: EXP-20261018-0001
title: PWA 导航请求必须 network-first，不能 cache-first
tags: [pwa, service-worker, cache, deploy]
severity: high
status: active
guard: G-0001
seen: 1
source: YingChuangXingQiu PWA-02
created: 2026-10-18
---

# PWA 导航请求必须 network-first，不能 cache-first

**症状**：部署新版后，装过 PWA 的机器一直看到旧界面，甚至白屏。

**根因**：HTML 导航请求走了 cache-first，`/` 被永久钉在安装时的版本。HTML 里哈希过的 JS 在新版本已经 404。

**规则**：导航请求（`request.mode === 'navigate'`）一律 network-first，失败再回落缓存。只有带哈希的静态资源才用 cache-first。

**守卫**：`G-0001`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
