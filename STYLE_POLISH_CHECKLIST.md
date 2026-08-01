# 移动端记账 App · 样式完善点清单

> 编制：需求发现分析师 许明需（Xu）
> 对象：`accounting-app-prototype.html`（6 屏 + FAB 半屏 Sheet）
> 基准：`DESIGN.md`（indigo-ledger v1） + `QUALITY_REVIEW.md`（PASS 22/25）
> 复核方式：通读 HTML 全文（CSS+结构+JS）+ Chrome headless 实拍 5 屏核对视觉
>
> 视觉证据：`_shots/home.png` / `report.png` / `cards.png` / `periodic.png` / `search.png`

---

## A. 上轮审查遗留缺陷（对照 QUALITY_REVIEW.md 复核）

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **A1** | 报表分段 `#report-seg` 行 1204-1209 | 切换 周/月/季/年 仅切换高亮，趋势图柱高/折线、环形弧度、汇总数字全部不变 | 至少做 mock 视觉变化：4 套柱高数组 + 4 段弧长 + 4 组汇总（如本月 ¥12,840/¥23,500，周约 ¥2,800/¥5,800），否则用户明显感到 mock 失败 | **P1** |
| **A2** | 记账保存 行 1186-1201 | `record-save` 后 `#record-amount` 保留上次值，下次开 Sheet 不是 ¥0.00；type/cat/acc chips 也不复位；图片预览也不复位 | `closeSheet` 与 `record-save` 后统一重置：金额 `¥0.00`、type→支出、cat→餐饮、acc→现金、图片→显示 upload，preview 隐藏 | **P1** |
| **A3** | 我的→卡片管理 行 1123-1125 + 543 | `[data-nav]` 走 `showScreen('screen-cards')`，未走 `switchTab`，进入卡片屏时 Tab 仍高亮上一个 Tab | 改为 `switchTab('screen-cards')`（让 tabbar 高亮跟随）；同时 `data-nav` 到 `screen-periodic/screen-search` 应保留来源 Tab（搜索屏不是 Tab 目标，按"我的"高亮合理） | **P1** |
| **A4** | 分组头组总额 行 946 `<span>'+fmt(sum)+'</span>` | 缺 `.amount` 类（无 `tabular-nums`），数字不等宽，且与卡片右边缘不齐 | 改为 `<span class="amount amount-md">'+fmt(sum)+'</span>`（或 amount-lg）；并确认 header 右侧 16px 边距与 card padding 16px 对齐（见 A6） | **P1** |
| **A5** | `.toast top:52px` 行 311 + `.app-header min-height:52px` 行 95 | Toast 顶部 y=52，正好压在 app-header（状态栏下方起始）的标题行上，"已记一笔 ¥xx"会被"我的账单"盖住 | 下移：top 改为 64~72px（或改为 `top: calc(44px statusbar + 12px)`，落在 header 下方居中） | **P1** |
| **A6** | `.group-header` 行 200 `padding:8px 4px` vs `.group-card` 行 205 `padding:8px 16px` | 组头文本左边 x=4，卡内第一行 x=16，水平差 **12px**，肉眼一眼能看出"未对齐"（home / search 都受影响） | 将 group-header 改为 `padding: var(--space-3) var(--space-4)`（或 group-card 改为 padding-left 4px）；推荐统一到 16px | **P1** |
| **A7** | 分类明细占比条 行 491-495 + 占比条 fill 全部 indigo | 1) "周期负债"条 fill 用 primary 靛，按四态语义应为 liability 橙；2) 4 类合计 ¥14,160 ≠ 本月支出 ¥12,840；3) 条宽 78%+9%+16%+7%=110% | 周期负债条 fill 改 `var(--color-liability)`；金额/宽度按"本月支出 ¥12,840"重新分布并校到合计 12,840；条宽按实际 % of 12,840 计算 | **P1** |
| **A8** | 环心 `#donut-expense` 行 472 用 `amount amount-lg`（22px） | DESIGN §2.4⑧ 明确环心金额用 `--text-amount-xl`（34px） | 改为 `amount amount-xl amount--expense`；如 170px 环内拥挤可保留 amount-lg（已是当前字号，已做视觉权衡） | **P2**（视觉权衡） |
| **A9** | `.tabbar` 行 107、`.fab` 行 129 安全区 | **已修复**：当前用 `env(safe-area-inset-bottom, 20px)`，QUALITY_REVIEW 提及的硬编码已纠正 | 维持 | ✅ 已修 |
| **A10** | 筛选抽屉 + `renderSearch` 行 1024-1025 | **金额 min/max 已生效**（行 1011-1014/1026-1027 实际可用）；但 **筛选抽屉根本无"时间"分组**（行 700-717 仅 类别/类型/金额），而 `searchFilter.time` 的 if 块是空操作 | 方案二选一：① 在 drawer 加"时间"分组（本周/本月/本季/本年 chips）并在 renderSearch 中按 group 过滤；② 直接删除 `searchFilter.time` 死代码 | **P1** |

