# BaseCompetence：Agent 通用配置包

把跨项目的经验打包成一套配置：会话连续性、任务去重、踩坑守卫、skill 路由检查、token 节省与 git 安全规则。

## 第一次使用：只要一句话

1. 克隆配置包（SSH 推荐，国内网络 https 常超时）：

   ```powershell
   git clone git@github.com:MustangLvQian/BaseCompetence.git D:\BaseCompetence
   ```

2. 打开你的 Agent（opencode），对它说：

   > 读 `D:\BaseCompetence\AGENTS.md`，并完成里面的所有任务。

Agent 会自己检查环境、补装依赖、安装全局规则和 skill、验证结果，最后给你一份报告。它只会在以下情况停下来问你：

- 需要把 SSH 公钥添加到 GitHub
- 要不要接入某个项目（需要你给路径）
- 结束时提醒你重启 opencode

## 目录结构

| 路径 | 作用 |
|---|---|
| `AGENTS.md` | **Agent 的安装任务清单**，第一次使用从这里开始 |
| `AGENTS.base.md` | 通用规则。安装后作为全局规则，也会复制进各项目 |
| `bootstrap.ps1` | 安装全局规则，或把通用文件接入某个项目 |
| `tools/doctor.ps1` | 环境体检，只读，不修改任何东西 |
| `tools/install-skills.ps1` | 安装依赖的 skill 到 `~\.agents\skills`，已存在的保留 |
| `tools/check-skills.cjs` | 检查项目 AGENTS.md 里的 skill 路由表是否都存在 |
| `templates/pitfalls.md` | 踩坑登记表模板 → 项目 `docs/pitfalls.md` |
| `templates/handoff.md` | 交接手册模板 → 项目 `docs/handoff.md` |
| `templates/task-log.md` | 任务日志模板 → 项目 `docs/task-log.md` |

## 手动使用（不经过 Agent）

全部命令都可以手动执行，`<KIT>` 代表 `D:\BaseCompetence`：

```powershell
# 环境体检
powershell -ExecutionPolicy Bypass -File <KIT>\tools\doctor.ps1

# 安装 skill
powershell -ExecutionPolicy Bypass -File <KIT>\tools\install-skills.ps1

# 安装全局规则（所有项目生效，已有文件会备份）
powershell -ExecutionPolicy Bypass -File <KIT>\bootstrap.ps1 -Global

# 接入某个项目（已有的文件不覆盖）
powershell -ExecutionPolicy Bypass -File <KIT>\bootstrap.ps1 -Target D:\某个项目

# 在项目目录里直接运行，等同于 -Target 当前目录
cd D:\某个项目
powershell -ExecutionPolicy Bypass -File <KIT>\bootstrap.ps1
```

`bootstrap.ps1` 的参数：

| 参数 | 说明 |
|---|---|
| `-Target <路径>` | 要接入的项目目录；不给时，若没有 `-Global` 则用当前目录 |
| `-Global` | 安装全局规则到 `~\.config\opencode\AGENTS.md` |
| `-NoUpdate` | 不尝试更新配置包 |

## 更新

配置包有改动时，在 `D:\BaseCompetence` 里提交并推送。这台电脑下次运行 `bootstrap.ps1` 或让 Agent 读 `AGENTS.md` 时会自动拉取。**已经接入的项目文件不会被覆盖**，需要手动对比合并。

## 前提

- Windows PowerShell 5.1 或 PowerShell 7
- git（必需）、node（推荐）、python（可选，用于 Playwright）
- GitHub SSH 认证（用于克隆和安装 skill）。国内网络 https 常超时，所以使用 SSH

## 来源

规则提炼自英创星球项目（`D:\LvQian\YingChuangXingQiu`）的 `AGENTS.md`、`docs/pitfalls.md`、`docs/handoff.md`、`docs/git-workflow.md`、`tools/skills/install.ps1` 以及 `ycx-verify` skill。业务细节（题库、音频、小程序）没有放进来。
