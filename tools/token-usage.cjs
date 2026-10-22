#!/usr/bin/env node
'use strict'

// 查 opencode 会话的 token 消耗，只输出一行摘要（不输出转录，省 token）。
//
// 用法：
//   node tools\token-usage.cjs <会话ID>   查指定会话
//   node tools\token-usage.cjs            查当前目录所属项目最近一个会话
//
// 会话 ID 从哪来：开工时记进任务日志的 session 列（`opencode session list` 可查）。
// 注意：当次会话填不准自己的消耗（写日志的消息本身也在计费），所以流程是
// 开工记 ID → 任务结束后新开会话跑本工具补填。

const { spawnSync } = require('node:child_process')

function run (args) {
  const r = spawnSync('opencode', args, {
    encoding: 'utf8',
    shell: true,
    maxBuffer: 256 * 1024 * 1024
  })
  if (r.status !== 0 || r.error) {
    const detail = r.error ? String(r.error.message) : (r.stderr || '').trim().slice(0, 300)
    console.error(`opencode ${args.join(' ')} 失败：${detail}`)
    console.error('提示：需要能连上 opencode 后台服务，先开一次 opencode 再试。')
    process.exit(1)
  }
  return r.stdout
}

const fmt = (n) => n.toLocaleString('en-US')

function summarize (data) {
  const acc = { input: 0, output: 0, reasoning: 0, cacheRead: 0, cacheWrite: 0, cost: 0 }
  let messages = 0
  // 不依赖导出结构的具体字段名：凡是带 tokens.input 数字的节点（即 assistant 消息）都计入，
  // 结构变了也不会静默漏统计。
  const walk = (node) => {
    if (!node || typeof node !== 'object') return
    const t = node.tokens
    if (t && typeof t === 'object' && typeof t.input === 'number') {
      messages += 1
      acc.input += t.input || 0
      acc.output += t.output || 0
      acc.reasoning += t.reasoning || 0
      if (t.cache) {
        acc.cacheRead += t.cache.read || 0
        acc.cacheWrite += t.cache.write || 0
      }
      if (typeof node.cost === 'number') acc.cost += node.cost
    }
    if (Array.isArray(node)) node.forEach(walk)
    else Object.values(node).forEach(walk)
  }
  walk(data)
  const title = (data && data.info && data.info.title) || ''
  return { ...acc, messages, title }
}

let sessionId = process.argv[2]
if (!sessionId) {
  let list
  try {
    list = JSON.parse(run(['session', 'list', '--format', 'json', '-n', '5']))
  } catch (e) {
    console.error(`解析 opencode session list 输出失败：${String(e.message).slice(0, 200)}`)
    process.exit(1)
  }
  if (!Array.isArray(list) || list.length === 0) {
    console.error('当前目录所属项目没有会话。请显式给出会话 ID，或在项目目录里运行。')
    process.exit(1)
  }
  sessionId = list[0].id
}

let data
try {
  data = JSON.parse(run(['session', 'export', sessionId]))
} catch (e) {
  console.error(`解析 opencode session export 输出失败：${String(e.message).slice(0, 200)}`)
  process.exit(1)
}

const s = summarize(data)
if (s.messages === 0) {
  console.error(`会话 ${sessionId} 里没有找到任何带 tokens 的消息（会话不存在或已删除）。`)
  process.exit(1)
}

const titlePart = s.title ? `（${s.title.slice(0, 20)}）` : ''
console.log(
  `${sessionId}${titlePart}: input ${fmt(s.input)} / output ${fmt(s.output)} / cache-read ${fmt(s.cacheRead)} / cost $${s.cost.toFixed(2)}`
)
