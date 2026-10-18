# 安卓版记账App · 开发计划（v16 · 账户资产模型重构）

> 状态：**批次 0 已完成**——4 Tab 壳、主题令牌、drift 8 表、Repository、单测、Android debug APK 已跑通；下一步批次 1（资产页 + 账户 CRUD）。
> 主设计：`doc/设计-账户资产模型.md` ｜ 视觉基准：`DESIGN.md`
> 四份 v16 实现文档已重写：数据模型 / UI架构 / 实现规格 / 交互规格。
> 原型状态：`记账-app/` 为 v15 历史原型；**v16 原型已建在 `记账-app-v16/`**（4 Tab + 资产/存单/记账 + 银行卡/储值卡/贷款添加编辑，金额输入 P0 已修复），用于 v16 视觉/交互验收。
> Flutter 工程：`jizhang-flutter/`。**顶层目录使用 ASCII**，因为 Windows 下 Gradle/Flutter shader 编译器无法在非 ASCII 工程路径构建；`lib/` 内文件仍按中文命名约定。

---

## 1. 需求边界（已确认）

| 项 | 结论 |
|---|---|
| 形态 | 自用安卓 App，本地安装 APK，不上应用市场 |
| 平台 | 仅安卓；目标 Android 16，minSdk 26（Android 8.0+） |
| 设备数 | 1 台主力设备；WebDAV 仅用于换机备份/防丢 |
| 数据 | 本地 SQLite（drift）为主 + WebDAV 备份（db+图片打包 zip） |
| 同步策略 | 备份式：手动 + 启动时距上次备份超 24h 自动触发；恢复=覆盖（恢复前自动备份当前库） |
| 记账图片 | 保留，随备份打包 |
| 记账日期 | 可自由选择，默认今天（支持补记） |
| 账户模型 | **账户中心**：现金/银行卡/电子钱包/储值卡/信用卡/存单/贷款 |
| 交易类型 | **仅收入/支出/转账**；删除 card/period/recharge 等特例 |
| 资产范围 | 电子存单、信用卡、房贷/车贷；投资/理财估值暂不做 |
| 删除规则 | 有流水账户只归档；类别删除归【其他】；资产交易 locked |
| UI 基准 | DESIGN.md 令牌，375dp 竖屏，仅浅色 |
| 命名 | 目录/文件中文，Dart 类名/变量英文 |
| 主框架 | 4 Tab：**首页 / 报表 / 资产 / 我的**（原“卡片”升级为“资产”） |
| 明确不做 | 预算提醒、投资行情、多币种、双向同步、后台自动记账 |

---

## 2. 技术栈（不变）

| 层 | 选型 |
|---|---|
| UI 框架 | Flutter（Dart） |
| 状态管理 | Riverpod |
| 路由 | go_router + StatefulShellRoute（4 Tab 壳 + 栈内跳转；Sheet 走 showModalBottomSheet） |
| 本地存储 | drift（类型安全 SQLite） |
| WebDAV | webdav_client（地址可配置） |
| 图表 | fl_chart |
| 图片凭证 | image_picker（拍照 + 相册；CAMERA 权限） |
| Excel 导入 | excel 包 + file_picker（仅 .xlsx） |
| 安全存储 | flutter_secure_storage（WebDAV 凭据，Keystore 加密） |

---

## 3. 工程结构

```
lib/
  主入口.dart            # 入口 + go_router 4 Tab Shell
  状态/
    提供者.dart          # Riverpod providers（仓库注入 + 页面 notifier）
  主题/
    令牌.dart            # DESIGN.md 令牌 → ThemeExtension（AppTokens）
    主题.dart            # ColorScheme/TextTheme/组件定制
  数据/
    数据库.dart          # drift 连接 + schemaVersion
    账户表.dart          # account
    交易表.dart          # transaction（income/expense/transfer）
    类别表.dart          # category
    卡片详情表.dart      # card_detail
    存单详情表.dart      # deposit_detail
    贷款详情表.dart      # loan_detail
    周期规则表.dart      # recurring_rule
    余额.dart            # 余额派生查询（辅助展示，不做净资产）
    仓库.dart            # 唯一数据出入口（交易/转账/资产动作/汇总）
  同步/
    webdav同步.dart      # 备份/恢复/保留5份/CRC/zip
  导入导出/
    excel导入.dart       # 收入/支出导入（账户映射）
  页面/
    首页.dart            # 概览 + 待办 + 最近流水 + 中央记一笔
    记账页.dart          # 支出/收入 Sheet（不出现转账）
    报表页.dart          # 收支 + 分类构成 + 趋势
    资产页.dart          # 卡片/存单/贷款列表（辅助）
    账户详情页.dart      # 余额/流水/上下文动作
    明细搜索页.dart      # 筛选
    周期账单页.dart      # 待办/规则
    类别管理页.dart
    我的页.dart
    设置页.dart          # 默认账户/WebDAV/删除默认
  组件/
    金额.dart            # ¥ + 千分位 + tabular-nums + fitAmount（分输入）
    流水项.dart
    账户项.dart
    进度条.dart
    图表.dart
```

