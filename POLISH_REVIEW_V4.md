# POLISH_REVIEW_V4.md — v4 独立复查报告（F1-F3 + E1-E3）

> 复查官：严过审（Yan）· 质量审查
> 目标：`accounting-app-prototype.html` v4（1714 行 / 101KB，单文件）
> 基准：v3（PASS 12 条 ⭐）+ 本轮新增 F1-F3 视觉修复 / E1-E3 编辑功能
> 方法：**独立通读源码 + Node VM 数值/结构断言 46/46 + 真实 Chrome CDP 行为驱动（13 截图 + 程序化几何/样式测量）**
> 说明：本环境 Bash/PowerShell 的 stdout 捕获暂时失效，且当前模型无法直接查看位图；故所有"视觉"结论均改用**程序化测量**（getBoundingClientRect / getComputedStyle / DOM 文本）作为证据，比肉眼更严格。截图已落盘存档。

---

## 总判定：✅ **PASS（6 项全部落实 · 无回归 · 无令牌违规）**

- F1 组头吸顶：sticky 贴顶 gap = **0px**（原 16px 缝隙消除），且 6 屏首子 margin 补偿全部生效。
- F2 排行布局：chart-head 改 column，分段按钮 nowrap+flex:none 且右对齐；`#record-type` 无回归（inline flex:1 正常覆盖）。
- F3 有效期白字：渐变卡上 `rgba(255,255,255,.92)` / `#fff`，白底 validity-row 不受影响。
- E1 流水编辑：预填/保存/双屏联动全链路在真实浏览器验证通过（6800→6999 后今天组总额实时 7038→7237）。
- E2 周期编辑：进行中/月付/已结清三分支编辑均可；改期数联动状态（已结清⇄进行中）。
- E3 卡片编辑：预填/保存/余额更新/内嵌有效期编辑全部通过。
- v3 12 条 ⭐ 数值回归 46/46 通过；提前还款/筛选/排行/图片上传/Tab·FAB·Sheet 无回归。

---

## 一、F1 组头吸顶 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 line 88 | `.app-content{...;padding:0 var(--space-4) calc(var(--space-4)+80px)}`（padding-top→0） |
| 源码 line 90 | `.app-content > div:first-child{margin-top:var(--space-4)}` 补偿 16px |
| 源码 line 199 | `.group-header{position:sticky;top:0;z-index:2}` |
| 源码 renderHome 1033-1037 / renderSearch 1124-1140 | 组头/组卡直接 `insertAdjacentHTML('beforeend')` 挂到 `.app-content` host |
| CDP home 滚动后 | 组头 top 与 app-content top 的 gap = **0**（内容贴顶无缝隙） |
| CDP search 滚动后 | 组头 gap = **0** |
| CDP 6 屏首子 margin | home/report/cards/profile/periodic/search 首子 marginTop 均 = **16px**，app-content paddingTop=0 |

**P2 观察（非阻断）**：因 mock 数据较短（3 组，max scrollTop≈539），吸顶元素为同容器多组头 siblings，滚动中"今天"组头保持吸顶、后序组头在其下方滚动（v3 亦如此，非 v4 引入的回归）。真实长列表下各分组会自然到达顶部吸顶。如需严格"分组跟随"，可把每组包一层 per-group 容器，属可选优化。

---

## 二、F2 消费排行布局 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 line 234 | `.segmented button{...;white-space:nowrap;flex:none}` |
| 源码 line 331 | `#ranking-card .chart-head{flex-direction:column;align-items:stretch;gap:var(--space-2)}` |
| 源码 line 332 | `#ranking-seg{display:flex;justify-content:flex-end}` |
| CDP 计算样式 | flexDir=**column**、segJustify=**flex-end**、btnNowrap=**nowrap**、btnFlex=**0 0 auto**、h2↔seg gap=**8px** |

**回归确认（关键）**：`.segmented button` 全局加 `flex:none` 未破坏记账 Sheet 的类型分段——`#record-type` 按钮是 inline `style="flex:1"`，inline 优先级更高，CDP 实测 computed flex = **`1 1 0%`**，两按钮宽度 **158/158** 均分。`#report-seg` 保持自然宽度 nowrap。