---

## B. 令牌纪律偏离（对照 DESIGN.md）

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **B1** | `.chip` 行 252-258 `border-radius:var(--radius-full)`（pill） | 全站所有 chip 都用 pill，但 DESIGN §2.4②"类别 chips" 与 §2.4⑥"筛选 chips" 明确写 `--radius-sm`(6px) | 二选一：① chip 改为 radius-sm 6px（贴 DESIGN，更紧凑）；② 保留 pill 但在 DESIGN.md 增补"chip 用 radius-full"以保持令牌纪律 | **P1** |
| **B2** | 行 192 `.flow-main .sub` font-size:12px；行 176 `.stored-card .valid` 12px；行 245 `.bar-row .name` 14px | 12/14px 均非令牌字号（令牌 13/caption、15/body） | `.sub` → caption 13px secondary（DESIGN §2.4④ 备注·时间就是 caption）；`.valid` → caption；`.name` → body 15px | **P2** |
| **B3** | 占比条 fill 全 indigo | 周期负债应按四态语义用 liability 橙（DESIGN §2.1 四态语义色 + §2.4⑧ 图表对比序列用 liability） | 同 A7 处理 | **P1** |
| **B4** | `.rank-num.other` font-size:14px（非令牌） | 14px 无对应 token | 改 caption 13px 或 secondary text；top3 18px 也偏大可改 h2 17px | **P2** |
| **B5** | `.bar-row .val` 行 248 | 虽设了 tabular-nums，但缺 `.amount` 基类（无 right-align 的统一规则），且 width:84px 硬编码 | 改为 `class="amount amount-md"` + 取消固定 84px | **P2** |
| **B6** | 环形图例 行 476-477 "支出 ¥12,840" "收入 ¥23,500" | 普通文本，无 tnum | 包一层 `<span class="amount amount--expense/income">` | **P2** |
| **B7** | FAB "+" 行 622 `stroke-width="2"` | DESIGN §2.5 FAB"+" 用稍重 stroke（建议 2.5） | stroke-width="2.5" | **P2** |
| **B8** | Tab 指示条 行 123 `width:24px;height:2px` | DESIGN §2.4① 明确 2px×**20px** | 改 20px | **P2** |
| **B9** | 状态栏 行 76 `height:44px`（无 env(safe-area-inset-top)） | 设备框内可忽略；真机需要 | 改为 `padding-top: env(safe-area-inset-top, 0); height: calc(44px + env(...))` —— 仅当脱离设备框演示时必要 | **P2** |

---

