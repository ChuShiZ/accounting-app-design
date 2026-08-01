# POLISH_REVIEW.md — 样式完善 12 条独立复查报告

> 复查官：严过审（Yan）· 质量审查
> 目标：`accounting-app-prototype.html` v3（1481 行，单文件）
> 基准：`DESIGN.md` + `STYLE_POLISH_CHECKLIST.md` ⭐12 条
> 方法：**独立读源码 + Node VM 跑内嵌 JS 数值断言 + Chrome headless/CDP 真机交互 19 张截图**
> 复查日期：2026-07-22

---

## 总判定：PASS（12 条全部落实 · 无回归 · 无令牌违规）

12 条全部落实到位，证据由源码行号、Node 数值断言（32/32）、真实 Chrome CDP 行为断言构成。
本次新增 CSS 均使用 DESIGN.md 令牌变量，无硬编码新色值/字号/圆角。可进入导出环节。

---

## 一、12 条逐条落实证据

### ⭐1 `.app-content` 底部 padding = `calc(var(--space-4) + 80px)` PASS
- 代码：第 88 行 `.app-content{...;padding:var(--space-4) var(--space-4) calc(var(--space-4) + 80px);}`，含 ⭐1 C1/E2 FAB 避让 注释。
- 数值：bottom = 16+80 = 96px > FAB 高度 56 + 16 right gap + 56 tabbar 视觉不重叠。
- 视觉：home_scrolled_bottom.png 显示滚到底后 更早 ¥3,356.30 / 车贷月供 ¥3,200.00 / 超市 ¥156.30 完整可见，FAB 仅覆盖右下空白。

### ⭐2 `.group-header` padding = `var(--space-3) var(--space-4)`，与 `.group-card` 16px 对齐 PASS
- 代码：第 200 行 padding 12/16px；第 205 行 .group-card padding 8/16px。两者左右均为 16px。
- 视觉：home.png 中 今天 组头左侧 x 与 房贷月供/午餐/... 卡片内第一行左端 x 严格对齐（X = 16px padding）。

### ⭐3 组头总额 span 带 `class="amount amount-md"` PASS
- 代码：第 955 行 `<span class="amount amount-md">${fmt(sum)}</span>`。
- 效果：启用 .amount 的 tabular-nums / right-align；视觉上 ¥7,038.00 与卡片右边缘对齐且数字等宽。

### ⭐4 报表分段 周/月/季/年 4 套数据联动 PASS（核心项）
- 代码：第 1236-1245 行 reportData 四套；第 1246-1284 行 renderReport(period) 重写 SVG 柱高/折线/环形弧长/环心文本/汇总/分类明细；第 1285-1291 行 #report-seg click handler 调 renderReport(b.dataset.seg)；第 1478 行 renderReport('月') 初始化。
- Node 数值断言（verify_polish.js，32/32 PASS）：

  | 周期 | 收入 | 支出 | 结余 | 分类合计=支出 | 条宽取整和 |
  |------|------|------|------|---------------|------------|
  | 周 | 5,800 | 2,800 | 3,000 | 1200+680+500+420=2800 OK | 43+24+18+15=100 OK |
  | 月 | 23,500 | 12,840 | 10,660 | 10000+1200+1240+400=12840 OK | 78+9+10+3=100 OK |
  | 季 | 70,000 | 38,000 | 32,000 | 28000+3200+4200+2600=38000 OK | 74+8+11+7=100 OK |
  | 年 | 280,000 | 150,000 | 130,000 | 105000+15000+18000+12000=150000 OK | 70+10+12+8=100 OK |

- CDP DOM 快照（每次 renderReport 后读真 DOM）：

  | 周期 | donut-arc dash | 环心 | 结余 |
  |------|----------------|------|------|
  | 周 | 110.5 339.3 | 本周支出 ¥2,800.00 | ¥3,000.00 |
  | 月 | 119.9 339.3 | 本月支出 ¥12,840.00 | ¥10,660.00 |
  | 季 | 119.4 339.3 | 本季支出 ¥38,000.00 | ¥32,000.00 |
  | 年 | 118.4 339.3 | 本年支出 ¥150,000.00 | ¥130,000.00 |

- 视觉：report_week.png / report_month.png / report_year.png 趋势柱高度/折线明显不同；环心文本分别 本周支出/本月支出/本年支出。

