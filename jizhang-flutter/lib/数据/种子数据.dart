import '数据库.dart';
import '仓库/类别仓库.dart';
import '仓库/账户仓库.dart';

class _PresetChild {
  const _PresetChild(this.name, this.icon);

  final String name;
  final String icon;
}

class _PresetGroup {
  const _PresetGroup(this.name, this.icon, {this.children = const []});

  final String name;
  final String icon;
  final List<_PresetChild> children;
}

const _expensePresets = <_PresetGroup>[
  _PresetGroup('餐饮', 'food', children: [
    _PresetChild('早餐', 'breakfast'),
    _PresetChild('午餐', 'lunch'),
    _PresetChild('晚餐', 'dinner'),
    _PresetChild('夜宵', 'snack'),
    _PresetChild('外卖', 'takeout'),
    _PresetChild('咖啡饮品', 'drink'),
    _PresetChild('零食', 'snack'),
    _PresetChild('水果', 'fruit'),
    _PresetChild('买菜', 'groceries'),
    _PresetChild('聚餐', 'food'),
  ]),
  _PresetGroup('交通', 'car', children: [
    _PresetChild('公交地铁', 'bus'),
    _PresetChild('打车', 'car'),
    _PresetChild('加油', 'fuel'),
    _PresetChild('停车', 'parking'),
    _PresetChild('过路费', 'ticket'),
    _PresetChild('车辆保养', 'repair'),
    _PresetChild('车辆维修', 'repair'),
    _PresetChild('共享单车', 'bike'),
    _PresetChild('火车高铁', 'train'),
    _PresetChild('飞机', 'plane'),
  ]),
  _PresetGroup('购物', 'cart', children: [
    _PresetChild('服饰', 'clothes'),
    _PresetChild('数码', 'digital'),
    _PresetChild('家电', 'appliance'),
    _PresetChild('美妆', 'beauty'),
    _PresetChild('母婴', 'baby'),
    _PresetChild('日用品', 'cart'),
    _PresetChild('箱包', 'package'),
    _PresetChild('首饰', 'gift'),
    _PresetChild('其他购物', 'cart'),
  ]),
  _PresetGroup('居家', 'building', children: [
    _PresetChild('房租', 'rent'),
    _PresetChild('水电燃气', 'utility'),
    _PresetChild('物业费', 'building'),
    _PresetChild('家庭宽带', 'wifi'),
    _PresetChild('家政', 'beauty'),
    _PresetChild('维修', 'repair'),
    _PresetChild('家具', 'furniture'),
    _PresetChild('其他居家', 'building'),
  ]),
  _PresetGroup('娱乐', 'fun', children: [
    _PresetChild('电影', 'movie'),
    _PresetChild('游戏', 'game'),
    _PresetChild('演出', 'music'),
    _PresetChild('健身', 'sports'),
    _PresetChild('订阅', 'subscription'),
    _PresetChild('休闲', 'fun'),
    _PresetChild('其他娱乐', 'fun'),
  ]),
  _PresetGroup('医疗', 'medical', children: [
    _PresetChild('门诊', 'hospital'),
    _PresetChild('药品', 'medicine'),
    _PresetChild('住院', 'medical'),
    _PresetChild('体检', 'health'),
    _PresetChild('牙科', 'dental'),
    _PresetChild('保健品', 'health'),
    _PresetChild('其他医疗', 'medical'),
  ]),
  _PresetGroup('教育', 'education', children: [
    _PresetChild('学费', 'education'),
    _PresetChild('培训', 'education'),
    _PresetChild('书籍', 'book'),
    _PresetChild('文具', 'stationery'),
    _PresetChild('考试', 'bonus'),
    _PresetChild('网课', 'digital'),
    _PresetChild('其他教育', 'education'),
  ]),
  _PresetGroup('通讯', 'phone', children: [
    _PresetChild('话费', 'phone'),
    _PresetChild('手机流量', 'wifi'),
    _PresetChild('宽带费', 'wifi'),
    _PresetChild('快递', 'package'),
    _PresetChild('其他通讯', 'phone'),
  ]),
  _PresetGroup('人情', 'gift', children: [
    _PresetChild('红包', 'redpacket'),
    _PresetChild('礼物', 'gift'),
    _PresetChild('请客', 'food'),
    _PresetChild('孝敬', 'charity'),
    _PresetChild('慈善', 'charity'),
    _PresetChild('其他人情', 'gift'),
  ]),
  _PresetGroup('金融', 'bank', children: [
    _PresetChild('房贷', 'mortgage'),
    _PresetChild('车贷', 'car'),
    _PresetChild('贷款', 'loan'),
    _PresetChild('手续费', 'fee'),
    _PresetChild('保险', 'insurance'),
    _PresetChild('利息支出', 'interest'),
    _PresetChild('其他金融', 'bank'),
  ]),
  _PresetGroup('旅行', 'travel', children: [
    _PresetChild('机票', 'plane'),
    _PresetChild('酒店', 'hotel'),
    _PresetChild('景点门票', 'ticket'),
    _PresetChild('旅行购物', 'travel'),
    _PresetChild('当地交通', 'bus'),
    _PresetChild('旅行餐饮', 'food'),
    _PresetChild('其他旅行', 'travel'),
  ]),
  _PresetGroup('宠物', 'pet', children: [
    _PresetChild('宠物食品', 'pet'),
    _PresetChild('宠物医疗', 'medical'),
    _PresetChild('宠物用品', 'cart'),
    _PresetChild('宠物寄养', 'building'),
    _PresetChild('其他宠物', 'pet'),
  ]),
  _PresetGroup('储值卡充值', 'card'),
  _PresetGroup('其他', 'other'),
];

