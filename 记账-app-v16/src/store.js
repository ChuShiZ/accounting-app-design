/* ============ v16 原型全局 store：账户 + 收入/支出流水 ============ */
import { reactive } from 'vue'

/* ---------- 图标库 ---------- */
const ICONS = {
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
  clock:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  help:'<circle cx="12" cy="12" r="8.5"/><path d="M12 8v.5M12 11v5"/>',
  edit:'<path d="M5 19h3l10-10-3-3L5 16z"/><path d="M14 6l3 3"/>',
  upload:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>',
  img:'<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>',
  settings:'<path d="M4 7h10M18 7h2M4 12h4M12 12h8M4 17h7M15 17h5"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="13" cy="17" r="2"/>',
  cloud:'<path d="M7 18h10a4 4 0 0 0 .6-8 6 6 0 0 0-11.4 1.6A3.5 3.5 0 0 0 7 18z"/>',
  download:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>',
  lock:'<rect x="4" y="10" width="16" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  database:'<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
  eye:'<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12z"/><circle cx="12" cy="12" r="2.5"/>',
  check:'<path d="M5 12.5 10 17l9-10"/>',
  info:'<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8v.5"/>',
  wallet:'<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M16 14h2"/>',
  credit:'<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h4"/>',
  deposit:'<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8 9h8M8 13h8M8 17h5"/>',
  loan:'<path d="M4 9 12 4l8 5"/><path d="M5 9v9M9 9v9M15 9v9M19 9v9"/><path d="M3 20h18"/><path d="M9 14h6"/>',
  interest:'<line x1="19" y1="5" x2="5" y2="19"/><circle cx="7.5" cy="7.5" r="2.5"/><circle cx="16.5" cy="16.5" r="2.5"/>',
  gift:'<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v8h14v-8"/><path d="M12 8v12"/><path d="M12 8c-2 0-4-1.5-4-3.5S10 2 12 4v4zm0 0c2 0 4-1.5 4-3.5S14 2 12 4v4z"/>',
  medical:'<path d="M9 4h6v5h5v6h-5v5H9v-5H4V9h5z"/>',
  education:'<path d="M4 6h7a3 3 0 0 1 3 3v11a3 3 0 0 0-3-3H4z"/><path d="M20 6h-3a3 3 0 0 0-3 3v11a3 3 0 0 1 3-3h3z"/>',
  fun:'<rect x="3" y="8" width="18" height="9" rx="4"/><path d="M8 12v2M7 13h2M15 12h2"/>',
  invest:'<path d="M4 17 10 11l4 4 6-8"/><path d="M15 7h5v5"/>',
  other:'<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>',
  arrow:'<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
  calendar:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  empty:'<path d="M4 13l3-8h10l3 8v6H4z"/><path d="M4 13h5l1 2h4l1-2h5"/>'
}
export function icon(name, size){
  size = size || 20
  return '<svg width="'+size+'" height="'+size+'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+(ICONS[name]||'')+'</svg>'
}

export const ICON_COLORS = {
  food:'var(--icon-food)', car:'var(--icon-car)', cart:'var(--icon-cart)', building:'var(--icon-building)',
  fun:'var(--icon-fun)', coffee:'var(--icon-coffee)', medical:'var(--icon-medical)', education:'var(--icon-education)',
  phone:'var(--icon-phone)', mortgage:'var(--icon-mortgage)', card:'var(--icon-card)', salary:'var(--icon-salary)',
  gift:'var(--icon-gift)', interest:'var(--icon-interest)', invest:'var(--icon-invest)', other:'var(--icon-other)',
  bank:'var(--color-primary)', deposit:'var(--color-primary)', credit:'var(--color-primary)', wallet:'var(--color-primary)',
  loan:'var(--icon-mortgage)', settings:'var(--color-primary)', database:'var(--color-primary)',
  upload:'var(--color-primary)', help:'var(--color-primary)', empty:'var(--color-text-disabled)'
}
export function iconColor(key){ return ICON_COLORS[key] || 'var(--color-text-secondary)' }

/* ---------- 金额 / 日期 ---------- */
export function fmt(n){ return '¥' + Number(n).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2}) }
export function fmtSigned(n){
  const v = Number(n) || 0
  return (v < 0 ? '-¥' : '¥') + Math.abs(v).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2})
}
export function fmtRate(bp){ return (Number(bp || 0) / 100).toFixed(2) + '%' }
export function fmtShort(n){ return Number(n || 0).toLocaleString('zh-CN',{maximumFractionDigits:0}) }
export function round2(n){ return Math.round((Number(n) || 0) * 100) / 100 }

export const DEMO_TODAY = '2026-06-22'
export const periodLabel = { '周':'近7天', '月':'本月', '季':'本季', '年':'本年' }

