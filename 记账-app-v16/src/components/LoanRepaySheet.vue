<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">贷款还款</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="sheet-summary">
        <div class="asset-name">{{a.name}}</div>
        <div class="asset-sub">剩余本金 {{fmt(Math.abs(a.balance))}} · 付款账户 招商银行卡</div>
      </div>

      <div class="field-label">还款金额</div>
      <input class="ledger-input" v-model="amount" type="number" inputmode="decimal" placeholder="0.00" />
      <div class="field-label">日期</div>
      <input class="ledger-input" type="date" v-model="date" />

      <div class="computed-box">
        <div class="computed-row"><span>还款后剩余本金</span><strong>{{fmt(Math.max(0, Math.abs(a.balance) - (parseFloat(amount)||0)))}}</strong></div>
        <div class="computed-row"><span>本次计入支出</span><strong class="amount--expense">{{fmt(parseFloat(amount)||0)}}</strong></div>
      </div>
      <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">月供整笔计入支出；本金/利息不在界面拆分。</div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="confirm">确认还款</button>
    </div>
  </div>
</template>

<script>
import { store, accountById, icon, fmt, repayLoan, closeSheet, showToast, DEMO_TODAY } from '../store.js'

export default {
  name: 'LoanRepaySheet',
  setup(){ return { store, icon, fmt, closeSheet, showToast } },
  data(){ return { amount:'', date:DEMO_TODAY, note:'' } },
  computed: { a(){ return accountById(store.loanId) } },
  created(){
    if(this.a && this.a.loan) this.amount = String(this.a.loan.perAmount || 0)
  },
  methods: {
    confirm(){
      if(!this.a) return
      const amt = Math.round((parseFloat(this.amount) || 0) * 100) / 100
      if(amt <= 0){ showToast('请输入还款金额'); return }
      if(amt > Math.abs(this.a.balance)){ showToast('还款金额不能超过剩余本金'); return }
      const bank = accountById('bank1')
      if(bank && amt > bank.balance){ showToast('付款账户余额不足'); return }
      if(!repayLoan(this.a, { amount:amt, date:this.date, note:this.note })){
        showToast('还款失败')
        return
      }
      closeSheet(); showToast('已还款')
    }
  }
}
</script>
