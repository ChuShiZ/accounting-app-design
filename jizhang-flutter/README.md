# jizhang · 记账（Flutter）

> 自用离线安卓记账 App。主设计：`../doc/设计-账户资产模型.md`；视觉基准：`../DESIGN.md`。
> 当前进度：**首页 / 记一笔 / 报表 / 资产 / 存单 / 信用卡 / 贷款 / 类别 / 设置主体完成**；WebDAV 与 Excel 导入仍按原型保留演示入口。

## 环境

- Flutter 3.38.8 / Dart 3.10.7
- Android SDK 36.1.0；minSdk 26；targetSdk 36
- applicationId：`com.self.jizhang`
- 显示名：记账
- 依赖：drift、riverpod、go_router、lucide_icons、image_picker

> 工程顶层目录使用 ASCII `jizhang-flutter/`。Windows 下 Gradle/Flutter shader 编译器无法在包含非 ASCII 的工程路径构建；`lib/` 内部文件名仍按中文约定。

## 已实现

### 基础

- 主题令牌：`lib/主题/令牌.dart`、`lib/主题/主题.dart`
- 线性图标：`lucide_icons`（与 DESIGN.md 的 Lucide 线性风格一致；MaterialIcons 的 CFF3 字体在 MuMu Android 12 上显示为 tofu，已替换）
- 4 Tab 壳 + 中央「记一笔」：`lib/路由/路由.dart`、`lib/组件/主壳.dart`
- 8 张 drift 表：account / transaction / category / card_detail / deposit_detail / loan_detail / recurring_rule / settings
- 数据库：`lib/数据/数据库.dart`（schemaVersion=2；新增 `reportable`）
- Repository：账户、交易、类别、报表、设置、资产动作
- Riverpod providers：`lib/状态/提供者.dart`
- 种子类别：首次启动写入 13 个支出 + 6 个收入预设类别

### 首页与流水

- 今日支出 / 本月支出 / 本月收入 / 结余
- 最近交易按日期分组、搜索类别/备注/账户、组内支出合计
- 待办气泡：30 天内存单、7 天内信用卡还款、贷款下次还款；点入账户详情
- 记一笔：支出/收入、金额（分）、类别、账户（不显示余额）、日期、备注、图片凭证（拍照/相册）
- 流水编辑/删除，余额和报表自动回退；资产动作流水锁定不可单独改删
- 类别固定颜色 + 24px Lucide 图标

### 报表

- 周报 / 月报 / 季报 / 年报；收入/支出切换；上一期/下一期
- 4 个汇总指标；趋势图；分类环形图（最多 6 个外部标签，自动避让）+ 分类列表
- 近 5 期对比；流水排行（前 8 / 全部）；分类筛选
- 不包含 AI 总结或自动摘要

### 资产

- 资产页：账户 / 储值卡 / 存单卡片 / 信用卡 / 贷款分组；存单空态和添加入口
- 银行卡、储值卡、信用卡、贷款 CRUD；存单添加/编辑/详情
- 储值卡充值（实付+赠送）、默认消费类别；消费不重复计支出
- 信用卡消费计入支出；还款为转账不计支出；额度/账单日/还款日
- 贷款整笔月供计支出；内部本金回补不计收入；还款后下次还款日 +1 月
- 存单购买本金转账不计收支；到期/提前支取；转存；利息计收入；30 天提醒
- 账户删除：无流水硬删；有流水归档；历史保留

### 类别与设置

- 类别管理：支出/收入切换、新增/编辑、名称/图标、已用笔数
- 删除已用类别归入【其他】；固定类别不可删除/改名/改类型
- 设置：默认记账账户（记一笔默认选中）、WebDAV 配置、连接校验、备份记录、恢复确认、自动备份开关
- 我的：设置、类别管理、Excel 导入/帮助入口

### 测试

- `flutter analyze` 0 issue
- `flutter test` 23/23（16 个仓库/业务测试 + 7 个 Widget 测试）
- 已用 x86_64 debug APK 在 MuMu Player 12（Android 12 / API 32）安装启动，手工验证：添加银行卡/储值卡/信用卡/存单、记账、流水编辑、充值、储值卡消费、信用卡还款、存单支取、报表、类别管理、设置页、图片选择入口
- 尚未在 arm64 真机安装验证

## 命令

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
# MuMu 模拟器（x86_64）：
flutter build apk --debug --target-platform android-x64
```

Debug APK：`build/app/outputs/flutter-apk/app-debug.apk`

## 已知 / 未接入

- WebDAV 仅完成配置、校验、备份记录与恢复确认的交互原型；真实上传/下载/zip 打包与 Keystore 凭据存储未接入。
- Excel 导入入口仍为原型提示，未接入 `.xlsx` 解析与账户映射。
- 周期账单规则表已建，但尚无规则 UI。
- 当前只创建 Android 平台；已在 MuMu 模拟器验证，未在真机验证。
- `sqlite3_flutter_libs` 使用兼容 Flutter 3.38 的 0.5.x；drift 2.28（Dart 3.10 约束）。
- MuMu 使用 x86_64 包；真机请用默认 `flutter build apk --debug` 的 arm64 包。
- image_picker 的 Android 插件在首次构建时可能触发 Kotlin incremental cache 警告，但可正常产出 APK。
