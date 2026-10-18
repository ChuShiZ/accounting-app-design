# 设计-UI架构（v16）

> 状态：v16 定稿 ｜ 原型：`../记账-app-v16/` ｜ 视觉基准：`DESIGN.md`
> 关联：`设计-账户资产模型.md`（账户/资产）、`设计-报表.md`（报表）、`ANDROID_PLAN.md`（批次）
> 目标：4 Tab + 统一 Sheet 体系；页面只消费状态/仓库，不直接散落业务规则。

---

## 1. 信息架构

```
底部 4 Tab
├─ 首页
│  ├─ 本月概览
│  ├─ 最近交易（点击打开编辑流水）
│  ├─ 搜索
│  └─ 待办入口
├─ 报表
│  ├─ 周报 / 月报 / 季报 / 年报
│  ├─ 支出 / 收入
│  ├─ 四项汇总
│  ├─ 趋势 / 分类构成 / 近 5 期对比 / 单笔排行
├─ 资产
│  ├─ 账户（银行卡/电子钱包）
│  ├─ 储值卡
│  ├─ 存单
│  ├─ 信用卡
│  ├─ 贷款
│  └─ 添加账户 / 账户详情
└─ 我的
   ├─ 设置（默认账户、WebDAV、备份恢复）
   ├─ 类别管理
   ├─ Excel 导入（后续批次）
   └─ 帮助与反馈（后续批次）
```

不出现：预算、净资产、投资行情、转账记账入口、多账户同步、后台自动记账。

---

## 2. 路由

### 2.1 Tab Shell

- Flutter：`StatefulShellRoute.indexedStack`，4 个独立导航栈，保留滚动位置。
- Vue 原型：`store.tab` / `store.tabBar` + `<section class="app-screen">`。
- 中央“记一笔”不是 Tab 页面，是底部中央按钮，打开 RecordSheet。

### 2.2 页面路由

| 路径 | 页面 | 说明 |
|---|---|---|
| `/` | 首页 | Tab |
| `/report` | 报表 | Tab |
| `/assets` | 资产 | Tab |
| `/profile` | 我的 | Tab |
| `/categories` | 类别管理 | push |
| `/settings` | 设置 | push |
| `/search` | 搜索/筛选 | 后续可并入首页 |
| `/import` | Excel 导入 | 后续批次 |
| `/ranking` | 全部排行 | 当前用报表内展开，暂不单独路由 |

### 2.3 Sheet 清单（不走路由）

| Sheet | 入口 |
|---|---|
| RecordSheet 记一笔/编辑流水 | 中央按钮、首页流水、报表排行、卡/贷款详情流水 |
| AddSheet 添加 | 资产页右上角 + |
| AccountFormSheet 账户编辑 | AddSheet、银行卡/储值卡详情、贷款详情 |
| DepositFormSheet | 添加存单/编辑存单 |
| DepositDetailSheet | 存单卡片 |
| DepositSettleSheet / DepositRenewSheet | 存单详情 |
| CardDetailSheet | 银行/储值/信用卡列表 |
| RechargeSheet | 储值卡详情 |
| CreditRepaySheet | 信用卡详情 |
| LoanDetailSheet / LoanRepaySheet | 贷款列表/详情 |
| CategorySheet | 类别管理 |
| DueSheet | 首页待办 |
| BackupSheet | 设置 → 恢复备份 |
| ConfirmDialog | 删除确认（全局） |

### 2.4 Sheet 层级

- 详情 → 编辑/充值/还款：**先关详情，再开表单**，不层叠。
- 删除确认是全局居中弹窗，不关闭当前 Sheet；确认后关闭。
- 所有 Sheet 顶部圆角 `radius-xl`，长表单近全屏（top 44px），底部操作栏固定。

---

## 3. 页面结构

### 3.1 首页

```
日期 / 我的账单        [待办 N]
今日支出（32px hero）
本月支出 / 本月收入
本月结余
搜索框
最近交易（按今天/昨天/日期分组）
  分类图标（24px，无底色，图标固定色）
  类别 / 备注 · 时间
  金额（收入绿、支出红、房贷橙）
```

- 点击流水 → 编辑流水 Sheet。
- 首页顶部只显示今天和本月概览；不做净资产。
- 组头右侧显示该日/组支出；储值卡消费显示但组总额不计。

### 3.2 报表

- 顶部标题「收支报表」。
- 下划线 Tab：周报 / 月报 / 季报 / 年报。
- 周期翻页 + 支出/收入切换。
- 四项汇总：本期、月均/日均、比上期、收支结余。
- 趋势：渐变面积 + 最高点气泡 + 横轴标签。
- 分类构成：环形图 + 最多 6 个外标签（左右列避让）+ 分类列表。
- 近 5 期对比柱状。
- 单笔排行：默认 8 条，可展开全部；点击流水编辑。
- 不展示 AI/月度/年度小结，不做订阅设置、自定义周期、子分类切换。

详见 `设计-报表.md`。

### 3.3 资产

```
资产                         [+]
账户
  招商银行卡 / 支付宝
储值卡
  银座购物卡
存单
  存单卡片（本金、预计利息、状态、进度）
信用卡
贷款
```