export function parseDate(s){
  const p = String(s || DEMO_TODAY).split('-').map(Number)
  return new Date(p[0], p[1] - 1, p[2] || 1)
}
export function fmtDate(d){
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return y + '-' + m + '-' + day
}
export function addDays(s, n){
  const d = parseDate(s); d.setDate(d.getDate() + n); return fmtDate(d)
}
export function addMonths(s, months){
  const d = parseDate(s)
  const day = d.getDate()
  d.setDate(1)
  d.setMonth(d.getMonth() + Number(months || 0))
  const last = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
  d.setDate(Math.min(day, last))
  return fmtDate(d)
}
export function daysBetween(a, b){
  return Math.round((parseDate(b).getTime() - parseDate(a).getTime()) / 86400000)
}
export function shortDate(s){ return String(s || '').slice(5) }

/* ---------- 账户 ---------- */
export const ACCOUNT_TYPE_LABEL = {
  cash:'现金', bank:'银行卡', ewallet:'电子钱包', stored:'储值卡',
  credit:'信用卡', deposit:'存单', loan:'贷款'
}

export const accounts = reactive([
  { id:'bank1', type:'bank', name:'招商银行卡', institution:'招商银行', icon:'bank', balance:32000, note:'' },
  { id:'alipay', type:'ewallet', name:'支付宝', institution:'支付宝', icon:'wallet', balance:8600, note:'' },
  { id:'stored1', type:'stored', name:'银座购物卡', institution:'银座', icon:'cart', balance:850, defaultCategory:'购物', note:'' },
  { id:'credit1', type:'credit', name:'招行信用卡', institution:'招商银行', icon:'credit', balance:-3200, creditLimit:50000, billingDay:5, repaymentDay:23, note:'' },
  { id:'deposit1', type:'deposit', name:'招行3年存单', institution:'招商银行', icon:'deposit', balance:100000,
    deposit:{ certificateNo:'CD20240601001', principal:100000, rateBp:325, termMonths:36, startAt:'2024-06-01', maturityAt:'2027-06-01', closedAt:null, closeType:null, actualInterest:null, note:'大额存单' } },
  { id:'deposit2', type:'deposit', name:'招行1年存单', institution:'招商银行', icon:'deposit', balance:50000,
    deposit:{ certificateNo:'CD20250701008', principal:50000, rateBp:200, termMonths:12, startAt:'2025-07-01', maturityAt:'2026-07-01', closedAt:null, closeType:null, actualInterest:null, note:'' } },
  { id:'deposit3', type:'deposit', name:'工行6个月存单', institution:'工商银行', icon:'deposit', balance:30000,
    deposit:{ certificateNo:'CD20251215003', principal:30000, rateBp:180, termMonths:6, startAt:'2025-12-15', maturityAt:'2026-06-15', closedAt:null, closeType:null, actualInterest:null, note:'已到期待处理' } },
  { id:'loan1', type:'loan', name:'房贷', institution:'建设银行', icon:'mortgage', balance:-1024300,
    loan:{ kind:'mortgage', originalPrincipal:1200000, rateBp:410, termMonths:360, startAt:'2021-07-01', nextDueAt:'2026-07-01', perAmount:6800, repaymentMethod:'equal_principal_interest', note:'' } }
])

export function accountById(id){ return accounts.find(a => a.id === id) || null }
export function assetAccounts(){ return accounts.filter(a => a.type !== 'credit' && a.type !== 'loan') }
export function expenseAccounts(){ return accounts.filter(a => ['cash','bank','ewallet','stored','credit'].includes(a.type)) }
export function incomeAccounts(){ return accounts.filter(a => ['cash','bank','ewallet','stored','deposit'].includes(a.type)) }
export function typeLabel(a){ return ACCOUNT_TYPE_LABEL[a.type] || a.type }

export function accountSubtitle(a){
  if(!a) return ''
  if(a.type === 'stored') return a.defaultCategory ? '默认消费 · ' + a.defaultCategory : '储值卡'
  if(a.type === 'credit') return (a.repaymentDay || '—') + ' 号还款 · ' + (a.institution || '信用卡')
  if(a.type === 'deposit') {
    const s = depositStatus(a)
    return s.label + ' · ' + fmtRate(a.deposit.rateBp) + ' · 到期 ' + shortDate(a.deposit.maturityAt)
  }
  if(a.type === 'loan') return '下次还款 ' + shortDate(a.loan.nextDueAt)
  return a.institution || typeLabel(a)
}

