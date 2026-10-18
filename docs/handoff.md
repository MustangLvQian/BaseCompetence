# 交接：配置包（BaseCompetence）

> 新会话第一句话：「读 `D:\LvQian\BaseCompetence\docs\handoff.md`，然后继续。」
> 本文件只写现在的状态和待办。历史任务记在 `docs/task-log.md`（含「补录历史」节），细节看 git log。

**最后更新：** 2026-10-18（晚）　**配置包最新提交：** `ad9e61c`（改动见本次会话提交）

## 当前状态

- 配置包结构就位：`AGENTS.md`（安装清单）、`AGENTS.base.md`（全局规则 ≈220 token）、`rules/`（按需读取的细节）、`experience/`（经验 21 条，带领域 tags）、`guards/`（守卫，由 git 钩子执行）、`skills/`（清单与标签）、`tools/`
- 守卫钩子已接入英创星球和 VoiceBuilder（`.git/hooks/pre-commit`、`pre-push`）
- 计划任务 `BaseCompetence-Sync` 每 4 小时同步：全局规则、已登记项目的托管文件、skill 清单、标签
- 全局 skill：自动调用只有 5 个（`grilling`、`tdd`、`diagnosing-bugs`、`code-review`、`webapp-testing`），约 66 token；隐藏靠 `permission.skill: deny`，已验证有效
- 标签新格式（用户已确认）：英文功能句（≤5 词）+ 中文触发词（3–4 个），每条 ≤45 字符，见 `skills/labels.txt`、`rules/skill-labels.md`
- `check-skills.cjs` 已修「不要用」列误报（G-0018，方案 a）：该列的弃用名不算 missing、不影响退出码

## 待办（按优先级）

1. **英创 12 个标签等用户确认后提交**：英创 Agent（或下个会话）把 12 个 `.agents/skills/*/SKILL.md`（每个只有 description 一行改动）单独提交，不要带上仓库其他未提交改动。12 个新标签清单见英创交接第 9 节
2. **积累 token 数据**：任务日志的「token 消耗」列要坚持填。积累约 10 个任务后，再决定哪些规则留下、哪些删掉
3. **英创遗留：3.3 行高改动的视觉验证**：需用户在微信开发者工具开启服务端口后跑 `npm run verify:ui` 补截图（守卫和 `npm run check` 已通过）

## 不要做的事

- 不要用 `--no-verify` 绕过守卫
- 不要直接改英创项目的文件；需要英创做的事，写进英创的 `docs/handoff-base-competence.md`
- 不要给别的项目的 skill 打标签
- 不要把英创的 `.agents/skills` 当作全局 skill 处理
- handoff 不记历史任务，历史进 `docs/task-log.md` 的「补录历史」节

## 关键路径

- 全局规则：`C:\Users\rose_\.config\opencode\AGENTS.md`（由 `AGENTS.base.md` 生成）
- 任务日志与历史：`docs\task-log.md`
- 同步脚本：`tools\sync-experience.ps1`
- 健康检查：`tools\doctor.ps1`、`node tools\run-guards.cjs --self-check`
- 英创交接：`D:\LvQian\YingChuangXingQiu\docs\handoff-base-competence.md`
- VoiceBuilder 交接：`D:\LvQian\VoiceBuilder\docs\handoff.md`

## 长期决定（避免重新讨论）

- 项目专用 skill 由各项目 Agent 自己打标签，配置包不代劳
- 不删除用户的文件，只隐藏（`permission.skill` 设为 `deny`）；删除的只有用户明确表示不要的 gstack
- 守卫只做机械检查，不做需要判断的事（如「答错能否重选」）
- 同步只推送到用户自己的仓库（`basecompetence.push` 开关）
- 标签功能句用英文、触发词必须中文：中文 1 字 ≈ 1 token、英文 4 字符 ≈ 1 token，真正省钱的是缩短篇幅，不是换语言；触发词换英文会匹配不上中文提问
- 经验读取按当前任务领域过滤：先从任务提炼 1～2 个最小必要的领域标签再查 `find-experience.cjs`，不相关领域的条目直接忽略，不深入读
- 开机同步暂不处理（2026-10-18）
