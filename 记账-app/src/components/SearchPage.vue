<template>
  <div class="page">
  <header class="app-header">
    <button class="icon-btn" @click="backToTab" aria-label="返回"><span v-html="icon('back',22)"></span></button>
    <div class="title" style="flex:1">
      <div class="search-box" style="background:var(--color-surface-2)">
        <span v-html="icon('search',18)"></span>
        <input type="text" v-model="store.keyword" placeholder="搜索交易" />
        <button class="filter-btn" @click="openSheet('筛选')">筛选</button>
      </div>
    </div>
  </header>
  <div class="app-content">
    <div class="caption" style="color:var(--color-text-secondary);padding:var(--space-2) 0">本月 · 共 <span>{{results.length}}</span> 笔</div>
    <div v-if="!results.length" class="empty">
      <div class="ic" v-html="icon('empty',24)"></div>
      <div class="t">没有找到记录</div>
      <div class="d">试着调整筛选条件，或更换关键词重新搜索。</div>
    </div>
    <template v-for="(g,gi) in groups()" :key="gi">
      <div class="group-header"><span>{{g[0]}}</span></div>
      <div class="group-card">
        <SwipeDelete v-for="(t,i) in g[1]" :key="i" @delete="confirmDelete(t)">
          <div class="flow-item" @click="editFlow(t)">
            <div class="badge" :class="'badge--'+t.cls" v-html="icon(t.icon,20)"></div>
            <div class="flow-main"><div class="cat">{{t.cat}}</div><div class="sub">{{t.remark}} · {{t.time}}</div></div>
            <div class="flow-amount amount amount-lg" :class="'amount--'+t.cls">{{fmt(t.amount)}}</div>
          </div>
        </SwipeDelete>
      </div>
    </template>
  </div>
  </div>
</template>

<script>
import { store, homeData, fmt, icon, openSheet, backToTab, flowSum, timeCover, showToast, askConfirm } from '../store.js'
import SwipeDelete from './SwipeDelete.vue'

/* ⑥ 搜索页：关键词 + 筛选结果（左滑删除） */
export default {
  name: 'SearchPage',
  components: { SwipeDelete },
  setup(){ return { store, homeData, fmt, icon, openSheet, backToTab } },
  computed: {
    results(){
      const min = store.filterMin!=='' ? parseFloat(store.filterMin) : NaN
      const max = store.filterMax!=='' ? parseFloat(store.filterMax) : NaN
      const kw = (store.keyword||'').trim().toLowerCase()
      return homeData.filter(t=>{
        if(kw && !(t.remark||'').toLowerCase().includes(kw) && !(t.cat||'').toLowerCase().includes(kw)) return false
        if(store.searchFilter.cat.length && !store.searchFilter.cat.includes(t.catKey)) return false
        if(store.searchFilter.type.length){
          const ok = (store.searchFilter.type.includes('支出')&&t.cls==='expense')
                  || (store.searchFilter.type.includes('收入')&&t.cls==='income')
                  || (store.searchFilter.type.includes('周期扣款')&&t.cls==='liability')
                  || (store.searchFilter.type.includes('卡片消费')&&t.cls==='balance')
          if(!ok) return false
        }
        if(store.searchFilter.time.length){
          const covered = new Set()
          store.searchFilter.time.forEach(p=>{ (timeCover[p]||[p]).forEach(x=>covered.add(x)) })
          if(!covered.has(t.timeGroup)) return false
        }
        if(!isNaN(min) && t.amount < min) return false
        if(!isNaN(max) && t.amount > max) return false
        return true
      })
    }
  },
  methods: {
    groups(){
      const gs = {}
      this.results.forEach(t=>{ (gs[t.group]=gs[t.group]||[]).push(t) })
      return [['今天',gs['今天']||[]],['昨天',gs['昨天']||[]],['更早',gs['更早']||[]]].filter(x=>x[1].length)
    },
    sum(list){ return fmt(flowSum(list)) },
    editFlow(t){ store.flowEditIdx = homeData.indexOf(t); openSheet('记录') },
    confirmDelete(t){
      const self = this
      askConfirm('确定删除这笔记录吗？', function(){ self.deleteFlow(t) })
    },
    deleteFlow(t){
      const i = homeData.indexOf(t)
      if(i>=0) homeData.splice(i,1)
      showToast('已删除')
    }
  }
}
</script>
