# 给 Agent 的安装任务清单

> 用户说「读 AGENTS.md 并完成」时，读完本文件，按顺序执行，**只在标明「需要用户」的地方停下来**。
> 本文件所在目录就是配置包目录，下文记作 `<KIT>`。使用绝对路径，不要假设当前工作目录。

## 任务目标

在这台电脑上完成以下四件事，完成后给出一份结果报告：

1. 环境齐全（git、node、GitHub SSH，可选 python / Playwright）
2. 全局规则生效：`~/.config/opencode/AGENTS.md` 与 `<KIT>\AGENTS.base.md` 一致
3. 依赖的 skill 全部安装到 `~\.agents\skills`
4. 用户指定的项目（如有）已接入通用配置

## 不要做的事

- 不要扫描整个磁盘寻找项目。只接入用户明确给出的路径
- 不要修改 `<KIT>` 里的文件，除非用户要求改配置包本身
- 不要覆盖用户已有的文件。脚本会自己备份，你也不要手动删除
- 不要 `git push --force`，不要改写 git 历史
- 不要把规则写进 `<KIT>` 自己（`bootstrap.ps1` 已经会拒绝这种操作）

## 第 0 步：确认配置包是最新的

```powershell
git -C "<KIT>" pull --rebase
```

- 成功：继续
- 失败（网络或本地冲突）：记下原因，继续使用本地版本，并在报告里说明

## 第 1 步：环境体检

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\doctor.ps1"
```

它只读，输出 `[PASS]` / `[WARN]` / `[FAIL]`。根据结果处理：

| 结果 | 怎么办 |
|---|---|
| git 缺失（FAIL） | 执行 `winget install --id Git.Git -e --silent`，装完重新打开终端再检查 |
| node 缺失（WARN） | 执行 `winget install --id OpenJS.NodeJS.LTS -e --silent` |
| python 缺失（WARN） | 执行 `winget install --id Python.Python.3.12 -e --silent`。这一项是可选的，失败不影响其他步骤 |
| GitHub SSH 未认证（FAIL） | 见第 2 步 |
| skill 缺失（FAIL） | 在第 3 步处理，然后重跑 doctor |
| 全局规则缺失或不一致（FAIL / WARN） | 在第 4 步处理 |
| Playwright 未装（WARN） | 执行 `python -m pip install playwright`。**不要**执行 `playwright install chromium`，本机用系统 Edge |

winget 报错需要管理员权限或 UAC 时，把具体的命令告诉用户，请用户手动执行后回复你。

## 第 2 步：GitHub SSH（需要用户）

只有 doctor 报告 SSH 未认证时才做这一步。

1. 如果 `~\.ssh\id_ed25519.pub` 不存在，生成一个。邮箱用 `git config --global user.email` 的值，没有就用 `mustanglvqian@hotmail.com`。**已存在就不要覆盖。**
   Windows PowerShell 5.1 会吞掉 `-N ""` 里的空参数，所以用下面这种方式（直接传命令行字符串）：
   ```powershell
   $f = "$HOME\.ssh\id_ed25519"
   if (-not (Test-Path "$f.pub")) {
     New-Item -ItemType Directory -Force -Path "$HOME\.ssh" | Out-Null
     $psi = New-Object System.Diagnostics.ProcessStartInfo 'ssh-keygen'
     $psi.Arguments = "-t ed25519 -C <邮箱> -f `"$f`" -N `"`""
     $psi.UseShellExecute = $false
     $p = [System.Diagnostics.Process]::Start($psi); $p.WaitForExit()
   }
   ```
   把 `<邮箱>` 换成实际值。生成后应有 `$f` 和 `$f.pub` 两个文件。
2. 读取公钥：`Get-Content "$HOME\.ssh\id_ed25519.pub"`
3. **停下来**，请用户把这行公钥添加到 <https://github.com/settings/keys>（如果这台机器打不开该网页，请用户在别的设备上添加）。
4. 用户回复「已添加」后，执行 `ssh -T git@github.com`。输出含 `successfully authenticated` 即通过。
5. 如果仍然失败，最多再重试两次，然后报告失败原因，不要无限重试。

## 第 3 步：安装 skill

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\install-skills.ps1"
```

