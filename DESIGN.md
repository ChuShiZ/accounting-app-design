# DESIGN.md — 移动端记账 App「现代简约·财务可信」设计系统

> 基准系统：**Stripe（靛信任色 + 数据极简）** 为视觉与色彩基石，叠加 **Apple iOS HIG** 原生移动范式（Tab Bar / 底部 Sheet / 安全区 / 系统字体），以 **Coinbase（纯蓝信任）** 为可选备选色相。
> 平台：原生 iOS/Android，375–430dp 竖屏，单手热区；仅浅色，不做深色模式。

---

## 1. 候选系统推荐

| 方案 | 设计系统 | 匹配度 | 核心特征 | 适合原因 |
|------|---------|--------|---------|---------|
| **A（最终基准）** | **Stripe** | ★★★★★ | 靛蓝 `#635BFF` 信任色、极低装饰、数据优先排版、强数字层级 | 完美命中"现代简约·财务可信"+"单一靛信任色"；金融级可信度与克制度 |
| B | **Coinbase** | ★★★★☆ | 纯蓝 `#0052FF`、极简白底、移动友好、清晰层级 | 若主理人更偏好"蓝"而非"靛"，可直接替换主色相，其余令牌不变 |
| C | **Apple (iOS HIG)** | ★★★★☆ | 原生 Tab Bar / 底部 Sheet / SF 字体 / 安全区 | 提供原生移动组件语法（非色相基准），保证 iOS/Android 交互惯例一致 |

**最终选定基准：Stripe（色相/哲学）+ Apple（原生组件范式）融合。**
靛主色取 Stripe 意象但修正为可访问的 `#4F46E5`（indigo-600，白底对比 5.9:1 ≥ AA），避免因 `#635BFF` 过浅导致正文/按钮不达标。

---

## 2. 设计令牌（Design Tokens）

### 2.1 Color Palette

#### 中性色阶（低饱和、冷调以呼应靛）
| Token | HEX | OKLCh(近似) | Usage |
|-------|-----|------|-------|
| `--color-bg` | `#FFFFFF` | oklch(100% 0 0) | 页面背景 |
| `--color-surface` | `#F7F8FA` | oklch(97.5% 0.003 260) | 卡片/分区底色 |
| `--color-surface-2` | `#F1F3F7` | oklch(96% 0.004 260) | 输入框/进度轨道/次级底 |
| `--color-border` | `#E5E8EF` | oklch(93% 0.006 260) | 描边、卡片边框、分隔 |
| `--color-divider` | `#F0F2F6` | oklch(96.5% 0.004 260) | 列表行内细分隔（比 border 更轻）|
| `--color-border-strong` | `#D2D7E2` | oklch(89% 0.008 260) | 输入框 focus 边框 |
| `--color-text-primary` | `#1A1D29` | oklch(22% 0.01 270) | 标题、正文、金额 |
| `--color-text-secondary` | `#6B7280` | oklch(55% 0.01 270) | 时间/备注/次要（白底对比 4.8:1 ✓ AA）|
| `--color-text-disabled` | `#A6ADBB` | oklch(73% 0.006 270) | 禁用、占位（仅装饰，不需 AA）|

#### 单一信任主色（靛 / Indigo，主·浅·深三档）
| Token | HEX | OKLCh(近似) | Usage |
|-------|-----|------|-------|
| `--color-primary` | `#4F46E5` | oklch(52% 0.22 265) | CTA、选中态、链接、主色文字（白底 5.9:1 ✓）|
| `--color-primary-hover` | `#4338CA` | oklch(46% 0.21 265) | 按压/深色态（白底 8.6:1 ✓）|
| `--color-primary-light` | `#EEF2FF` | oklch(96% 0.03 265) | 选中底、浅填充、徽章底 |
| `--color-primary-soft` | `#C7D2FE` | oklch(85% 0.08 265) | 浅色描边、图表辅助线 |

#### 四态语义色（收入/支出/负债/余额）— 小面积使用，正文保持中性
| 状态 | 主色 HEX | 浅底 HEX | 用途 |
|------|---------|---------|------|
| 收入 income | `#16A34A` | `#ECFDF3` | 收入金额、结余为正、成功态 |
| 支出 expense | `#E5484D` | `#FEECEC` | 支出金额（克制红，仅数字与徽章）|
| 负债 liability | `#EA580C` | `#FFF1E6` | 房贷/车贷/周期扣款金额、还款进度 |
| 余额 balance | `#4F46E5` | `#EEF2FF` | 储值卡余额（复用主色，保持色相纪律）|

> 状态色复用：success=`#16A34A`、warning=`#EA580C`、danger=`#E5484D`、info=`#4F46E5`。全站仅 4 个色相（靛+绿+红+橙），无第五色，杜绝彩虹。

