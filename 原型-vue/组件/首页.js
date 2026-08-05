/* ① 首页：概览卡 + 搜索 + 最近交易分组 */
window.首页 = {
  setup(){ return { store: window.store, homeData: window.homeData, fmt: window.fmt, icon: window.icon, openSheet: window.openSheet, showScreen: window.showScreen } },
  computed: {
    today(){ return window.homeData.filter(t=>t.group==='今天') },
    yesterday(){ return window.homeData.filter(t=>t.group==='昨天') },
    earlier(){ return window.homeData.filter(t=>t.group==='更早') }
  },
  methods: {
    sum(list){ return window.fmt(window.flowSum(list)) },
    editFlow(i){ window.store.flowEditIdx = i; window.openSheet('记录') }
  },
  template: `
  <header class="app-header">
    <div class="title"><div class="caption" style="color:var(--color-text-secondary)">2026年6月22日 周一</div><div class="h1">我的账单</div></div>
  </header>
  <div class="app-content">
    <div class="overview">
      <div class="cell"><div class="label caption">今日支出</div><div class="amount amount-lg amount--expense">¥86.50</div></div>
      <div class="cell"><div class="label caption" style="text-align:right">本月支出</div><div class="amount amount-lg amount--expense" style="text-align:right">¥12,840.00</div></div>
      <div class="cell full"><div class="label caption">本月收入</div><div class="amount amount-xl amount--income">¥23,500.00</div></div>
    </div>
    <div style="margin-top:var(--space-4)">
      <div class="search-box" @click="showScreen('search')">
        <span v-html="icon('search',18)"></span>
        <input type="text" placeholder="搜索交易、卡片、备注" readonly />
      </div>
    </div>
    <div class="section-gap"></div>
    <div class="section-title">最近交易</div>
    <template v-for="(g,gi) in [['今天',today],['昨天',yesterday],['更早',earlier]]" :key="gi">
      <div v-if="g[1].length" class="group-header"><span>{{g[0]}}</span><span class="amount amount-md">{{sum(g[1])}}</span></div>
      <div v-if="g[1].length" class="group-card">
        <div class="flow-item" v-for="(t,i) in g[1]" :key="i" @click="editFlow(homeData.indexOf(t))">
          <div class="badge" :class="'badge--'+t.cls" v-html="icon(t.icon,20)"></div>
          <div class="flow-main"><div class="cat">{{t.cat}}</div><div class="sub">{{t.remark}} · {{t.time}}</div></div>
          <div class="flow-amount amount amount-lg" :class="'amount--'+t.cls">{{fmt(t.amount)}}</div>
        </div>
      </div>
    </template>
  </div>`
}