/* ---------- 类别 ---------- */
export const categories = reactive([
  { id:'c-food', name:'餐饮', type:'expense', icon:'food' },
  { id:'c-transport', name:'交通', type:'expense', icon:'car' },
  { id:'c-shopping', name:'购物', type:'expense', icon:'cart' },
  { id:'c-home', name:'居家', type:'expense', icon:'building' },
  { id:'c-fun', name:'娱乐', type:'expense', icon:'fun' },
  { id:'c-medical', name:'医疗', type:'expense', icon:'medical' },
  { id:'c-education', name:'教育', type:'expense', icon:'education' },
  { id:'c-phone', name:'通讯', type:'expense', icon:'phone' },
  { id:'c-mortgage', name:'房贷', type:'expense', icon:'mortgage' },
  { id:'c-car-loan', name:'车贷', type:'expense', icon:'car' },
  { id:'c-loan', name:'贷款', type:'expense', icon:'loan' },
  { id:'c-recharge', name:'储值卡充值', type:'expense', icon:'card' },
  { id:'c-other', name:'其他', type:'expense', icon:'other' },
  { id:'c-salary', name:'工资', type:'income', icon:'salary' },
  { id:'c-bonus', name:'奖金', type:'income', icon:'gift' },
  { id:'c-interest', name:'利息', type:'income', icon:'interest' },
  { id:'c-gift', name:'赠送', type:'income', icon:'gift' },
  { id:'c-invest', name:'理财', type:'income', icon:'invest' },
  { id:'c-other-income', name:'其他', type:'income', icon:'other' }
])

export const categoryIconChoices = [
  { key:'food', label:'餐饮' },
  { key:'car', label:'交通' },
  { key:'cart', label:'购物' },
  { key:'building', label:'居家' },
  { key:'fun', label:'娱乐' },
  { key:'coffee', label:'咖啡' },
  { key:'medical', label:'医疗' },
  { key:'education', label:'教育' },
  { key:'phone', label:'通讯' },
  { key:'mortgage', label:'房贷' },
  { key:'loan', label:'贷款' },
  { key:'card', label:'充值' },
  { key:'salary', label:'工资' },
  { key:'gift', label:'奖金' },
  { key:'interest', label:'利息' },
  { key:'invest', label:'理财' },
  { key:'other', label:'其他' }
]

export function iconForCategory(name, type){
  const sameType = categories.find(c => c.name === name && (!type || c.type === type))
  const anyType = categories.find(c => c.name === name)
  return (sameType || anyType || { icon:'other' }).icon
}
export function categoryOptions(type){ return categories.filter(c => c.type === type) }
export function colorForCategory(name, type){ return iconColor(iconForCategory(name, type)) }

/* ---------- 存单派生 ---------- */
export function expectedInterest(a){
  const d = a && a.deposit
  if(!d) return 0
  return round2(d.principal * d.rateBp / 10000 * d.termMonths / 12)
}
export function depositStatus(a){
  const d = a && a.deposit
  if(!d) return { key:'active', label:'进行中', cls:'active' }
  if(d.closedAt) return { key:'closed', label:d.closeType === 'renew' ? '已转存' : '已支取', cls:'closed' }
  if(DEMO_TODAY >= d.maturityAt) return { key:'matured', label:'待处理', cls:'matured' }
  const days = daysBetween(DEMO_TODAY, d.maturityAt)
  if(days <= 30) return { key:'due', label:'即将到期', cls:'due' }
  return { key:'active', label:'进行中', cls:'active' }
}
export function daysToMaturity(a){
  const d = a && a.deposit
  return d ? daysBetween(DEMO_TODAY, d.maturityAt) : 0
}
export function depositProgress(a){
  const d = a && a.deposit
  if(!d) return 0
  if(d.closedAt) return 100
  const total = Math.max(1, daysBetween(d.startAt, d.maturityAt))
  const done = Math.max(0, Math.min(total, daysBetween(d.startAt, DEMO_TODAY)))
  return Math.round(done / total * 100)
}

/* ---------- 流水 ---------- */
let txSeq = 100
let accSeq = 100

