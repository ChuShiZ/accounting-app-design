/// 将旧记账软件导出的分类名称映射到本 App 的两级分类。
///
/// 返回的是目标分类名称（同级内唯一）。返回 null 表示没有预设映射，
/// 由导入服务按旧逻辑创建为一级分类，避免丢失用户数据。
class ExcelCategoryMapper {
  const ExcelCategoryMapper._();

  static const _expense = <String, String>{
    '餐饮': '餐饮',
    '早午晚餐': '餐饮',
    '美食特产': '餐饮',
    '烟酒茶叶': '餐饮',
    '购物': '购物',
    '消费': '其他',
    '交通': '交通',
    '车': '交通',
    '加油充电': '加油',
    '公交地铁': '公交地铁',
    '停车费': '停车',
    '打车租车': '打车',
    '高速': '过路费',
    '住房': '居家',
    '水电燃气': '水电燃气',
    '水电费': '水电燃气',
    '医疗': '医疗',
    '婚礼筹备': '人情',
    '人情社交': '人情',
    '请客送礼': '请客',
    '通讯': '话费',
    '转账': '其他',
    '红包': '红包',
    '水果零食': '零食',
    '咖啡奶茶': '咖啡饮品',
    '其他': '其他',
    '房贷车贷': '金融',
    '还款': '金融',
    '投资': '金融',
    '娱乐': '娱乐',
    '穿搭美妆': '服饰',
    '美容': '美妆',
    '生活日用': '日用品',
    '火车飞机': '火车高铁',
    '教育': '教育',
    '房租物业': '物业费',
    '共享单车': '共享单车',
    '保养修车': '车辆保养',
    '烹饪食材': '买菜',
    '旅行': '旅行',
    '快递': '快递',
    '维修清洁': '维修',
    '旅行交通': '当地交通',
    '保险': '保险',
    '酒店住宿': '酒店',
    '手机数码': '数码',
    '慈善捐款': '慈善',
    '培训考试': '考试',
    '借出': '其他',
    '景点门票': '景点门票',
  };

  static const _income = <String, String>{
    '礼金': '礼金',
    '收红包': '收红包',
    '收转账': '其他',
    '住房': '补贴',
    '投资': '投资',
    '还款': '其他',
    '其他': '其他',
  };

  static const _fruitWords = [
    '水果',
    '鲜生',
    '榴莲',
    '火龙果',
    '苹果',
    '香蕉',
    '西瓜',
    '橙',
    '柚',
    '梨',
    '桃',
    '葡萄',
    '提子',
    '草莓',
    '蓝莓',
    '樱桃',
    '芒果',
  ];

  static const _flightWords = ['飞机', '机场', '航班', '航空'];

  static String? targetName(String type, String sourceCategory, {String note = ''}) {
    final source = sourceCategory.trim();
    if (source.isEmpty) return null;
    if (type == 'income') {
      if (source == '其他' && note.contains('退款')) return '退款';
      return _income[source];
    }
    if (source == '水果零食') {
      return _fruitWords.any(note.contains) ? '水果' : '零食';
    }
    if (source == '火车飞机') {
      return _flightWords.any(note.contains) ? '飞机' : '火车高铁';
    }
    return _expense[source];
  }
}