- 资产页 `+` → AddSheet，四个入口：存单、银行卡、储值卡、贷款。
- 银行/储值卡详情有「编辑」；储值卡另有「充值」。
- 贷款详情有「编辑」「还款」。
- 账户余额/贷款余额只辅助展示；不做净资产。
- 存单：添加、编辑、提前支取、到期支取、转存、删除。
- 信用卡：消费、还款；不在资产页添加（后续批次）。

### 3.4 我的

- 设置、类别管理、Excel 导入（占位）、帮助与反馈（占位）。
- 不展示账号/头像/登录；自用离线应用。
- 设置页：默认账户、WebDAV、立即备份、恢复备份、版本信息。

### 3.5 类别管理

- 支出/收入分段。
- 列表：分类图标（固定色）+ 名称 + 使用笔数 + 箭头。
- 新增/编辑 Sheet：名称、收支类型、图标选择器；编辑可删除。
- 图标选择器每个图标显示自己的颜色；同一图标全局同色。

---

## 4. 组件结构（Vue 原型 → Flutter）

| Vue | Flutter 对应 |
|---|---|
| `App.vue` | `主入口.dart` + Shell |
| `HomePage.vue` | `首页页.dart` |
| `ReportPage.vue` | `报表页.dart` |
| `AssetsPage.vue` | `资产页.dart` |
| `ProfilePage.vue` | `我的页.dart` |
| `CategoriesPage.vue` | `类别页.dart` |
| `SettingsPage.vue` | `设置页.dart` |
| `RecordSheet.vue` | `记一笔Sheet.dart` |
| `AccountFormSheet.vue` | `账户表单Sheet.dart` |
| `AddSheet.vue` | `添加Sheet.dart` |
| `Deposit*Sheet.vue` | `存单*Sheet.dart` |
| `CardDetailSheet.vue` | `账户详情Sheet.dart` |
| `RechargeSheet.vue` | `充值Sheet.dart` |
| `CreditRepaySheet.vue` | `信用卡还款Sheet.dart` |
| `Loan*Sheet.vue` | `贷款*Sheet.dart` |
| `CategorySheet.vue` | `类别编辑Sheet.dart` |
| `DueSheet.vue` | `待办Sheet.dart` |
| `BackupSheet.vue` | `备份Sheet.dart` |
| `ConfirmDialog.vue` | `确认删除弹窗.dart` |

---

## 5. 状态与数据流

### 5.1 原型（Vue）

```
组件 → store.js（reactive 状态 + 动作函数）
     → accounts / transactions / categories 内存数组
     → 页面 computed 自动刷新
```

- 原型数据刷新后重置；不是持久化实现。
- 账户编辑/交易编辑通过 `openAccountForm()` / `openRecord(txId)` 统一入口。

### 5.2 Flutter（目标）

```
Page(watch Riverpod) → ViewModel/Notifier → Repository → drift
                                            ↕
                                   WebDAV 备份/恢复
```

- `Provider<Repository>` 注入仓库单例。
- 页面级 `AsyncNotifierProvider`：首页、报表、资产、分类、设置。
- 交易/账户变更后 `invalidate` 相关 provider；恢复整库后全局刷新。
- 页面不直接拼 SQL；余额/报表由 Repository 聚合。

---

## 6. 主题与组件

- `AppTokens`（ThemeExtension）承载色板、圆角、间距、阴影、字号；禁止硬编码。
- ColorScheme：primary `#4F46E5`；income `#16A34A`；expense `#E5484D`；liability `#EA580C`；surface `#F7F8FA`；border `#E5E8EF`。
- 字体：标题 20/600、正文 15、说明 13、Tab 11；金额 `tabular-nums`、千分位、右对齐。
- 图标：
  - 线性 24px、stroke 1.8–2、round cap。
  - 分类图标**无底色**，颜色由图标 key 固定，同一图标全局同色。
  - 通用菜单/操作图标可用 primary。
- 卡片：白底、1px border、radius-lg、轻阴影；页面背景 surface。
- 设备：375dp 竖屏，仅浅色；原型高度 `clamp(667, calc(100vh - 48px), 812)`。
- BottomSheet：`showModalBottomSheet`；长表单近全屏；底部按钮固定且不遮挡内容。
- 分段控件：surface-2 容器 + 白色选中块。
- Toast：2 秒自动消失；确认：居中卡片弹窗。

---

## 7. 交互反馈

| 动作 | 反馈 |
|---|---|
| 保存流水 | Toast「已记一笔 …」 |
| 更新流水/账户 | Toast「已更新」 |
| 删除流水/类别/存单 | 二次确认 → Toast「已删除」 |
| 添加账户 | Toast「已添加银行卡/储值卡/贷款」 |
| 充值/还款/支取/转存 | 对应成功 Toast |
| 校验失败 | 具体原因；不关闭 Sheet |
| WebDAV 失败 | 「连接失败：{原因}」 |
| 备份/恢复 | 「备份成功」「恢复成功」 |

---

## 8. 空态/加载/危险态

- 首页无流水：线性图标 + 文案 + 记账按钮；搜索无结果文案区分「没有匹配记录」。
- 报表无数据：分类/排行显示「暂无记录」；趋势全 0 但不出现 NaN。
- 资产空分组：只显示有数据的分组；存单空态提示添加。
- 删除一律二次确认；删除按钮 danger 样式；取消不产生任何数据变化。
- 长表单底部按钮必须可见；内容区可滚动。