### 2.2 Typography

**字体栈（移动端原生 + 中文回退）**
```css
--font-sans: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display",
             "Roboto", "Helvetica Neue", "PingFang SC", "Microsoft YaHei",
             "Noto Sans SC", "Source Han Sans SC", sans-serif;
--font-num:  var(--font-sans);  /* 数字复用同栈，靠 font-feature 启用等宽 */
```
数字强制等宽：`font-variant-numeric: tabular-nums lining-nums; font-feature-settings: "tnum" 1, "lnum" 1;`

**字号阶（dp/px，移动基准）**
| Token | 尺寸 | 字重 | 行高 | 用途 |
|-------|------|------|------|------|
| `--text-amount-xl` | 34px | 700 | 1.10 | 概览本月/今日支出、报表合计 |
| `--text-amount-lg` | 22px | 600 | 1.20 | 流水每条金额（右对齐 tnum）|
| `--text-amount-md` | 17px | 600 | 1.30 | 卡片余额、表单输入金额 |
| `--text-h1` | 20px | 600 | 1.30 | 页面标题、Sheet 标题 |
| `--text-h2` | 17px | 600 | 1.35 | 分组标题（今天/昨天/更早）、卡片标题 |
| `--text-body-lg` | 16px | 500 | 1.50 | 按钮文字、重要正文 |
| `--text-body` | 15px | 400 | 1.50 | 类别名、备注、列表正文 |
| `--text-caption` | 13px | 400 | 1.40 | 时间、次要元数据（secondary 色）|
| `--text-micro` | 12px | 500 | 1.30 | 标签、徽章、单位（¥/期）|

**金额铁律**：`text-align:right` + `tabular-nums` + 千分位（`Intl.NumberFormat('zh-CN')`，`¥` 前缀同字号、字重可降一档）。

### 2.3 Spacing / Radius / Shadow

**间距（4/8 基准）**
`--space-1:4px --space-2:8px --space-3:12px --space-4:16px --space-5:20px --space-6:24px --space-8:32px --space-10:40px --space-12:48px`

**圆角（分级，严禁混用）**
`--radius-sm:6px`（徽章/标签/小输入） · `--radius-md:10px`（按钮/输入/行） · `--radius-lg:16px`（卡片/分组） · `--radius-xl:20px`（大卡/Sheet 顶/弹层） · `--radius-full:999px`（FAB/头像/胶囊）

**阴影（弱装饰：默认扁平+1px边框，阴影只给浮层）**
| Level | Value | Usage |
|-------|-------|-------|
| none | `none` | 默认表面 |
| xs | `0 1px 2px rgba(16,24,40,.04)` | 卡片微分离 |
| sm | `0 1px 3px rgba(16,24,40,.06)` | Tab Bar 顶边、分组卡 |
| md | `0 4px 12px rgba(16,24,40,.08)` | 浮层、Popover |
| lg | `0 8px 24px rgba(16,24,40,.10)` | 底部 Sheet、Modal |
| fab | `0 6px 16px rgba(79,70,229,.35)` | FAB 主色光晕 |

### 2.4 Component Styles

**① 底部 Tab Bar（4 项：首页/报表/卡片/我的）**
- 高 56px + `env(safe-area-inset-bottom)`；底白、顶 `1px --color-border` + `--shadow-sm`。
- 每项：线性图标 24px（stroke 2）+ 文字 11px/500；命中区 ≥48×48。
- 未选：`--color-text-secondary`；选中：图标+文字 `--color-primary`，顶部加 2px×20px 圆角指示条（radius 1px）。**不用背景色块/胶囊高亮**（保持极简）。
- 分屏之间无竖线分隔。

**② 悬浮按钮 FAB（"+" 记账）**
- 固定：`right:16px; bottom: calc(56px + safe-area-inset-bottom + 16px)`；仅首页（Sheet 打开时隐藏）。
- 56×56，`--radius-full`，`--color-primary` 底，白"+" 24px（stroke 2.5），`--shadow-fab`。
- 按压：`--color-primary-hover` + `scale(.96)`；点击触发**半屏底部 Sheet**（覆盖 ~85% 高，顶 `radius-xl`，含拖拽把手）。

**③ 进度条（周期 已还/剩余/总期数）**
- 轨道：`--color-surface-2`，高 8px，`radius-full`；填充：`--color-liability`(橙) 表"已还进度"，宽=百分比。
- 上方标签行：左"已还 24 期" / 右"剩余 36 期 · 58%"（`--text-caption`）；下方"剩余金额 ¥xxx"（`--text-amount-md` 橙）。
- 变体：行内细版高 4px；详情页标准版高 8px。