---

## 4. 数据模型（八表 + 派生）

详细 DDL/字段/流程见 `doc/设计-账户资产模型.md` §4–§6。

| 表 | 作用 | 关键规则 |
|---|---|---|
| account | 账户 | type=cash/bank/ewallet/stored/credit/deposit/loan；资产正、负债负；不存 balance |
| transaction | 交易 | type=income/expense/transfer；转账 to_account 必填；group_id/locked |
| category | 类别 | 两级；【其他】固定；删除已用类别归【其他】；无 is_auto/【卡片】 |
| card_detail | 卡片详情 | 默认消费类别、有效期、信用额度/账单日/还款日 |
| deposit_detail | 存单详情 | 本金/利率/存期/到期/关闭/实际利息；状态派生 |
| loan_detail | 贷款详情 | 原始本金/利率/期限/下次还款/还款方式 |
| recurring_rule | 周期规则 | 计划，不是账户/流水；到期待办，手动生成交易 |
| settings | 设置 | WebDAV、default_account_id、del_category |

**派生公式**

```
账户余额 = 期初 + 收入 − 支出 + 转入 − 转出（仅辅助展示，不做净资产报表）
```

**支出口径（v16）**

- **支出 = 实际付出（消费 + 储值卡充值 + 还贷整笔 + 其他利息/费用）**；账户间转账不计支出。
- 储值卡充值=计支出；消费只扣余额、不再计支出；赠送=收入。
- 信用卡消费=支出，还款=转账（避免重复计支出）。
- 贷款月供**整笔计入支出**；不在界面拆本金/利息。
- 存单购买/到期本金=转账，利息=收入。
- 报表：收入/支出/结余 + 分类构成 + 趋势；不做真实成本/净资产。
- **记账 Sheet 只暴露支出/收入**；转账只由充值/存单/贷款/信用卡还款等资产动作内部生成。

**关键动作**

| 动作 | 生成交易 |
|---|---|
| 普通支出 | expense：account=付款账户 |
| 普通收入 | income：account=收款账户 |
| 转账 | transfer：account→to_account |
| 储值卡充值 | transfer 实付 + income 赠送（group） |
| 贷款还款 | transfer 本金 + expense 利息（group；报表支出计整笔） |
| 信用卡还款 | transfer 银行→信用卡 |
| 存单购买 | transfer 银行→存单 |
| 存单支取 | transfer 存单→银行 + income 利息（group，locked） |
| 存单转存 | income 利息到新存单 + transfer 本金到新存单（locked） |
| 周期账单 | 到期手动生成普通 expense/income |

---

## 5. 迭代计划（小步迭代，每批截图验证）