export const transactions = reactive([
  { id:1, type:'income', amount:23500, date:'2026-06-22', time:'10:00', category:'工资', accountId:'bank1', note:'6月薪资' },
  { id:2, type:'expense', amount:38, date:'2026-06-22', time:'12:15', category:'餐饮', accountId:'alipay', note:'公司附近·黄焖鸡' },
  { id:3, type:'expense', amount:6800, date:'2026-06-20', time:'08:30', category:'房贷', accountId:'bank1', loanId:'loan1', note:'房贷月供' },
  { id:4, type:'expense', amount:200, date:'2026-06-18', time:'18:40', category:'储值卡充值', accountId:'bank1', storedId:'stored1', note:'银座购物卡 · 充200送200' },
  { id:5, type:'income', amount:200, date:'2026-06-18', time:'18:40', category:'赠送', accountId:'stored1', note:'充值赠送' },
  { id:6, type:'expense', amount:320, date:'2026-06-17', time:'20:10', category:'餐饮', accountId:'credit1', note:'信用卡消费' },
  { id:7, type:'expense', amount:99, date:'2026-06-15', time:'09:00', category:'通讯', accountId:'alipay', note:'电话费' },
  { id:8, type:'expense', amount:156.30, date:'2026-06-12', time:'16:20', category:'购物', accountId:'bank1', note:'超市日用品' },
  { id:9, type:'income', amount:300, date:'2026-06-10', time:'09:00', category:'利息', accountId:'bank1', note:'存单利息' },
  { id:10, type:'expense', amount:420, date:'2026-05-18', time:'19:00', category:'购物', accountId:'bank1', note:'夏季T恤' },
  { id:11, type:'expense', amount:860, date:'2026-04-10', time:'20:00', category:'餐饮', accountId:'alipay', note:'部门团建' },
  { id:12, type:'expense', amount:1299, date:'2026-02-01', time:'11:00', category:'购物', accountId:'credit1', note:'蓝牙耳机' },
  { id:13, type:'expense', amount:6800, date:'2026-05-20', time:'08:30', category:'房贷', accountId:'bank1', loanId:'loan1', note:'房贷月供' },
  { id:14, type:'expense', amount:6800, date:'2026-04-20', time:'08:30', category:'房贷', accountId:'bank1', loanId:'loan1', note:'房贷月供' },
  { id:15, type:'expense', amount:6800, date:'2026-03-20', time:'08:30', category:'房贷', accountId:'bank1', loanId:'loan1', note:'房贷月供' },
  { id:16, type:'expense', amount:6800, date:'2026-02-20', time:'08:30', category:'房贷', accountId:'bank1', loanId:'loan1', note:'房贷月供' },
  { id:17, type:'income', amount:23500, date:'2026-05-22', time:'10:00', category:'工资', accountId:'bank1', note:'5月薪资' },
  { id:18, type:'income', amount:23500, date:'2026-04-22', time:'10:00', category:'工资', accountId:'bank1', note:'4月薪资' },
  { id:19, type:'income', amount:23500, date:'2026-03-22', time:'10:00', category:'工资', accountId:'bank1', note:'3月薪资' },
  { id:20, type:'income', amount:23500, date:'2026-02-22', time:'10:00', category:'工资', accountId:'bank1', note:'2月薪资' }
])

export function addTransactionFactory(t){
  const tx = Object.assign({ id: ++txSeq, date: DEMO_TODAY, time: '刚刚', note: '', reportable: true }, t)
  transactions.unshift(tx)
  return tx
}
export function addExpense({ amount, category, accountId, date, note }){
  const acc = accountById(accountId)
  const amt = round2(amount)
  if(!acc || amt <= 0) return null
  if(acc.type === 'stored' && amt > acc.balance) return null
  acc.balance = round2(acc.balance - amt)
  return addTransactionFactory({ type:'expense', amount:amt, category:category, accountId:accountId, date:date || DEMO_TODAY, note:note || '', reportable: acc.type !== 'stored' })
}
export function addIncome({ amount, category, accountId, date, note }){
  const acc = accountById(accountId)
  const amt = round2(amount)
  if(!acc || amt <= 0) return null
  acc.balance = round2(acc.balance + amt)
  return addTransactionFactory({ type:'income', amount:amt, category:category, accountId:accountId, date:date || DEMO_TODAY, note:note || '' })
}
function adjustTransactionAccount(tx, sign){
  const acc = accountById(tx.accountId)
  if(!acc) return
  const delta = tx.type === 'expense' ? -tx.amount : tx.amount
  acc.balance = round2(acc.balance + sign * delta)
}
export function updateTransaction(id, patch){
  const tx = transactions.find(t => t.id === id)
  if(!tx) return null
  const next = Object.assign({}, tx, patch)
  next.amount = round2(next.amount)
  const newAcc = accountById(next.accountId)
  if(!newAcc || next.amount <= 0) return null
  const oldAcc = accountById(tx.accountId)
  let available = newAcc.balance
  if(oldAcc && oldAcc.id === newAcc.id){
    available = round2(available + (tx.type === 'expense' ? tx.amount : -tx.amount))
  }
  if(next.type === 'expense' && newAcc.type === 'stored' && next.amount > available) return null
  const oldLoan = (tx.loanId && tx.type === 'expense') ? accountById(tx.loanId) : null
  const oldStored = (tx.storedId && tx.type === 'expense' && tx.storedId !== tx.accountId) ? accountById(tx.storedId) : null
  const newLoan = (next.loanId && next.type === 'expense') ? accountById(next.loanId) : null
  const newStored = (next.storedId && next.type === 'expense' && next.storedId !== next.accountId) ? accountById(next.storedId) : null
  if(oldAcc) adjustTransactionAccount(tx, -1)
  if(oldLoan) oldLoan.balance = round2(oldLoan.balance - tx.amount)
  if(oldStored) oldStored.balance = round2(oldStored.balance - tx.amount)
  newAcc.balance = round2(newAcc.balance + (next.type === 'expense' ? -next.amount : next.amount))
  if(newLoan) newLoan.balance = round2(newLoan.balance + next.amount)
  if(newStored) newStored.balance = round2(newStored.balance + next.amount)
  next.reportable = next.type === 'expense' ? newAcc.type !== 'stored' : true
  Object.assign(tx, next)
  return tx
}
export function deleteTransaction(id){
  const i = transactions.findIndex(t => t.id === id)
  if(i < 0) return null
  const tx = transactions[i]
  adjustTransactionAccount(tx, -1)
  if(tx.loanId && tx.type === 'expense'){
    const loan = accountById(tx.loanId)
    if(loan) loan.balance = round2(loan.balance - tx.amount)
  }
  if(tx.storedId && tx.type === 'expense' && tx.storedId !== tx.accountId){
    const stored = accountById(tx.storedId)
    if(stored) stored.balance = round2(stored.balance - tx.amount)
  }
  transactions.splice(i, 1)
  return tx
}