const _incomePresets = <_PresetGroup>[
  _PresetGroup('工资', 'salary', children: [
    _PresetChild('基本工资', 'salary'),
    _PresetChild('加班费', 'bonus'),
    _PresetChild('补贴', 'gift'),
    _PresetChild('提成', 'commission'),
    _PresetChild('年终奖', 'bonus'),
    _PresetChild('奖金', 'gift'),
  ]),
  _PresetGroup('经营', 'business', children: [
    _PresetChild('营业收入', 'business'),
    _PresetChild('兼职', 'sidejob'),
    _PresetChild('稿费', 'stationery'),
    _PresetChild('直播', 'music'),
    _PresetChild('其他经营', 'business'),
  ]),
  _PresetGroup('投资', 'invest', children: [
    _PresetChild('利息', 'interest'),
    _PresetChild('理财', 'invest'),
    _PresetChild('分红', 'dividend'),
    _PresetChild('股票收益', 'stock'),
    _PresetChild('基金收益', 'fund'),
    _PresetChild('租金', 'rent'),
    _PresetChild('其他投资', 'invest'),
  ]),
  _PresetGroup('人情', 'gift', children: [
    _PresetChild('收红包', 'redpacket'),
    _PresetChild('礼金', 'gift'),
    _PresetChild('赠送', 'gift'),
    _PresetChild('其他人情收入', 'gift'),
  ]),
  _PresetGroup('其他收入', 'wallet', children: [
    _PresetChild('退款', 'refund'),
    _PresetChild('报销', 'reimburse'),
    _PresetChild('中奖', 'bonus'),
    _PresetChild('意外收入', 'cash'),
  ]),
  _PresetGroup('其他', 'other'),
];

/// 首次打开数据库时写入预设类别；已有类别时补齐两级预设，不覆盖用户已有名称。
Future<void> seedPresetData(AppDatabase db) async {
  const markerKey = 'category_tree_version';
  final marker = await (db.select(db.settings)..where((t) => t.key.equals(markerKey))).getSingleOrNull();
  final version = int.tryParse(marker?.value ?? '') ?? 0;
  if (version < 3) {
    final categories = CategoryRepository(db);
    await _ensurePresets(categories, 'expense', _expensePresets);
    await _ensurePresets(categories, 'income', _incomePresets);
    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: markerKey, value: '3'),
        );
  }
  await AccountRepository(db).ensureDefaultAccount();
}

Future<void> _ensurePresets(
  CategoryRepository repository,
  String type,
  List<_PresetGroup> presets,
) async {
  for (final preset in presets) {
    var group = await repository.findByName(preset.name, type);
    if (group == null) {
      final id = await repository.create(
        name: preset.name,
        type: type,
        icon: preset.icon,
        isPreset: true,
        isFixed: true,
      );
      group = await repository.findById(id);
    } else {
      if (group.parentId != null) {
        await repository.setParent(group.id, null);
      }
      if (group.isPreset && !group.isFixed) {
        await repository.setFixed(group.id, true);
      }
    }
    if (group == null) continue;

    for (final child in preset.children) {
      final existing = await repository.findByName(child.name, type);
      if (existing == null) {
        await repository.create(
          name: child.name,
          type: type,
          icon: child.icon,
          parentId: group.id,
          isPreset: true,
          isFixed: true,
        );
      } else {
        if (existing.id != group.id && existing.parentId == null) {
          // 旧版本预设是一级分类：这里迁移到对应的一级分类下面。
          // 用户自建且已经有子分类的分类保持原样，避免出现三级结构。
          final hasChildren = await repository.hasChildren(existing.id);
          if (!hasChildren) {
            await repository.setParent(existing.id, group.id);
          }
        }
        if (existing.isPreset && !existing.isFixed) {
          await repository.setFixed(existing.id, true);
        }
      }
    }
  }
}