**④ 卡片组件（三型统一基座）**
- 基座：白底、`1px --color-border`、`--radius-lg`、padding 16px、`--shadow-xs`（或无阴影仅边框）。
- **流水项**：左 40px 圆角-full 徽章（浅底+20px 线性图标）→ 中（类别 `--text-body` / 备注·时间 `--text-caption` secondary）→ 右金额 `--text-amount-lg` 按状态着色、右对齐 tnum。行 padding 12px 16px。
- **概览卡**：`--radius-xl`，含 3 指标（今日/本月支出、本月收入），大数 `--text-amount-xl`。
- **卡片实体（储值卡）**：全站**唯一**允许的 1 处 2-stops 品牌渐变 `linear-gradient(135deg,#4F46E5,#4338CA)`；白字：名称/类型徽章/余额 `--text-amount-md`/有效期 `--text-caption`。

**⑤ 列表分组**
- 组头（今天/昨天/更早）：sticky，`--text-caption` 600 secondary，右侧可附组总额；padding 12px 16px，无卡（读作分区）。
- 组内：单张 `--radius-lg` 白卡包裹多行，行间 `1px --color-divider`，首尾行裁切贴合圆角。

**⑥ 搜索 + 筛选抽屉**
- 搜索框：高 40px，`--radius-md`，底 `--color-surface-2`，左 18px 搜索图标，占位 `--text-body` secondary；focus → 边框 1.5px `--color-primary`、底白。右侧"筛选"按钮（图标+13px）开抽屉。
- 筛选抽屉（底部 Sheet，`radius-xl` 顶）：类别/类型/时间/金额区间用 `--radius-sm` 芯片多选（选中=primary-light 底+primary 文字+primary 边框）；底部"重置/应用"双按钮。

**⑦ 周期切换（周/月/季/年）— 分段控件**
- 胶囊容器 `--color-surface-2`，高 36px，`--radius-full`；4 段，选中段白底+`--shadow-xs`+primary 文字，未选 secondary。

**⑧ 图表占位规范**
- 容器：白卡 `--radius-lg`，最小高 200px。
- 折线/柱状：浅网格线 `--color-divider`；主序列 `--color-primary`，对比序列用 `--color-liability`；最多 2 序列，无重渐变。
- 环形：外圈 `border:12px --color-divider`，主弧 `--color-primary`；中心放总额 `--text-amount-xl`；图例为小行（色点+标签+金额）。
- 轴标签 `--text-caption` secondary。

**⑨ 空 / 加载 / 成功 / 危险态**
- 空态：居中 48px 线性图标（secondary 浅底）+ 标题 17px/600 + 描述 13px secondary + 可选 primary 幽灵按钮"去记账"。**不用大插画**。
- 加载：骨架屏（块 `--color-surface-2`，可加极淡移动微光，仅 loading 用）；行内 spinner 24px primary。
- 成功：顶部 Toast，底 `#1A1D29`+白字+对勾，`radius-md`，`--shadow-md`，2s 自动消失；或保存后勾选动画再关 Sheet。
- 危险（删除/清空）：底部 alert Sheet，取消（secondary）+ 删除（`--color-danger` 文字/边框，限按钮），不整片红底。

### 2.5 Icons
- 风格：**线性（outline）为主**，stroke 1.75–2px、圆头圆角、24px 栅格；`stroke=currentColor` 以继承文字/语义色。
- 类别图标：40px 圆角-full 浅底徽章 + 20px 线性图标（中性灰或按四态语义着色，**禁用每类一色**）。
- 统一图标集（SF Symbols / Material Symbols / Lucide 风格）；FAB"+"用稍重 stroke。
- **禁止 emoji 占位**。

---

## 3. Cautions（Anti-Slop 注意）

- ❌ 过多渐变：仅卡片实体 1 处 2-stops 品牌渐变，其余纯色/描边。
- ❌ 彩虹分类：类别图标统一中性灰底+单色线图标，或按四态语义着色，而非每类一色。
- ❌ 阴影滥用：默认扁平+1px 边框；阴影只给 FAB / 底部 Sheet / 浮层。
- ❌ emoji 占位图标：用统一线性图标集。
- ❌ 金额比例字体：必须 `tabular-nums`、右对齐、千分位。
- ❌ 高饱和撞色大色块：语义色只用于小面积数字/徽章，正文文本保持中性。
- ❌ 圆角不一致：严格用 sm/md/lg/xl/full 阶梯。
- ❌ 混入深色模式：本期仅浅色，不写 `dark:` 变体。
- ❌ 装饰插画堆砌：空态用线性图标，不放大图。
- ❌ Tab Bar 背景色块/胶囊高亮：用颜色+顶部指示条，保持极简。
- ❌ 系统默认 alert 红滥用：危险操作用 `--color-danger` 仅限按钮文字/边框。

