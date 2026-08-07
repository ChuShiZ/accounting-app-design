/* ============ 全局 store（vue.global.js 构建：无 ES 模块，全部挂 window，脚本顺序引入） ============ */
/* ---------- 图标库 ---------- */
window.ICONS = {
  mortgage:'<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20h14V9.5"/><path d="M9.5 13.5h5a1.5 1.5 0 0 1 0 3h-5a1.5 1.5 0 0 1 0-3z"/>',
  food:'<path d="M3 11h18a9 9 0 0 1-18 0z"/><path d="M12 11V4M9 4h6"/>',
  card:'<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h4"/>',
  salary:'<rect x="3" y="7" width="18" height="12" rx="2"/><circle cx="12" cy="13" r="2.5"/><path d="M7 7V5h10v2"/>',
  parking:'<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M9.5 16V8h3a2.5 2.5 0 0 1 0 5H9.5"/>',
  phone:'<rect x="7" y="3" width="10" height="18" rx="2.5"/><path d="M11 18h2"/>',
  scissors:'<circle cx="6" cy="6" r="2.5"/><circle cx="6" cy="18" r="2.5"/><path d="M8.5 7.5 20 18M8.5 16.5 20 6"/>',
  car:'<path d="M5 13l1.5-4.5A2 2 0 0 1 8.4 7h7.2a2 2 0 0 1 1.9 1.5L19 13"/><path d="M4 13h16v4H4z"/><circle cx="8" cy="17" r="1.5"/><circle cx="16" cy="17" r="1.5"/>',
  cart:'<path d="M3 4h2l2.5 12h10L20 7H6"/><circle cx="9" cy="20" r="1.5"/><circle cx="17" cy="20" r="1.5"/>',
  bank:'<path d="M4 9 12 4l8 5"/><path d="M5 9v9M9 9v9M15 9v9M19 9v9"/><path d="M3 20h18"/>',
  coffee:'<path d="M5 9h12v5a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4z"/><path d="M17 10h2.5a2 2 0 0 1 0 4H17"/><path d="M8 3v2M11 3v2"/>',
  building:'<path d="M4 9 12 4l8 5"/><path d="M5 9v9M9 9v9M15 9v9M19 9v9"/><path d="M3 20h18"/><path d="M10 14h4v3h-4z"/>',
  search:'<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  back:'<path d="M15 5l-7 7 7 7"/>',
  close:'<path d="M6 6l12 12M18 6 6 18"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  chevron:'<path d="m9 6 6 6-6 6"/>',
  refresh:'<path d="M4 11a8 8 0 0 1 14-5l2 2M20 13a8 8 0 0 1-14 5l-2-2"/><path d="M20 4v4h-4M4 20v-4h4"/>',
  card2:'<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h4"/>',
  clock:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  help:'<circle cx="12" cy="12" r="8.5"/><path d="M12 8v.5M12 11v5"/>',
  edit:'<path d="M5 19h3l10-10-3-3L5 16z"/><path d="M14 6l3 3"/>',
  upload:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>',
  img:'<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>',
  empty:'<path d="M4 13l3-8h10l3 8v6H4z"/><path d="M4 13h5l1 2h4l1-2h5"/>'
}
window.icon = function(name, size){
  size = size || 20
  return '<svg width="'+size+'" height="'+size+'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+(window.ICONS[name]||'')+'</svg>'
}
window.fmt = function(n){ return '¥' + Number(n).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2}) }

