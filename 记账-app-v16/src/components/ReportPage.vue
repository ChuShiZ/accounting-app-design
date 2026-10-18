<template>
  <div class="page report-page">
  <header class="app-header"><div class="title h1">收支报表</div></header>
  <div class="app-content">
    <div class="report-tabs">
      <button v-for="s in segs" :key="s.key" :class="{active:seg===s.key}" @click="setSeg(s.key)">{{s.label}}</button>
    </div>

    <div class="report-controls">
      <div class="period-nav">
        <button class="period-arrow" @click="offset--" aria-label="上一期"><span v-html="icon('back',18)"></span></button>
        <span class="period-label">{{periodText}}</span>
        <button class="period-arrow" :disabled="offset>=0" @click="offset++" aria-label="下一期" style="transform:rotate(180deg)"><span v-html="icon('back',18)"></span></button>
      </div>
      <div class="segmented segmented--sm">
        <button :class="{active:kind==='expense'}" @click="setKind('expense')">支出</button>
        <button :class="{active:kind==='income'}" @click="setKind('income')">收入</button>
      </div>
    </div>

    <div class="overview report-summary">
      <div class="cell">
        <div class="label">{{periodWord}}{{kindLabel}}</div>
        <div class="report-metric">{{fmt(d.total)}}</div>
      </div>
      <div class="cell">
        <div class="label">{{avgLabel}}</div>
        <div class="report-metric">{{avgValue}}</div>
      </div>
      <div class="cell">
        <div class="label">{{prevLabel}} <span v-if="changePctText" class="report-pct" :class="changeCls">{{changePctText}}</span></div>
        <div class="report-metric">{{changeValue}}</div>
      </div>
      <div class="cell">
        <div class="label">收支结余</div>
        <div class="report-metric">{{signed(d.balance)}}</div>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="chart-card">
      <div class="chart-head"><div class="h2">{{kindLabel}}趋势</div><span class="caption" style="color:var(--color-text-secondary)">{{periodText}}</span></div>
      <svg class="trend-chart" viewBox="0 0 320 170" width="100%" height="170" fill="none">
        <defs>
          <linearGradient id="trendFillExpense" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="#4F46E5" stop-opacity=".24"/>
            <stop offset="100%" stop-color="#4F46E5" stop-opacity=".02"/>
          </linearGradient>
          <linearGradient id="trendFillIncome" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="#16A34A" stop-opacity=".22"/>
            <stop offset="100%" stop-color="#16A34A" stop-opacity=".02"/>
          </linearGradient>
        </defs>
        <line v-for="y in [20,60,100,140]" :key="y" x1="0" :y1="y" x2="320" :y2="y" stroke="var(--color-divider)" stroke-width="1"/>
        <polygon :points="areaPoints" :fill="kind==='income'?'url(#trendFillIncome)':'url(#trendFillExpense)'"/>
        <polyline :points="trendPoints" fill="none" :stroke="kind==='income'?'var(--color-income)':'var(--color-primary)'" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <template v-if="maxPoint">
          <line :x1="maxPoint.x" y1="20" :x2="maxPoint.x" y2="140" stroke="var(--color-border-strong)" stroke-width="1" stroke-dasharray="3 3"/>
          <circle :cx="maxPoint.x" :cy="maxPoint.y" r="3.5" :fill="kind==='income'?'var(--color-income)':'var(--color-primary)'"/>
          <g>
            <rect :x="maxPoint.rectX" :y="maxPoint.rectY" :width="maxPoint.rectW" height="22" rx="7" :fill="kind==='income'?'var(--color-income)':'var(--color-primary)'"/>
            <text :x="maxPoint.rectX + maxPoint.rectW / 2" :y="maxPoint.rectY + 15" text-anchor="middle" font-size="9" font-weight="600" fill="#fff">{{maxPoint.tip}}</text>
          </g>
        </template>
      </svg>
      <div class="trend-x">
        <span v-for="(l,i) in trendLabels" :key="i">{{l}}</span>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="chart-card">
      <div class="chart-head"><div class="h2">{{kindLabel}}分类构成</div><span class="report-kicker">主分类</span></div>
      <template v-if="d.cats.length">
        <div class="donut-wrap donut-wrap--labeled">
          <svg viewBox="0 0 300 240" width="100%" height="240" preserveAspectRatio="xMidYMid meet">
            <circle cx="150" cy="120" r="62" fill="none" stroke="var(--color-divider)" stroke-width="18"/>
            <circle v-for="(a,i) in donutArcs" :key="i" cx="150" cy="120" r="62" fill="none" :stroke="a.color" stroke-width="18" :stroke-dasharray="a.len+' '+donutC" :stroke-dashoffset="-a.off" transform="rotate(-90 150 120)"/>
            <template v-for="(l,i) in donutLabels" :key="'label'+i">
              <polyline :points="l.x+','+l.y+' '+l.lx+','+l.ly" :stroke="l.color" stroke-width="1" fill="none" opacity=".6"/>
              <text :x="l.tx" :y="l.ty" :text-anchor="l.anchor" font-size="9.5" fill="var(--color-text-secondary)">{{l.label}}</text>
            </template>
          </svg>
          <div class="donut-center">
            <div class="caption" style="color:var(--color-text-secondary)">{{kindLabel}}合计</div>
            <div class="amount amount-lg">{{fmt(d.total)}}</div>
          </div>
        </div>
        <div class="cat-list">
          <div v-for="(c,i) in visibleCats" :key="c.name" class="cat-row" :class="{active:selectedCat===c.name}" @click="toggleCat(c.name)">
            <span class="cat-rank">#{{i+1}}</span>
            <span class="cat-icon" :style="{color:catColor(c.name)}" v-html="icon(catIcon(c.name),24)"></span>
            <div class="cat-main">
              <div class="cat-name">{{c.name}}</div>
              <div class="cat-sub">{{c.count}} 笔 · {{c.pct}}%</div>
            </div>
            <div class="cat-amount amount amount-md" :class="kind==='income'?'amount--income':'amount--expense'">{{fmt(c.amount)}}</div>
            <span v-html="icon('chevron',16)"></span>
          </div>
          <button v-if="d.cats.length > 6" class="cat-more" @click="showAllCats=!showAllCats">
            {{showAllCats ? '收起' : '查看更多'}} <span v-html="icon('chevron',14)"></span>
          </button>
        </div>
      </template>
      <div v-else class="empty" style="padding:var(--space-6) 0">
        <div class="t">暂无{{kindLabel}}记录</div>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="chart-card">
      <div class="chart-head"><div class="h2">{{compareTitle}}</div><span class="caption" style="color:var(--color-text-secondary)">近 5 期</span></div>
      <div class="compare-bars">
        <div v-for="(c,i) in d.comparison" :key="i" class="compare-item">
          <div class="compare-amount">{{fmtCompact(c.amount)}}</div>
          <div class="compare-track"><div class="compare-bar" :class="{current:c.current}" :style="{height:barHeight(c)+'%'}"></div></div>
          <div class="compare-label">{{c.label}}</div>
        </div>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="chart-card ranking-card">
      <div class="chart-head">
        <div class="h2">{{rankingTitle}}</div>
        <button v-if="selectedCat" class="link-btn" @click="selectedCat=''">清除筛选</button>
      </div>
      <div v-if="!visibleTop.length" class="empty" style="padding:var(--space-8) 0">
        <div class="ic" v-html="icon('empty',24)"></div>
        <div class="t">暂无记录</div>
      </div>
      <div v-else class="rank-list">
        <div class="rank-item" v-for="t in visibleTop" :key="t.id" @click="editFlow(t)">
          <div class="rank-badge" :style="{color:colorForCategory(t.category,t.type)}" v-html="icon(catIcon(t.category),24)"></div>
          <div class="rank-main">
            <div class="cat">{{t.note || t.category}}</div>
            <div class="sub">{{t.date}} · {{t.accountName}}</div>
          </div>
          <div class="rank-amt">
            <div class="amount amount-md" :class="kind==='income'?'amount--income':'amount--expense'">{{kind==='income'?'+':'-'}}{{fmt(t.amount)}}</div>
          </div>
        </div>
        <button v-if="hasMoreTop" class="rank-more" @click="showAllTop=!showAllTop">
          {{showAllTop ? '收起' : '全部排行'}} <span v-html="icon('chevron',14)"></span>
        </button>
      </div>
    </div>

    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { fmt, fmtSigned, fmtShort, icon, reportFor, periodLabelFor, iconForCategory, colorForCategory, openRecord, addDays, shortDate } from '../store.js'

