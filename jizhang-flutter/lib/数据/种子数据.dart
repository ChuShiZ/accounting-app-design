import '数据库.dart';
import '仓库/类别仓库.dart';
import '仓库/账户仓库.dart';

class _PresetCategory {
  const _PresetCategory(this.name, this.type, this.icon, {this.fixed = false});

  final String name;
  final String type;
  final String icon;
  final bool fixed;
}

const _presets = <_PresetCategory>[
  _PresetCategory('餐饮', 'expense', 'food'),
  _PresetCategory('交通', 'expense', 'car'),
  _PresetCategory('购物', 'expense', 'cart'),
  _PresetCategory('居家', 'expense', 'building'),
  _PresetCategory('娱乐', 'expense', 'fun'),
  _PresetCategory('医疗', 'expense', 'medical'),
  _PresetCategory('教育', 'expense', 'education'),
  _PresetCategory('通讯', 'expense', 'phone'),
  _PresetCategory('房贷', 'expense', 'mortgage'),
  _PresetCategory('车贷', 'expense', 'car'),
  _PresetCategory('贷款', 'expense', 'loan'),
  _PresetCategory('储值卡充值', 'expense', 'card'),
  _PresetCategory('其他', 'expense', 'other', fixed: true),
  _PresetCategory('工资', 'income', 'salary'),
  _PresetCategory('奖金', 'income', 'gift'),
  _PresetCategory('利息', 'income', 'interest'),
  _PresetCategory('赠送', 'income', 'gift'),
  _PresetCategory('理财', 'income', 'invest'),
  _PresetCategory('其他', 'income', 'other', fixed: true),
];

/// 首次打开数据库时写入预设类别；已有类别时不动。默认账户始终确保存在。
Future<void> seedPresetData(AppDatabase db) async {
  final existing = await db.select(db.categories).get();
  if (existing.isEmpty) {
    final categories = CategoryRepository(db);
    for (final preset in _presets) {
      await categories.create(
        name: preset.name,
        type: preset.type,
        icon: preset.icon,
        isPreset: true,
        isFixed: preset.fixed,
      );
    }
  }
  await AccountRepository(db).ensureDefaultAccount();
}
