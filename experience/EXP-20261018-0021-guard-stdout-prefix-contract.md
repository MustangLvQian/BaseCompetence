---
id: EXP-20261018-0021
title: 守卫靠解析 stdout 判违规时，脚本的信息性输出不能用「  - 」前缀
tags: [guards, tools, maintenance, output-format]
severity: medium
status: active
guard: none
seen: 1
source: 本次发现（修 G-0018 误报时踩到）
created: 2026-10-18
---

# 守卫靠解析 stdout 判违规时，脚本的信息性输出不能用「  - 」前缀

**症状**：`G-0018` 守卫把 `check-skills.cjs` 输出里 `  - ` 开头的行都算作「路由表引用了不存在的 skill」。给 check-skills 加「已豁免，预期如此」的提示列表时若也用 `  - ` 前缀，豁免名单会被守卫重新变成违规——误报换了个门回来。

**根因**：守卫与脚本之间没有结构化的返回值，只靠行首前缀约定通信（`run-guards.cjs` 里 `check-skills.cjs` 的 catch 分支用 `/^\s+-\s/` 抽违规行）。前缀是隐式契约，脚本加新输出时很容易踩。

**规则**：
- 给被守卫解析的脚本加信息性输出时，用不同的行首标记（如 `  · `），不要复用 `  - `
- 改这类脚本后，要跑「只有豁免项、无真实违规」的用例，确认 exit 0
- 反向原则同样成立：违规行的前缀是接口，改它等于改守卫，要同步改守卫

**守卫**：`guard: none`（无法机械检查，靠本条经验提醒）
