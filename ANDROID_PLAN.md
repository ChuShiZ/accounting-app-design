# 安卓版记账App · 开发计划（v13）

> 基于最新 Vue 原型 `记账-app/`（Vite + Vue 3，**页面布局基准**）与 `DESIGN.md`（令牌/组件规范），交付自用安卓App。早期 `accounting-app-prototype.html` / `原型-vue/` 已归档，不再作为 UI 基准。
> 状态：**计划待确认**——设计已定稿（见 `doc/`），未动工，等「确认开始」。
> 设计文档：`doc/README.md`（总览）+ 8 个子文档。

---

## 1. 需求边界（已确认）

| 项 | 结论 |
|---|---|
| 形态 | 自用安卓App，本地安装APK，不上应用市场 |
| 平台 | 仅安卓；目标设备 Android 16，minSdk 26（Android 8.0+） |
| 设备数 | 1 台主力设备；WebDAV 仅用于后期换机备份 |
| 数据 | 本地 SQLite（drift）为主 + WebDAV 备份（db+图片打包 zip） |
| 同步策略 | **A 备份式**：手动 + 启动时距上次备份超24h自动触发；恢复=覆盖（恢复前自动备份当前库） |
| WebDAV | 服务商可配置（地址/账号/密码手填） |
| 记账图片 | 保留，随备份打包 |
| 记账日期 | **可自由选择，默认今天**（支持补记） |
| 删除联动 | 常驻【其他】/【卡片】总分类；删除一律询问 + 可配置默认行为（默认保留） |
| UI基准 | DESIGN.md 设计令牌，375dp 竖屏，仅浅色 |
| 命名 | 目录/文件中文，Dart 类名/变量英文（批次0 PoC 验证） |
| 主框架 | 4 Tab：首页 / 报表 / 卡片 / 我的（设置/类别/导入/同步入口在「我的」，**无统计/无预算提醒**） |

## 2. 技术栈（已确认）

| 层 | 选型 |
|---|---|
| UI框架 | Flutter（Dart） |
| 状态管理 | **Riverpod**（声明式，依赖注入 + 自动刷新） |
| 路由 | **go_router + StatefulShellRoute**（4 Tab 壳 + 栈内跳转；Sheet 走 showModalBottomSheet） |
| 本地存储 | drift（类型安全 SQLite） |
| WebDAV | webdav_client（地址可配置） |
| 图表 | fl_chart（趋势图/环形图） |
| 图片凭证 | image_picker（拍照 + 相册；拍照需 CAMERA 权限，AndroidManifest 配置） |
| Excel导入 | excel 包 + file_picker（仅 .xlsx） |
| 安全存储 | flutter_secure_storage（WebDAV 凭据，Keystore 加密） |

## 3. 工程结构

```
lib/
  主入口.dart            # 入口 + 路由（go_router 4 Tab Shell）
  状态/
    提供者.dart          # Riverpod providers（仓库注入 + 页面级 notifier）
  主题/
    令牌.dart            # DESIGN.md 令牌 → ThemeExtension（AppTokens）
    主题.dart            # ColorScheme/TextTheme/组件定制
  数据/
    数据库.dart          # drift 连接
    流水表.dart          # 收支流水（cardId/periodId 双可空外键）
    类别表.dart          # 类别（【其他】/【卡片】常驻 + 预设 + 自定义 + 自动子分类）
    卡片表.dart          # 卡片（kind 三选一 + icon + 储值聚合）
    周期支出表.dart
    仓库.dart            # 唯一数据出入口（含聚合/导入/删除联动事务）
  同步/
    webdav同步.dart      # 备份/恢复/保留5份/CRC校验/zip打包
  导入导出/
    excel导入.dart       # 模板校验/去重/自动建类别
  页面/
    首页.dart            # 概览 + 流水 + 搜索 + FAB
    记账页.dart          # 半屏 Sheet 录入
    报表页.dart          # 周/月/季/年
    卡片管理页.dart
    周期支出页.dart
    明细搜索页.dart      # 筛选抽屉
    类别管理页.dart
    我的页.dart          # 入口：设置/类别/Excel导入/备份恢复
    设置页.dart          # WebDAV 配置 + 删除默认行为配置
  组件/
    金额.dart            # ¥ + 千分位 + tabular-nums + fitAmount（分输入）
    流水项.dart
    进度条.dart
    图表.dart
```

