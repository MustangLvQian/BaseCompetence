---
id: EXP-20261018-0002
title: Service Worker 预缓存清单必须覆盖离线需要的全部资源
tags: [pwa, service-worker, offline, audio]
severity: high
status: active
seen: 1
source: YingChuangXingQiu PWA-01
created: 2026-10-18
---

# Service Worker 预缓存清单必须覆盖离线需要的全部资源

**症状**：装好 PWA 后离线一切正常，就是没有声音，控制台也没有报错。

**根因**：预缓存清单漏了音频文件。离线时 `fetch` 直接失败，而播放器把失败吞掉了。

**规则**：应用离线需要的每个静态资源都要能被预缓存清单解析到。改了资源目录（比如音频）后，要同步核对清单和资源索引（manifest）。

**守卫**：`✅ 自动` 写一个检查脚本，对比预缓存清单与 `public/` 资源列表，接进 `npm run check`。
