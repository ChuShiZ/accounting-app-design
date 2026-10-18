# jizhang · 记账（Flutter）

> 自用离线安卓记账 App。主设计：`../doc/设计-账户资产模型.md`；视觉基准：`../DESIGN.md`。
> 当前进度：**批次 0 完成**。

## 环境

- Flutter 3.38.8 / Dart 3.10.7
- Android SDK 36.1.0；minSdk 26；targetSdk 36
- applicationId：`com.self.jizhang`
- 显示名：记账

> 工程顶层目录使用 ASCII `jizhang-flutter/`。Windows 下 Gradle/Flutter shader 编译器无法在包含非 ASCII 的工程路径构建；`lib/` 内部文件名仍按中文约定。

## 已实现（批次 0）

- 主题令牌：`lib/主题/令牌.dart`、`lib/主题/主题.dart`
- 线性图标：`lucide_icons`（与 DESIGN.md 的 Lucide 线性风格一致；MaterialIcons 的 CFF3 字体在 MuMu Android 12 上显示为 tofu，已替换）
- 4 Tab 壳 + 中央「记一笔」：`lib/路由/路由.dart`、`lib/组件/主壳.dart`
- 8 张 drift 表：account / transaction / category / card_detail / deposit_detail / loan_detail / recurring_rule / settings
- 数据库：`lib/数据/数据库.dart`（schemaVersion=1）
- Repository：账户、交易、类别、报表、设置
- Riverpod providers：`lib/状态/提供者.dart`
- 测试：余额派生、储值卡详情、贷款负余额、报表区间、类别/设置读写、4 Tab 壳

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

- 批次 1：资产页 + 银行卡/储值卡/贷款新增与编辑
- 批次 2：记一笔 + 首页流水 + 流水编辑/删除

## 已知

- 当前只创建 Android 平台；已在 MuMu 模拟器验证，未在真机验证。
- `sqlite3_flutter_libs` 使用兼容 Flutter 3.38 的 0.5.x；drift 2.28（Dart 3.10 约束）。
- MuMu 使用 x86_64 包；真机请用默认 `flutter build apk --debug` 的 arm64 包。