### ⭐5 记账保存后重置（金额 ¥0.00/支出/餐饮/现金/图片复位） PASS
- 代码：第 1121-1132 行 resetRecordSheet()；第 1119 行 closeSheet 内调用；第 1228 行 record-save 内也调用（幂等双保险）。
  - record-amount.value='¥0.00'
  - #record-type button 仅 data-type="expense" 保留 active
  - #record-cat .chip[data-v="餐饮"] 激活
  - #record-acc .chip[data-v="现金"] 激活
  - record-note.value=''
  - img-upload.style.display='flex' / img-preview.style.display='none'
- CDP 行为：打开 Sheet 初始 = {amt:¥0.00, type:expense, cat:餐饮, acc:现金, upload:flex, preview:none, note:''} → 修改为 88/交通/银行卡/上传图片/备注"打车" → 保存（Toast=已记一笔 ¥88.00）→ 重开 Sheet = 完全回归上述初始态。record_sheet_reset.png 验证。

### ⭐6 `data-nav` 到 `screen-cards` 走 `switchTab` PASS
- 代码：第 1150-1157 行 [data-nav] click handler，if(nav==='screen-cards') switchTab(...)；screen-periodic / screen-search 仍走 showScreen() 保留来源 Tab 高亮。
- CDP 行为：profile 页点 卡片管理 后 tab.active.dataset.tab === 'screen-cards' 且 app-screen.active.id === 'screen-cards'。

### ⭐7 `.toast` top = `calc(44px + var(--space-4) + var(--space-2))` = 68px PASS
- 代码：第 311 行 top = 44+16+8 = 68px。已加注释 ⭐7 A5 Toast 下移避开 app-header。
- 对比：app-header min-height:52px + 状态栏 44px = 96px；toast 在 68px 处位于状态栏与 header 标题区之间的留白带，不压标题行。

### ⭐8 `.filter-btn` 加 `white-space:nowrap` PASS
- 代码：第 221 行 .filter-btn{...;white-space:nowrap;} 含 ⭐8 C2 注释。
- 视觉：filter_drawer.png 显示抽屉打开正常；search.png 搜索框中"筛选"按钮未换行。

### ⭐9 占比条：周期负债 fill=liability；4 项金额合计=12,840；宽和=100% PASS
- 静态 HTML（第 490-495 行，renderReport('月') 初始覆盖）：
  - 周期负债 fill width:78% background:var(--color-liability) ¥10,000
  - 居家      fill width:9%                           ¥1,200
  - 餐饮      fill width:10%                          ¥1,240
  - 交通      fill width:3%                           ¥400
- Node 断言：月 4 项合计 = 12840，条宽取整 = [78,9,10,3]，和 = 100，周期负债 liability OK。

### ⭐10 今天组总额只算支出 = ¥7,038.00 PASS
- 代码：第 953 行 list.filter(t=>t.cls==='expense'||t.cls==='liability'||t.cls==='balance').reduce(...) 剔除 income。
- Node 断言：今天 4 条 → 6800+38+200 = 7038；含工资全部 = 30538（!=7038，确认已剔除）。home.png 视觉显示 今天 ¥7,038.00。
- CDP 实测：保存 88 后今天组总额变为 ¥7,126.00（7038+88），证明过滤逻辑随新增条目实时正确。

### ⭐11 筛选抽屉有"时间"分组 chips + renderSearch 按 timeGroup/timeCover 过滤 PASS
- 代码 HTML：第 707-713 行 chips data-group="time" 含 本周/本月/本季/本年 chips。
- 代码 JS：第 1020 行 timeCover 4 档；第 1035-1039 行 renderSearch 按 covered.has(t.timeGroup) 过滤。
- CDP 实测：抽屉打开 4 个时间 chips OK；选 本周 应用 → search-count = 7（排除 2 条 更早/本月）；重置 → 9。
- 视觉：filter_drawer.png 时间分组清晰。

### ⭐12 periodMap：本周→['本周']、本月→['本周','本月']，本周!=本月 PASS
- 代码：第 1064 行 periodMap = {'本周':['本周'], '本月':['本周','本月'], '本季':['本周','本月','本季'], '本年':['本周','本月','本季','本年']}。
- CDP 实测：消费排行 本周 → 3 条；本月 → 10 条（包含本周）。集合不同 OK。

---

## 二、回归检查（真实 Chrome 浏览器交互）

