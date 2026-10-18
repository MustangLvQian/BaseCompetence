# BaseCompetence：Agent 通用配置包

跨项目的经验、守卫和 skill 清单，托管在 GitHub，多台电脑共享。

## 第一次使用：只要一句话

```powershell
git clone git@github.com:MustangLvQian/BaseCompetence.git D:\BaseCompetence
```

然后对 Agent 说：「读 `D:\BaseCompetence\AGENTS.md`，并完成里面的所有任务。」

## 它包含什么

| 路径 | 作用 |
|---|---|
| `AGENTS.md` | Agent 的安装任务清单（第一次用这个） |
| `AGENTS.base.md` | 通用规则：遇到问题先搜经验库、会话连续性、守卫、skill、token 节省。作为全局规则安装，也会托管到各项目 |
| `experience/` | 经验库，一条经验一个文件（`EXP-*.md`），`find-experience.cjs` 搜索 |
| `guards/guards.cjs` | 守卫：真正会执行的检查代码，编号与经验的 `guard:` 字段对应 |
| `skills/wanted.txt` | skill 清单（仓库 + 目录），所有电脑同步到同一份 |
| `tools/run-guards.cjs` | 运行守卫。由 git 钩子调用，只检查改动的文件，只输出违规行 |
| `tools/find-experience.cjs` | 搜索经验库，只输出摘要 |
| `tools/sync-experience.ps1` | 同步：提交本机改动 → 拉取 → 推送 → 刷新全局规则和已登记的项目 |
| `tools/install-sync-task.ps1` | 注册计划任务，登录时和每 4 小时同步一次 |
| `tools/install-skills.ps1` | 按 `wanted.txt` 安装缺失的 skill |
| `tools/add-skill.ps1` / `remove-skill.ps1` | 添加或删除一个 skill，并更新清单 |
| `tools/doctor.ps1` | 环境体检，只读 |
| `bootstrap.ps1` | 安装全局规则，或接入项目（托管文件、用户文件、守卫钩子） |
| `templates/` | 项目的 `docs/pitfalls.md`、`handoff.md`、`task-log.md` 模板 |

## 守卫是怎么执行的

- 接入项目时，`bootstrap.ps1` 在项目的 `.git/hooks` 安装 pre-commit 和 pre-push 钩子
- pre-commit 运行 `run-guards.cjs --staged`，只检查暂存的文件
- pre-push 拒绝强制推送 main
- 违规时提交失败；不要用 `--no-verify` 绕过
- 每次提交还会自检经验库：经验引用的守卫必须存在

## 每台电脑要做的事

1. 克隆配置包（上面一句）
2. 让 Agent 读 `AGENTS.md`，它会完成体检、全局规则、skill、同步任务
3. 需要接入的项目，告诉 Agent 路径，或手动运行：
   `powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Target <项目路径>`

## 经验同步

- 会话开始时，Agent 运行 `sync-experience.ps1`
- 计划任务每 4 小时运行一次同步
- 同步只提交 `experience/`、`guards/`、`skills/`、`AGENTS.base.md` 的改动。其他文件有未提交改动时，同步会停止，避免误提交
- 拉取冲突时自动中止 rebase，本地内容保留

## 前提

- Windows PowerShell 5.1 或 PowerShell 7
- git（必需）、node（守卫和搜索工具需要）
- GitHub SSH 认证（克隆、同步、安装 skill 需要）。国内网络 https 常超时，所以使用 SSH
