# Skill 路由表

只在需要选 skill 时读取。

「调用方式」两种：
- **自动**：opencode 按描述自动选中，照常描述需求即可
- **读 SKILL.md**：这些 skill 禁止模型自动调用。用读取工具打开 `~/.agents/skills/<名字>/SKILL.md`，按其中的流程执行

| 需求 | skill | 调用方式 |
|---|---|---|
| 需求或方案不清楚，要被追问到清楚 | `grilling` | 自动 |
| 同上，并把结论沉淀进领域文档（ADR、术语表） | `grill-with-docs` | 读 SKILL.md |
| 术语、领域模型、GLOSSARY、ADR | `domain-modeling` | 读 SKILL.md |
| 测试先行、用 TDD 写功能或修 bug | `tdd` | 自动 |
| 难 bug、性能退化、「诊断一下」 | `diagnosing-bugs` | 自动 |
| 代码评审、按提交范围评审 | `code-review` | 自动 |
| 写 PR 描述 | `pr` | 读 SKILL.md |
| 模块接口设计、可测性、接缝位置 | `codebase-design` | 读 SKILL.md |
| 扫描架构里可以加深的模块 | `improve-codebase-architecture` | 读 SKILL.md |
| 用原型验证一个设计问题 | `prototype` | 读 SKILL.md |
| 调研资料，结果落盘成 Markdown | `research` | 读 SKILL.md |
| 把当前对话整理成规格并发布 | `to-spec` | 读 SKILL.md |
| 把规格或计划拆成可执行的 ticket | `to-tickets` | 读 SKILL.md |
| 按规格或 ticket 实现代码 | `implement`、`implement-spec` | 读 SKILL.md |
| 超大工作拆成决策地图，逐个解决 | `wayfinder` | 读 SKILL.md |
| issue 分诊 | `triage` | 读 SKILL.md |
| 复盘一次会话 | `retro` | 读 SKILL.md |
| 把对话交接给下一个 Agent | `handoff`、`claude-handoff` | 读 SKILL.md |
| 写给 Agent 的文档、skill、AGENTS.md | `writing-for-agents` | 读 SKILL.md |
| 写文章：先收集素材，再成稿 | `writing-fragments`，然后 `writing-shape` | 读 SKILL.md |
| 长流程、多子任务的协调 | `chief-of-staff` | 读 SKILL.md |
| 不确定该用哪个 skill | `ask-matt` | 读 SKILL.md |
| 人类必须亲自完成的步骤（凭据、控制台、迁移切换）给出向导 | `wizard` | 读 SKILL.md |
| 用户手动要求（斜杠命令） | `grill-me`、`teach`、`wait-what`、`to-questionnaire` | 仅用户触发 |

`grill-me` 是 `grilling` 的手动入口，行为相同。Agent 需要自动选中时用 `grilling`。

项目专用的 skill（如动效类）在对应项目的 `.agents/skills` 里，不在这张表中。