const SEGS = [
  { key:'周', label:'周报' },
  { key:'月', label:'月报' },
  { key:'季', label:'季报' },
  { key:'年', label:'年报' }
]

export default {
  name: 'ReportPage',
  setup(){ return { fmt, fmtSigned, fmtShort, icon, colorForCategory } },
  data(){ return { seg:'月', kind:'expense', offset:0, selectedCat:'', showAllCats:false, showAllTop:false, segs:SEGS, donutC:389.6 } },
  computed: {
    d(){ return reportFor(this.seg, this.kind, this.offset) },
    periodText(){ return periodLabelFor(this.seg, this.offset) },
    kindLabel(){ return this.kind === 'income' ? '收入' : '支出' },
    periodWord(){ return ({周:'本周', 月:'本月', 季:'本季', 年:'本年'})[this.seg] },
    prevWord(){ return ({周:'上周', 月:'上月', 季:'上季', 年:'上年'})[this.seg] },
    prevLabel(){ return '比' + this.prevWord + this.kindLabel },
    avgLabel(){ return (this.seg === '年' || this.seg === '季' ? '月均' : '日均') + this.kindLabel },
    avgValue(){
      if(this.seg === '年') return fmt(this.d.total / 12)
      if(this.seg === '季') return fmt(this.d.total / 3)
      return fmt(this.d.daily)
    },
    changeCls(){
      if(this.d.change === 0) return ''
      if(this.kind === 'expense') return this.d.change > 0 ? 'amount--expense' : 'amount--income'
      return this.d.change > 0 ? 'amount--income' : 'amount--expense'
    },
    changePctText(){
      if(this.d.changePct === null) return ''
      if(Math.abs(this.d.changePct) > 999) return this.d.changePct > 0 ? '>999%' : '<-999%'
      return (this.d.changePct >= 0 ? '+' : '') + this.d.changePct + '%'
    },
    changeValue(){ return this.signed(this.d.change) },
    trendPoints(){
      const tr = this.d.trend
      const max = Math.max.apply(null, tr.concat([0]))
      return tr.map((v,i) => {
        const x = i * (320 / Math.max(1, tr.length - 1))
        const y = max > 0 ? 140 - (v / max) * 100 - 10 : 140
        return x.toFixed(1) + ',' + y.toFixed(1)
      }).join(' ')
    },
    areaPoints(){ return '0,140 ' + this.trendPoints + ' 320,140' },
    trendLabels(){
      const n = this.d.trend.length
      if(this.seg === '年') return Array.from({ length:12 }, (_,i) => (i + 1) + '月')
      if(this.seg === '季'){
        const start = Number(this.d.from.slice(5,7))
        return Array.from({ length:n }, (_,i) => (start + i) + '月')
      }
      if(this.seg === '周') return Array.from({ length:n }, (_,i) => shortDate(addDays(this.d.from,i)))
      const picks = [0,4,9,14,19,24,Math.max(0,n - 1)]
      const labels = picks.filter((v,i,a) => a.indexOf(v) === i).map(i => (i + 1) + '日')
      return labels
    },
    maxPoint(){
      const tr = this.d.trend
      if(!tr.length) return null
      const max = Math.max.apply(null, tr)
      if(max <= 0) return null
      const i = tr.indexOf(max)
      const x = i * (320 / Math.max(1, tr.length - 1))
      const y = 140 - (max / max) * 100 - 10
      const label = this.maxLabel(i)
      const tip = label + this.kindLabel + ' ¥' + fmtShort(max)
      const rectW = Math.max(88, tip.length * 6.4)
      const rectX = Math.max(2, Math.min(320 - rectW - 2, x - rectW / 2))
      const rectY = y > 34 ? y - 34 : y + 12
      return { x:x, y:y, rectX:rectX, rectY:rectY, rectW:rectW, tip:tip }
    },
    donutArcs(){
      let off = 0
      return this.d.cats.map(c => {
        const len = Math.round(c.amount / Math.max(1, this.d.total) * this.donutC * 10) / 10
        const arc = { len:len, off:off, color:this.catColor(c.name) }
        off += len
        return arc
      })
    },
    donutLabels(){
      let off = 0
      const items = this.d.cats.slice(0,6).map(c => {
        const len = c.amount / Math.max(1, this.d.total) * this.donutC
        const mid = -90 + (off + len / 2) / this.donutC * 360
        off += len
        const rad = mid * Math.PI / 180
        return {
          name:c.name, pct:c.pct,
          x:150 + Math.cos(rad) * 62,
          y:120 + Math.sin(rad) * 62,
          naturalY:120 + Math.sin(rad) * 82,
          side:Math.cos(rad) >= 0 ? 'right' : 'left',
          color:this.catColor(c.name)
        }
      })
      ;['left','right'].forEach(side => {
        const list = items.filter(i => i.side === side).sort((a,b) => a.naturalY - b.naturalY)
        let y = 28
        list.forEach(i => { y = Math.max(y, i.naturalY); i.labelY = y; y += 20 })
        const overflow = y - 20 - 214
        if(overflow > 0) list.forEach(i => { i.labelY -= overflow })
      })
      return items.map(i => {
        const right = i.side === 'right'
        const lx = right ? 236 : 64
        const name = i.name.length > 6 ? i.name.slice(0, 6) + '…' : i.name
        return { x:i.x, y:i.y, lx:lx, ly:i.labelY, tx:lx + (right ? 4 : -4), ty:i.labelY + 3, anchor:right ? 'start' : 'end', color:i.color, label:name + ' ' + i.pct + '%' }
      })
    },
    visibleCats(){ return this.showAllCats ? this.d.cats : this.d.cats.slice(0,6) },
    filteredTop(){
      return this.selectedCat ? this.d.top.filter(t => t.category === this.selectedCat) : this.d.top
    },
    visibleTop(){ return this.filteredTop.slice(0, this.showAllTop ? 20 : 8) },
    hasMoreTop(){ return this.filteredTop.length > 8 },
    compareTitle(){ return this.seg + this.kindLabel + '对比' },
    rankingTitle(){
      if(this.selectedCat) return '「' + this.selectedCat + '」' + this.kindLabel + '排行'
      return this.periodText + this.kindLabel + '排行'
    }
  },
  watch: {
    seg(){ this.offset = 0; this.selectedCat = ''; this.showAllCats = false; this.showAllTop = false },
    kind(){ this.selectedCat = ''; this.showAllCats = false; this.showAllTop = false }
  },
  methods: {
    setSeg(s){ this.seg = s },
    setKind(k){ this.kind = k },
    editFlow(t){ openRecord(t.id) },
    toggleCat(name){
      this.selectedCat = this.selectedCat === name ? '' : name
      this.showAllTop = false
    },
    catColor(name){ return colorForCategory(name, this.kind) },
    catIcon(c){ return iconForCategory(c, this.kind) },
    signed(n){ return Number(n) > 0 ? '+' + fmt(n) : fmtSigned(n) },
    fmtCompact(n){
      const v = Number(n) || 0
      if(Math.abs(v) >= 10000) return (v / 10000).toFixed(2).replace(/\.?0+$/, '') + '万'
      return fmtShort(v)
    },
    maxLabel(i){
      if(this.seg === '年') return (i + 1) + '月'
      if(this.seg === '季') return (Number(this.d.from.slice(5,7)) + i) + '月'
      if(this.seg === '周') return shortDate(addDays(this.d.from,i))
      return (i + 1) + '日'
    },
    barHeight(c){
      const max = Math.max.apply(null, this.d.comparison.map(x => x.amount).concat([0]))
      return max > 0 ? Math.max(3, Math.round(c.amount / max * 100)) : 0
    }
  }
}
</script>
