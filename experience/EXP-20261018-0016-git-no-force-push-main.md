---
id: EXP-20261018-0016
title: 多台电脑共用一个 Git 仓库：禁止 force push main，拉取一律 --rebase
tags: [git, workflow, multi-machine]
severity: high
status: active
seen: 1
source: YingChuangXingQiu WF-01 / docs/git-workflow.md
created: 2026-10-18
---

# 多台电脑共用一个 Git 仓库：禁止 force push main，拉取一律 --rebase

**症状**：历史被改写后，另一台电脑 `git pull` 冲突或分叉，只能删库重新克隆。

**根因**：`force push` 会改写其他机器已经拉取的提交。`git pull` 不带 `--rebase` 会产生多余的合并提交，两边慢慢分叉。

**规则**：
- 拉取一律 `git pull --rebase`，可以设置 `pull.rebase=true`
- 禁止 `git push --force` 到 main
- 网络不通时先本地提交，网络恢复后再推送

**守卫**：`manual`：在仓库设置里开启 main 分支保护，禁止强推。每台电脑运行 `git config pull.rebase true`。