## C. 视觉细节

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **C1** | `.app-content` 行 88 padding `var(--space-4)` 上下都 16px；FAB bottom=92px+56=148px from 底 | 首页最后一条"工资收入 ¥23,500.00" 被 FAB 圆形区域覆盖（home.png 可见） | `.app-content` 底部 padding 改为 `calc(var(--space-4) + 80px)`（FAB 避让），或 `.app-content` 加 `padding-bottom: 96px`，确保列表最末项可滚出 FAB 区域 | **P1** |
| **C2** | 搜索页 `.filter-btn` 行 221 | "筛选"二字**竖向换行**为"筛"/"选"（search.png 可见） | `.filter-btn` 加 `white-space: nowrap;`；或收紧 `padding-left`/`gap` 给 input 更多空间 | **P1** |
| **C3** | group-header 右总额 | 见 A4 | — | — |
| **C4** | group-header 左对齐 | 见 A6 | — | — |
| **C5** | `.group-card` padding 8px 16px + `.flow-item` padding 12px 0 | 首行顶部距卡边 8px，行间距 12px，最后一行底部 8px（垂直节奏 8-12-12-12-8） | group-card padding 上下改为 `var(--space-3)`(12px)，与 flow-item 节奏对齐 | **P2** |
| **C6** | 卡片管理"咖啡储值卡"（valid:null） | 末张被状态栏/FAB 视觉压住，"永久有效"信息微弱（cards.png） | 卡片列表底部加 `padding-bottom: 24px` 呼吸；并把"永久有效"颜色适当提亮（已是 primary 蓝） | **P2** |
| **C7** | 占比条宽度 78+9+16+7=110% | 不归一化 | 按真实占比重算并和=100% | **P2**（同 A7） |
| **C8** | 状态栏与 app-header | 无分割线但留白足够，可接受 | — | — |
| **C9** | stored-card `.type-badge` 12px/500 + 半透白 | 在 90% 紫底上略显低调 | 字色调到纯白，opacity:1（与 `.valid` 对齐） | **P2** |

---

## D. 交互体验

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **D1** | 报表分段 | 见 A1 | — | — |
| **D2** | 记账保存 | 见 A2 | — | — |
| **D3** | `.add-periodic-btn` 行 1365 | 点击仅 toast"新增周期性支出（示例）" | 同卡片"添加"按钮 → 打开 Sheet；如暂时不做，至少 toast 改为"功能开发中"避免 demo 误解 | **P2** |
| **D4** | 卡片详情"充值/消费" 行 1244-1245 | 仅 toast"充值入口（示例）"/"消费入口（示例）" | 已是 mock，但可考虑 toast 写"点击了充值（演示）"避免"（示例）"字样显得半成品 | **P2** |
| **D5** | `.chip` / `.menu .item` / `.tab` / `.btn-ghost` | 均无 `:active` 视觉反馈，桌面浏览器点击无变化 | `.chip:active{background:var(--color-primary-soft)}`；`.menu .item:active{background:var(--color-surface-2)}`；`.tab:active{opacity:.7}`；`.btn-ghost:active{background:var(--color-primary-light)}` | **P2** |
| **D6** | 筛选抽屉缺时间分组 | 见 A10 | — | — |
| **D7** | 消费排行 `periodMap` 行 1050 | `'本周':['本周','本月']`、`'本月':['本周','本月']` → 切换本周/本月显示**完全相同列表**，明显 mock 失败 | 改为 `'本周':['本周']`、`'本月':['本周','本月']`、`'本季':['本周','本月','本季']`、`'本年':['本周','本月','本季','本年']` | **P1** |
| **D8** | Sheet 把手 `.sheet-handle` | 装饰性，无实际拖拽 | 可接受（原型） | **P2** |
| **D9** | 记账金额输入 行 1166-1174 | 每按一键立即千分位重排，光标跳到末尾 | 可接受（记账场景通常一次输入完成） | **P2** |

---

## E. 布局 / 响应式

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **E1** | `.device` 390×844 固定 | 覆盖 375-430 范围 | 接受（原型） | — |
| **E2** | `.app-content` 无 FAB 避让 | 见 C1 | — | — |
| **E3** | `.app-content` 与 `.tabbar` 中间无 gap | 列表滚到底紧贴 tabbar（视觉粘连） | `.app-content` padding-bottom: 16px + FAB 避让（约 80-96px） | **P2** |
| **E4** | 消费排行 `.chart-head` 行 498-506 | h2"消费排行 · 高→低"+4 段 segmented 同行 | 在 358px(390-32 边距) 内两段都偏紧，建议 h2 一行 + segmented 独占第二行 `justify-content:flex-end` | **P2** |
| **E5** | 输入框聚焦 | 仅边框变 primary，无 ring/shadow | 可接受 | **P2** |

