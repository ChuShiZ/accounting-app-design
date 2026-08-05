/* ⑥ 搜索页：关键词 + 筛选结果 */
window.搜索页 = {
  setup(){ return { store: window.store, homeData: window.homeData, fmt: window.fmt, icon: window.icon, openSheet: window.openSheet, backToTab: window.backToTab } },
  computed: {
    results(){
      const min = window.store.filterMin!=='' ? parseFloat(window.store.filterMin) : NaN
      const max = window.store.filterMax!=='' ? parseFloat(window.store.filterMax) : NaN
      const kw = (window.store.keyword||'').trim().toLowerCase()
      return window.homeData.filter(t=>{
        if(kw && !(t.remark||'').toLowerCase().includes(kw) && !(t.cat||'').toLowerCase().includes(kw)) return false
        if(window.store.searchFilter.cat.length && !window.store.searchFilter.cat.includes(t.catKey)) return false
        if(window.store.searchFilter.type.length){
          const ok = (window.store.searchFilter.type.includes('支出')&&t.cls==='expense')
                  || (window.store.searchFilter.type.includes('收入')&&t.cls==='income')
                  || (window.store.searchFilter.type.includes('周期扣款')&&t.cls==='liability')
                  || (window.store.searchFilter.type.includes('卡片消费')&&t.cls==='balance')
          if(!ok) return false
        }
        if(window.store.searchFilter.time.length){
          const covered = new Set()
          window.store.searchFilter.time.forEach(p=>{ (window.timeCover[p]||[p]).forEach(x=>covered.add(x)) })
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
    sum(list){ return window.fmt(window.flowSum(list)) },
    editFlow(t){ window.store.flowEditIdx = window.homeData.indexOf(t); window.openSheet('记录') }
  },
  template: `
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
        <div class="flow-item" v-for="(t,i) in g[1]" :key="i" @click="editFlow(t)">
          <div class="badge" :class="'badge--'+t.cls" v-html="icon(t.icon,20)"></div>
          <div class="flow-main"><div class="cat">{{t.cat}}</div><div class="sub">{{t.remark}} · {{t.time}}</div></div>
          <div class="flow-amount amount amount-lg" :class="'amount--'+t.cls">{{fmt(t.amount)}}</div>
        </div>
      </div>
    </template>
  </div>`
}
