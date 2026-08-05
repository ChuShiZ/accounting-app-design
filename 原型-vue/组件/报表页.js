/* ⑤ 报表页：分段 + 汇总 2×2 + 环形 + 分类明细 + 消费排行 + 趋势 */
window.报表页 = {
  setup(){ return { store: window.store, fmt: window.fmt, icon: window.icon, periodLabel: window.periodLabel, catColors: window.catColors } },
  data(){ return { seg:'月', ranking:'本月' } },
  computed: {
    d(){ return window.reportData[this.seg] || window.reportData['月'] },
    cats(){ return this.d.cats },
    total(){ return this.d.expense },
    daily(){ return Math.round(this.d.expense/window.periodDays[this.seg]*100)/100 },
    diffLabel(){ return window.diffLabels[this.seg] || '比上月支出' },
    balance(){ return this.d.income - this.d.expense },
    diffHtml(){ return '<span class="diff-arrow">'+(this.d.diff>=0?'↑':'↓')+'</span>'+Math.abs(this.d.diff)+'%' },
    trendPoints(){
      const tr = this.d.trend
      const tmin = Math.min.apply(null,tr), tmax = Math.max.apply(null,tr)
      return tr.map((v,i)=>{
        const x = i*(320/(tr.length-1||1))
        const y = 140 - ((v-tmin)/((tmax-tmin)||1))*110 - 10
        return x.toFixed(1)+','+y.toFixed(1)
      }).join(' ')
    },
    donutArcs(){
      const C = 339.3; let off = 0
      return this.d.cats.map((c,i)=>{
        const len = Math.round(c[1]/this.d.expense*C*10)/10
        const arc = { len:len, off:off, color: window.catColors[i]||'var(--color-primary)' }
        off += len
        return arc
      })
    },
    rankList(){
      const valid = window.rankPeriodMap[this.ranking] || ['本周','本月']
      return window.expenseRankingData.filter(x=>valid.includes(x.period)).sort((a,b)=>b.amt-a.amt).slice(0,10)
    },
    rankTotal(){ return this.rankList.reduce((s,d)=>s+d.amt,0) }
  },
  methods: {
    catPct(c){ return Math.round(c[1]/this.d.expense*100) },
    rankPct(d){ return Math.round(d.amt/this.rankTotal*100) },
    rankIcon(cat){ return cat.indexOf('餐饮')>=0?'food':(cat.indexOf('购物')>=0?'card':(cat.indexOf('交通')>=0?'car':(cat.indexOf('居家')>=0?'building':'cart'))) },
    rankCls(i){ return i<3 ? 'top3' : 'other' },
    catColor(c){ return c[2]==='liability' ? 'var(--color-liability)' : 'var(--color-primary)' },
    catCls(c){ return c[2]==='liability' ? ' amount--liability' : '' }
  },
  template: `
  <header class="app-header"><div class="title h1">统计报表</div></header>
  <div class="app-content">
    <div style="display:flex;justify-content:center;margin-bottom:var(--space-4)">
      <div class="segmented">
        <button v-for="s in ['周','月','季','年']" :key="s" :class="{active:seg===s}" @click="seg=s">{{s}}</button>
      </div>
    </div>
    <div class="overview" id="report-summary">
      <div class="cell"><div class="label caption">支出</div><div class="amount amount-lg amount--expense">{{fmt(total)}}</div></div>
      <div class="cell"><div class="label caption" style="text-align:right">日均支出</div><div class="amount amount-lg amount--expense" style="text-align:right">{{fmt(daily)}}</div></div>
      <div class="cell"><div class="label caption">{{diffLabel}}</div><div class="amount amount-lg amount--expense" v-html="diffHtml"></div></div>
      <div class="cell"><div class="label caption" style="text-align:right">收支结余</div><div class="amount amount-lg" :class="balance>=0?'amount--income':'amount--expense'" style="text-align:right">{{fmt(balance)}}</div></div>
    </div>
    <div class="section-gap"></div>
    <div class="chart-card">
      <div class="chart-head"><div class="h2">支出分类构成</div></div>
      <div class="donut-wrap">
        <svg viewBox="0 0 140 140" width="170" height="170">
          <circle cx="70" cy="70" r="54" fill="none" stroke="var(--color-divider)" stroke-width="12"/>
          <circle v-for="(a,i) in donutArcs" :key="i" cx="70" cy="70" r="54" fill="none" :stroke="a.color" stroke-width="12" :stroke-dasharray="a.len+' 339.3'" :stroke-dashoffset="-a.off" transform="rotate(-90 70 70)"/>
        </svg>
        <div class="donut-center">
          <div class="caption" style="color:var(--color-text-secondary)">{{periodLabel[seg]}}总支出</div>
          <div class="amount amount-lg amount--expense">{{fmt(total)}}</div>
        </div>
      </div>
      <div class="legend" style="justify-content:center;flex-wrap:wrap;margin-top:var(--space-2)">
        <span v-for="(c,i) in cats" :key="i"><i :style="{background:catColors[i]}"></i>{{c[0]}} {{fmt(c[1])}}</span>
      </div>
    </div>
    <div class="section-gap"></div>
    <div class="section-title">分类明细</div>
    <div class="card">
      <div class="bar-row" v-for="(c,i) in cats" :key="i">
        <span class="name">{{c[0]}}</span>
        <div class="track"><div class="fill" :style="{width:catPct(c)+'%',background:catColor(c)}"></div></div>
        <span class="val amount" :class="catCls(c)">{{fmt(c[1])}}</span>
      </div>
    </div>
    <div class="section-gap"></div>
    <div class="chart-card" id="ranking-card">
      <div class="chart-head"><div class="h2">消费排行</div>
        <div class="segmented" id="ranking-seg">
          <button v-for="s in ['本周','本月','本季','本年']" :key="s" :class="{active:ranking===s}" @click="ranking=s">{{s}}</button>
        </div>
      </div>
      <div v-if="rankList.length>=3">
        <div v-for="(d,i) in rankList" :key="i">
          <div class="rank-item">
            <div class="rank-num" :class="rankCls(i)">#{{i+1}}</div>
            <div class="rank-badge" v-html="icon(rankIcon(d.cat),16)"></div>
            <div class="rank-main"><div class="cat">{{d.cat}}</div><div class="sub">{{d.sub}} · {{d.date}}</div></div>
            <div class="rank-amt"><div class="amount amount-md amount--expense">{{fmt(d.amt)}}</div></div>
          </div>
          <div class="rank-bar" :style="{width:rankPct(d)+'%'}"></div>
        </div>
      </div>
      <div v-else style="text-align:center;padding:var(--space-8) 0;color:var(--color-text-secondary);font-size:14px">数据不足，暂无排行</div>
    </div>
    <div class="section-gap"></div>
    <div class="chart-card">
      <div class="chart-head"><div class="h2">支出趋势</div>
        <div class="legend"><span><i style="background:var(--color-primary)"></i>支出</span></div>
      </div>
      <svg viewBox="0 0 320 160" width="100%" height="160" fill="none">
        <line x1="0" y1="20" x2="320" y2="20" stroke="var(--color-divider)" stroke-width="1"/>
        <line x1="0" y1="60" x2="320" y2="60" stroke="var(--color-divider)" stroke-width="1"/>
        <line x1="0" y1="100" x2="320" y2="100" stroke="var(--color-divider)" stroke-width="1"/>
        <line x1="0" y1="140" x2="320" y2="140" stroke="var(--color-divider)" stroke-width="1"/>
        <polyline :points="trendPoints" fill="none" stroke="var(--color-primary)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </div>
    <div class="section-gap"></div>
  </div>`
}