/* ---------- 资产动作 ---------- */
export function createBankAccount({ name, institution, balance, note }){
  const account = {
    id:'bank' + (++accSeq), type:'bank', name:name, institution:institution || '', icon:'bank',
    balance:round2(balance || 0), note:note || ''
  }
  accounts.push(account)
  return account
}
export function createStoredAccount({ name, institution, balance, defaultCategory, note }){
  const account = {
    id:'stored' + (++accSeq), type:'stored', name:name, institution:institution || '', icon:'cart',
    balance:round2(balance || 0), defaultCategory:defaultCategory || '', note:note || ''
  }
  accounts.push(account)
  return account
}
export function createLoanAccount(data){
  const account = {
    id:'loan' + (++accSeq), type:'loan', name:data.name, institution:data.institution || '',
    icon:data.kind === 'car' ? 'car' : data.kind === 'mortgage' ? 'mortgage' : 'loan',
    balance:-round2(data.remainingPrincipal || 0), note:data.note || '',
    loan:{
      kind:data.kind || 'mortgage',
      originalPrincipal:round2(data.originalPrincipal || 0),
      rateBp:Number(data.rateBp) || 0,
      termMonths:Number(data.termMonths) || 0,
      startAt:data.startAt || DEMO_TODAY,
      nextDueAt:data.nextDueAt || DEMO_TODAY,
      perAmount:round2(data.perAmount || 0),
      repaymentMethod:data.repaymentMethod || 'equal_principal_interest',
      note:data.note || ''
    }
  }
  accounts.push(account)
  return account
}
export function updateBankAccount(account, data){
  if(!account) return
  account.name = data.name
  account.institution = data.institution || ''
  account.note = data.note || ''
}
export function updateStoredAccount(account, data){
  if(!account) return
  account.name = data.name
  account.institution = data.institution || ''
  account.defaultCategory = data.defaultCategory || ''
  account.note = data.note || ''
}
export function updateLoanAccount(account, data){
  if(!account || !account.loan) return
  account.name = data.name
  account.institution = data.institution || ''
  account.icon = data.kind === 'car' ? 'car' : data.kind === 'mortgage' ? 'mortgage' : 'loan'
  account.balance = -round2(data.remainingPrincipal || 0)
  Object.assign(account.loan, {
    kind:data.kind || account.loan.kind,
    originalPrincipal:round2(data.originalPrincipal || 0),
    rateBp:Number(data.rateBp) || 0,
    termMonths:Number(data.termMonths) || 0,
    startAt:data.startAt || account.loan.startAt,
    nextDueAt:data.nextDueAt || account.loan.nextDueAt,
    perAmount:round2(data.perAmount || 0),
    repaymentMethod:data.repaymentMethod || account.loan.repaymentMethod,
    note:data.note || ''
  })
  account.note = data.note || ''
}
export function createDeposit({ bank, name, principal, rateBp, termMonths, startAt, certificateNo, note, sourceAccountId }){
  const p = round2(principal)
  if(p <= 0) return null
  const start = startAt || DEMO_TODAY
  const maturityAt = addMonths(start, termMonths)
  if(sourceAccountId){
    const src = accountById(sourceAccountId)
    if(!src || p > src.balance) return null
  }
  const id = 'deposit' + (++accSeq)
  const account = {
    id:id, type:'deposit', name:name || (bank + termLabel(termMonths) + '存单'), institution:bank,
    icon:'deposit', balance:p,
    deposit:{ certificateNo:certificateNo || '', principal:p, rateBp:Number(rateBp) || 0, termMonths:Number(termMonths) || 12, startAt:start, maturityAt:maturityAt, closedAt:null, closeType:null, actualInterest:null, note:note || '' }
  }
  accounts.push(account)
  if(sourceAccountId){
    const src = accountById(sourceAccountId)
    if(src) src.balance = round2(src.balance - p)
  }
  return account
}
export function updateDeposit(account, data){
  if(!account || !account.deposit) return
  const p = round2(data.principal)
  account.name = data.name || account.name
  account.institution = data.bank || account.institution
  Object.assign(account.deposit, {
    certificateNo:data.certificateNo || '',
    principal:p,
    rateBp:Number(data.rateBp) || 0,
    termMonths:Number(data.termMonths) || 12,
    startAt:data.startAt || account.deposit.startAt,
    maturityAt:addMonths(data.startAt || account.deposit.startAt, Number(data.termMonths) || 12),
    note:data.note || ''
  })
  account.balance = p
}
export function termLabel(m){ return ({1:'1个月',3:'3个月',6:'6个月',12:'1年',24:'2年',36:'3年',60:'5年'})[m] || (m + '个月') }

