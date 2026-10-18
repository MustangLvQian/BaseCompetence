#!/usr/bin/env node
// 把 skills/labels.txt 里的短标签写进已安装 skill 的 description，减少每次会话的开销。
// 原文保存为同目录的 SKILL.md.orig（只保存一次）。幂等：可以重复运行。
// 用法：node tools/apply-labels.cjs

const fs = require('fs')
const path = require('path')
const os = require('os')

const KIT = path.resolve(__dirname, '..')
const home = os.homedir()
const roots = [
  path.join(home, '.agents', 'skills'),
  path.join(home, '.config', 'opencode', 'skills'),
  path.join(home, '.claude', 'skills'),
]

const labels = new Map()
for (const raw of fs.readFileSync(path.join(KIT, 'skills', 'labels.txt'), 'utf8').split(/\r?\n/)) {
  const line = raw.trim()
  if (!line || line.startsWith('#')) continue
  const i = line.indexOf('|')
  if (i < 0) continue
  labels.set(line.slice(0, i).trim(), line.slice(i + 1).trim())
}

// 把 frontmatter 里的 description 换成标签（处理单行和多行写法）
function setDescription(text, label) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text)
  if (!m) return null
  const lines = m[1].split(/\r?\n/)
  const out = []
  let skipping = false
  for (const l of lines) {
    if (/^description:/.test(l)) { out.push(`description: ${JSON.stringify(label)}`); skipping = true; continue }
    if (skipping && (/^\s/.test(l) || l === '')) continue
    skipping = false
    out.push(l)
  }
  const fm = out.join('\n')
  return text.replace(m[0], `---\n${fm}\n---`)
}

let changed = 0
const missing = new Set(labels.keys())
for (const root of roots) {
  if (!fs.existsSync(root)) continue
  for (const d of fs.readdirSync(root)) {
    const dir = path.join(root, d)
    const file = path.join(dir, 'SKILL.md')
    if (!fs.existsSync(file)) continue
    const text = fs.readFileSync(file, 'utf8')
    const name = (/^name:\s*(.+)$/m.exec(text) || [, d])[1].trim()
    if (!labels.has(name)) continue
    missing.delete(name)
    const next = setDescription(text, labels.get(name))
    if (next === null || next === text) continue
    const orig = path.join(dir, 'SKILL.md.orig')
    if (!fs.existsSync(orig)) fs.writeFileSync(orig, text, 'utf8')
    fs.writeFileSync(file, next, 'utf8')
    changed++
  }
}

console.log(`标签已应用：${changed} 处${missing.size ? `；未找到：${[...missing].join(', ')}` : ''}`)