---

## 三、F3 卡片有效期白字 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 line 178 | `.stored-card .valid{font-size:12px;opacity:1}` |
| 源码 validDisplay 1040-1044 | `valid==null → color:#fff 永久有效`；有期 → `color:rgba(255,255,255,.92)` |
| CDP 卡片0（有期） | 有效期至 12/28，color=`rgba(255,255,255,0.92)`，valid opacity=`1` |
| CDP 卡片2（永久） | 永久有效，color=`rgb(255,255,255)` |
| CDP 详情 validity-row | color=`rgb(107,114,128)`（--color-text-secondary），**白底处未被误改** |
| CDP 详情 stored-card | 渐变卡内有效期同样白字 `rgba(255,255,255,0.92)` |

---

## 四、E1 流水项编辑 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 flowItemHTML 1011-1018 | `data-flow-idx` + `cursor:pointer`；renderHome/renderSearch 传原始 homeData index |
| 源码 openRecordEdit 1353-1376 | 预填金额/type/cat/acc/备注/图片；标题→"编辑这笔"；复用 #sheet-record |
| 源码 record-save 1329-1342 | `editingFlowIdx>=0` 分支更新 `homeData[idx]` + renderHome + renderSearch + reset + closeSheet |
| 源码事件委托 1377-1383 | `['screen-home','screen-search']` 各 `.app-content` click 委托 |
| CDP 打开预填 | title=`编辑这笔`、amt=`¥6,800.00`、type=`expense`、cat=`周期`、acc=`现金` |
| CDP 保存后 | Toast=`已更新`、首条金额=`¥6,999.00`、`homeData[0].amount=6999`、今天组总额=`¥7,237.00`（=7038−6800+6999，**实时正确**）、标题复位`记一笔` |

---

## 五、E2 周期支出编辑 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 3 分支编辑按钮 | 进行中（1588-1590 与提前还款并排）/ 月付类（1570）/ 已结清（1581）均有 `id="periodic-edit"` |
| 源码 #sheet-periodic-edit 846-880 | 名称/每期金额/周期 chips/已还/总期/剩余金额；`#pedit-freq-wrap` 与 `#pedit-periods` 条件显示 |
| 源码 pedit-save 1639-1658 | freq 类改名称/金额/周期；贷款类改期数/剩余；`paid>=total`→已结清，否则→进行中 |
| 源码修复 bug 1599-1614 | `prepay-btn` 不存在时不再 `return`，`periodic-edit` 总是绑定（已结清/月付分支可编辑） |
| CDP 房贷(进行中) | 预填 paid=24/total=360/remain=1024300，freqWrap=none/periods=block；改 paid=30 → data.paid=30、state=进行中、列表`已还 30` |
| CDP 停车费(月付) | 预填 amt=¥15.00、freqWrap=block/periods=none、freqActive=月付 |
| CDP 装修贷(已结清) | 预填 paid=12/total=12/remain=0；改 paid=5 → state=进行中；随后"已结清"筛选=0 张 |

---

## 六、E3 卡片编辑 ✅ 落实

| 证据项 | 结果 |
|--------|------|
| 源码 #sheet-card 747 | 新增"编辑卡片"按钮 `#card-edit` |
| 源码 #sheet-card-edit 883-909 | 类型 chips/名称/余额/"编辑有效期"按钮 |
| 源码 openValidityEditor 1480-1488 | 抽出共用；`card-edit-valid` 与 `cardedit-valid-btn` 双入口 |
| 源码 cardedit-save 1537-1547 | 更新 type/name/balance/icon + renderCards |
| CDP 预填 | name=`银行卡`、type=`储蓄卡`、balance=`3200` |
| CDP 保存后 | Toast=`已更新`；`cardsData[0]={name:'工资卡',type:'储蓄卡',icon:'bank',balance:5000,valid:'12/28'}`；首卡显示 `工资卡 ¥5,000.00` |
| CDP cardedit→编辑有效期 | validity sheet open=true，mm=`12` yy=`28` |

