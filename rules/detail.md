# 细节规则

只在需要时读取。<KIT> 即全局规则里写出的配置包路径。

## Token 节省

- 先 `grep` 定位，再用 `read` 带 `offset` / `limit` 读需要的段落，不整文件读
- 目录扫描排除 `node_modules`、`dist`、`.git`、音频、`package-lock.json`、大型 manifest
- 命令输出过长时只取需要的列或计数
- 不重复粘贴已经在文件里的内容，引用路径和行号
- 能用脚本验证的，先跑脚本，不要反复问模型
- 同一问题先搜经验库，再动手
- 一个任务一个会话：任务结束立即关闭，下一任务新开会话，靠 `docs/handoff.md` 接续。缓存读取是 token 的主要成本，会话越长每轮越贵（实测一个跨两件事的会话缓存读取 13.7M，输入仅 4.1k）
- `docs/handoff.md` 只写当前状态、下一步、待确认；超过约 5 KB 时把历史段落移到 `docs/archive/`
- `docs/task-log.md` 只按任务 ID 或关键词 grep，不整文件读；新任务行只写一行结果，细节放 commit 或产物文件
- token 用量：开工运行 `node <KIT>\tools\record-usage.cjs --start <任务ID>` 记下会话 ID；任务结束后新开会话，运行 `node <KIT>\tools\record-usage.cjs <任务ID>` 写入用量。新增任务行的 token 列由守卫 G-0020 检查，不能留空
- 项目 `AGENTS.md` 只放硬约束与路由，超过约 10 KB 时把细节移到 `docs/` 或 `rules/` 按需读取

## 验证

- 改了前端：用真实浏览器验证。Playwright 动画页面要设 `reduced_motion="reduce"`；本机没有 Chromium 时用系统 Edge（`channel="msedge"`）
- 改了界面：先看截图，不要只看单元测试
- 结论要标明验证方式：「已在浏览器看到」和「只跑了单元测试」是两件事

## 经验同步

经验库在 GitHub 上，多台电脑共享。同步由**计划任务每 4 小时自动完成**，不需要每次会话手动运行。

需要立刻同步时（例如刚新增了通用经验）：

```powershell
powershell -ExecutionPolicy Bypass -File "<KIT>\tools\sync-experience.ps1"
```

- 同步失败不阻塞工作，在结束时简短说明
- 推送只在配置包所有者开启后才会发生（`git config basecompetence.push true`），否则只保留在本地

## 守卫

- 守卫定义在 `<KIT>\guards\guards.cjs`，由 git 的 pre-commit 和 pre-push 钩子运行
- pre-commit 只检查暂存的文件，只输出违规行
- pre-push 拒绝强制推送 main
- 违规时修正代码，不要用 `--no-verify`
- 新增通用经验时，能写成检查的，同时在 `guards/guards.cjs` 加一项守卫

## 通用经验怎么写

- 只写通用做法，不写个人路径、邮箱、凭据（守卫 G-0019 会拦截）
- 写之前先搜，已有相近条目就更新它，不要新建重复项
