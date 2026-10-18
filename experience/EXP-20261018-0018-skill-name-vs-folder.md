---
id: EXP-20261018-0018
title: skill 的 frontmatter name 与文件夹名不一致时，路由表要写 name，不要写文件夹名
tags: [skills, opencode, routing, frontmatter]
severity: medium
status: active
guard: G-0018
seen: 1
source: 本次发现（英创项目 tools/skills/install.ps1 误报）
created: 2026-10-18
---

# skill 的 frontmatter name 与文件夹名不一致时，路由表要写 name

**症状**：安装脚本报 `gstack-*` 系列失败，因为文件夹名（`gstack-qa`）和 frontmatter 的 `name`（`qa`）不一致。路由表里写 `gstack-qa` 时，自动选择也可能对不上。

**根因**：opencode 按 frontmatter 的 `name` 识别 skill，不是按文件夹名。

**规则**：
- 路由表和文档里写 **frontmatter 的 `name`**
- 校验时两种名字都认（`check-skills.cjs` 已经这样处理）
- 不要因为文件夹名和 name 不一致就判定 skill 损坏

**守卫**：`G-0018`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
