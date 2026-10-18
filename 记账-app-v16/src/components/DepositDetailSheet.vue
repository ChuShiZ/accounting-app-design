<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{a ? a.name : '存单详情'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="detail-top">
        <div>
          <div class="asset-sub">{{a.institution}} · {{termLabel(d.termMonths)}} · {{fmtRate(d.rateBp)}}</div>
          <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-1)">存单号 {{d.certificateNo || '—'}}</div>
        </div>
        <span class="chip" :class="statusCls" style="pointer-events:none">{{status.label}}</span>
      </div>

      <div class="overview" style="margin-top:var(--space-4)">
        <div class="cell"><div class="label caption">本金</div><div class="amount amount-lg">{{fmt(d.principal)}}</div></div>
        <div class="cell" style="text-align:right"><div class="label caption">预计利息</div><div class="amount amount-lg amount--income">{{fmt(interest)}}</div></div>
        <div class="cell full">
          <div class="label caption">{{d.closedAt ? '实际利息' : '到期日'}}</div>
          <div :class="d.closedAt ? 'amount amount-xl amount--income' : 'detail-date'">{{d.closedAt ? fmt(d.actualInterest || 0) : d.maturityAt}}</div>
        </div>
      </div>

      <div class="progress-wrap" v-if="!d.closedAt">
        <div class="progress-top"><span>已存 {{progress}}%</span><span>{{days >= 0 ? '剩余 '+days+' 天' : '已到期'}}</span></div>
        <div class="progress-track"><div class="progress-fill progress-fill--asset" :style="{width:progress+'%'}"></div></div>
      </div>
      <div class="computed-box" v-else>
        <div class="computed-row"><span>支取日</span><strong>{{d.closedAt}}</strong></div>
        <div class="computed-row"><span>支取方式</span><strong>{{d.closeType==='early'?'提前支取':(d.closeType==='renew'?'转存':'到期支取')}}</strong></div>
      </div>

      <div class="action-grid">
        <template v-if="!d.closedAt && status.key !== 'matured'">
          <button class="btn btn-ghost" @click="edit">编辑</button>
          <button class="btn btn-ghost" @click="settle('early')">提前支取</button>
        </template>
        <template v-if="!d.closedAt && status.key === 'matured'">
          <button class="btn btn-primary" @click="settle('maturity')">到期支取</button>
          <button class="btn btn-ghost" @click="renew">转存</button>
        </template>
        <button v-if="d.closedAt" class="btn btn-ghost" disabled>已关闭</button>
      </div>

      <div class="field-label">存单信息</div>
      <div class="card">
        <div class="setting-row"><span class="setting-label">年利率</span><span class="setting-value">{{fmtRate(d.rateBp)}}</span></div>
        <div class="setting-row"><span class="setting-label">存期</span><span class="setting-value">{{termLabel(d.termMonths)}}</span></div>
        <div class="setting-row"><span class="setting-label">起存日</span><span class="setting-value">{{d.startAt}}</span></div>
        <div class="setting-row"><span class="setting-label">到期日</span><span class="setting-value">{{d.maturityAt}}</span></div>
        <div class="setting-row"><span class="setting-label">本息合计</span><span class="setting-value">{{fmt(d.principal + interest)}}</span></div>
        <div class="setting-row" v-if="d.note"><span class="setting-label">备注</span><span class="setting-value">{{d.note}}</span></div>
      </div>

      <button class="delete-link" @click="remove">删除存单记录</button>
    </div>
  </div>
</template>

<script>
import { store, accountById, icon, fmt, fmtRate, termLabel, depositStatus, expectedInterest, daysToMaturity, depositProgress, openSheet, closeSheet, showToast, deleteAccount, askConfirm } from '../store.js'

export default {
  name: 'DepositDetailSheet',
  setup(){ return { store, icon, fmt, fmtRate, termLabel, depositStatus, expectedInterest, daysToMaturity, depositProgress, openSheet, closeSheet, showToast } },
  computed: {
    a(){ return accountById(store.depositId) },
    d(){ return this.a ? this.a.deposit : null },
    status(){ return this.a ? depositStatus(this.a) : { key:'', label:'' } },
    interest(){ return this.a ? expectedInterest(this.a) : 0 },
    days(){ return this.a ? daysToMaturity(this.a) : 0 },
    progress(){ return this.a ? depositProgress(this.a) : 0 },
    statusCls(){
      const k = this.status.key
      if(k === 'matured') return 'chip--warn'
      if(k === 'due') return 'chip--due'
      if(k === 'closed') return 'chip--muted'
      return 'chip--asset'
    }
  },
  methods: {
    edit(){ openSheet('编辑存单') },
    settle(mode){ store.settleMode = mode; openSheet('存单支取') },
    renew(){ openSheet('存单转存') },
    remove(){
      const a = this.a
      askConfirm('删除存单记录？已记的利息收入将保留。', function(){
        deleteAccount(a)
        closeSheet()
        showToast('已删除')
      }, { title:'删除存单', confirmText:'删除' })
    }
  }
}
</script>