export function settleDeposit(account, { actualInterest, mode }){
  if(!account || !account.deposit || account.deposit.closedAt) return
  const d = account.deposit
  const interest = round2(actualInterest)
  const principal = d.principal
  const bank = accountById('bank1')
  if(bank) bank.balance = round2(bank.balance + principal + interest)
  account.balance = 0
  d.closedAt = DEMO_TODAY
  d.closeType = mode === 'early' ? 'early' : 'maturity'
  d.actualInterest = interest
  if(interest > 0){
    addTransactionFactory({ type:'income', amount:interest, category:'利息', accountId:bank ? bank.id : 'bank1', date:DEMO_TODAY, note:account.name + (mode === 'early' ? '提前支取利息' : '到期利息') })
  }
}
export function renewDeposit(account, data){
  if(!account || !account.deposit || account.deposit.closedAt) return null
  const d = account.deposit
  const interest = round2(data.actualInterest)
  const newPrincipal = round2(data.newPrincipal)
  const newAccount = {
    id:'deposit' + (++accSeq), type:'deposit', name:data.name || (account.institution + termLabel(data.termMonths) + '存单'),
    institution:account.institution, icon:'deposit', balance:newPrincipal,
    deposit:{ certificateNo:data.certificateNo || '', principal:newPrincipal, rateBp:Number(data.rateBp) || 0, termMonths:Number(data.termMonths) || 12, startAt:data.startAt || DEMO_TODAY, maturityAt:addMonths(data.startAt || DEMO_TODAY, Number(data.termMonths) || 12), closedAt:null, closeType:null, actualInterest:null, note:data.note || '' }
  }
  account.balance = 0
  d.closedAt = DEMO_TODAY
  d.closeType = 'renew'
  d.actualInterest = interest
  accounts.push(newAccount)
  if(interest > 0){
    addTransactionFactory({ type:'income', amount:interest, category:'利息', accountId:newAccount.id, date:DEMO_TODAY, note:account.name + '转存利息' })
  }
  return newAccount
}
export function deleteAccount(account){
  const i = accounts.indexOf(account)
  if(i >= 0) accounts.splice(i, 1)
}

export function rechargeStored(account, { paid, bonus, date, note }){
  if(!account) return false
  const p = round2(paid); const b = round2(bonus)
  const bank = accountById('bank1')
  if(p <= 0 || b < 0) return false
  if(bank && p > bank.balance) return false
  if(bank) bank.balance = round2(bank.balance - p)
  account.balance = round2(account.balance + p + b)
  addTransactionFactory({ type:'expense', amount:p, category:'储值卡充值', accountId:bank ? bank.id : 'bank1', storedId:account.id, date:date || DEMO_TODAY, note:(account.name || '储值卡') + '充值' + (note ? ' · ' + note : '') })
  if(b > 0){
    addTransactionFactory({ type:'income', amount:b, category:'赠送', accountId:account.id, date:date || DEMO_TODAY, note:account.name + '充值赠送' })
  }
  return true
}
export function repayCredit(account, { amount, date, note }){
  if(!account) return false
  const amt = round2(amount)
  const due = Math.abs(account.balance)
  const bank = accountById('bank1')
  if(amt <= 0 || amt > due) return false
  if(bank && amt > bank.balance) return false
  if(bank) bank.balance = round2(bank.balance - amt)
  account.balance = round2(account.balance + amt)
  return true
}
export function repayLoan(account, { amount, date, note }){
  if(!account || !account.loan) return false
  const amt = round2(amount)
  const due = Math.abs(account.balance)
  const bank = accountById('bank1')
  if(amt <= 0 || amt > due) return false
  if(bank && amt > bank.balance) return false
  if(bank) bank.balance = round2(bank.balance - amt)
  account.balance = round2(account.balance + amt)
  account.loan.nextDueAt = addMonths(account.loan.nextDueAt || DEMO_TODAY, 1)
  const category = account.loan.kind === 'car' ? '车贷' : (account.loan.kind === 'mortgage' ? '房贷' : '贷款')
  addTransactionFactory({ type:'expense', amount:amt, category:category, accountId:bank ? bank.id : 'bank1', loanId:account.id, date:date || DEMO_TODAY, note:account.name + '月供' + (note ? ' · ' + note : '') })
  return true
}

