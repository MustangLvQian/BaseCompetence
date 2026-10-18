---
id: EXP-20261018-0013
title: prefers-reduced-motion 覆写的选择器特异度必须不低于被覆盖的规则
tags: [css, accessibility, reduced-motion, specificity]
severity: medium
status: active
guard: none
seen: 1
source: YingChuangXingQiu WEB-01
created: 2026-10-18
---

# prefers-reduced-motion 覆写的选择器特异度必须不低于被覆盖的规则

**症状**：开启了「减少动态效果」，元素仍然在漂移。

**根因**：覆写选择器的特异度低于原规则。媒体查询本身不增加特异度，所以覆写没有生效。

**规则**：覆写选择器的特异度要大于或等于被覆盖的规则。写覆写时，逐条对照原规则的选择器。

**守卫**：`none`。不能自动检查，靠上面的规则人工遵守；不要把它当成已强制执行的规则。