- 脚本只补装缺的 skill，已存在的保留，可以重复运行
- 依赖 SSH 能访问 github.com，如果第 2 步没通过，这里也会失败
- skill 清单在 `tools\install-skills.ps1` 的 `$Wanted` 里，不要自行增删

## 第 4 步：安装全局规则

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\bootstrap.ps1" -Global -NoUpdate
```

- 写入 `~\.config\opencode\AGENTS.md`，所有项目都会加载它
- 如果该文件已存在且内容不同，脚本会先备份为 `AGENTS.md.bak-<时间戳>`，并在输出里报告备份路径
- 本步骤不会修改任何项目，只有加 `-Target` 才会写项目

## 第 4b 步：经验同步

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\install-sync-task.ps1"
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\sync-experience.ps1"
```

- 第一条注册 Windows 计划任务 `BaseCompetence-Sync`：登录时同步，之后每 4 小时同步
- 第二条立即同步一次：提交本机经验、拉取别人的经验、推送、刷新全局规则和已登记的项目
- 同步输出里如果有「拉取冲突」，说明 rebase 已中止、本地内容保留，把原文告诉用户，不要自行强制覆盖
- 同步日志在 `%LOCALAPPDATA%\BaseCompetence\sync.log`

## 第 5 步：项目接入（需要用户给路径）

先问用户一次：「要接入哪些项目？请给出路径。没有的话我就跳过。」

- 用户给了路径：对每个路径执行
  ```powershell
  powershell -ExecutionPolicy Bypass -File "<KIT>\bootstrap.ps1" -Target "<项目路径>" -NoUpdate
  ```
  然后在项目目录里执行 `node tools/check-skills.cjs --file AGENTS.md`，把结果告诉用户
- 用户说跳过：直接进入第 6 步
- 项目路径不存在：报告给用户，不要创建目录

接入后，项目里的 `AGENTS.md` 只会被补一行引用（如果原来没有 `AGENTS.md`，会创建一个）。已有的 `AGENTS.md` 不会被修改，你只需要提醒用户：**项目专属规则（技术栈、硬约束、路由表）需要用户自己补充**。

## 第 6 步：最终验证

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\doctor.ps1"
```

- 0 项 FAIL 才算完成
- 剩下的 WARN 逐条说明原因，并告诉用户影响（例如 Playwright 未装，浏览器测试不可用）

## 第 7 步：告诉用户

最后一段对话只需要包括：

1. **需要用户重启 opencode**，否则新装的 skill 和全局规则不会生效
2. 结果报告（见下）
3. 用户还需要自己做的事（例如补充项目专属规则、填写 `docs/pitfalls.md` 的守卫命令）

### 报告格式

```
安装结果：通过 / 有 N 项需要处理

环境        git <版本> / node <版本> / python <版本或未装> / GitHub SSH <通过|未通过>
全局规则    ~\.config\opencode\AGENTS.md <已安装 | 已更新（备份：<路径>）>
skill       <N> 个已就位，本次新装 <列表或无>
项目        <路径：已接入 | 跳过 | 失败原因>
需要用户    <重启 opencode / 添加 SSH 公钥 / 补充项目规则 / 无>
```

## 以后再次使用

用户再次说「读 AGENTS.md」时，同样从第 0 步开始。所有脚本都是幂等的，重复运行只会补齐缺的东西。

**已接入的项目**（`%LOCALAPPDATA%\BaseCompetence\projects.txt` 里登记的路径）会由同步任务自动更新托管文件。新增项目时，只有通过 `bootstrap.ps1 -Target` 接入才会被登记，直接复制文件不会。
