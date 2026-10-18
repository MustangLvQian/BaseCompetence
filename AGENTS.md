# 给 Agent 的安装任务清单

> 用户说「读 AGENTS.md 并完成」时，读完本文件，按顺序执行。
> **只在标明「需要用户」的地方停下来**。其他情况自己处理，不要反复询问。
> 本文件所在目录就是配置包目录，下文记作 `<KIT>`。使用绝对路径，不要假设当前工作目录。

## 目标

完成后给出一份报告：

1. 环境体检通过（git、node、GitHub SSH；python / Playwright 可选）
2. 全局规则生效：`~\.config\opencode\AGENTS.md` 与 `<KIT>\AGENTS.base.md` 渲染结果一致
3. `<KIT>\skills\wanted.txt` 列出的 skill 全部在 `~\.agents\skills`
4. 经验同步计划任务已注册，并完成一次同步
5. 用户指定的项目（如有）已接入

## 不要做的事

- 不要扫描磁盘找项目，只接入用户给出的路径
- 不要修改 `<KIT>` 里的文件，除非用户要求改配置包本身
- 不要覆盖或删除用户已有的文件，脚本会自己备份
- 不要 `git push --force`，不要改写历史，不要用 `--no-verify`
- 不要生成 SSH 密钥、不要替用户执行需要管理员权限的命令

## 第 0 步：更新配置包

```powershell
git -C "<KIT>" pull --rebase
```

失败（网络或本地冲突）时记下原因，继续用本地版本，并写进报告。

## 第 1 步：环境体检

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\doctor.ps1"
```

输出 `[PASS]` / `[WARN]` / `[FAIL]`，只读。处理方式：

| 结果 | 怎么办 |
|---|---|
| git 缺失（FAIL） | 执行 `winget install --id Git.Git -e --silent`。若需要管理员权限，**需要用户**：把命令告诉用户，请其手动执行 |
| node 缺失（WARN） | 执行 `winget install --id OpenJS.NodeJS.LTS -e --silent`，同上 |
| python 缺失（WARN） | 可选。执行 `winget install --id Python.Python.3.12 -e --silent`，失败就跳过 |
| Playwright 未装（WARN） | 执行 `python -m pip install playwright`。**不要**执行 `playwright install chromium`，本机用系统 Edge |
| GitHub SSH 未认证（FAIL） | 见第 2 步 |
| skill 缺失（FAIL） | 见第 3 步 |
| 全局规则不一致（WARN / FAIL） | 见第 4 步 |
| 经验同步任务未注册（WARN） | 见第 4b 步 |

## 第 2 步：GitHub SSH（需要用户）

只有 doctor 报告 SSH 未认证时才做。**不要替用户生成密钥。** 告诉用户以下步骤，然后停下来：

1. 如果本机没有 SSH 密钥，请用户在 PowerShell 里运行：
   `ssh-keygen -t ed25519 -C "你的邮箱"`（一路回车，口令可留空）
2. 请用户打开 `%USERPROFILE%\.ssh\id_ed25519.pub`，把整行内容添加到 <https://github.com/settings/keys>。如果这台电脑打不开该网页，请用户在其他设备上添加
3. 用户回复「已添加」后，执行 `ssh -T git@github.com`。输出含 `successfully authenticated` 即通过。未通过就告诉用户原文，最多再试两次

## 第 3 步：安装 skill

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\install-skills.ps1"
```

- 按 `<KIT>\skills\wanted.txt` 补装缺失的 skill，已存在的保留，可以重复运行
- 依赖 SSH 能访问 github.com，第 2 步没通过的话这里也会失败

### 按需添加和删除 skill

- 任务需要某种能力、而本机没有对应 skill 时，在 GitHub 搜索（`gh search repos "skill <主题>"`）。读一遍候选的 SKILL.md，确认来源可信、内容清楚，再安装：
  `powershell -ExecutionPolicy Bypass -File "<KIT>\tools\add-skill.ps1" -Repo <owner/repo> -Path <skill 目录>`
- **用完即删**：任务结束时，为它装的 skill 没有用上，就执行
  `powershell -ExecutionPolicy Bypass -File "<KIT>\tools\remove-skill.ps1" -Name <名字>`
- 添加或删除后都要同步（第 4b 步），让其他电脑也一致；并告诉用户需要重启 opencode

## 第 4 步：安装全局规则

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\bootstrap.ps1" -Global -NoUpdate
```

- 写入 `~\.config\opencode\AGENTS.md`，所有项目都会加载它
- 原文件内容不同时，脚本先备份为 `AGENTS.md.bak-<时间戳>`，把备份路径写进报告
- 只有加 `-Target` 才会改项目，本步骤不改项目

## 第 4b 步：经验同步

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\install-sync-task.ps1"
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\sync-experience.ps1"
```

- 第一条注册计划任务 `BaseCompetence-Sync`：登录时同步，之后每 4 小时同步一次
- 第二条立即同步：提交本机的经验、守卫、skill 清单改动，拉取其他电脑的改动，推送，刷新全局规则和已登记的项目
- 输出里出现「拉取冲突」时，rebase 已中止、本地内容保留。把原文告诉用户，不要强制覆盖
- 日志：`%LOCALAPPDATA%\BaseCompetence\sync.log`

## 第 5 步：项目接入（需要用户给路径）

问用户一次：「要接入哪些项目？请给出路径。没有的话我就跳过。」

- 给了路径：对每个路径执行
  `powershell -ExecutionPolicy Bypass -File "<KIT>\bootstrap.ps1" -Target "<项目路径>" -NoUpdate`
  它会更新托管文件，补齐缺失的用户文件，登记到同步列表，并在 `.git/hooks` 安装守卫钩子（已有的其他钩子不会被覆盖，会给出警告，原文告诉用户）
- 之后在项目里执行 `node tools/check-skills.cjs --file AGENTS.md`，把结果告诉用户
- 项目路径不存在就报告，不要创建目录
- 已有的项目 `AGENTS.md` 不会被改动。提醒用户：**项目专属规则（技术栈、硬约束、路由表）需要用户自己补充**

## 第 6 步：最终验证

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\doctor.ps1"
node "<KIT>\tools\run-guards.cjs" --self-check
```

- doctor 0 项 FAIL 才算完成。WARN 逐条说明原因和影响
- 自检必须通过：它确认每条经验引用的守卫都存在

## 第 7 步：报告

最后的对话包括：

1. 需要用户重启 opencode（新 skill 和全局规则要重启才生效）
2. 需要用户做的事：添加 SSH 公钥、补充项目专属规则、必要时手动执行管理员命令
3. 结果报告：

```
安装结果：通过 / 有 N 项需要处理

环境        git <版本> / node <版本> / python <版本或未装> / GitHub SSH <通过|未通过>
全局规则    ~\.config\opencode\AGENTS.md <已安装 | 已更新（备份：<路径>）>
skill       <N> 个已就位；本次新装 <列表或无>；本次删除 <列表或无>
同步        计划任务 <已注册>；本次拉取 <N> 条经验，推送 <完成 | 失败原因>
项目        <路径：已接入 | 跳过 | 失败原因>
需要用户    <重启 opencode / 添加 SSH 公钥 / 补充项目规则 / 无>
```

## 以后再次使用

用户再次说「读 AGENTS.md」时，从第 0 步开始。所有脚本都是幂等的，重复运行只补齐缺的部分。已接入的项目由同步任务自动更新托管文件；新项目只有通过 `bootstrap.ps1 -Target` 接入才会被登记。
