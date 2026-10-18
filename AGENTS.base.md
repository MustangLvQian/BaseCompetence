# Agent 基础规则（所有项目通用）

> 托管文件：由配置包 `{{KIT_PATH}}` 维护，每次同步会覆盖。不要在这里写项目专属内容，
> 项目专属规则写在项目自己的 `AGENTS.md` 里。项目规则与本文件冲突时，以项目规则为准。
> 经验库位置：`{{KIT_PATH}}\experience\`

## 0. 会话开始：自动执行，不需要用户指定

用户不会记这些步骤。每次会话开始，你自己按顺序做，**不要问用户要路径或文件名**：

1. **同步经验库**：运行 `powershell -ExecutionPolicy Bypass -File "{{KIT_PATH}}\tools\sync-experience.ps1"`。失败不阻塞工作，记下原因，在结束时简短告诉用户
2. **读取当前项目的交接**：如果当前项目根目录有 `docs/handoff.md`，读它；有 `docs/task-log.md` 也读它。两者都没有，就跳过，不要主动创建
3. **处理交接里的待确认事项**：如果交接文档列出「需要人确认」的事项，先问用户这些，其他事情照常推进
4. **只在必要时问用户**：路径、项目信息都从文件和 git 里找。只有真正的需求分歧，或者需要用户亲自完成的操作（登录、管理员权限、SSH 公钥），才停下来问

**会话结束前**（用户说结束、或任务告一段落）：
- 更新当前项目的 `docs/handoff.md`（如果存在）：当前状态、下一步、待确认事项
- 如果本次产生了通用经验，写进经验库并运行同步（第 8 节）

## 1. 会话连续性：进度写进文件，不靠对话

对话窗口随时可能关闭，所以**任何需要跨会话保留的信息都必须落到仓库文件里**。

- 每完成一个阶段或一个任务，更新 `docs/task-log.md`（状态 + commit）
- 会话结束前（或对话很长时），更新 `docs/handoff.md`：当前做到哪、下一步、未决问题
- 新会话的第一句话固定为：「先读 `docs/handoff.md` 和 `docs/task-log.md`，再开始」
- 给会话起一个有意义的标题，方便从列表里找回
- 需要保存更完整的上下文时，用 `gstack-context-save` / `gstack-context-restore`（如已安装）

## 2. 任务去重：动手前先查日志

- 开工前搜索 `docs/task-log.md`，同一任务 ID 已是 `done` 就不要重跑
- 开始长任务前先写一行 `started`，结束后改为 `done` 或 `failed`，
  这样即使对话断了，下一个会话也知道它跑到哪了
- 批处理脚本必须**幂等**：重跑只处理变化的部分（用 manifest、hash 或基线对比做增量），
  不要每次全量重新生成、重新调用付费接口
- 生成类任务（音频、TTS、大模型批量输出）先检查产物是否已存在，再决定是否生成
- 不确定某件事是否做过，先 `grep` 日志和 git log，再动手

## 3. 遇到问题：先搜经验库，再动手

遇到报错、异常行为、或要用一个不熟悉的工具时，**先搜经验库，不要先试错**。试错是最费 token 的做法。

```powershell
node "{{KIT_PATH}}\tools\find-experience.cjs" <关键词1> <关键词2>
```

命中的条目会输出一行摘要（编号、严重度、标题、守卫、文件路径）。需要细节时，只读那一个文件。
没有命中，再开始排查。

**守卫是真正会执行的检查，不是文字提醒。**
- 提交时 pre-commit 钩子运行守卫，只检查本次改动的文件，只输出违规行
- 推送时 pre-push 钩子拒绝强制推送 main
- 违规时提交会被拒绝。**不要用 `--no-verify` 绕过**；修正违规，或者说明为什么守卫误报并请用户决定
- 经验条目的 `guard` 字段是 `none` 时，表示它不能自动检查，只是知识，不要声称已经被强制执行

**解决问题后**：
- 只属于本项目的：写进项目的 `docs/pitfalls.md`
- 通用的（工具、框架、平台、Git、PowerShell 等）：在 `{{KIT_PATH}}\experience\` 新建一条（格式见 `_template.md`），能写成守卫的，在 `{{KIT_PATH}}\guards\guards.cjs` 里加一项检查，然后运行第 8 节的同步
- 第二次出现的坑，必须有一个能执行的守卫；做不到的，写明 `guard: none`，不要伪造守卫

## 4. Skill：按需搜索、安装、用完即删

- 需要某种能力但本机没有对应 skill 时，先在 GitHub 搜索（`gh search repos "skill <主题>"` 或 websearch），挑一个 SKILL.md 清楚、来源可信的，读一遍 SKILL.md 再装
- 安装：`powershell -ExecutionPolicy Bypass -File "{{KIT_PATH}}\tools\add-skill.ps1" -Repo <owner/repo> -Path <skill 目录>`。它会校验 frontmatter 并登记到 `skills/wanted.txt`，其他电脑同步后也会装上
- **用完即删**：本次任务结束时，如果为它装的 skill 没有用上，运行 `remove-skill.ps1 -Name <名字>` 删除，并同步
- 路由表只写**本机真实存在的 skill 名**（frontmatter 的 `name`）。新增、改名 skill 后，运行：
  ```bash
  node tools/check-skills.cjs --file AGENTS.md
  ```
- 同一功能只保留一个 skill，避免自动选择时互相竞争
- 不确定用哪个时，选路由表里的那一个，不要自行挑功能相近的
- 路由表要放在标题里含 "Skill" 的章节下（如 `## Skills`），检查工具只读这些章节
- **需求不清楚时先问，不要假设后动手**：用提问工具（如 `question`）逐条确认范围、验收标准、约束；需要系统梳理时用 `gstack-office-hours`（六个强制问题）或 `gstack-spec`。问清楚之前不要开始实现

