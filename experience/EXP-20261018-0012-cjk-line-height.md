---
id: EXP-20261018-0012
title: 中文字的 line-height 要至少 1.35，否则上下被裁掉
tags: [css, cjk, typography, overflow]
severity: medium
status: active
seen: 1
source: YingChuangXingQiu WEB-02
created: 2026-10-18
---

# 中文字的 line-height 要至少 1.35，否则上下被裁掉

**症状**：中文字的顶部和底部被切掉一截，尤其在带 `overflow: hidden` 的容器里。

**根因**：CJK 字形需要约 1.34em 的行盒。`line-height` 小于它，字就会掉出行盒，被祖先元素的 `overflow: hidden` 裁掉。实测 1.15 和 1.20 会被裁，1.35 安全。

**规则**：含中文的行盒，`line-height` 取 1.35 或更大。

**守卫**：`manual`：写含中文的按钮和标题样式时检查。能用截图验证的，用截图确认。
