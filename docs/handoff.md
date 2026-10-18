# 交接：配置包（BaseCompetence）

> 新会话第一句话：「读 `D:\LvQian\BaseCompetence\docs\handoff.md`，然后继续。」
> 本文件只写现在的状态和待办。历史细节看 git log。

**最后更新：** 2026-10-18　**配置包最新提交：** `c5b27e6`（工作区干净）

## 已经完成（不要重做）

- 配置包结构：`AGENTS.md`（安装清单）、`AGENTS.base.md`（全局规则，已瘦身到约 220 token）、`rules/`（按需读取的细节）、`experience/`（经验库，19 条）、`guards/`（守卫，由 git 钩子执行）、`skills/`（清单与标签）、`tools/`
- 守卫钩子：已接入英创星球和 VoiceBuilder（`.git/hooks/pre-commit`、`pre-push`）
- 同步：计划任务 `BaseCompetence-Sync` 每 4 小时拉取 GitHub，更新全局规则、已登记项目的托管文件、项目 skill 清单、skill 标签
- 全局 skill：自动调用的只剩 5 个（`grilling`、`tdd`、`diagnosing-bugs`、`code-review`、`webapp-testing`），标签已写入，约 66 token
- gstack 已删除（54 个副本，`~/gstack`、`~/.gstack`）
- 动效类 11 个 skill 和 `ycx-verify` 只在英创项目的 `.agents/skills` 里
- 英创 Agent 已按 `rules/skill-labels.md` 完成 12 个项目 skill 的打标签（有 `SKILL.md.orig` 备份）
- 模板（`templates/`）已去掉示例行，任务日志有「token 消耗」列
- **skill 隐藏验证通过（2026-10-18）**：新会话里可用 skill 只剩 5 个自动调用 + `opencode`/`report` 两个内置，被 deny 的（prototype、codebase-design 等）都不出现
- **prototype 重名已解决（2026-10-18）**：用户选保留 mattpocock 版——已取消 deny（本会话已确认可用）；UI 多方案版移到 `%LOCALAPPDATA%\BaseCompetence\backup\prototype-ui-20261018`（opencode 和 Claude 目录各一份，未永久删除）
- **标签格式已更新（2026-10-18，用户确认）**：新格式 = 英文功能句（≤5 词）+ 中文触发词（3–4 个），每条 ≤45 字符。`skills/labels.txt` 和 `rules/skill-labels.md` 已改；英创 12 个标签按新格式重做已写进英创 handoff 第 9 节
- 开机同步：用户决定暂不处理（2026-10-18）

## 待办（按优先级）

1. **英创 12 个 skill 标签按新格式重做**：英创 Agent 按其 handoff 第 9 节重打（英文功能句 + 中文触发词，≤45 字符）。重做后给用户确认，确认后英创只提交标签相关文件
2. **英创守卫违规（交接文档第 3 节）**：6 项路由 + 1 个 .ps1 缺 BOM + 1 个样式 + 4 处 `?.`，英创 Agent 还没有修完。修完前提交会被钩子拦下
3. **英创路由表的 gstack 替换**（交接文档第 3.1b 节）：`investigate`→`diagnosing-bugs`，`review`→`code-review`，`qa`→`webapp-testing`
4. **积累 token 数据**：任务日志的「token 消耗」列要坚持填。积累约 10 个任务后，再决定哪些规则留下、哪些删掉

## 不要做的事

- 不要用 `--no-verify` 绕过守卫
- 不要直接改英创项目的文件；需要英创做的事，写进英创的 `docs/handoff-base-competence.md`
- 不要给别的项目的 skill 打标签
- 不要把英创的 `.agents/skills` 当作全局 skill 处理

## 关键路径

- 全局规则：`C:\Users\rose_\.config\opencode\AGENTS.md`（由 `AGENTS.base.md` 生成）
- 同步脚本：`tools\sync-experience.ps1`
- 健康检查：`tools\doctor.ps1`、`node tools\run-guards.cjs --self-check`
- 英创交接：`D:\LvQian\YingChuangXingQiu\docs\handoff-base-competence.md`
- VoiceBuilder 交接：`D:\LvQian\VoiceBuilder\docs\handoff.md`

## 本次会话的关键决定（避免重新讨论）

- 项目专用 skill 由各项目 Agent 自己打标签，配置包不代劳
- 不删除用户的文件，只隐藏（`permission.skill` 设为 `deny`）；删除的只有用户明确表示不要的 gstack
- 守卫只做机械检查，不做需要判断的事（如“答错能否重选”）
- 同步只推送到用户自己的仓库（`basecompetence.push` 开关）
- 标签功能句用英文、触发词必须中文（2026-10-18）：中文 1 字 ≈ 1 token、英文 4 字符 ≈ 1 token，真正省钱的是缩短篇幅，不是换语言；触发词换英文会匹配不上中文提问
