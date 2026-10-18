import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '主题/主题.dart';
import '路由/路由.dart';
import '数据/数据库.dart';
import '数据/种子数据.dart';
import '状态/提供者.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  await seedPresetData(db);
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const JizhangApp(),
    ),
  );
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
