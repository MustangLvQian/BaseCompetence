#!/usr/bin/env node
// 运行守卫（由 git 钩子调用，也可以手动跑）。只检查改动的文件，只输出违规行。
//   --staged      检查暂存区（pre-commit）
//   --pre-push    读取 git 从 stdin 提供的 ref 列表（pre-push）
//   --all         检查所有已跟踪文件（手动体检）
//   --self-check  校验经验文件里的 guard 字段都指向存在的守卫
// 退出码：有违规或自检失败为 1，否则为 0。

const fs = require('fs')
const path = require('path')
const { execFileSync } = require('child_process')

const KIT = path.resolve(__dirname, '..')
const guards = require(path.join(KIT, 'guards', 'guards.cjs'))
const mode = process.argv[2] || '--staged'
const ZERO = /^0+$/

function git(args) {
  return execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
}

function listFiles() {
  if (mode === '--all') return git(['ls-files', '-z']).split('\0').filter(Boolean)
  return git(['diff', '--cached', '--name-only', '--diff-filter=ACM', '-z']).split('\0').filter(Boolean)
}

function selfCheck() {
  const dir = path.join(KIT, 'experience')
  const known = new Set(guards.map((g) => g.id))
  const problems = []
  const entries = fs.readdirSync(dir).filter((n) => /^EXP-.*\.md$/.test(n))
  for (const f of entries) {
    const head = fs.readFileSync(path.join(dir, f), 'utf8').split(/\r?\n/).slice(0, 15)
    const guardLine = head.find((l) => /^guard:/.test(l))
    if (!guardLine) { problems.push(`${f}: 缺少 guard 字段（写 guard: none 也可以）`); continue }
    const id = guardLine.replace(/^guard:\s*/, '').trim()
    if (id !== 'none' && !known.has(id)) problems.push(`${f}: guard "${id}" 在 guards/guards.cjs 里不存在`)
  }
  for (const g of guards) {
    if (!entries.some((n) => n.startsWith(g.exp))) problems.push(`守卫 ${g.id} 指向的经验 ${g.exp} 不存在`)
  }
  return problems
}

const out = []

if (mode === '--self-check') {
  const problems = selfCheck()
  if (problems.length) { console.log(problems.map((p) => `自检: ${p}`).join('\n')); process.exit(1) }
  console.log(`自检通过：${guards.length} 条守卫，经验引用全部有效`)
  process.exit(0)
}

if (mode === '--pre-push') {
  const updates = fs.readFileSync(0, 'utf8').split(/\r?\n/).filter(Boolean).map((l) => {
    const [localRef, localSha, remoteRef, remoteSha] = l.split(/\s+/)
    return { localRef, localSha, remoteRef, remoteSha }
  })
  for (const g of guards.filter((x) => x.prePush)) {
    for (const v of g.prePush(updates)) out.push(`${g.id} [${g.exp}] ${v}`)
  }
} else {
  // 暂存区模式下也顺带自检一次经验引用，避免提交无效的 guard 字段
  if (mode === '--staged') {
    const problems = selfCheck()
    for (const p of problems) out.push(`自检: ${p}`)
  }
  const files = listFiles()
  for (const f of files) {
    const applicable = guards.filter((g) => g.files && g.files(f))
    if (!applicable.length || !fs.existsSync(f)) continue
    const text = fs.readFileSync(f, 'utf8')
    for (const g of applicable) {
      for (const v of g.check(f, text)) out.push(`${g.id} [${g.exp}] ${f}: ${v}`)
    }
  }
}

if (out.length) {
  console.log(out.join('\n'))
  console.log(`\n守卫：${out.length} 项违规。修正后再提交；不要用 --no-verify 绕过。`)
  process.exit(1)
}
process.exit(0)
