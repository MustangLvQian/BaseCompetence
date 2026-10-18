# 经验库

跨项目的踩坑记录与避免规则。**一条经验一个文件**，文件名为 `EXP-<日期>-<编号>-<短名>.md`。

这样做是为了多台电脑同时写入时 Git 不冲突：两台机器各自新增文件，合并时互不干扰。

## 什么该放这里，什么留在项目里

| 放这里（通用） | 留在项目（业务专属） |
|---|---|
| 工具、框架、平台的行为（PWA、Service Worker、小程序、Playwright、Git、PowerShell） | 本项目的题库规则、产品决定、业务数据结构 |
| 换一个项目还会踩的坑 | 只在本项目出现的 bug |
| 通用的工作流教训（如 Agent 输出过大、skill 命名） | 本项目的守卫命令、路径、人员 |

拿不准时，先写到项目的 `docs/pitfalls.md`。第二次在别的项目遇到时，再搬到这里。

## 怎么写一条

1. 复制 `_template.md`，改名为 `EXP-今天日期-四位编号-短名.md`。编号用 4 位十六进制，随机即可，只要不和已有文件撞车
2. 写清楚四段：**症状**（你实际看到的现象）、**根因**、**规则**（以后怎么做）、**守卫**（怎么自动拦住）
3. `tags` 写 2–5 个关键词，便于搜索（如 `pwa`、`miniprogram`、`powershell`）
4. 写完运行同步：`powershell -ExecutionPolicy Bypass -File <KIT>\tools\sync-experience.ps1`

## 怎么找

动手前先搜索，不要整库读：

```powershell
Select-String -Path "<KIT>\experience\*.md" -Pattern "tags:.*pwa" -List | Select-Object -ExpandProperty Path
```

或者直接按症状关键词搜正文。

## 守卫怎么写

守卫是 `guards/guards.cjs` 里的一段真实检查代码，由 git 钩子执行，违规时提交会被拒绝。文字说明不算守卫。

1. 在 `guards/guards.cjs` 里加一项：`id`（G-xxxx）、`exp`（经验编号）、`files`（哪些文件需要检查）、`check`（返回违规描述数组）
2. 经验文件的 `guard:` 字段填这个 id
3. 运行 `node tools/run-guards.cjs --self-check` 确认引用有效

不能写成代码的，写 `guard: none`，并且正文里不要写「已强制执行」。`none` 的条目只是知识。

## 状态

`status` 字段：`active`（有效）、`superseded`（已被新经验取代，写明是哪一条）、`not-applicable`（不适用于某类项目）。不要删除文件，删除会让别人的引用失效。
