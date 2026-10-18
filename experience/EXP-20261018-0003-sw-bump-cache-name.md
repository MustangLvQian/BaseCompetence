---
id: EXP-20261018-0003
title: 改了 Service Worker 行为必须同时提升 CACHE_NAME 版本
tags: [pwa, service-worker, cache]
severity: medium
status: active
seen: 1
source: YingChuangXingQiu PWA-04
created: 2026-10-18
---

# 改了 Service Worker 行为必须同时提升 CACHE_NAME 版本

**症状**：改了 SW 的缓存逻辑，老用户仍然跑旧缓存。

**根因**：`CACHE_NAME` 没有变，`activate` 不会清理旧缓存，`install` 也不会重建。

**规则**：每次修改 SW 行为，都必须提升 `CACHE_NAME` 里的版本号。

**守卫**：`✅ 自动` 检查 `CACHE_NAME` 包含数字版本，接进 check 命令。
