<template>
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{mode==='early'?'提前支取':'到期支取'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="card">
        <div class="setting-row"><span class="setting-label">存单</span><span class="setting-value">{{a.name}}</span></div>
        <div class="setting-row"><span class="setting-label">本金</span><span class="setting-value">{{fmt(d.principal)}}</span></div>
        <div class="setting-row"><span class="setting-label">到账账户</span><span class="setting-value">{{bank ? bank.name : '招商银行卡'}}</span></div>
      </div>

      <div class="field-label">实际利息</div>
      <input class="ledger-input" v-model="actual" type="number" inputmode="decimal" placeholder="0.00" />
      <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">
        {{mode==='early' ? '按银行实际到账填写，可为 0；提前支取通常按活期计息。' : '默认按预计利息，可按银行实际到账修改。'}}
      </div>

      <div class="computed-box">
        <div class="computed-row"><span>本金</span><strong>{{fmt(d.principal)}}</strong></div>
        <div class="computed-row"><span>利息</span><strong class="amount amount--income">{{fmt(interest)}}</strong></div>
        <div class="computed-row"><span>到账本息</span><strong>{{fmt(d.principal + interest)}}</strong></div>
      </div>
      <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">本金不计收入；实际利息计入「利息」收入。</div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="confirm">确认支取</button>
    </div>
  </div>
</template>

<script>
import { store, accountById, icon, fmt, expectedInterest, settleDeposit, closeSheet, showToast } from '../store.js'

export default {
  name: 'DepositSettleSheet',
  setup(){ return { store, icon, fmt, closeSheet, showToast } },
  data(){ return { actual:'' } },
  computed: {
    a(){ return accountById(store.depositId) },
    d(){ return this.a ? this.a.deposit : null },
    mode(){ return store.settleMode || 'maturity' },
    bank(){ return accountById('bank1') },
    interest(){ return Math.max(0, Math.round((parseFloat(this.actual) || 0) * 100) / 100) }
  },
  created(){
    if(this.a){
      this.actual = String(this.mode === 'maturity' ? expectedInterest(this.a).toFixed(2) : '0.00')
    }
  },
  methods: {
    confirm(){
      if(!this.a) return
      if((parseFloat(this.actual) || 0) < 0){ showToast('请输入正确的利息'); return }
      settleDeposit(this.a, { actualInterest:this.interest, mode:this.mode })
      closeSheet()
      showToast(this.mode === 'early' ? '提前支取成功' : '已支取')
    }
  }
}
</script>