/* ---------- 报表 ---------- */
export function periodRange(seg, offset){
  offset = Number(offset) || 0
  const base = parseDate(DEMO_TODAY)
  if(seg === '周'){
    const mondayOffset = (base.getDay() + 6) % 7
    const start = addDays(DEMO_TODAY, -mondayOffset + offset * 7)
    return [start, addDays(start, 6)]
  }
  if(seg === '月'){
    const d = new Date(base.getFullYear(), base.getMonth() + offset, 1)
    return [fmtDate(d), fmtDate(new Date(d.getFullYear(), d.getMonth() + 1, 0))]
  }
  if(seg === '季'){
    const q = Math.floor(base.getMonth() / 3) + offset
    const d = new Date(base.getFullYear(), q * 3, 1)
    return [fmtDate(d), fmtDate(new Date(d.getFullYear(), q * 3 + 3, 0))]
  }
  const y = base.getFullYear() + offset
  return [y + '-01-01', y + '-12-31']
}
export function periodLabelFor(seg, offset){
  offset = Number(offset) || 0
  const from = periodRange(seg, offset)[0]
  if(seg === '周') return (offset === 0 ? '本周 ' : '') + shortDate(periodRange(seg, offset)[0]) + ' 至 ' + shortDate(periodRange(seg, offset)[1])
  if(seg === '月') return from.slice(0,4) + '年' + Number(from.slice(5,7)) + '月'
  if(seg === '季') return from.slice(0,4) + ' Q' + Math.floor((Number(from.slice(5,7)) - 1) / 3 + 1)
  return from.slice(0,4) + '年'
}
export function shortPeriodLabel(seg, offset){
  offset = Number(offset) || 0
  const from = periodRange(seg, offset)[0]
  if(seg === '周') return shortDate(from)
  if(seg === '月') return Number(from.slice(5,7)) + '月'
  if(seg === '季') return 'Q' + Math.floor((Number(from.slice(5,7)) - 1) / 3 + 1)
  return from.slice(0,4)
}
function inRange(t, from, to){ return t.date >= from && t.date <= to && t.reportable !== false }
function totalsFor(seg, offset){
  const range = periodRange(seg, offset)
  const list = transactions.filter(t => inRange(t, range[0], range[1]))
  const income = round2(list.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0))
  const expense = round2(list.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0))
  return { from:range[0], to:range[1], list:list, income:income, expense:expense }
}
function buildTrend(seg, from, to, list, kind){
  if(seg === '季' || seg === '年'){
    const start = parseDate(from)
    const count = seg === '季' ? 3 : 12
    return Array.from({ length:count }, (_, i) => {
      const d = new Date(start.getFullYear(), start.getMonth() + i, 1)
      const key = fmtDate(d).slice(0,7)
      return round2(list.filter(t => t.type === kind && t.date.slice(0,7) === key).reduce((s, t) => s + t.amount, 0))
    })
  }
  const days = Math.max(1, daysBetween(from, to) + 1)
  return Array.from({ length:days }, (_, i) => {
    const d = addDays(from, i)
    return round2(list.filter(t => t.type === kind && t.date === d).reduce((s, t) => s + t.amount, 0))
  })
}
export function reportFor(seg, kind, offset){
  kind = kind === 'income' ? 'income' : 'expense'
  offset = Number(offset) || 0
  const cur = totalsFor(seg, offset)
  const prev = totalsFor(seg, offset - 1)
  const total = round2(kind === 'income' ? cur.income : cur.expense)
  const prevTotal = round2(kind === 'income' ? prev.income : prev.expense)
  const change = round2(total - prevTotal)
  const changePct = prevTotal > 0 ? Math.round(change / prevTotal * 100) : null
  const days = Math.max(1, daysBetween(cur.from, cur.to) + 1)
  const map = {}
  cur.list.filter(t => t.type === kind).forEach(t => {
    if(!map[t.category]) map[t.category] = { name:t.category, amount:0, count:0 }
    map[t.category].amount = round2(map[t.category].amount + t.amount)
    map[t.category].count++
  })
  const cats = Object.values(map).sort((a, b) => b.amount - a.amount)
  cats.forEach(c => { c.pct = Math.round(c.amount / Math.max(1, total) * 100) })
  const top = cur.list.filter(t => t.type === kind).sort((a, b) => b.amount - a.amount).slice(0, 20).map(t => {
    const a = accountById(t.accountId)
    return Object.assign({}, t, { accountName: a ? a.name : '' })
  })
  const comparison = Array.from({ length:5 }, (_, i) => {
    const o = offset - 4 + i
    const t = totalsFor(seg, o)
    return { label:shortPeriodLabel(seg, o), amount:round2(kind === 'income' ? t.income : t.expense), current:o === offset }
  })
  return {
    from:cur.from, to:cur.to, income:cur.income, expense:cur.expense,
    balance:round2(cur.income - cur.expense), total:total, prevTotal:prevTotal,
    change:change, changePct:changePct, daily:round2(total / days),
    cats:cats, trend:buildTrend(seg, cur.from, cur.to, cur.list, kind),
    top:top, comparison:comparison
  }
}

