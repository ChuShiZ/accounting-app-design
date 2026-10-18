<template>
  <div class="page">
  <header class="app-header">
    <div class="title">
      <div class="caption" style="color:var(--color-text-secondary)">2026年6月22日 周一</div>
      <div class="h1">我的账单</div>
    </div>
    <button v-if="dueAll.length" class="due-pill" @click="openSheet('待办')">
      <span class="due-pill-dot"></span>待办 {{dueAll.length}}
    </button>
  </header>
  <div class="app-content">
    <div class="overview home-overview">
      <div class="cell full">
        <div class="label">今日支出</div>
        <div class="home-hero">{{fmt(todayExpense)}}</div>
      </div>
      <div class="cell">
        <div class="label">本月支出</div>
        <div class="home-secondary">{{fmt(month.expense)}}</div>
      </div>
      <div class="cell" style="text-align:right">
        <div class="label" style="text-align:right">本月收入</div>
        <div class="home-secondary" style="text-align:right">{{fmt(month.income)}}</div>
      </div>
      <div class="cell full home-balance">
        <span>本月结余</span><span>{{fmtSigned(month.balance)}}</span>
      </div>
    </div>

    <div class="search-box" style="margin-top:var(--space-4)">
      <span v-html="icon('search',18)"></span>
      <input type="text" v-model="keyword" placeholder="搜索类别、备注、账户" />
      <button v-if="keyword" class="filter-btn" @click="keyword=''">清除</button>
    </div>

    <div class="section-gap"></div>
    <div class="section-title">最近交易</div>

    <div v-if="!groups.length" class="empty">
      <div class="ic" v-html="icon('empty',24)"></div>
      <div class="t">{{keyword ? '没有匹配记录' : '还没有记录'}}</div>
      <div class="d">{{keyword ? '换个关键词试试，或点“清除”。' : '点底部 + 记一笔。'}}</div>
    </div>

    <template v-for="g in groups" :key="g.label">
      <div class="group-header"><span>{{g.label}}</span><span v-if="g.expense" class="group-sum">{{fmt(g.expense)}}</span></div>
      <div class="group-card">
        <div class="flow-item" v-for="t in g.list" :key="t.id" @click="editFlow(t)">
          <div class="badge" :style="{color:colorForCategory(t.category,t.type)}" v-html="icon(categoryIcon(t.category,t.type),24)"></div>
          <div class="flow-main">
            <div class="cat">{{t.category}}</div>
            <div class="sub">{{t.note || accountName(t.accountId)}} · {{t.time}}</div>
          </div>
          <div class="flow-amount amount amount-md" :class="'amount--'+amountCls(t)">
            {{t.type==='income'?'+':'-'}}{{fmt(t.amount)}}
          </div>
        </div>
      </div>
    </template>

    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { store, transactions, fmt, fmtSigned, icon, dueItems, accountById, reportFor, openRecord, openSheet, DEMO_TODAY, shortDate, iconForCategory, colorForCategory } from '../store.js'

export default {
  name: 'HomePage',
  setup(){ return { store, fmt, fmtSigned, icon, colorForCategory, openSheet } },
  data(){ return { keyword:'' } },
  computed: {
    month(){ return reportFor('月') },
    todayExpense(){
      const sum = transactions.filter(t => t.date === DEMO_TODAY && t.type === 'expense' && t.reportable !== false).reduce((s, t) => s + t.amount, 0)
      return Math.round(sum * 100) / 100
    },
    dueAll(){ return dueItems() },
    filtered(){
      const kw = (this.keyword || '').trim().toLowerCase()
      if(!kw) return transactions
      return transactions.filter(t => {
        const acc = accountById(t.accountId)
        return (t.category || '').toLowerCase().includes(kw)
          || (t.note || '').toLowerCase().includes(kw)
          || (acc ? acc.name.toLowerCase().includes(kw) : false)
      })
    },
    groups(){
      const map = {}
      const list = this.filtered.slice().sort((a,b) => (b.date+b.time).localeCompare(a.date+a.time))
      list.forEach(t => {
        const label = t.date === DEMO_TODAY ? '今天' : (t.date === '2026-06-21' ? '昨天' : shortDate(t.date))
        if(!map[label]) map[label] = { label:label, list:[], expense:0 }
        map[label].list.push(t)
        if(t.type === 'expense' && t.reportable !== false) map[label].expense += t.amount
      })
      const order = ['今天','昨天']
      return Object.keys(map).map(k => map[k]).sort((a,b) => {
        const ia = order.indexOf(a.label), ib = order.indexOf(b.label)
        if(ia >= 0 || ib >= 0) return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib)
        return b.label.localeCompare(a.label)
      })
    }
  },
  methods: {
    editFlow(t){ openRecord(t.id) },
    accountName(id){ const a = accountById(id); return a ? a.name : '' },
    categoryIcon(c, type){ return iconForCategory(c, type) },
    amountCls(t){
      if(t.type === 'income') return 'income'
      if(t.category === '房贷' || t.category === '车贷' || t.category === '贷款') return 'liability'
      return 'expense'
    }
  }
}
</script>
