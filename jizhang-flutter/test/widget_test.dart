import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/主入口.dart';

void main() {
  testWidgets('4 Tab shell renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JizhangApp()));
    await tester.pumpAndSettle();

    expect(find.text('我的账单'), findsOneWidget);
    expect(find.text('工程骨架已就绪'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('报表'), findsWidgets);
    expect(find.text('资产'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