/* ---------- 待办 ---------- */
export function dueItems(){
  const items = []
  accounts.filter(a => a.type === 'deposit').forEach(a => {
    const s = depositStatus(a)
    if(s.key === 'due' || s.key === 'matured'){
      items.push({ kind:'deposit', account:a, status:s, days:daysToMaturity(a), title:a.name,
        sub:s.key === 'matured' ? '已到期 · 待支取' : '还有 ' + Math.max(0, daysToMaturity(a)) + ' 天到期' })
    }
  })
  accounts.filter(a => a.type === 'credit' && a.balance < 0).forEach(credit => {
    const day = Number(credit.repaymentDay || 0)
    const days = day - 22
    if(day && days >= 0 && days <= 7){
      items.push({ kind:'credit', account:credit, days:days, title:credit.name, sub:days === 0 ? '今天还款日' : '还款日还有 ' + days + ' 天' })
    }
  })
  accounts.filter(a => a.type === 'loan').forEach(loan => {
    if(!loan.loan) return
    const days = daysBetween(DEMO_TODAY, loan.loan.nextDueAt)
    if(days >= 0 && days <= 7){
      items.push({ kind:'loan', account:loan, days:days, title:loan.name, sub:'下次还款 ' + shortDate(loan.loan.nextDueAt) })
    }
  })
  return items.sort((a, b) => a.days - b.days).slice(0, 3)
}

/* ---------- 全局状态 ---------- */
export const store = reactive({
  tab: 'home',
  tabBar: 'home',
  sheet: null,
  toastShow: false,
  toastMsg: '',
  keyword: '',
  depositId: null,
  cardId: null,
  loanId: null,
  categoryEditId: null,
  categoryType: 'expense',
  settleMode: 'maturity',
  addSourceAccountId: 'bank1',
  txEditId: null,
  accountFormType: 'bank',
  accountEditId: null
})
let __toastTimer = null
export function showToast(msg){
  store.toastMsg = msg; store.toastShow = true
  clearTimeout(__toastTimer)
  __toastTimer = setTimeout(function(){ store.toastShow = false }, 2000)
}

export const confirmState = reactive({ show:false, title:'确认删除', message:'', confirmText:'删除', danger:true, onOk:null })
export function askConfirm(message, onOk, options){
  options = options || {}
  confirmState.title = options.title || '确认删除'
  confirmState.message = message
  confirmState.confirmText = options.confirmText || '删除'
  confirmState.danger = options.danger !== false
  confirmState.onOk = onOk
  confirmState.show = true
}
export function closeConfirm(){ confirmState.show = false; confirmState.onOk = null }

export function openSheet(name){ store.sheet = name }
export function openRecord(txId){ store.txEditId = txId || null; store.sheet = '记一笔' }
export function openAccountForm(type, accountId){
  store.accountFormType = type || 'bank'
  store.accountEditId = accountId || null
  store.sheet = '账户编辑'
}
export function closeSheet(){ store.sheet = null }
export function showScreen(name){ store.tab = name }
export function switchTab(name){ store.tabBar = name; store.tab = name }
export function backToTab(){ store.tab = store.tabBar }

/* ---------- 设置 / 备份 ---------- */
export const settingsData = reactive({
  webdavUrl: 'https://dav.jianguoyun.com/dav/',
  webdavUser: 'linxiao@example.com',
  webdavPass: 'app-pass-2026',
  webdavDir: '/记账备份/',
  connected: true,
  autoBackup: true,
  lastBackup: '2026-06-22 08:30',
  defaultAccountId: 'bank1'
})
export const backupsData = reactive([
  { name:'backup_20260622_083000.zip', at:'2026-06-22 08:30', size:'2.4 MB' },
  { name:'backup_20260621_221500.zip', at:'2026-06-21 22:15', size:'2.3 MB' },
  { name:'backup_20260620_090000.zip', at:'2026-06-20 09:00', size:'2.3 MB' },
  { name:'backup_20260618_203000.zip', at:'2026-06-18 20:30', size:'2.2 MB' },
  { name:'backup_20260615_090000.zip', at:'2026-06-15 09:00', size:'2.2 MB' }
])
