#!/usr/bin/env node
// 复盘经验库：列出可能重复的条目，供人或 Agent 决定是否合并。
// 只读，不修改任何文件。不自动合并，因为自动合并会把未经审核的规则写进守卫。
// 用法：node tools/review-experience.cjs [--threshold 0.5]

const fs = require('fs')
const path = require('path')

const KIT = path.resolve(__dirname, '..')
const dir = path.join(KIT, 'experience')
const args = process.argv.slice(2)
const ti = args.indexOf('--threshold')
const threshold = ti >= 0 ? Number(args[ti + 1]) : 0.5

const entries = fs.readdirSync(dir).filter((n) => /^EXP-.*\.md$/.test(n)).map((f) => {
  const text = fs.readFileSync(path.join(dir, f), 'utf8')
  const field = (k) => ((new RegExp(`^${k}:\\s*(.*)$`, 'm').exec(text) || [, ''])[1]).trim()
  const body = text.replace(/^---[\s\S]*?---/, '')
  return { file: f, title: field('title'), tags: field('tags'), status: field('status'), seen: Number(field('seen')) || 1, body }
})

// 中文按二元组切分，英文按单词切分，得到比较用的特征集合
function features(s) {
  const low = s.toLowerCase().replace(/[\s\p{P}]+/gu, ' ')
  const set = new Set()
  for (const w of low.split(' ')) {
    if (/[\u4e00-\u9fff]/.test(w)) { for (let i = 0; i < w.length - 1; i++) set.add(w.slice(i, i + 2)) }
    else if (w) set.add(w)
  }
  return set
}
const jaccard = (a, b) => {
  const inter = [...a].filter((x) => b.has(x)).length
  return inter / (a.size + b.size - inter || 1)
}

const pairs = []
for (let i = 0; i < entries.length; i++) {
  for (let j = i + 1; j < entries.length; j++) {
    const A = entries[i], B = entries[j]
    const score = jaccard(features(`${A.title} ${A.tags}`), features(`${B.title} ${B.tags}`))
    if (score >= threshold) pairs.push({ score, A, B })
  }
}

if (!pairs.length) { console.log(`没有相似度 >= ${threshold} 的候选重复条目（共 ${entries.length} 条）`); process.exit(0) }
console.log(`候选重复 ${pairs.length} 组（相似度 >= ${threshold}）。请逐组判断：合并、保留、或说明不同。`)
for (const { score, A, B } of pairs.sort((x, y) => y.score - x.score)) {
  console.log(`\n${score.toFixed(2)}  ${A.file}  |  ${B.file}`)
  console.log(`      「${A.title}」 vs 「${B.title}」`)
}
console.log('\n合并办法：保留一条，把另一条的独特内容并入，并把被合并的那条改为 status: superseded 并写明取代者。不要直接删除文件。')