| 回归项 | 证据 | 结论 |
|--------|------|------|
| 提前还款 二级 Sheet | prepay.png 截图显示；hint="剩余本金 ¥1,024,300.00，输入还款金额后将扣除"；prepay-amount 输入会实时刷新 prepay-after；确认还款扣减 remain 并改 paid | 无回归 |
| 卡片有效期编辑（含无有效期 Toggle） | card_validity.png；卡 0 valid=12/28 → mm=12/yy=28/toggle off/"关闭"；点 toggle → mm disabled / "永久有效"；保存更新 cardsData 并 renderCards | 无回归 |
| 图片上传（记账 Sheet） | img-upload 点击 → display:none；img-preview display:flex；img-remove 复位 | 无回归 |
| 已结清状态筛选（周期） | periodic_settled.png；点 已结清 chip → #periodic-list .card 数量 = 1（装修贷）；点 全部 恢复 | 无回归 |
| 消费排行 Top10 | report_ranking_month.png；rank-item .length=10；前 3 名 .top3、其余 .other；rank-bar 宽度按占比 | 无回归 |
| Tab/FAB/Sheet 基本交互 | Tab 切换调 closeSheet + switchTab；FAB 点击 hide 自己并 openSheet；data-close + backdrop 关闭 | 无回归 |
| 添加卡片 Sheet | 类型 chip 单选；保存 push 到 cardsData + renderCards | 无回归 |

---

## 三、令牌纪律抽查（grep hex 颜色）

| 行号 | 选择器 | 值 | 性质 |
|------|--------|----|----|
| 131 | .fab | color:#fff | 白字 on primary（pre-existing） |
| 164 | .stored-card | color:#fff | 白字 on 渐变卡（pre-existing） |
| 165 | .stored-card | linear-gradient(135deg,#4F46E5,#4338CA) | DESIGN §2.4④ 唯一允许的 1 处品牌渐变 |
| 265 | .btn-primary | color:#fff | 白字 on primary（pre-existing） |
| 312 | .toast | color:#fff | 白字 on text-primary 黑底（pre-existing） |

- 12 条新增 CSS **全部** 使用 var(--space-*) / var(--color-*) / var(--radius-*) / var(--shadow-*) 令牌变量。
- 本次未引入任何**新的** hex 颜色、新的字号硬编码或新的圆角硬编码。
- 唯一非令牌数字 80px（⭐1 FAB 避让 padding-bottom 计算中的加数）出自 checklist 规范 calc(var(--space-4) + 80px)，与 FAB 视觉避让直接相关；不构成令牌违规（属 spec 例外）。

---

## 四、截图证据索引（19 张）

| 截图 | 关键验证点 |
|------|-----------|
| home.png | ⭐2/⭐3/⭐10：今天 ¥7,038.00 右对齐，与卡左缘对齐 |
| home_scrolled_bottom.png | ⭐1：更早 ¥3,356.30 / 超市 ¥156.30 完整可滚出 FAB |
| profile.png | 我的屏入口正常 |
| cards.png | 4 张卡片渲染正常（回归） |
| card_detail.png / card_validity.png | 卡片详情 + 有效期编辑（无有效期 Toggle） |
| periodic.png / periodic_settled.png | 周期屏 + 已结清筛选=1 |
| prepay.png | 提前还款二级 Sheet（hint/实时扣减） |
| report_month.png / report_week.png / report_year.png | ⭐4：柱高/折线/环形/环心/汇总随周期变 |
| report_ranking_month.png | 消费排行 Top10（回归） |
| search.png / filter_drawer.png / search_filtered_week.png | ⭐8/⭐11：搜索/抽屉/时间分组过滤 |
| record_sheet.png / record_saved.png / record_sheet_reset.png | ⭐5：记账 Sheet 初始 / 保存 / 重开回归初始 |

---

## 五、最终结论

- 12 条 ⭐ 必改：12/12 全部落实（代码 + 数值 + 视觉三重证据）
- 数值自洽：⭐4 4 套数据分类合计=支出、条宽和=100、结余=收入-支出 OK；⭐9 合计 12840、宽 78/9/10/3 和=100 OK；⭐10 今天组=7038 OK
- 回归项：提前还款 / 有效期编辑（无有效期 Toggle）/ 图片上传 / 已结清筛选 / 消费排行 Top10 / Tab·FAB·Sheet 均无破坏
- 令牌纪律：无新增 hex 色值/字号/圆角；80px 例外属 checklist 规范
- 视觉：真实 Chrome 截图对齐确认：group-header 与 card 左缘对齐、Toast 不压 header、占条配色=橙、筛选抽屉含时间分组、Sheet 重置回归

PASS —— 可进入导出环节（导出 PNG / PDF / 部署）。

---

## 六、复查脚本与产物

- verify_polish.js — Node VM 数值断言（32/32 PASS）
- cdp_shots.js — Chrome CDP 行为驱动（19 张截图 + 行为日志）
- _review_shots/ — 19 张 PNG 截图（见上节索引）