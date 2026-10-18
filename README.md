# BaseCompetence：Agent 通用配置包

跨项目的经验、守卫和 skill 清单，托管在 GitHub。

## 第一次使用：只要一句话

1. 选一个你有权限的文件夹（例如 `%USERPROFILE%\Documents`），克隆配置包：

   ```powershell
   git clone git@github.com:MustangLvQian/BaseCompetence.git "<你选的文件夹>\BaseCompetence"
   ```

2. 对 Agent 说：「读 `<你选的文件夹>\BaseCompetence\AGENTS.md`，并完成里面的所有任务。」

路径由你决定，配置包里不写死任何盘符。Agent 会问你路径，不会自己假设。

## 它包含什么

| 路径 | 作用 |
|---|---|
| `AGENTS.md` | Agent 的安装任务清单（第一次用这个） |
| `AGENTS.base.md` | 通用规则：遇到问题先搜经验库、需求不清先问、守卫、skill、token 节省。作为全局规则安装，也托管到各项目 |
| `experience/` | 经验库，一条经验一个文件（`EXP-*.md`） |
| `guards/guards.cjs` | 守卫：真正会执行的检查代码，编号与经验的 `guard:` 字段一一对应 |
| `skills/wanted.txt` | skill 清单（仓库 + 目录） |
| `tools/run-guards.cjs` | 运行守卫，由 git 钩子调用；`--self-check` 检查守卫和经验的引用、编号、标题是否重复 |
| `tools/find-experience.cjs` | 搜索经验库，只输出摘要 |
| `tools/review-experience.cjs` | 列出可能重复的经验，供人决定合并（只读） |
| `tools/sync-experience.ps1` | 同步：提交本机改动 → 拉取 → 推送（需开启）→ 刷新全局规则和已登记的项目 |
| `tools/install-sync-task.ps1` | 注册计划任务，每 4 小时同步一次 |
| `tools/install-skills.ps1` | 按 `wanted.txt` 安装缺失的 skill |
| `tools/add-skill.ps1` / `remove-skill.ps1` | 添加或删除一个 skill，并更新清单 |
| `tools/doctor.ps1` | 环境体检，只读 |
| `bootstrap.ps1` | 安装全局规则，或接入项目（托管文件、用户文件、守卫钩子） |
| `templates/` | 项目的 `docs/pitfalls.md`、`handoff.md`、`task-log.md` 模板 |

## 守卫是怎么执行的

- 接入项目时，`bootstrap.ps1` 在项目的 `.git/hooks` 安装 pre-commit 和 pre-push 钩子
- pre-commit 运行 `run-guards.cjs --staged`，只检查暂存的文件，只输出违规行
- pre-push 拒绝强制推送 main
- 违规时提交失败；不要用 `--no-verify` 绕过

## 防止经验和守卫重复

- 写新经验前先 `find-experience.cjs` 搜索；已有相近条目就更新它（把 `seen` 加一），不要新建
- `run-guards.cjs --self-check` 会拒绝重复的守卫编号、重复的经验标题，以及两个守卫指向同一条经验
- 定期运行 `review-experience.cjs`，人工决定合并。**不做自动合并或自动学习入库**：未经审核的规则直接进入守卫，风险比重复更大

## 每台电脑要做的事

1. 克隆配置包（上面一句）
2. 让 Agent 读 `AGENTS.md`，它会完成体检、全局规则、skill、同步任务
3. 需要接入的项目，告诉 Agent 路径，或手动运行：
   `powershell -ExecutionPolicy Bypass -File "<配置包路径>\bootstrap.ps1" -Target "<项目路径>"`

## GitHub 访问方式

国内网络常常无法直接访问 `https://github.com`，但 443 端口的 SSH 可用。配置包使用的方式是：

- **SSH 端口路由**：在 `~/.ssh/config` 里把 `github.com` 指向 `ssh.github.com:443`。这不是代理，只是换了一个能通的端口
- `doctor.ps1` 会检查这一项，未配置时给出警告
- 如果你的网络有 HTTP/SOCKS 代理，也可以在 `~/.ssh/config` 里用 `ProxyCommand` 指向代理。这需要你自己的代理工具支持，配置包不内置

## 同步与推送

- 会话开始时，Agent 运行 `sync-experience.ps1`；计划任务每 4 小时运行一次
- 同步只提交 `experience/`、`guards/`、`skills/`、`AGENTS.base.md` 的改动。其他文件有未提交改动时，同步会停止
- **推送默认关闭**。只有配置包所有者在自己的仓库里执行 `git config basecompetence.push true` 才会推送。别人 fork 后，把 `origin` 改成自己的仓库再开启
- 拉取冲突时自动中止 rebase，本地内容保留

## 开源与隐私说明

- **经验库可能公开。** 守卫 G-0019 会拦截经验里的个人路径、邮箱和疑似凭据。写经验时请使用占位符
- **别人使用这个配置，不会把经验提交到作者的仓库。** 他们在本机产生的改动只留在本地，除非他们 fork 仓库并把推送指向自己的仓库。他们对作者仓库没有写入权限，除非作者明确授予
- **许可证：尚未声明。** 在没有许可证的情况下，默认的版权保护适用，别人不能随意复制、修改或再分发。如果希望开放使用，需要作者在仓库根目录添加 `LICENSE` 文件（常见选择：MIT、Apache-2.0、CC BY 4.0）
- 经验条目的 `source` 字段记录来源，贡献者的名字可以写进去，保持署名

## 前提

- Windows PowerShell 5.1 或 PowerShell 7
- git（必需）、node（守卫和搜索工具需要）
- GitHub SSH 认证（克隆、同步、安装 skill 需要）