---

## 七、回归检查（真实 Chrome）

| 回归项 | 证据 | 结论 |
|--------|------|------|
| 提前还款 | 车贷详情 → hint=`剩余本金 ¥76,800.00，输入还款金额后将扣除` | ✅ |
| 有效期编辑（无有效期 Toggle） | v3 逻辑保留，E3 复用同一 Sheet | ✅ |
| 图片上传（记账 Sheet） | 点击 → upload none / preview flex；移除 → 还原 | ✅ |
| 已结清状态筛选 | 编辑装修贷改回进行中后，已结清筛选=0（联动正确） | ✅ |
| 消费排行 Top10 / 本周≠本月 | 本周=3 / 本月=10 | ✅ |
| Tab / FAB / Sheet | switchTab+showScreen+FAB hide/openSheet+data-close 全通 | ✅ |
| 筛选抽屉时间分组 | 时间 chips=4；选[本周]应用命中=7 | ✅ |
| 记账保存重置 | 新增 Sheet 初始 ¥0.00/支出/餐饮/记一笔 | ✅ |
| **v3 ⭐12 条数值** | Node VM 46/46：⭐4 四套数据自洽、条宽和=100、结余=收入-支出；⭐9 合计 12840、宽 78/9/10/3；⭐10 今天组=7038；⭐11 timeCover；⭐12 periodMap | ✅ |

---

## 八、令牌纪律（新增 CSS / 新 Sheet）

- 新增/修改 CSS 全部使用 `var(--space-*)` / `var(--color-*)` / `var(--radius-*)`，无新 hex、新字号、新圆角硬编码。
- F3 白字 `#fff` / `rgba(255,255,255,.92)` 属 DESIGN §2.4④ 渐变卡白字规范（组件固有语义），与 v3 `.stored-card{color:#fff}` 一致，不算违规。
- E2/E3 新增 Sheet 全部复用既有组件类：`.sheet / .sheet-handle / .sheet-head / .sheet-body / .sheet-foot / .field-label / .ledger-input / .chip / .btn / .record-amount / .chips`。
- `:root` 外出现的 hex 仅 `#fff` 与渐变 `#4F46E5,#4338CA`（值等同 `--color-primary/--color-primary-hover`，DESIGN 唯一允许的品牌渐变）。

---

## 九、截图证据索引（13 张，`_review_shots_v4/`）

F1_home_sticky / F2_ranking_head / F3_cards_valid_white / F3_card_detail_validityrow /
E1_edit_sheet_prefill / E1_home_after_edit / E2_periodic_edit_loan / E2_periodic_list_after /
E2_periodic_edit_freq / E3_card_edit_sheet / E3_cards_after_edit / R_prepay / R_search_filtered

---

## 十、结论

| 维度 | 结论 |
|------|------|
| F1-F3 + E1-E3 六项 | **6/6 全部落实**（源码 + Node 断言 + 真实浏览器程序化测量三重证据） |
| 数值自洽 | E1 金额联动（7038→7237）、E2 期数联动（已结清⇄进行中）、E3 余额更新均实时正确 |
| 回归 | 提前还款/有效期/图片上传/已结清筛选/排行 Top10/Tab·FAB·Sheet/12 条 ⭐ 全无破坏 |
| 令牌纪律 | 无新 hex/字号/圆角硬编码；新 Sheet 复用既有组件类 |
| P0/P1 | **无**。仅 1 条 P2 可选优化（F1 多组头 sticky 的"分组跟随"如需严格实现，可加 per-group 容器） |

**✅ PASS —— 可进入导出环节。**

---

## 附：复查脚本与产物

- `verify_v4_js.js` → `_verify_v4_numeric.txt`（Node VM 46/46 PASS）
- `cdp_v4_all.js` → `_verify_v4_behavior.txt`（CDP 行为 33 项）
- `cdp_v4_probe.js` → `_verify_v4_probe.txt`（F1 跟踪/F1b margin/F2 record-type 回归/F3 详情）
- `_review_shots_v4/`（13 张 PNG）
