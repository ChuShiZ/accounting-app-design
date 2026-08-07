<template>
  <div class="page">
  <header class="app-header">
    <button class="icon-btn" @click="backToTab" aria-label="返回"><span v-html="icon('back',22)"></span></button>
    <div class="title h1">周期性支出</div>
    <button class="icon-btn" @click="showToast('新增周期性支出（示例）')" aria-label="新增"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
    <div class="periodic-filter chips">
      <button v-for="s in ['全部','进行中','已结清']" :key="s" class="chip" :class="{active:store.periodicFilter===s}" @click="store.periodicFilter=s">{{s}}</button>
    </div>
    <template v-for="(p,i) in list" :key="i">
      <div class="card" @click="openDetail(periodicData.indexOf(p))" style="cursor:pointer">
        <div class="flow-item" style="padding:0">
          <div class="badge" :class="p.state==='已结清'?'badge--done':'badge--liability'" v-html="icon(iconOf(p),20)"></div>
          <div class="flow-main">
            <div class="cat" :style="p.state==='已结清'?{color:'var(--color-text-disabled)'}:{}">{{p.name}}</div>
            <div class="sub" v-if="p.freq">每期 {{fmt(p.per)}} · {{p.note}}</div>
            <div class="sub" v-else-if="p.state==='已结清'">每期 {{fmt(p.per)}} · 全部还清</div>
            <div class="sub" v-else>每期 {{fmt(p.per)}} · 下次扣款 {{p.next}}</div>
          </div>
          <span v-if="p.freq" class="chip active" style="pointer-events:none">周期性·{{p.freq}}</span>
          <span v-else-if="p.state==='已结清'" class="chip" style="pointer-events:none;background:var(--color-surface-2);color:var(--color-text-disabled)">已结清</span>
          <span v-else v-html="icon('chevron',18)"></span>
        </div>
        <div v-if="!p.freq" class="progress-wrap">
          <div class="progress-top">
            <span :style="p.state==='已结清'?{color:'var(--color-text-disabled)'}:{}">已还 {{p.paid}} / 共 {{p.total}} 期</span>
            <span :style="p.state==='已结清'?{color:'var(--color-text-disabled)'}:{}">{{pct(p)}}%</span>
          </div>
          <div class="progress-track"><div class="progress-fill" :class="p.state==='已结清'?'progress-fill--done':''" :style="{width:pct(p)+'%'}"></div></div>
          <div v-if="p.state!=='已结清'" class="progress-bottom"><span class="label">剩余金额</span><span class="amount amount-md amount--liability">{{fmt(p.remain)}}</span></div>
        </div>
      </div>
      <div v-if="i<list.length-1" style="height:var(--space-3)"></div>
    </template>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { store, periodicData, fmt, icon, openSheet, showToast, backToTab } from '../store.js'

/* ③ 周期页：状态筛选 + 列表（三形态） */
export default {
  name: 'PeriodicPage',
  setup(){ return { store, periodicData, fmt, icon, openSheet, showToast, backToTab } },
  computed: {
    list(){
      return store.periodicFilter==='全部' ? periodicData : periodicData.filter(p=>p.state===store.periodicFilter)
    }
  },
  methods: {
    pct(p){ return Math.round(p.paid/p.total*100) },
    iconOf(p){ return p.name==='房贷'?'mortgage':(p.name==='停车费'?'parking':(p.name==='装修贷'?'building':'car')) },
    openDetail(i){ store.periodicDetailIdx = i; openSheet('周期详情') }
  }
}
</script>