---

## F. 内容与文案

| # | 位置 | 现状 | 建议 | 优先级 |
|---|------|------|------|--------|
| **F1** | home "今天"组总额 行 946 | ¥30,538 = 6800+38+200+**23500**，把工资收入混进了"今天"组总额 | 口径改为只算支出：`const sum = list.filter(t=>t.cls==='expense'||t.cls==='liability'||t.cls==='balance').reduce((a,b)=>a+b.amount,0)`，或拆为"今日支出 ¥7,038 · 收入 ¥23,500" | **P1** |
| **F2** | 房贷 `paid:24, total:360, start:2021-07-01` | 2021-07-01 到 2026-06-22 ≈ 60 期，"已还 24"明显不符；progress 7% 偏低 | 改为 paid:60 / 6%，或改 start 为 2024-07-01（更贴近 24 期/360=6.7% 的数据） | **P2** |
| **F3** | 占比条 4 项 ¥14,160 ≠ 本月支出 ¥12,840 | 数据不一致 | 校到 12,840（见 A7） | **P1** |
| **F4** | 消费排行"本月"合计 ¥3,990 | 与本月支出 ¥12,840 差距大 | 加几条大额支出让合计更接近，或在表头加"示例数据"小字提示 | **P2** |
| **F5** | 日期"2026-06-22 周一" | 与系统一致（已核对 Monday ✓） | — | ✅ |
| **F6** | search "本月 · 共 9 笔" | 与 homeData 9 条一致 | — | ✅ |
| **F7** | 错别字 | 无 | — | ✅ |
| **F8** | 单位统一 | ¥/期/月 一致 | — | ✅ |

---

## G. 组件完整度（DESIGN §2.4 比对）

| 组件 | 状态 | 备注 |
|------|------|------|
| ① Tab Bar | ✓ | 指示条宽度 B8 例外 |
| ② FAB | ✓ | stroke B7 例外 |
| ③ 进度条 | ✓ | 完整实现（轨道/填充/标签/剩余金额/已结清态） |
| ④ 卡片组件 | ✓ | chips 例外 B1；stored-card 唯一渐变 ✓ |
| ⑤ 列表分组 | ✓ | 对齐 A6、组总额 A4 例外 |
| ⑥ 搜索+筛选 | ✗ | 抽屉缺时间分组 A10；筛选按钮换行 C2 |
| ⑦ 分段控件 | ✓ | 完全符合 |
| ⑧ 图表 | ✗ | 趋势图无 X 轴月份、Y 轴刻度；环心 amount-lg（A8）；占比条语义/数据 A7 |
| ⑨ 空/加载/成功/危险 | ✓ | 搜索空态 ✓；Toast ✓；无骨架可接受；无危险态场景 |

---

## ✅ 建议本次必改清单（⭐ 12 条，肉眼可见改善 × 改动低成本）

