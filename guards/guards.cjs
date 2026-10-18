// 守卫定义。每条守卫对应一条经验（exp 字段），由 tools/run-guards.cjs 在 git 钩子里执行。
// 守卫只检查改动的文件，只返回违规描述。没有违规时输出为空。
// 新增守卫：在这里加一项，并把经验文件的 guard 字段改成它的 id，node tools/run-guards.cjs --self-check 会校验。

const fs = require('fs')
const path = require('path')
const { execFileSync } = require('child_process')

const norm = (p) => p.replace(/\\/g, '/')
const inMini = (p) => /(^|\/)(wechat-miniprogram|miniprogram)\//.test(norm(p))
const isTest = (p) => /(^|\/)(tests?|__tests__)\/|\.test\.[cm]?js$/.test(norm(p))
const lines = (t) => t.split(/\r?\n/)
const at = (t, re) => lines(t).flatMap((l, i) => (re.test(l) ? [`第${i + 1}行`] : []))

// 上一个提交里的文件内容，用于比较「本次有没有改」
function headText(p) {
  try { return execFileSync('git', ['show', `HEAD:${norm(p)}`], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }) }
  catch { return null }
}

module.exports = [
  {
    id: 'G-0001', exp: 'EXP-20261018-0001',
    files: (p) => /(^|\/)(sw|service-worker)\.js$/.test(norm(p)),
    check: (p, t) => {
      if (!/addEventListener\(\s*['"]fetch['"]/.test(t)) return []
      return /mode\s*===?\s*['"]navigate['"]/.test(t) ? [] : ['缺少 navigate 分支：导航请求必须 network-first']
    },
  },
  {
    id: 'G-0003', exp: 'EXP-20261018-0003',
    files: (p) => /(^|\/)(sw|service-worker)\.js$/.test(norm(p)),
    check: (p, t) => {
      const cacheName = (s) => (/CACHE_NAME\s*=\s*['"][^'"]*['"]/.exec(s || '') || [''])[0]
      const now = cacheName(t)
      if (!/CACHE_NAME\s*=\s*['"][^'"]*\d/.test(t)) return ['CACHE_NAME 缺少版本号']
      const old = headText(p)
      if (old !== null && old !== t && now === cacheName(old)) return ['SW 行为有改动但 CACHE_NAME 未提升版本']
      return []
    },
  },
  {
    id: 'G-0006', exp: 'EXP-20261018-0006',
    files: (p) => inMini(p) && /\.js$/.test(p) && !isTest(p),
    check: (p, t) => {
      const out = []
      const re = /require\(\s*['"]([^'"]+\.json)['"]\s*\)/g
      let m
      while ((m = re.exec(t))) {
        const target = path.resolve(path.dirname(p), m[1])
        if (!fs.existsSync(`${target}.js`)) out.push(`require('${m[1]}') 缺少同名 ${path.basename(m[1])}.js 包装文件`)
      }
      return out
    },
  },
  {
    id: 'G-0007', exp: 'EXP-20261018-0007',
    files: (p) => /\.(wxml|wxss)$/.test(p),
    check: (p, t) => {
      if (/\.wxss$/.test(p)) {
        const clean = t.replace(/\/\*[\s\S]*?\*\//g, '')
        const open = (clean.match(/\{/g) || []).length
        const close = (clean.match(/\}/g) || []).length
        return open === close ? [] : [`花括号不成对：{ ${open} 个，} ${close} 个`]
      }
      const VOID = new Set(['image', 'input', 'icon', 'progress', 'checkbox', 'radio', 'switch', 'slider', 'import', 'include', 'template', 'wxs', 'movable-area', 'map', 'canvas', 'textarea'])
      const body = t.replace(/<!--[\s\S]*?-->/g, '')
      const stack = []
      const out = []
      const re = /<(\/?)([a-zA-Z][\w-]*)\b[^>]*?(\/?)>/g
      let m
      while ((m = re.exec(body))) {
        const [, closing, name, selfClose] = m
        if (selfClose || (!closing && VOID.has(name))) continue
        if (!closing) { stack.push(name); continue }
        const top = stack.pop()
        if (top !== name) { out.push(`</${name}> 与 <${top || '无'}> 不匹配`); break }
      }
      if (stack.length) out.push(`未闭合的标签：<${stack.join('>, <')}>`)
      return out
    },
  },
  {
    id: 'G-0008', exp: 'EXP-20261018-0008',
    files: (p) => inMini(p) && /\.svg$/.test(p),
    check: (p, t) => {
      const tag = (/<svg\b[^>]*>/.exec(t) || [''])[0]
      const missing = ['xmlns', 'width', 'height', 'viewBox'].filter((a) => !new RegExp(`\\b${a}=`).test(tag))
      return missing.length ? [`<svg> 缺少属性：${missing.join(', ')}`] : []
    },
  },
  {
    id: 'G-0009', exp: 'EXP-20261018-0009',
    files: (p) => inMini(p) && /\.js$/.test(p) && !isTest(p),
    check: (p, t) => at(t, /^(?!\s*(\/\/|\*)).*(\?\.(?!\d)|\?\?)/).map((w) => `${w} 使用了 ?. 或 ??（基础库可能不支持）`),
  },
  {
    id: 'G-0011', exp: 'EXP-20261018-0011',
    files: (p) => /\.(py|js|ts|mjs|cjs|tsx|jsx)$/.test(p) && !/node_modules/.test(p),
    check: (p, t) => {
      if (!/sync_playwright|@playwright\/test|from playwright|require\(['"]playwright/.test(t)) return []
      if (!/new_context\(|newContext\(/.test(t)) return []
      return /reduced_motion|reducedMotion/.test(t) ? [] : ['新建浏览器上下文未设置 reduced_motion="reduce"（动画会导致定位器超时）']
    },
  },
  {
    id: 'G-0012', exp: 'EXP-20261018-0012',
    files: (p) => /\.(css|wxss)$/.test(p),
    check: (p, t) => lines(t).flatMap((l, i) => {
      const m = /line-height:\s*(\d*\.?\d+)\s*(;|\}|$)/.exec(l)
      if (!m || /lh-ok/.test(l) || Number(m[1]) >= 1.35) return []
      return [`第${i + 1}行 line-height: ${m[1]} 小于 1.35，中文会被裁切（确无中文时写 /* lh-ok */）`]
    }),
  },
  {
    id: 'G-0014', exp: 'EXP-20261018-0014',
    files: (p) => /\.ps1$/.test(p),
    check: (p, t) => {
      const hasBom = t.charCodeAt(0) === 0xfeff
      return !hasBom && /[^\x00-\x7F]/.test(t) ? ['含中文但没有 UTF-8 BOM（Windows PowerShell 5.1 会解析错位）'] : []
    },
  },
  {
    id: 'G-0016', exp: 'EXP-20261018-0016',
    prePush: (updates) => updates
      .filter((u) => u.remoteRef === 'refs/heads/main' && !/^0+$/.test(u.remoteSha) && !/^0+$/.test(u.localSha))
      .filter((u) => {
        try { execFileSync('git', ['merge-base', '--is-ancestor', u.remoteSha, u.localSha], { stdio: 'ignore' }); return false }
        catch { return true }
      })
      .map(() => '禁止强制推送 main（非快进）。请先 git pull --rebase，不要 force push'),
  },
  {
    id: 'G-0018', exp: 'EXP-20261018-0018',
    files: (p) => /(^|\/)AGENTS\.md$/.test(norm(p)),
    check: (p) => {
      const checker = path.join(__dirname, '..', 'tools', 'check-skills.cjs')
      try {
        execFileSync('node', [checker, '--file', p], { stdio: ['ignore', 'pipe', 'pipe'] })
        return []
      } catch (e) {
        return String(e.stdout || '').split(/\r?\n/).filter((l) => /^\s+-\s/.test(l)).map((l) => `路由表引用了本机不存在的 skill：${l.trim().slice(2)}`)
      }
    },
  },
]
