import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '主题/主题.dart';
import '路由/路由.dart';
import '数据/数据库.dart';
import '数据/种子数据.dart';
import '状态/提供者.dart';
import '同步/备份服务.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applyPendingRestore();
  final db = AppDatabase.open();
  await seedPresetData(db);
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const JizhangApp(),
    ),
  );
  WidgetsBinding.instance.addObserver(_BackupLifecycleObserver(db));
  unawaited(maybeAutoBackup(db));
}

class _BackupLifecycleObserver with WidgetsBindingObserver {
  _BackupLifecycleObserver(this.db);

  final AppDatabase db;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(maybeAutoBackup(db));
    }
  }
}

class JizhangApp extends StatefulWidget {
  const JizhangApp({super.key});

  @override
  State<JizhangApp> createState() => _JizhangAppState();
}

class _JizhangAppState extends State<JizhangApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '记账',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