---

## 4. Responsive / 移动适配

- 设计基准 375dp，覆盖至 430dp（iPhone Pro Max）；单列竖屏。
- 安全区：`padding-top: env(safe-area-inset-top)`（状态栏）、`padding-bottom: env(safe-area-inset-bottom)`（Tab Bar/FAB）。
- 单手热区：主操作（FAB、Tab、主按钮）落在屏幕下 1/3；次级操作上置。
- 断点仅作 dp 微调：`<375` 缩 `--space-4`→12px、金额 `--text-amount-lg`→20px；`>414` 放宽外边距至 `--space-5`。不引入横屏/平板布局（本期原生竖屏）。

---

## 5. Agent Prompt Guide + 给原型构建师的使用说明

### Key Instructions
- 所有颜色/间距/圆角/字号一律走 CSS 变量，禁止硬编码新值。
- 金额组件封装为独立原子：传入 `value` + `state(income|expense|liability|balance)`，内部负责 `¥`+千分位+`tabular-nums`+右对齐+状态色。
- 语义色只上数字与徽章；列表正文/标题永远中性色。
- 任何表面默认 `border + 无阴影`；仅 FAB/Sheet/Toast/Popover 加阴影。

### 直接消费的 :root 速查
```css
:root{
  --color-bg:#FFFFFF; --color-surface:#F7F8FA; --color-surface-2:#F1F3F7;
  --color-border:#E5E8EF; --color-divider:#F0F2F6; --color-border-strong:#D2D7E2;
  --color-text-primary:#1A1D29; --color-text-secondary:#6B7280; --color-text-disabled:#A6ADBB;
  --color-primary:#4F46E5; --color-primary-hover:#4338CA; --color-primary-light:#EEF2FF; --color-primary-soft:#C7D2FE;
  --color-income:#16A34A; --color-income-bg:#ECFDF3;
  --color-expense:#E5484D; --color-expense-bg:#FEECEC;
  --color-liability:#EA580C; --color-liability-bg:#FFF1E6;
  --color-balance:#4F46E5; --color-balance-bg:#EEF2FF;
  --radius-sm:6px; --radius-md:10px; --radius-lg:16px; --radius-xl:20px; --radius-full:999px;
  --space-1:4px; --space-2:8px; --space-3:12px; --space-4:16px; --space-5:20px; --space-6:24px; --space-8:32px; --space-10:40px; --space-12:48px;
  --shadow-none:none; --shadow-xs:0 1px 2px rgba(16,24,40,.04); --shadow-sm:0 1px 3px rgba(16,24,40,.06);
  --shadow-md:0 4px 12px rgba(16,24,40,.08); --shadow-lg:0 8px 24px rgba(16,24,40,.10); --shadow-fab:0 6px 16px rgba(79,70,229,.35);
  --font-sans:-apple-system,BlinkMacSystemFont,"SF Pro Text","SF Pro Display","Roboto","Helvetica Neue","PingFang SC","Microsoft YaHei","Noto Sans SC","Source Han Sans SC",sans-serif;
}
```

### 6 屏令牌映射表（原型构建师直用）
| 屏 | 主要组件 | 所用令牌 |
|----|---------|---------|
| ① 首页 | Tab Bar(选中=首页) / 概览卡 / 流水列表(今天·昨天·更早) / 搜索框 / FAB | primary-light(选中底)、amount-xl(概览)、amount-lg+四态色(流水)、surface-2(搜索框)、FAB(primary+shadow-fab) |
| ② 记账页 | 半屏 Sheet / 金额输入 / 类别 chips / 保存按钮 | radius-xl(Sheet 顶)、shadow-lg、amount-md tnum(输入)、radius-sm chips(选中 primary-light)、primary 按钮 |
| ③ 周期性支出 | 分组卡 / 进度条 / 详情 | radius-lg(卡)、liability 橙(进度填充+剩余金额)、caption(期数标签) |
| ④ 卡片管理 | 卡片实体 / 消费记录列表 / 有效期 | 唯一渐变(primary→primary-hover)、balance 白字 amount-md、divider(行)、caption(有效期) |
| ⑤ 统计报表 | 分段控件(周月季年) / 趋势图 / 环形 / 明细 | surface-2(分段底)、primary+liability(序列)、divider(网格)、amount-xl(环心) |
| ⑥ 明细搜索 | 搜索框 / 筛选抽屉(chips) / 结果列表 | surface-2(搜索)、radius-xl(Sheet)、radius-sm chips、复用流水项(amount-lg+四态) |

> 所有 6 屏共享同一令牌层；差异化仅来自组件组合与四态语义着色，确保"弱装饰、强数据、低学习成本"。
