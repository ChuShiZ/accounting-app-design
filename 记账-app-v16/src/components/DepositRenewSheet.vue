<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">存单转存</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="sheet-summary">
        <div class="asset-name">{{a.name}}</div>
        <div class="asset-sub">原本金 {{fmt(d.principal)}} · 预计利息 {{fmt(expectedInterest(a))}}</div>
      </div>

      <div class="field-label">实际利息</div>
      <input class="ledger-input" v-model="actual" type="number" inputmode="decimal" placeholder="0.00" />

      <div class="field-label">新本金（本息转存）</div>
      <div class="computed-box" style="margin-top:0">
        <div class="computed-row"><span>本金 + 利息</span><strong>{{fmt(newPrincipal)}}</strong></div>
      </div>

      <div class="field-label">新利率（%）</div>
      <input class="ledger-input" v-model="rate" type="number" inputmode="decimal" step="0.01" />

      <div class="field-label">新存期</div>
      <div class="chips chips--tight">
        <button v-for="t in terms" :key="t.v" class="chip" :class="{active:termMonths===t.v}" @click="termMonths=t.v">{{t.l}}</button>
      </div>

      <div class="field-label">新起存日</div>
      <input class="ledger-input" type="date" v-model="startAt" />

      <div class="form-preview">
        <span>新到期 {{maturityAt}}</span>
        <span>新预计利息 <strong class="amount--income">{{fmt(newInterest)}}</strong></span>
      </div>

      <div class="field-label">存单名称（选填）</div>
      <input class="ledger-input" v-model="name" type="text" :placeholder="a.institution + termLabel(termMonths) + '存单'" />
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="confirm">确认转存</button>
    </div>
  </div>
</template>

<script>
import { store, accountById, icon, fmt, expectedInterest, termLabel, addMonths, renewDeposit, closeSheet, showToast, DEMO_TODAY } from '../store.js'

const TERMS = [
  { v:3, l:'3个月' }, { v:6, l:'6个月' }, { v:12, l:'1年' },
  { v:24, l:'2年' }, { v:36, l:'3年' }, { v:60, l:'5年' }
]

export default {
  name: 'DepositRenewSheet',
  setup(){ return { store, icon, fmt, termLabel, expectedInterest, closeSheet, showToast } },
  data(){ return { terms:TERMS, actual:'', rate:'3.25', termMonths:12, startAt:DEMO_TODAY, name:'' } },
  computed: {
    a(){ return accountById(store.depositId) },
    d(){ return this.a ? this.a.deposit : null },
    newPrincipal(){ return Math.round(((this.d ? this.d.principal : 0) + (parseFloat(this.actual) || 0)) * 100) / 100 },
    maturityAt(){ return addMonths(this.startAt || DEMO_TODAY, this.termMonths) },
    newInterest(){ return Math.round(this.newPrincipal * (parseFloat(this.rate) || 0) / 100 * this.termMonths / 12 * 100) / 100 }
  },
  created(){
    if(this.a){
      this.actual = expectedInterest(this.a).toFixed(2)
      this.rate = String(this.d.rateBp / 100)
      this.termMonths = this.d.termMonths
      this.startAt = DEMO_TODAY
    }
  },
  methods: {
    confirm(){
      if(!this.a) return
      if((parseFloat(this.actual) || 0) < 0){ showToast('请输入正确的利息'); return }
      renewDeposit(this.a, {
        actualInterest:Math.max(0, parseFloat(this.actual) || 0),
        newPrincipal:this.newPrincipal,
        rateBp:Math.round((parseFloat(this.rate) || 0) * 100),
        termMonths:this.termMonths,
        startAt:this.startAt,
        name:this.name.trim() || (this.a.institution + termLabel(this.termMonths) + '存单'),
        certificateNo:'', note:''
      })
      closeSheet(); showToast('已转存')
    }
  }
}
</script>