### 按需求选 skill（路由表）

「调用方式」两种：
- **自动**：opencode 会按描述自动选中，你只需要照常描述需求
- **读 SKILL.md**：这些 skill 设置了禁止模型自动调用。遇到对应需求时，用读取工具打开 `~/.agents/skills/<名字>/SKILL.md`，按其中的流程执行

| 需求 | skill | 调用方式 |
|---|---|---|
| 需求或方案不清楚，要被追问到清楚 | `grilling` | 自动 |
| 同上，并把结论沉淀进领域文档（ADR、术语表） | `grill-with-docs` | 读 SKILL.md |
| 术语、领域模型、GLOSSARY、ADR | `domain-modeling` | 自动 |
| 测试先行、用 TDD 写功能或修 bug | `tdd` | 自动 |
| 难 bug、性能退化、「诊断一下」 | `diagnosing-bugs` | 自动 |
| 代码评审、按提交范围评审 | `code-review` | 自动 |
| 写 PR 描述 | `pr` | 自动 |
| 模块接口设计、可测性、接缝位置 | `codebase-design` | 自动 |
| 扫描架构里可以加深的模块 | `improve-codebase-architecture` | 读 SKILL.md |
| 用原型验证一个设计问题 | `prototype` | 自动 |
| 调研资料，结果落盘成 Markdown | `research` | 自动 |
| 把当前对话整理成规格并发布 | `to-spec` | 读 SKILL.md |
| 把规格或计划拆成可执行的 ticket | `to-tickets` | 读 SKILL.md |
| 按规格或 ticket 实现代码 | `implement`、`implement-spec` | 读 SKILL.md |
| 超大工作拆成决策地图，逐个解决 | `wayfinder` | 读 SKILL.md |
| issue 分诊 | `triage` | 读 SKILL.md |
| 复盘一次会话 | `retro` | 读 SKILL.md |
| 把对话交接给下一个 Agent | `handoff`、`claude-handoff` | 读 SKILL.md |
| 写给 Agent 的文档、skill、AGENTS.md | `writing-for-agents` | 自动 |
| 写文章：先收集素材，再成稿 | `writing-fragments`，然后 `writing-shape` | 读 SKILL.md |
| 长流程、多子任务的协调 | `chief-of-staff` | 读 SKILL.md |
| 不确定该用哪个 skill | `ask-matt` | 读 SKILL.md |
| 人类必须亲自完成的步骤（凭据、控制台、迁移切换）给出向导 | `wizard` | 自动 |
| 用户手动要求（斜杠命令） | `grill-me`、`teach`、`wait-what`、`to-questionnaire` | 仅用户触发 |

`grill-me` 是 `grilling` 的手动入口，行为相同。Agent 需要自动选中时用 `grilling`。

## 5. Token 节省

- 先 `grep` 定位，再用 `read` 带 `offset` / `limit` 读需要的段落，不整文件读
- 目录扫描排除 `node_modules`、`dist`、`.git`、音频（`*.wav`、`*.mp3`）、`package-lock.json`、大型 manifest
- 命令输出过长时，只取需要的列或计数，不要把整张表打印到对话里
- 长日志落盘后只读末尾或 grep 关键行
- 不重复粘贴已经在文件里的内容，引用路径和行号即可
- 能用脚本验证的，先跑脚本，不要反复问模型

## 6. Git 与安全

- `git pull` 一律 `--rebase`；**禁止 force push 到 main**
- 改动未提交前，不做任何会丢弃工作区的操作（`reset --hard`、`checkout --`、删目录）
- 清理或删除文件前，先确认不是用户未提交的工作；不确定就备份
- 测试未全绿不提交

## 7. 验证

- 改了前端：用真实浏览器验证。Playwright 的动画页面要设 `reduced_motion="reduce"`，
  否则无限循环动画会让元素永远不稳定；本机没有 Chromium 时可用系统 Edge（`channel="msedge"`）
- 改了界面：先看截图，不要只看单元测试
- 结论要标明验证方式：「已在浏览器看到」和「只跑了单元测试」是两件事

## 8. 经验同步：会话开始和结束时各一次

经验库在 GitHub 上，多台电脑共享。同步让每台电脑都能用到别人踩过的坑。

**会话开始时**（第一次动手前）运行：

```powershell
powershell -ExecutionPolicy Bypass -File "{{KIT_PATH}}\tools\sync-experience.ps1"
```

**会话结束前**，如果本次新增了通用经验，或修改了全局规则，运行同一条命令。改动会提交到本地；只有配置包所有者开启了推送（`git config basecompetence.push true`）时才会推送到 GitHub，否则输出里会说明「推送：未开启」。

- 同步失败（网络、冲突）时，不要阻塞工作，在最后的报告里说明即可
- 同步会同时刷新全局规则和已登记的项目，所以不需要手动更新各项目的 `AGENTS.base.md`
- 每台电脑还有一个计划任务每 4 小时自动同步，但不能替代会话开始时的同步

同步输出里列出的新经验，如果和当前任务相关，要读一下再动手。
