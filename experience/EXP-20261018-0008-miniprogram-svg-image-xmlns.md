---
id: EXP-20261018-0008
title: SVG 放进小程序 <image> 必须带 xmlns 和 width/height，否则静默不渲染
tags: [miniprogram, svg, image, xml]
severity: high
status: active
seen: 1
source: YingChuangXingQiu MP-03
created: 2026-10-18
---

# SVG 放进小程序 <image> 必须带 xmlns 和 width/height，否则静默不渲染

**症状**：`<image>` 里的 SVG 完全不显示，连破图占位都没有。

**根因**：小程序把 SVG 当独立文档做严格解析。缺少 `xmlns`，或缺少 `width`/`height`，就会渲染成 0×0。浏览器在 DOM 里会宽容，所以网页上看不出问题。从网页组件用 `outerHTML` 导出的 SVG 通常两样都没有。

**规则**：小程序的 SVG 资源必须自带 `xmlns`、`width`、`height` 和 `viewBox`。

**守卫**：`✅ 自动`（YingChuangXingQiu）`check-templates.cjs` 扫描 `assets/**.svg`。
