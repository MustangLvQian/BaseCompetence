---
id: EXP-20261018-0005
title: iOS Safari 会清空 7 天未打开的 PWA 存储
tags: [pwa, ios, storage, offline]
severity: medium
status: active
seen: 1
source: YingChuangXingQiu PWA-05
created: 2026-10-18
---

# iOS Safari 会清空 7 天未打开的 PWA 存储

**症状**：长时间没打开的机器，离线缓存凭空消失。

**根因**：iOS Safari 对 7 天未活跃的 PWA 清空存储。

**规则**：不要把「可离线」当成数据存储。关键状态要能在下次联网时重建。

**守卫**：`manual`：涉及本地持久化的功能，设计时确认数据可以从服务端恢复。
