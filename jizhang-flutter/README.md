# jizhang · 记账（Flutter）

> 自用离线安卓记账 App。主设计：`../doc/设计-账户资产模型.md`；视觉基准：`../DESIGN.md`。
> 当前进度：**首页 / 记一笔 / 报表 / 资产 / 存单 / 信用卡 / 贷款 / 类别 / 设置 / WebDAV 备份 / Excel 导入主体完成**。

## 环境

- Flutter 3.38.8 / Dart 3.10.7
- Android SDK 36.1.0；minSdk 26；targetSdk 36
- applicationId：`com.self.jizhang`
- 显示名：记账
- 依赖：drift、riverpod、go_router、lucide_icons、image_picker、archive、flutter_secure_storage、excel、file_picker

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

- 今日支出 / 本月支出 / 本月收入（本月结余仅在报表中查看）
- 最近交易按日期分组、搜索类别/备注/账户、组内支出合计；长按流水可确认删除
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

- 资产页：默认账户 / 账户 / 储值卡 / 存单卡片 / 信用卡 / 贷款分组；默认账户无余额、不可编辑/删除
- 银行卡、储值卡、信用卡、贷款 CRUD；存单添加/编辑/详情
- 储值卡充值（实付+赠送）、默认消费类别；消费不重复计支出
- 信用卡消费计入支出；还款为转账不计支出；额度/账单日/还款日
- 贷款整笔月供计支出；内部本金回补不计收入；还款后下次还款日 +1 月
- 存单购买本金转账不计收支；到期/提前支取；转存；利息计收入；30 天提醒
- 账户删除：无流水硬删；有流水归档；历史保留

### 类别与设置

- 类别管理：支出/收入切换、新增/编辑、名称/图标、已用笔数
- 删除已用类别归入【其他】；固定类别不可删除/改名/改类型
- 设置：默认记账账户（记一笔默认选中）、WebDAV 配置、连接校验、备份恢复、自动备份开关与间隔
- 我的：设置、类别管理、Excel 导入/帮助入口

### WebDAV 备份

- 坚果云等 WebDAV：真实 PROPFIND 连接校验、MKCOL 建目录、PUT 上传、GET 下载、DELETE 轮转
- 默认目录 `记账备份`（如 `/dav/记账备份/`），不写 WebDAV 根目录
- 备份 zip 包含 SQLite 数据库；图片凭证为可选项，**默认关闭**，开启后才打包 `receipts/`
- 服务端仅保留最近 5 份；手动“立即备份”随时可用
- 自动备份：启动、回到前台时检查；间隔可选 24 小时 / 3 天 / 7 天，默认 **3 天**；不做逐操作同步
- 凭据：应用密码保存到系统安全存储；恢复先下载校验，重启 App 时替换数据库，并保留恢复前备份
- 已用坚果云账号实测连接、建目录、上传、列表、下载、删除、恢复落盘

### Excel 导入

- 入口：我的 → Excel 导入；支持 `.xlsx`
- 识别表头：日期/账单日期、收支类型、金额、类别/记账分类、备注、账户（可选）
- 无账户列时导入到设置页选择的账户；未设置时回退到系统「默认账户」；类别按名称+类型自动复用/创建
- 重复判断：日期时间、金额、类型、类别、备注、账户一致视为重复
- 结果报告：成功/重复/跳过，失败行号
- 已用 3800 行账单实测：成功 3800、跳过 0、重复 0、新建类别 19；首页本月支出/收入与源文件汇总一致

### 测试

- `flutter analyze` 0 issue
- `flutter test` 26/26（18 个仓库/业务测试 + 8 个 Widget 测试）
- 已用 x86_64 debug APK 在 MuMu Player 12（Android 12 / API 32）安装启动，手工验证：添加银行卡/储值卡/信用卡/存单、记账、流水编辑、充值、储值卡消费、信用卡还款、存单支取、报表、类别管理、设置页、图片选择入口
- 坚果云实测：连接、`/记账备份/` 建目录、上传、列表、下载、删除、重启恢复；默认备份不含图片，开启后包含 `receipts/`
- Excel 实测：3800 行账单成功导入，分类自动创建，重复导入可跳过
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

- WebDAV 已接真实坚果云备份；Excel `.xlsx` 导入已接入
- 周期账单规则表已建，但尚无规则 UI。
- 当前只创建 Android 平台；已在 MuMu 模拟器验证，未在真机验证。
- `sqlite3_flutter_libs` 使用兼容 Flutter 3.38 的 0.5.x；drift 2.28（Dart 3.10 约束）。
- MuMu 使用 x86_64 包；真机请用默认 `flutter build apk --debug` 的 arm64 包。
- image_picker 的 Android 插件在首次构建时可能触发 Kotlin incremental cache 警告，但可正常产出 APK。