## 4. 数据模型（五表 + 聚合派生，金额一律整数分 int，DDL 见 doc/设计-数据模型.md v13）

| 表 | 关键字段 | 规则 |
|---|---|---|
| 流水表 | categoryId、type(income/expense/card/period/**recharge**)、amount(分)、note、createdAt、imagePath、**cardId/periodId 双可空外键**、**channel(bank 渠道,仅记录)**、**creditAmount(到账,仅recharge)** | CHECK 互斥+类型强绑定；充200送200：amount=200实付/credit=400到账 |
| 类别表 | name、icon、type、**parentId**、isPreset、isFixed、isAuto | 两级：id=1【其他】、id=2【卡片】(均 isFixed 禁删改)；卡片自动类别挂【卡片】下；UNIQUE(name,type) |
| 卡片表 | kind(bank/stored/custom)、icon、name、**defaultCategoryId(默认消费类别)**、isStoredValue、initialAmount、expireAt | 余额=initialAmount+Σ到账−Σ消费（聚合）；**不提供直接改余额**；充值=双流水；kind 强制储值属性；储值卡消费默认=defaultCategory（未配回退自动子分类） |
| 周期支出表 | **periodType(term/recurring)**、kind、name、totalAmount/totalCount(term)、perAmount/frequency(recurring)、initialPaidCount/Amount、startAt、nextDueAt、status | term：进度/还款/提前还款/自动结清；recurring：每期金额+频率，扣款记普通支出 |
| 设置表 | key/value（KV） | WebDAV配置+删除默认行为，**随备份携带**；密码入 Keystore，备份时间戳入 shared_preferences |

**派生量（不建表，运行时聚合）**：卡片余额、已还期数、已还金额、剩余金额、还款进度——单一数据源，删流水自动正确。

**统计口径（D9/D13/D14，ADR-020 红利简化）**：支出 = `expense + period`（纯 type 判断——银行卡消费已是 expense+channel、储值卡充值已是 expense、储值卡消费 type=card 不计、recharge 不计）；收入 = income；环形图/Top10 按支出口径聚合类别。**充值=双流水职责分离**：expense（实付，永久计支出）+ recharge（creditAmount 到账，虚空驱动余额）；删储值卡虚空随删、支出流水询问保留（默认保留，**归【卡片】(2)**），无需类型转换。

**记账 Sheet 账户选择（原型还原）**：账户 = **默认账户虚拟卡 + 卡片列表**（无现金，ADR-023）；选默认账户 → **expense+channel=bank（类别正常选，渠道仅记录）**；选银行卡（非储值）→ **expense+channel=bank**；选储值卡 → **card+card_id（默认卡片子分类可切换）**；收入恒 income 不挂卡。

**删除联动（已定，按卡型）**：删除类别→询问删/保留（保留则归【其他】）；删除有还款流水的周期支出→询问+可配置默认；**储值卡**：虚空流水（recharge+消费）随删、充值支出询问保留（归【卡片】(2)）；**非储值卡**：直接删（消费是 expense+channel，无虚空流水）；自动类别随实体回收。详见 `doc/设计-删除联动.md`。

## 5. 迭代计划（小步迭代，每批截图验证）

| 批次 | 内容 | 验收 |
|---|---|---|
| 0 | **环境检查（flutter doctor）+ 工程骨架（applicationId=com.self.jizhang）+ 主题令牌映射（AppTokens）+ 路由骨架（go_router 4 Tab Shell）+ 数据层（schemaVersion=1+迁移预案+仓库+约束）+ Repository 单测框架 + 中文命名PoC** | 编译通过，单测跑通 |
| 1 | 4 Tab 框架 + 首页：概览卡 + 流水分组 + 搜索框 + FAB（mock 数据渲染）；**流水列表=全部明细（含储值卡消费），recharge 仅卡片内展示** | 与原型截图对比一致 |
| 2 | 记账：半屏 Sheet + 金额输入(分) + **账户/卡片选择（默认账户→expense+channel；银行卡→渠道；储值卡→card 默认子分类可切换）+ 类别随收支联动 + 日期自由选择默认今天** + 图片凭证（拍照+相册，CAMERA 权限）+ 保存落库 + 流水编辑/删除 | 保存/编辑/删除后首页刷新 |
| 3 | 报表：周/月/季/年分段 + **汇总卡2×2（支出/日均/环比/结余）** + 环形图 + **分类明细占比条** + 消费排行 Top10 + 趋势图 | 4 套数据联动正确 |
| 4 | 卡片管理：储值卡余额聚合 + **新增卡片（类型三选：bank/stored/custom，kind→储值属性强制；custom 显储值开关默认开；图标创建可换；默认消费类别选择器）+ 编辑 kind 提示统计口径变化** + **充值（双流水：expense 支出永久 + recharge 余额虚空，支持赠送；编辑=统一表单同步两条；删除=成对删除）+ 删卡（储值卡：虚空随删/支出询问保留归【卡片】；非储值卡：直接删）** + 有效期编辑 + 消费记录（记账Sheet选卡片 + 卡片详情快捷） | 充值余额增加，删卡支出保留，口径正确 |
| 5 | 周期支出：**两形态（term 进度/还款/提前还款/自动结清；recurring 频率/扣款记普通支出）** + 删除联动（自动类别） | 两形态增删改正确；期数计法=1笔1期；结清禁录还款 |
| 6 | 明细搜索：**关键词搜索（备注/类别/卡片名模糊匹配）** + 筛选抽屉（类别/类型/时间/金额）；**范围同首页（recharge 仅卡片内）** | 搜索+筛选叠加结果正确 |
| 7 | 类别管理：预设 + 自定义 + 【其他】/【卡片】保护 + 删除联动 | 删除询问/归集正确 |
| 8 | Excel 导入：按 `doc/设计-Excel导入.md` 实现（校验/去重/自动建类别/报告） | 导入数据正确落库 |
| 9 | 我的页（**入口列表，无统计/无预算提醒**）+ 设置页 + WebDAV：配置测通、备份/恢复、保留5份、CRC校验、凭据安全存储、24h自动 | 上传→删本地→恢复成功（含图片） |
| 10 | 打磨：原型已知瑕疵(P2) + 真机验证 + 自签 release APK（应用名默认"记账"+主色图标，可指定） | 安装可用 |

## 6. 验收标准

- 每批 UI 与原型截图逐屏对照（组件级对照 + 关键视觉抽查），通过才进下一批
- **Repository 单测通过**：聚合公式（卡片余额/期数/剩余金额）、删除联动事务、Excel 导入校验/去重
- 数据持久化：重启数据不丢；金额无浮点误差（分存储）
- 数据完整性：删除联动按 `设计-删除联动.md` 生效（含保留路径 FK 不悬空）；卡片余额随流水变化自动一致
- Excel 导入：模板校验正确、重复跳过、失败行有报告
- WebDAV：备份 zip 可下载、保留5份、恢复后数据+图片完整、损坏包不触碰本地
- 金额铁律：tabular-nums + 千分位 + 右对齐 + 禁止缩写

## 7. 设计文档索引（doc/）

| 文档 | 状态 |
|---|---|
| README.md（总览 + 决策索引 + ADR） | 定稿 |
| 设计-数据模型.md（五表 DDL + 聚合派生 + 种子数据） | 定稿（v14） |
| 设计-卡片余额.md | 定稿（双流水聚合） |
| 设计-删除联动.md | 定稿（按卡型区分 + 自动类别回收） |
| 设计-Excel导入.md | 定稿 |
| 设计-WebDAV同步.md | 定稿 |
| 设计-UI架构.md（Riverpod + go_router + 主题映射 + 工程配置） | 定稿 |
| 设计-实现规格.md（图标映射 + 记账 Sheet 交互 + Repository 接口） | 定稿 |
| 设计-交互规格.md（充值表单 + 删除交互体系 + 二级 Sheet + 导入报告） | 定稿 |

---
**动工前提：① 用户明确说「确认开始」；② 批次0 环境检查通过。**
