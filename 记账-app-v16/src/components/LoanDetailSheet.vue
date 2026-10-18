<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{a ? a.name : '贷款详情'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="card">
        <div class="detail-top">
          <div>
            <div class="asset-sub">{{a.institution}} · {{fmtRate(a.loan.rateBp)}} · {{a.loan.termMonths}} 期</div>
            <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-1)">下次还款 {{a.loan.nextDueAt}} · 每期 {{fmt(a.loan.perAmount)}}</div>
          </div>
          <span class="chip chip--warn" style="pointer-events:none">还款中</span>
        </div>
        <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-4)">剩余本金</div>
        <div class="amount amount-xl amount--liability">{{fmt(Math.abs(a.balance))}}</div>
        <div class="progress-wrap">
          <div class="progress-top"><span>已还进度 {{progress}}%</span><span>原始 {{fmt(a.loan.originalPrincipal)}}</span></div>
          <div class="progress-track"><div class="progress-fill" :style="{width:progress+'%'}"></div></div>
        </div>
      </div>

      <div class="action-grid action-grid--single">
        <button class="btn btn-primary" @click="openSheet('贷款还款')">还款</button>
      </div>
      <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">月供整笔计入支出；界面不拆本金/利息。</div>

      <div class="field-label">还款记录</div>
      <div v-if="!list.length" class="caption" style="color:var(--color-text-secondary)">暂无还款记录</div>
      <div v-else class="group-card">
        <div class="flow-item" v-for="t in list" :key="t.id" @click="editFlow(t)">
          <div class="badge" :style="{color:iconColor('mortgage')}" v-html="icon('mortgage',24)"></div>
          <div class="flow-main">
            <div class="cat">{{a.name}}月供</div>
            <div class="sub">{{t.date}} · {{t.note || '还款'}}</div>
          </div>
          <div class="flow-amount amount amount-md amount--expense">-{{fmt(t.amount)}}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { store, accountById, transactions, icon, iconColor, fmt, fmtRate, openSheet, openRecord, closeSheet } from '../store.js'

export default {
  name: 'LoanDetailSheet',
  setup(){ return { store, icon, iconColor, fmt, fmtRate, openSheet, closeSheet } },
  computed: {
    a(){ return accountById(store.loanId) },
    progress(){
      if(!this.a || !this.a.loan) return 0
      const paid = this.a.loan.originalPrincipal - Math.abs(this.a.balance)
      return Math.max(0, Math.min(100, Math.round(paid / this.a.loan.originalPrincipal * 100)))
    },
    list(){
      if(!this.a) return []
      return transactions.filter(t => t.category === '房贷' || t.category === '车贷').slice(0, 5)
    }
  },
  methods: {
    editFlow(t){ openRecord(t.id) }
  }
}
</script>
