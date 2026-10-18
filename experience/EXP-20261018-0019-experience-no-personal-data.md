---
id: EXP-20261018-0019
title: 经验库可能公开，条目里不能写个人路径、邮箱或凭据
tags: [privacy, open-source, experience, secrets]
severity: high
status: active
guard: G-0019
seen: 1
source: 本次发现（准备开源 BaseCompetence 时）
created: 2026-10-18
---

# 经验库可能公开，条目里不能写个人路径、邮箱或凭据

**症状**：经验文件里出现了 `C:\Users\<用户名>\...`、个人邮箱或 token，一旦仓库公开就泄露了。

**根因**：写经验时顺手把本机的真实路径、命令输出或配置原样粘进来。

**规则**：经验正文只写通用做法。路径用 `<项目路径>`、`<配置包路径>`，邮箱用 `<邮箱>`，凭据用 `<token>`。不要粘贴含凭据的命令输出。

**守卫**：`G-0019`，由 git 钩子自动执行（见 `guards/guards.cjs`），违规时提交或推送会被拒绝。
