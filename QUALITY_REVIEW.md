# 质量审查报告 · 移动端记账 App 原型

> 审查官：严过审（Yan）
> 待审文件：`accounting-app-prototype.html`
> 令牌基准：`DESIGN.md`（indigo-ledger v1，Stripe 靛 + iOS HIG，仅浅色）
> 判定：**PASS（22 / 25）** — 无 P0 / 无 Critical 级 Anti-Slop 违规，可进入导出

---

## 一、5 维度评分

| 维度 | 评分 | 一句话理由 |
|------|------|-----------|
| 设计哲学 Philosophy | **4/5** | Stripe 靛 + iOS HIG 方向贯穿一致、单浅色、令牌纪律好；唯一瑕疵是"Tab vs 栈"导航模型略散（周期性/搜索由菜单进入、我的→卡片管理不切 Tab 高亮）。 |
| 视觉层次 Hierarchy | **4/5** | 概览以"本月收入"为视觉主角、分组头 sticky、图表结构清晰；瑕疵为环形中心用了 `amount-lg` 而非规范 `amount-xl`，且分类占比条统一靛色（负债类未用橙）。 |
| 执行质量 Execution | **4/5** | 令牌化彻底、对齐整齐、tnum/千分位正确、Tab/Sheet/图表/Toast 均可用；瑕疵为筛选"时间/金额区间"未接入逻辑、安全区硬编码 20px 未用 `env()`、记账金额未重置。 |
| 特异性 Specificity | **5/5** | 紧扣记账场景：房贷/车贷剩余金额 + 进度条、储值卡渐变 + 余额、四态语义色、周期负债分类，毫无套模板感。 |
| 克制 Restraint | **5/5** | 全站仅 1 处渐变（储值卡）、无彩虹分类、无阴影滥用、无 emoji、圆角/色值严格走令牌、仅浅色、无装饰插画。 |

**总分：22 / 25 —— 所有维度 ≥ 3。**

---

## 二、Anti-Slop 检查清单（对照 DESIGN.md 第 3 节，逐条）

| # | 注意项 | 结果 | 证据 |
|---|--------|------|------|
| 1 | 过多渐变（仅储值卡 1 处） | ✅ 通过 | 仅 `stored-card` 第 165 行 `linear-gradient(135deg,#4F46E5,#4338CA)`，与规范完全一致 |
| 2 | 彩虹分类（每类一色） | ✅ 通过 | 徽章仅用 `badge--income/expense/liability/balance` 四态色，未按类别着色 |
| 3 | 阴影滥用 | ✅ 通过 | 阴影只出现在 card/overview/tabbar/fab/sheet/toast（均为 DESIGN 允许面），无滥用 |
| 4 | emoji 占位图标 | ✅ 通过 | 全部内联线性 SVG（`ICONS` 库），零 emoji |
| 5 | 金额比例字体（tnum/右对齐/千分位） | ✅ 通过（1 处例外 P1） | `.amount` 含 `tabular-nums`+右对齐；`fmt()` 用 `toLocaleString('zh-CN')` 千分位；仅环形中心缺 `.amount`（见 P1-3） |
| 6 | 高饱和撞色大色块 | ✅ 通过 | 语义色仅用于数字/徽章小面积，正文恒为中性色 |
| 7 | 圆角不一致 | ✅ 通过 | 严格走 sm/md/lg/xl/full 阶梯，仅 device 边框用 `calc(radius-xl*2.2)`（物理外壳） |
| 8 | 混入深色模式 | ✅ 通过 | 无 `dark:` 变体、无 `prefers-color-scheme: dark` |
| 9 | 装饰插画堆砌 | ✅ 通过 | 空态用 48px 线性图标 + 文案，无大插画 |
| 10 | Tab Bar 背景色块/胶囊高亮 | ✅ 通过 | 选中态为"图标+文字变色 + 顶部 2px 指示条"，无背景块 |
| 11 | 系统默认 alert 红滥用 | ✅ 通过 | 无整片红底，无危险态误用 |

**Anti-Slop 结果：11/11 通过，0 项违反。**

---

## 三、需求覆盖核对