/* ---------- 数据 ---------- */
window.homeData = Vue.reactive([
  {group:'今天', icon:'mortgage', cls:'liability', cat:'房贷月供', remark:'6月月供·剩余本金¥1,024,300', time:'08:30', amount:6800, catKey:'周期', timeGroup:'本周'},
  {group:'今天', icon:'food',     cls:'expense',   cat:'午餐',      remark:'公司附近·黄焖鸡',          time:'12:15', amount:38,   catKey:'餐饮', timeGroup:'本周'},
  {group:'今天', icon:'card',     cls:'balance',   cat:'银座购物卡消费', remark:'超市',                time:'18:40', amount:200,  catKey:'购物', timeGroup:'本周', acc:'银座购物卡'},
  {group:'今天', icon:'salary',   cls:'income',    cat:'工资收入',   remark:'6月薪资',                time:'10:00', amount:23500,catKey:'工资', timeGroup:'本周'},
  {group:'昨天', icon:'parking',  cls:'expense',   cat:'停车费',     remark:'写字楼地下',             time:'09:12', amount:15,   catKey:'交通', timeGroup:'本周'},
  {group:'昨天', icon:'phone',    cls:'liability', cat:'电话费',     remark:'套餐月付',              time:'20:05', amount:99,   catKey:'周期', timeGroup:'本周'},
  {group:'昨天', icon:'scissors', cls:'balance',   cat:'理发卡消费',  remark:'洗剪吹',               time:'15:30', amount:50,   catKey:'购物', timeGroup:'本周', acc:'理发卡'},
  {group:'更早', icon:'car',      cls:'liability', cat:'车贷月供',   remark:'剩余 24 期',            time:'06-15', amount:3200, catKey:'周期', timeGroup:'本月'},
  {group:'更早', icon:'cart',     cls:'expense',   cat:'超市',       remark:'日用品',               time:'06-12', amount:156.30,catKey:'居家', timeGroup:'本月'}
])
window.cardsData = Vue.reactive([
  {name:'银行卡',     type:'银行卡', icon:'bank',  balance:3200, valid:'12/28'},
  {name:'银座购物卡', type:'储值卡', icon:'card',  balance:850,  valid:'06/27', defcat:'购物'},
  {name:'理发卡',     type:'储值卡', icon:'scissors', balance:150, valid:null},
  {name:'咖啡储值卡', type:'自定义', icon:'coffee', balance:120, valid:null, defcat:'餐饮'}
])
window.periodicData = Vue.reactive([
  {name:'房贷',   per:6800, next:'07-01', paid:24,  total:360, remain:1024300, start:'2021-07-01', state:'进行中'},
  {name:'车贷',   per:3200, next:'07-05', paid:36,  total:60,  remain:76800,   start:'2023-07-05', state:'进行中'},
  {name:'停车费', per:15,   freq:'月付', note:'每月自动扣款', state:'进行中'},
  {name:'电话费', per:99,   freq:'月付', note:'每月自动扣款', state:'进行中'},
  {name:'装修贷', per:3000, next:'—',     paid:12,  total:12,  remain:0,       start:'2025-07-01', state:'已结清'}
])
window.expenseRankingData = [
  {cat:'餐饮 · 午餐', sub:'公司附近·黄焖鸡', amt:38, date:'06-22', period:'本周'},
  {cat:'居家 · 超市', sub:'日用品',           amt:156.30, date:'06-12', period:'本月'},
  {cat:'交通 · 停车', sub:'写字楼地下',       amt:15, date:'06-21', period:'本周'},
  {cat:'购物 · 服装', sub:'夏季T恤',          amt:420, date:'06-18', period:'本月'},
  {cat:'餐饮 · 聚餐', sub:'部门团建',         amt:860, date:'06-10', period:'本月'},
  {cat:'居家 · 维修', sub:'空调检修',         amt:350, date:'06-05', period:'本月'},
  {cat:'交通 · 加油', sub:'中石化',           amt:480, date:'06-08', period:'本月'},
  {cat:'购物 · 数码', sub:'蓝牙耳机',         amt:1299, date:'06-01', period:'本月'},
  {cat:'餐饮 · 外卖', sub:'晚餐',            amt:52, date:'06-20', period:'本周'},
  {cat:'居家 · 物业', sub:'6月物业费',        amt:320, date:'06-03', period:'本月'},
  {cat:'交通 · 打车', sub:'加班回家',         amt:67, date:'03-25', period:'本季'},
  {cat:'购物 · 家电', sub:'吸尘器',           amt:1899, date:'05-12', period:'本季'},
  {cat:'餐饮 · 蛋糕', sub:'生日蛋糕',         amt:288, date:'04-15', period:'本季'},
  {cat:'居家 · 装修', sub:'油漆涂料',         amt:2450, date:'02-10', period:'本年'},
  {cat:'交通 · 修车', sub:'保养',            amt:1200, date:'01-20', period:'本年'}
]
window.reportData = {
  '周': { expense:2800, income:5800, diff:8,
         cats:[['周期负债',1200,'liability'],['餐饮',680,'expense'],['居家',500,'expense'],['交通',420,'expense']],
         trend:[380,320,450,300,420,350,580] },
  '月': { expense:12840, income:23500, diff:-12,
         cats:[['周期负债',10000,'liability'],['居家',1200,'expense'],['餐饮',1240,'expense'],['交通',400,'expense']],
         trend:[900,1200,800,1500,950,1100,1600,700,1050,1300,880,860] },
  '季': { expense:38000, income:70000, diff:15,
         cats:[['周期负债',28000,'liability'],['居家',3200,'expense'],['餐饮',4200,'expense'],['交通',2600,'expense']],
         trend:[3000,2800,3500,3200,4000,2900,3400,3100,3600,2700,3300,2500] },
  '年': { expense:150000, income:280000, diff:-6,
         cats:[['周期负债',105000,'liability'],['居家',15000,'expense'],['餐饮',18000,'expense'],['交通',12000,'expense']],
         trend:[12000,11000,13500,12000,15000,12500,14000,11500,13000,11000,12500,12000] }
}
window.periodLabel = {'周':'本周','月':'本月','季':'本季','年':'本年'}
window.periodDays = {'周':7,'月':30,'季':90,'年':365}
window.diffLabels = {'周':'比上周支出','月':'比上月支出','季':'比上季支出','年':'比上年支出'}
window.catColors = ['var(--color-liability)','var(--color-primary)','var(--color-primary-hover)','var(--color-primary-soft)']
window.timeCover = {'本周':['本周'],'本月':['本周','本月'],'本季':['本周','本月','本季'],'本年':['本周','本月','本季','本年']}
window.rankPeriodMap = {'本周':['本周'], '本月':['本周','本月'], '本季':['本周','本月','本季'], '本年':['本周','本月','本季','本年']}

