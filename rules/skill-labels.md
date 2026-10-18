# 给项目专用 skill 打标签

适用于：项目自己的 `.agents/skills/`（或 `.opencode/skills/`）下的 skill。全局 skill 由配置包统一处理，不在这里。

## 为什么要打标签

每次会话，opencode 都会把每个可自动调用的 skill 的 `description` 放进上下文。原文通常很长（几百字），每次都付费。标签把它压缩成一句话，既能让 Agent 判断何时使用，又只占很少的 token。

## 标签格式

`description` 写成一行，用双引号包住，长度 **40–80 个字符**，结构固定：

```
<功能一句话>。触发词：<3–5 个关键词>
```

好的例子：

- `动画效果：从零设计动效，决定该不该动、用什么属性、曲线和时长。触发词：加动画、按钮回弹、过渡`
- `网页测试：用 Playwright 打开页面、点击、截图、看控制台。触发词：页面测试、截图、E2E`

不好的例子（太长，或没有触发词）：

- `This skill encodes Emil Kowalski's philosophy...`（英文长段，抄原文）
- `动画`（没有说明做什么，也没有触发词）

## 操作步骤

对每个项目专用 skill，依次做：

1. **读取原文**：只读 frontmatter（文件开头 `---` 之间的部分），不要通读全文。
2. **备份**：如果同目录下还没有 `SKILL.md.orig`，把原 `SKILL.md` 复制为 `SKILL.md.orig`。已经有的不要覆盖。
3. **只改 `description` 这一行**：保留 `name`、`license`、`metadata` 等其他字段，正文一个字都不动。
4. **验证**：确认 frontmatter 仍然合法（`name` 与目录名一致，`description` 非空），并且文件里只有一个 `description`。
5. **记录**：在 `docs/task-log.md` 写一条：打标签的 skill 名单、标签数量、备份位置。

## 不要做的事

- 不要改 skill 的正文或目录结构
- 不要删除 `SKILL.md.orig`
- 不要给别的项目的 skill 打标签
- 不要为了让标签更短而删掉触发词，触发词决定 Agent 能不能选中它

## 恢复

如果发现标签不够准，用 `SKILL.md.orig` 覆盖回 `SKILL.md`，改好标签再重做。