| 需求 | 覆盖 | 位置 |
|------|------|------|
| ① 周期性支出（房贷/车贷/停车费/电话费）+ 房贷车贷剩余金额+进度条 | ✅ | `screen-periodic` / `renderPeriodic`（房贷 24/360 期、车贷 36/60 期，含 `remain` 与进度条） |
| ② 卡片实体（银行卡/购物卡/理发卡/自定义卡）+ 储值卡样式 + 余额 | ✅ | `screen-cards` / `renderCards`（4 类齐全，渐变卡 + 余额 + 有效期） |
| ③ 收支统计 + 周/月/季/年报表（趋势图 + 环形 + 明细） | ✅ | `screen-report`（分段控件 + SVG 趋势 + 环形 + 分类明细条） |
| ④ 首页列表 + 今日/本月支出 + 本月收入概览 + 搜索 | ✅ | `screen-home` 概览卡 + 分组流水 + 搜索框 |
| ⑤ 底部 4 Tab + 首页 FAB 半屏录入 | ✅ | `tabbar`（首页/报表/卡片/我的）+ `fab` + `#sheet-record` 半屏 Sheet |

---

## 四、总评

原型完成度很高，是**品牌级**水准而非 AI 套路产物：
- **强项**：四态语义色与储值卡渐变运用克制且精准；金额铁律（tnum/右对齐/千分位）系统性落实；图表与进度条数据自洽（环形 35.3% : 64.6% 与 ¥12,840 / ¥23,500 完全吻合）；令牌使用彻底，无硬编码色值/圆角。
- **风险点（均非阻塞）**：筛选抽屉"时间/金额区间"为装饰性控件未接入逻辑；安全区未用 `env()`；个别组件未完全贴合 DESIGN 字号/对齐细则。

**判定：PASS** —— 满足全部通过条件（5 维 ≥ 3 且无 Critical 级 Anti-Slop 违规），可进入导出。

---

## 五、修改清单

### P0（必须修复）：无

### P1（建议修复，非阻塞 — 建议导出前处理）
1. **筛选"时间/金额区间"未接入逻辑** —— `renderSearch()`（第 859–887 行）仅消费 `cat`/`type` 过滤；`time` 集合与时间芯片（第 645–649 行）未生效，金额 `min/max` 输入框（第 652–655 行）未绑定。建议：在 `renderSearch` 增加 time 映射（本月→group 对应、本季/年→扩展数据集）并读取两个 `number` 输入做区间过滤；或删去未实现控件以守住"克制"。
2. **安全区未用 `env()`** —— DESIGN §4 要求 `env(safe-area-inset-bottom)`。当前 `.tabbar` `height:calc(56px + 20px)`（第 107–112 行）、`.fab` `bottom:calc(56px + 16px + 20px)`（第 127–135 行）硬编码 20px。建议改为 `calc(56px + env(safe-area-inset-bottom, 20px))` 与 `calc(56px + 16px + env(safe-area-inset-bottom, 20px))`，真机才正确。
3. **环形中心金额缺 `.amount`（tnum 缺失）+ 字号不符规范** —— 第 439 行 `<div class="amount-lg amount--expense">¥12,840</div>` 未带 `.amount` 基类，故无 `tabular-nums`；且 DESIGN §8 规定环心用 `amount-xl`。建议改为 `class="amount amount-xl amount--expense"`（若 34px 在 170px 环内显拥挤可保留 `amount-lg` 但务必补 `.amount`）。

### P2（可选优化，锦上添花）
- **报表分段无数据变化**：周/季/年切换仅高亮（第 1004–1009 行），建议切换时重渲染对应数据集。
- **记账金额未重置**：保存/关闭后 `#record-amount` 保留上次值（第 989–1001 行），再开 Sheet 不归零；建议在 `closeSheet` 或 save 后重置为 `¥0.00`。
- **我的→卡片管理 Tab 高亮不跟随**：用 `data-nav`(showScreen) 而非 `switchTab`（第 497 行），导致进入卡片屏时 Tab 仍高亮"我的"；建议改用 `switchTab('screen-cards')`。
- **分组头组总额缺 `.amount`**：第 815 行 `fmt(sum)` 未加 `.amount`，数字不等宽；建议补 `.amount`。
- **图表轴标签缺失**：趋势图/环形未加 X 轴月份或周标签（DESIGN §8 要求 `caption` secondary 轴标签），可补。
- **Toast 与头部重叠**：`.toast top:52px`（第 311 行）压在 `app-header` 上；建议下移或置于 header 下方。
- **分组头/卡片水平对齐差 12px**：`group-header` 左 padding 4px（第 200 行）vs `group-card` 16px（第 205 行）；建议统一。
- **占比条语义与数据校准**：分类明细"周期负债"等统一靛色，负债类可改 orange 贴合四态；且各分类金额之和（14,160）≠ 本月支出（12,840），属演示数据不一致，建议校准。