/* ---------- 全局状态 ---------- */
window.store = Vue.reactive({
  tab: 'home',
  tabBar: 'home',
  sheet: null,
  toastShow: false,
  toastMsg: '',
  keyword: '',
  rankingPeriod: '本月',
  periodicFilter: '全部',
  searchFilter: { cat: [], type: [], time: [] },
  filterMin: '', filterMax: '',
  flowEditIdx: -1,
  cardEditIdx: -1,
  rechargeIdx: -1,
  periodicDetailIdx: -1,
  periodicEditIdx: -1,
  /* ⭐v14 默认记账账户：卡片页"默认账户"弹窗设置（选卡片互斥）；null=未设置（记账默认第一张卡） */
  defAcc: null
})
let __toastTimer = null
window.showToast = function(msg){
  window.store.toastMsg = msg; window.store.toastShow = true
  clearTimeout(__toastTimer)
  __toastTimer = setTimeout(function(){ window.store.toastShow = false }, 2000)
}
window.openSheet = function(name){ window.store.sheet = name }
window.closeSheet = function(){ window.store.sheet = null }
window.showScreen = function(name){ window.store.tab = name }
window.switchTab = function(name){ window.store.tabBar = name; window.store.tab = name }
window.backToTab = function(){ window.store.tab = window.store.tabBar }
window.validDisplay = function(c){
  if(c.valid==null) return '<span style="color:#fff">永久有效</span>'
  return '<span style="color:rgba(255,255,255,.92)">有效期至 '+c.valid+'</span>'
}
window.flowSum = function(list){
  return list.filter(function(x){return x.cls==='expense'||x.cls==='liability'||x.cls==='balance'}).reduce(function(a,b){return a+b.amount},0)
}
