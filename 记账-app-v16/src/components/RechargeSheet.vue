<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">充值</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="sheet-summary">
        <div class="asset-name">{{a.name}}</div>
        <div class="asset-sub">当前余额 {{fmt(a.balance)}} · 付款账户 招商银行卡</div>
      </div>

      <div class="field-label">实付金额</div>
      <input class="ledger-input" v-model="paid" type="number" inputmode="decimal" placeholder="0.00" />
      <div class="field-label">赠送金额（选填）</div>
      <input class="ledger-input" v-model="bonus" type="number" inputmode="decimal" placeholder="0.00" />
      <div class="field-label">日期</div>
      <input class="ledger-input" type="date" v-model="date" />

      <div class="computed-box">
        <div class="computed-row"><span>到账金额</span><strong>{{fmt(total)}}</strong></div>
        <div class="computed-row"><span>充值后余额</span><strong>{{fmt(a.balance + total)}}</strong></div>
      </div>
      <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">充值实付计入支出；赠送金额计入收入；卡内消费不再重复计支出。</div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="confirm">确认充值</button>
    </div>
  </div>
</template>

<script>
import { store, accountById, icon, fmt, rechargeStored, closeSheet, showToast, DEMO_TODAY } from '../store.js'

export default {
  name: 'RechargeSheet',
  setup(){ return { store, icon, fmt, closeSheet, showToast } },
  data(){ return { paid:'', bonus:'', date:DEMO_TODAY, note:'' } },
  computed: {
    a(){ return accountById(store.cardId) },
    total(){ return Math.round(((parseFloat(this.paid) || 0) + (parseFloat(this.bonus) || 0)) * 100) / 100 }
  },
  methods: {
    confirm(){
      if(!this.a) return
      const p = Math.round((parseFloat(this.paid) || 0) * 100) / 100
      const b = Math.round((parseFloat(this.bonus) || 0) * 100) / 100
      if(p <= 0){ showToast('请输入实付金额'); return }
      if(b < 0){ showToast('赠送金额不能为负'); return }
      if(!this.date){ showToast('请选择日期'); return }
      if(!rechargeStored(this.a, { paid:p, bonus:b, date:this.date, note:this.note })){
        showToast('付款账户余额不足')
        return
      }
      closeSheet(); showToast('充值成功')
    }
  }
}
</script>
