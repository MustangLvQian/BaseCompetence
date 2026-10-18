# Agent 基础规则（所有项目通用）

> 托管文件：由配置包 `{{KIT_PATH}}` 维护，每次同步会覆盖。不要在这里写项目专属内容，
> 项目专属规则写在项目自己的 `AGENTS.md` 里。项目规则与本文件冲突时，以项目规则为准。
> 经验库位置：`{{KIT_PATH}}\experience\`

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

## 3. 踩坑：先查经验库，第二次出现必须留守卫

**动手前**，按技术栈和症状搜索经验库，不要整库读：

```powershell
Select-String -Path "{{KIT_PATH}}\experience\*.md" -Pattern "tags:.*<关键词>" -List
```

**遇到坑时**：
- 只属于本项目的：写进项目的 `docs/pitfalls.md`
- 通用的（工具、框架、平台、Git、PowerShell 等）：在 `{{KIT_PATH}}\experience\` 新建一条，格式见该目录的 `_template.md`，然后运行第 8 节的同步
- 第一次出现：修掉并登记
- 第二次出现：必须同时补一条**自动检查**，接进项目的 check 命令；做不到自动化的，守卫写 `manual` 并写清人工步骤
- 没有守卫的条目不算登记

## 4. Skill 路由

- 路由表只写**本机真实存在的 skill 名**（frontmatter 的 `name`）。新增、改名 skill 后，运行：
  ```bash
  node tools/check-skills.cjs --file AGENTS.md
  ```
- 同一功能只保留一个 skill，避免自动选择时互相竞争
- 不确定用哪个时，选路由表里的那一个，不要自行挑功能相近的
- 路由表要放在标题里含 "Skill" 的章节下（如 `## Skills`），检查工具只读这些章节

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

**会话结束前**，如果本次新增了通用经验，或修改了全局规则，运行同一条命令，把它推送出去。

- 同步失败（网络、冲突）时，不要阻塞工作，在最后的报告里说明即可
- 同步会同时刷新全局规则和已登记的项目，所以不需要手动更新各项目的 `AGENTS.base.md`
- 每台电脑还有一个计划任务每 4 小时自动同步，但不能替代会话开始时的同步

同步输出里列出的新经验，如果和当前任务相关，要读一下再动手。
