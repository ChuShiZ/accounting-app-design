# jizhang · 记账（Flutter）

> 自用离线安卓记账 App。主设计：`../doc/设计-账户资产模型.md`；视觉基准：`../DESIGN.md`。
> 当前进度：**批次 0 + 批次 1 主体完成**（资产页 + 银行卡/储值卡/贷款 CRUD）。

## 环境

- Flutter 3.38.8 / Dart 3.10.7
- Android SDK 36.1.0；minSdk 26；targetSdk 36
- applicationId：`com.self.jizhang`
- 显示名：记账

> 工程顶层目录使用 ASCII `jizhang-flutter/`。Windows 下 Gradle/Flutter shader 编译器无法在包含非 ASCII 的工程路径构建；`lib/` 内部文件名仍按中文约定。

## 已实现

### 批次 0

- 主题令牌：`lib/主题/令牌.dart`、`lib/主题/主题.dart`
- 线性图标：`lucide_icons`（与 DESIGN.md 的 Lucide 线性风格一致；MaterialIcons 的 CFF3 字体在 MuMu Android 12 上显示为 tofu，已替换）
- 4 Tab 壳 + 中央「记一笔」：`lib/路由/路由.dart`、`lib/组件/主壳.dart`
- 8 张 drift 表：account / transaction / category / card_detail / deposit_detail / loan_detail / recurring_rule / settings
- 数据库：`lib/数据/数据库.dart`（schemaVersion=1）
- Repository：账户、交易、类别、报表、设置
- Riverpod providers：`lib/状态/提供者.dart`
- 种子类别：首次启动写入 13 个支出 + 6 个收入预设类别

### 批次 1

- 资产页：账户/储值卡/存单/信用卡/贷款分组；空态；右上 + 添加
- 添加账户 Sheet：银行卡 / 储值卡 / 贷款
- 账户 CRUD：
  - 银行卡：名称、开户行、期初余额；编辑余额只读
  - 储值卡：名称、商户、期初余额、默认消费类别；编辑默认类别
  - 贷款：名称、机构、类型、原始本金、剩余本金、利率、期数、起贷日、下次还款日、每期还款、还款方式
- 账户详情：余额/剩余本金、类型、机构、贷款信息、编辑/删除
- 删除：无流水硬删；有流水归档；历史保留
- 资产列表余额由期初 + 流水派生

### 测试

- `flutter analyze` 0 issue
- `flutter test` 9/9
- 已用 x86_64 debug APK 在 MuMu Player 12（Android 12 / API 32）安装启动，验证 4 Tab、资产空态、添加银行卡、账户详情、表单/下拉/图标显示
- 尚未在真机安装验证

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

已在 MuMu Player 12（Android 12 / API 32 / x86_64）安装并启动验证：4 Tab、页面切换、中央记一笔 Sheet、Lucide 图标显示正常。

## 下一步

- 批次 2：记一笔 + 首页流水 + 流水编辑/删除
- 批次 3：储值卡充值/消费、信用卡消费/还款
- 批次 4：存单全流程
- 批次 5：贷款还款/待办/周期规则

## 已知

- 当前只创建 Android 平台；已在 MuMu 模拟器验证，未在真机验证。
- `sqlite3_flutter_libs` 使用兼容 Flutter 3.38 的 0.5.x；drift 2.28（Dart 3.10 约束）。
- MuMu 使用 x86_64 包；真机请用默认 `flutter build apk --debug` 的 arm64 包。
