#!/usr/bin/env node
'use strict'

// 把会话的 token 用量写进任务日志对应行的「token 消耗」列（最后一列）。
//
// 用法：
//   node tools\record-usage.cjs --start <任务ID>      开工时运行：把当前会话 ID 写进任务行
//   node tools\record-usage.cjs <任务ID> [会话ID]     任务结束后新开会话运行：写入用量
//
// 结束时不给会话 ID，就用开工时记下的 ID；没有记录才取当前目录最近一个有用量的会话。
// 守卫 G-0020 会在提交时检查：新增的任务行，token 列必须是用量数字，或写明「未知（原因）」。

const fs = require('node:fs')
const path = require('node:path')
const { spawnSync } = require('node:child_process')

const args = process.argv.slice(2)
const flagIdx = args.indexOf('--file')
const file = flagIdx >= 0 ? args[flagIdx + 1] : path.join('docs', 'task-log.md')
const startMode = args[0] === '--start'
const positional = args.filter((a, i) => !a.startsWith('--') && (flagIdx < 0 || (i !== flagIdx && i !== flagIdx + 1)))
const taskId = positional[0]
const sessionArg = positional[1]

if (!taskId || !/^T-\d{8}/.test(taskId)) {
  console.error('用法：node tools/record-usage.cjs [--start] <任务ID，如 T-20261022-XX> [会话ID] [--file docs/task-log.md]')
  process.exit(1)
}
if (!fs.existsSync(file)) {
  console.error(`找不到任务日志：${file}`)
  process.exit(1)
}

const readLines = () => {
  const raw = fs.readFileSync(file, 'utf8')
  return { eol: raw.includes('\r\n') ? '\r\n' : '\n', lines: raw.split(/\r?\n/) }
}

if (startMode) {
  const list = spawnSync('opencode', ['session', 'list', '--format', 'json', '-n', '1'], { encoding: 'utf8', shell: true })
  let current = ''
  try { current = JSON.parse(list.stdout)[0].id } catch { /* 下面统一报错 */ }
  if (!/^ses/.test(current)) {
    console.error('取不到当前会话 ID（需要 opencode 后台服务在运行）。请先开一次 opencode 再试')
    process.exit(1)
  }
  const { eol, lines } = readLines()
  const idx = lines.findIndex((l) => l.startsWith(`| ${taskId} |`))
  if (idx < 0) {
    console.error(`${file} 里没有 ${taskId} 的行。请先新增一行（7 列）`)
    process.exit(1)
  }
  const cells = lines[idx].split('|').slice(1, -1).map((c) => c.trim())
  if (cells.length !== 7) {
    console.error(`${taskId} 行是 ${cells.length} 列，应为 7 列`)
    process.exit(1)
  }
  cells[6] = `未知（待任务结束补填，会话 ${current}）`
  lines[idx] = `| ${cells.join(' | ')} |`
  fs.writeFileSync(file, lines.join(eol), 'utf8')
  console.log(`已记录 ${taskId} 的会话 ID：${current}`)
  process.exit(0)
}

let sessionId = sessionArg
if (!sessionId) {
  const { lines } = readLines()
  const row = lines.find((l) => l.startsWith(`| ${taskId} |`)) || ''
  const recorded = /ses_[A-Za-z0-9]+/.exec(row)
  if (recorded) sessionId = recorded[0]
}

const tool = path.join(__dirname, 'token-usage.cjs')
const r = spawnSync(process.execPath, sessionId ? [tool, sessionId] : [tool], { encoding: 'utf8' })
if (r.status !== 0) {
  console.error((r.stderr || r.stdout || '').trim())
  process.exit(1)
}
const summary = r.stdout.trim().split(/\r?\n/).pop()
const m = /^(ses_\S+?)(（.*?）)?: (input .*)$/.exec(summary)
if (!m) {
  console.error(`无法解析 token 用量输出：${summary}`)
  process.exit(1)
}
const [, usedSession, , usage] = m

const raw = fs.readFileSync(file, 'utf8')
const eol = raw.includes('\r\n') ? '\r\n' : '\n'
const lines = raw.split(/\r?\n/)
const idx = lines.findIndex((l) => l.startsWith(`| ${taskId} |`))
if (idx < 0) {
  console.error(`${file} 里没有 ${taskId} 的行。请先新增一行（7 列），再运行本工具。`)
  process.exit(1)
}

const cells = lines[idx].split('|').slice(1, -1).map((c) => c.trim())
if (cells.length !== 7) {
  console.error(`${taskId} 行是 ${cells.length} 列，应为 7 列（ID｜任务｜状态｜日期｜结果｜commit｜token 消耗）`)
  process.exit(1)
}
cells[6] = `${usage}（会话 ${usedSession}）`
lines[idx] = `| ${cells.join(' | ')} |`
fs.writeFileSync(file, lines.join(eol), 'utf8')
console.log(`已写入 ${taskId}：${cells[6]}`)
