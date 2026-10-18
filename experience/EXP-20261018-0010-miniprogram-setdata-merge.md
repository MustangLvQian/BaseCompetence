---
id: EXP-20261018-0010
title: 小程序同一事件里的多次 setData 要合并成一次
tags: [miniprogram, performance, setdata]
severity: medium
status: active
guard: none
seen: 1
source: YingChuangXingQiu MP-06
created: 2026-10-18
---

# 小程序同一事件里的多次 setData 要合并成一次

**症状**：真机上滑动或输入卡顿。

**根因**：每次 `setData` 都要跨 JS 线程和渲染层通信。同一事件里多次小更新叠加，开销很大。

**规则**：一个事件里要改的字段合并成一次 `setData`，只传变化的字段。

**守卫**：`none`。不能自动检查，靠上面的规则人工遵守；不要把它当成已强制执行的规则。
