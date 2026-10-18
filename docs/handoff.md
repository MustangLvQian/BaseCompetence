# 交接：配置包（BaseCompetence）

> 新会话第一句话：「读 `D:\LvQian\BaseCompetence\docs\handoff.md`，然后继续。」
> 本文件只写现在的状态和待办。历史细节看 git log。

**最后更新：** 2026-10-18（晚）　**配置包最新提交：** `ad9e61c`（工作区干净，已与 origin/main 同步）

## 已经完成（不要重做）

- 配置包结构：`AGENTS.md`（安装清单）、`AGENTS.base.md`（全局规则，已瘦身到约 220 token）、`rules/`（按需读取的细节）、`experience/`（经验库，20 条）、`guards/`（守卫，由 git 钩子执行）、`skills/`（清单与标签）、`tools/`
- 守卫钩子：已接入英创星球和 VoiceBuilder（`.git/hooks/pre-commit`、`pre-push`）
- 同步：计划任务 `BaseCompetence-Sync` 每 4 小时拉取 GitHub，更新全局规则、已登记项目的托管文件、项目 skill 清单、skill 标签
- 全局 skill：自动调用的只剩 5 个（`grilling`、`tdd`、`diagnosing-bugs`、`code-review`、`webapp-testing`），标签已写入，约 66 token
- gstack 已删除（54 个副本，`~/gstack`、`~/.gstack`）
- 动效类 11 个 skill 和 `ycx-verify` 只在英创项目的 `.agents/skills` 里
- 英创 Agent 第一轮打标签已完成（旧格式，有 `SKILL.md.orig` 备份；第二轮见下）
- 模板（`templates/`）已去掉示例行，任务日志有「token 消耗」列
- **skill 隐藏验证通过（2026-10-18）**：新会话里可用 skill 只剩 5 个自动调用 + `opencode`/`report` 两个内置，被 deny 的（prototype、codebase-design 等）都不出现
- **prototype 重名已解决（2026-10-18）**：用户选保留 mattpocock 版——已取消 deny（本会话已确认可用）；UI 多方案版移到 `%LOCALAPPDATA%\BaseCompetence\backup\prototype-ui-20261018`（opencode 和 Claude 目录各一份，未永久删除）
- **标签格式已更新（2026-10-18，用户确认）**：新格式 = 英文功能句（≤5 词）+ 中文触发词（3–4 个），每条 ≤45 字符。`skills/labels.txt` 和 `rules/skill-labels.md` 已改；英创 12 个标签按新格式重做已写进英创 handoff 第 9 节
- 开机同步：用户决定暂不处理（2026-10-18）
- **英创 4 类守卫违规全部修复并提交（2026-10-18，英创 Agent 完成）**：BOM `2e92c04`、行高 `a9907b0`、可选链 `bd60b29`、路由表 `21a531d`；`run-guards.cjs --all` 0 违规。遗留一项视觉验证（见待办 4）
- **英创 12 个 skill 标签第二轮完成（2026-10-18）**：新格式（英文功能句 + 中文触发词，≤45 字符），自验 12/12 通过、`check-skills.cjs` 通过。**12 个 `SKILL.md` 改动在英创工作区未提交，等用户确认标签后单独提交**
- **经验文件已带 tags 字段**（如 `[miniprogram, wechat, syntax, compatibility]`），经验按领域过滤有数据基础

## 待办（按优先级）

1. **英创 12 个标签等用户确认后提交（原重做已完成，只差这一步）**：英创 Agent（或下个会话）把 12 个 `.agents/skills/*/SKILL.md`（每个只有 description 一行改动）单独提交，不要带上仓库其他未提交改动。12 个新标签清单见英创交接第 9 节
2. **修 G-0018 误报（维护者任务，源自英创 Agent 的反馈）**：`tools/check-skills.cjs` 把路由表「不要用」列里的弃用 skill 名也算成 missing 并 `exit(1)`，但提示又说「可忽略」，人和守卫结论相反。修法：按 `|` 列解析表格，「不要用」列的缺失名不算 missing（英创反馈里的方案 a）
3. **积累 token 数据**：任务日志的「token 消耗」列要坚持填。积累约 10 个任务后，再决定哪些规则留下、哪些删掉
4. **英创遗留：3.3 行高改动的视觉验证**：需用户在微信开发者工具开启服务端口后跑 `npm run verify:ui` 补截图（守卫和 `npm run check` 已通过）

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
- **经验读取按当前任务领域过滤（2026-10-18，用户原则）**：不是开发小程序不读小程序经验，不是做动画不读动画经验，不是 UI 选型不读组件库经验，以此类推。先从任务提炼 1～2 个最小必要的领域标签再查 `find-experience.cjs`；结果里出现不相关领域的条目直接忽略，不深入读