| # | 条目 | 涉及 | 预计改动 |
|---|------|------|----------|
| ⭐1 | **C1 / E2** 首页内容底部加 FAB 避让 padding（≈80-96px） | CSS | `.app-content{padding-bottom: calc(var(--space-4) + 80px)}`  |
| ⭐2 | **A6 / C4** group-header 与 group-card 水平对齐（统一 padding-left 16px） | CSS | `.group-header{padding: var(--space-3) var(--space-4)}` |
| ⭐3 | **A4 / C3** 组总额加 `.amount` 类 + 与卡片右对齐 | JS | 行 946：`<span class="amount amount-md">${fmt(sum)}</span>` |
| ⭐4 | **A1 / D1** 报表分段 4 套数据 mock（周/月/季/年 4 组柱高+弧长+汇总） | JS | `#report-seg` click handler 调 `renderReport(period)`，重写 SVG/环形/summary/分类明细 |
| ⭐5 | **A2 / D2** 记账保存后统一重置（金额/type/cat/acc/图片/预览） | JS | `record-save` 内 `amountInput.value='¥0.00'; 复位 active class; 重置上传`；`closeSheet` 也加一份 |
| ⭐6 | **A3** 我的→卡片管理走 `switchTab('screen-cards')` | JS | 行 1124：改为 `switchTab(el.dataset.nav)` 并加白名单（卡片走 switchTab，周期性/搜索仍 showScreen） |
| ⭐7 | **A5** Toast 位置下移避开 app-header | CSS | `.toast{top: calc(44px + var(--space-4) + var(--space-2))}` 改为 ~68-72px |
| ⭐8 | **C2** 搜索"筛选"按钮加 nowrap / 收紧间距 | CSS | `.filter-btn{white-space:nowrap; padding-left: var(--space-2)}` |
| ⭐9 | **A7 / B3** 占比条 周期负债 fill 改 liability + 数据重算校到 12,840 | JS | 行 491-494 fill 颜色按类型；4 项金额调到合计 12,840，宽度按真实 % |
| ⭐10 | **F1** "今天"组总额只算支出（或拆为支出/收入两栏） | JS | 行 945：`list.filter(t=>['expense','liability','balance'].includes(t.cls))` |
| ⭐11 | **A10 / D6** 筛选抽屉补"时间"分组 + renderSearch 实现 | HTML+JS | drawer 加一组 chips + renderSearch 中按 `t.time`/`t.group` 过滤（可按今天/昨天/更早聚合） |
| ⭐12 | **D7** 消费排行 periodMap 修正（本周≠本月） | JS | 行 1050：本周→['本周']、本月→['本周','本月'] |

---

## ⏳ 可选清单（用户可勾选）

- **B1** chips 改 radius-sm 6px（贴 DESIGN）或更新 DESIGN 注释保留 pill
- **A8** 环心金额 amount-xl 34px（visual trade-off）
- **G8** 趋势图加 X 轴月份标签 + Y 轴刻度（caption 13px secondary）
- **B2** 统一 `.sub`/`.valid`/`.bar-row .name` 字号到令牌（13/13/15）
- **B6** 环形图例金额加 `.amount` 类
- **B7** FAB"+" stroke-width=2.5
- **B8** Tab 指示条 24px→20px
- **F2** 房贷 paid=24 改 60（或 start 调到 2024-07-01）
- **F4** 消费排行加几条大额支出让"本月"合计接近 12,840
- **C5** group-card padding 上下统一为 space-3
- **C6** 卡片管理列表底部 padding-bottom 24px 呼吸
- **D5** 给 chip/menu-item/tab/btn-ghost 加 `:active` 反馈
- **E4** 消费排行 chart-head 改为两行（h2 上 + segmented 下 flex-end）
- **D3 / D4** 调整 mock 按钮 toast 文案

---

## 📎 截图证据索引

| 屏 | 文件 | 关键发现 |
|----|------|----------|
| ① 首页 | `_shots/home.png` | C1（FAB 覆盖）、A6（header/card 错位）、A4（¥30,538 混收入） |
| ⑤ 报表 | `_shots/report.png` | A1（分段无变化）、A8（环心 22px）、G8（无轴标） |
| ④ 卡片 | `_shots/cards.png` | 渐变/余额/有效期 ✓；C6（末卡偏淡） |
| ③ 周期 | `_shots/periodic.png` | F2（24/360 不符）、进度条 ✓ |
| ⑥ 搜索 | `_shots/search.png` | C2（"筛选"换行）、A6（对齐）、C1（FAB 压底部） |

> 📌 待用户确认 12 条 ⭐ 后，原型构建师可一次性成批改 CSS+HTML+JS，集中在 4 处文件区域（CSS `.app-content/.group-header/.filter-btn/.toast`、HTML `sheet-filter`、JS `renderHome/renderReport/renderSearch/record-save/periodMap/data-nav`）。预计净增 ~80-120 行代码，无破坏性变更。