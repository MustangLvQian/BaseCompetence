# BaseCompetence：Agent 通用配置包

把跨项目的经验打包成一套配置，新项目一条命令拉取。包含：

- 会话连续性：交接手册、任务日志，防止对话丢失后重复劳动
- 任务去重：开工前查日志，批处理脚本要求幂等
- 踩坑守卫：踩坑登记表，第二次出现必须补自动检查
- skill 路由检查：确认 AGENTS.md 里引用的 skill 在本机真实存在
- token 节省与 git 安全规则

## 目录结构

| 路径 | 作用 |
|---|---|
| `bootstrap.ps1` | 一键脚本：拉取配置到项目；可选安装到全局 |
| `AGENTS.base.md` | 通用规则，项目的 `AGENTS.md` 引用它 |
| `templates/pitfalls.md` | 踩坑登记表模板 → 项目 `docs/pitfalls.md` |
| `templates/handoff.md` | 交接手册模板 → 项目 `docs/handoff.md` |
| `templates/task-log.md` | 任务日志模板 → 项目 `docs/task-log.md` |
| `tools/check-skills.cjs` | skill 路由检查 → 项目 `tools/check-skills.cjs` |

## 前提

- **git**（必需）
- **node**（推荐，用于 skill 路由检查；没有也能用，脚本会跳过检查）
- 访问 GitHub 的方式二选一：
  - SSH：`git@github.com:...`，需要本机已配置 SSH 公钥。国内网络常用这个
  - HTTPS：`https://github.com/...`，网络不稳定时可能超时

## 一键使用（任何一台电脑）

### 第一次：克隆配置包

SSH（推荐）：

```powershell
git clone git@github.com:MustangLvQian/BaseCompetence.git D:\BaseCompetence
```

HTTPS：

```powershell
git clone https://github.com/MustangLvQian/BaseCompetence.git D:\BaseCompetence
```

### 每个新项目：一条命令

在项目目录里直接运行（`-Target` 默认为当前目录）：

```powershell
cd D:\某个新项目
powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1
```

指定项目路径：

```powershell
powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Target D:\某个新项目
```

脚本会做：

1. 如果配置包是 git 仓库，先 `git pull --rebase` 更新自己（离线时跳过，继续用本地版本）
2. 把通用文件复制到项目（已存在的不覆盖）
3. 项目没有 `AGENTS.md` 时创建一个，并引用通用规则；已有的只提示，不擅自修改
4. 如果装了 node，运行 skill 路由检查并输出结果

### 可选：安装到全局（所有项目生效）

```powershell
powershell -ExecutionPolicy Bypass -File D:\BaseCompetence\bootstrap.ps1 -Target D:\某个新项目 -Global
```

这会把 `AGENTS.base.md` 写到 `~\.config\opencode\AGENTS.md`，所有项目都会加载它。
如果该文件已存在且内容不同，会先备份为 `AGENTS.md.bak-时间戳`。
**全局规则会影响每个项目**，只在确定要这样做时加 `-Global`。

### 参数

| 参数 | 说明 |
|---|---|
| `-Target <路径>` | 目标项目目录，默认当前目录 |
| `-Global` | 同时安装全局规则 |
| `-NoUpdate` | 不尝试更新配置包（离线或想固定版本时用） |

## 换一台电脑

1. 装好 git 和 node
2. 按上面「第一次：克隆配置包」克隆到任意目录
3. 对项目运行 `bootstrap.ps1`

之后每台电脑都从同一个 GitHub 仓库拉取，内容保持一致。

## 项目接入后要做的事

1. 在项目的 `docs/pitfalls.md` 里填写守卫命令表
2. 在项目的 `AGENTS.md` 里补充技术栈、硬约束和 skill 路由表
3. 运行 `node tools/check-skills.cjs --file AGENTS.md`，确认路由表里的名字都存在
4. 第一个任务开始时，在 `docs/task-log.md` 建第一条记录

## 更新规则

配置包有改动时，在 `D:\BaseCompetence` 里提交并推送即可。各项目下次运行 `bootstrap.ps1` 时会拿到新版本，但**已存在的项目文件不会被覆盖**。如果想让某个项目同步新规则，需要手动对比后合并。

## 来源

规则提炼自英创星球项目（`D:\LvQian\YingChuangXingQiu`）的 `AGENTS.md`、`docs/pitfalls.md`、`docs/handoff.md`、`docs/git-workflow.md` 以及 `ycx-verify` skill。业务细节（题库、音频、小程序）没有放进来。
