#!/usr/bin/env node
// 在经验库里搜索关键词，只输出匹配条目的一行摘要（省 token）。
// 用法：node tools/find-experience.cjs <关键词...>
//   例：node tools/find-experience.cjs pwa 离线 缓存
// 每个关键词都要命中（标题、标签、正文任一处）才算匹配；按命中次数排序，最多 8 条。

const fs = require('fs')
const path = require('path')

const KIT = path.resolve(__dirname, '..')
const dir = path.join(KIT, 'experience')
const keys = process.argv.slice(2).map((k) => k.toLowerCase()).filter(Boolean)
if (!keys.length) { console.log('用法：node tools/find-experience.cjs <关键词...>'); process.exit(2) }

const rows = []
for (const f of fs.readdirSync(dir).filter((n) => /^EXP-.*\.md$/.test(n))) {
  const text = fs.readFileSync(path.join(dir, f), 'utf8')
  const lower = text.toLowerCase()
  const hits = keys.filter((k) => lower.includes(k))
  if (hits.length !== keys.length) continue
  const title = (/^title:\s*(.*)$/m.exec(text) || [, f])[1].trim()
  const guard = (/^guard:\s*(.*)$/m.exec(text) || [, '?'])[1].trim()
  const id = (/^id:\s*(.*)$/m.exec(text) || [, f])[1].trim()
  const sev = (/^severity:\s*(.*)$/m.exec(text) || [, ''])[1].trim()
  rows.push({ score: hits.length, line: `${id}  [${sev}]  ${title}  (守卫: ${guard})  → experience/${f}` })
}

rows.sort((a, b) => b.score - a.score)
if (!rows.length) { console.log('经验库里没有匹配条目。可以开始排查；解决后记得新增经验。'); process.exit(0) }
console.log(rows.slice(0, 8).map((r) => r.line).join('\n'))