| 批次 | 内容 | 验收 |
|---|---|---|
| 0 | ✅ `flutter doctor` + 工程骨架（applicationId=com.self.jizhang）+ 主题令牌 + go_router 4 Tab Shell + v16 schema（8 表）+ Repository + 单测框架 + 中文命名 PoC | ✅ `flutter analyze` 0 issue；`flutter test` 6/6；`flutter build apk --debug` 成功 |
| 1 | 4 Tab 壳（首页/报表/资产/我的）+ 资产页：卡片/存单/贷款列表 + 添加账户 + 账户详情 | 账户 CRUD；余额正确 |
| 2 | 记一笔：支出/收入（不出现转账）+ 账户过滤 + 金额（分）+ 日期 + 图片 + 首页流水 + 明细搜索/筛选 | 两类交易落库；内部转账不计收支 |
| 3 | 储值卡（充值实付/赠送、消费、默认类别、余额核销）+ 信用卡（消费/还款/额度/账单日） | 充值/消费/还款余额与支出口径正确 |
| 4 | 电子存单：添加/详情/到期支取/提前支取/转存 + 首页 30 天提醒 | 本金不计收支；利息收入正确；状态边界正确 |
| 5 | 贷款：放款/还款/提前还款 + 周期账单规则/待办 | 月供整笔计支出；剩余本金正确 |
| 6 | 报表：周/月/季/年 + 收入/支出/结余 + 分类构成 + 趋势 | 与账户余额对账一致 |
| 7 | 类别管理 + Excel 导入（账户映射）+ 设置（默认账户/删除默认行为） | 类别删除/导入报告正确 |
| 8 | WebDAV：配置测通、备份/恢复、保留 5 份、CRC、凭据安全存储、24h 自动 | 上传→删本地→恢复成功（含图片） |
| 9 | 打磨：原型逐屏对照 + 真机验证 + 自签 release APK | 安装可用 |

---

## 6. 验收标准

- 每批 UI 与 v16 原型截图逐屏对照（组件级 + 关键视觉抽查）。
- **余额对账**：`期初 + 收入 − 支出 + 转入 − 转出` 与账户详情一致；不做净资产页面。
- **转账**：两边余额变化、收支报表不变。
- **储值卡**：充值计支出；消费只扣余额不再计支出；赠送计收入；归档前余额核销。
- **信用卡**：消费计支出；还款不计支出；欠款余额正确。
- **贷款**：月供整笔计入支出；剩余本金正确；界面不拆本金/利息。
- **存单**：购买/到期本金不计收支；利息收入正确；到期日当天=待处理；转存事务正确。
- **删除/归档**：有流水账户不能硬删；类别删除归【其他】；locked 交易不可在流水列表改删。
- **数据持久化**：重启不丢；金额整数分；无浮点落库。
- **Excel 导入**：模板校验、重复跳过、失败行报告、账户映射/默认账户。
- **WebDAV**：备份 zip 可下载、保留 5 份、恢复后数据+图片完整、损坏包不触碰本地。
- **金额铁律**：tabular-nums + 千分位 + 右对齐 + 禁止缩写 + fitAmount。

---

## 7. 设计文档索引（doc/）

| 文档/原型 | 状态 |
|---|---|
| `设计-账户资产模型.md`（v16 主设计） | **已确认** |
| `设计-数据模型.md`（v16 八表） | **v16 定稿** |
| `设计-卡片余额.md`（v15 双流水） | v15 历史参考 |
| `设计-删除联动.md`（v15 按卡型） | v15 历史参考 |
| `设计-Excel导入.md` | 定稿（需补账户映射） |
| `设计-WebDAV同步.md` | 定稿（新表随库备份） |
| `设计-UI架构.md`（v16） | **v16 定稿** |
| `设计-实现规格.md`（v16） | **v16 定稿** |
| `设计-交互规格.md`（v16） | **v16 定稿** |
| `设计-电子存单.md`（草案） | 已被账户模型吸收，待重写 |
| `设计-报表.md`（v16） | 已实现于 v16 原型 |
| `测试计划-v16.md` | **v16 测试计划 + 执行结果（114 PASS / 5 N/A）** |
| `原型复查报告.md` | v15 问题清单 |
| `../记账-app-v16/`（v16 原型） | 可运行；4 Tab + 资产/存单/记账 + 账户添加编辑 |
| `../jizhang-flutter/`（Flutter 实现） | **批次 0 完成**；analyze/test/APK 通过 |

---

## 8. 迁移说明

- 项目未上线，按 **greenfield** 处理：新 schema 直接 `schemaVersion=1`，不写旧数据迁移。
- 原型 mock 数据不迁移；Flutter 首版从空库 + 预设类别/默认账户开始。
- 备份恢复按整库替换，恢复后全局刷新。

---

**批次 0 已完成（2026-10-18）：Flutter 3.38.8 / Android SDK 36.1.0 / licenses 已接受；`flutter analyze` 0 issue、`flutter test` 6/6、`flutter build apk --debug` 成功。下一批：批次 1 资产页 + 账户 CRUD。**
