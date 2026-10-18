<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{editing?'编辑存单':'添加存单'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="field-label" style="margin-top:0">银行</div>
      <input class="ledger-input" v-model="bank" type="text" placeholder="如：招商银行" />

      <div class="field-label">本金</div>
      <input class="ledger-input" v-model="principal" type="number" inputmode="decimal" placeholder="0.00" />

      <div class="field-label">年利率（%）</div>
      <input class="ledger-input" v-model="rate" type="number" inputmode="decimal" step="0.01" placeholder="3.25" />

      <div class="field-label">存期</div>
      <div class="chips chips--tight">
        <button v-for="t in terms" :key="t.v" class="chip" :class="{active:termMonths===t.v}" @click="termMonths=t.v">{{t.l}}</button>
      </div>

      <div class="field-label">起存日</div>
      <input class="ledger-input" type="date" v-model="startAt" />

      <div class="form-preview">
        <span>到期 {{maturityAt}}</span>
        <span>预计利息 <strong class="amount--income">{{fmt(interest)}}</strong></span>
      </div>

      <template v-if="!editing">
        <div class="field-label">资金来源（可选）</div>
        <div style="position:relative">
          <select class="ledger-input" v-model="sourceAccountId" style="appearance:none;padding-right:32px;cursor:pointer">
            <option value="">不转出（已有存单直接录入）</option>
            <option v-for="a in sourceAccounts" :key="a.id" :value="a.id">{{a.name}} · {{fmtSigned(a.balance)}}</option>
          </select>
          <span style="position:absolute;right:12px;top:50%;transform:translateY(-50%);pointer-events:none;color:var(--color-text-secondary)" v-html="icon('chevron',16)"></span>
        </div>
        <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">选择账户则从该账户转出本金；存单购买不计支出。</div>
      </template>

      <div class="field-label">存单名称（选填）</div>
      <input class="ledger-input" v-model="name" type="text" :placeholder="defaultName" />

      <div class="field-label">存单号（选填）</div>
      <input class="ledger-input" v-model="certificateNo" type="text" placeholder="如 CD20260601001" />

      <div class="field-label">备注</div>
      <input class="ledger-input" v-model="note" type="text" placeholder="添加备注（选填）" />
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="save">保存</button>
    </div>
  </div>
</template>

<script>
import { store, accounts, icon, fmt, fmtSigned, addMonths, termLabel, createDeposit, updateDeposit, accountById, closeSheet, showToast, DEMO_TODAY } from '../store.js'

const TERMS = [
  { v:3, l:'3个月' }, { v:6, l:'6个月' }, { v:12, l:'1年' },
  { v:24, l:'2年' }, { v:36, l:'3年' }, { v:60, l:'5年' }
]

export default {
  name: 'DepositFormSheet',
  setup(){ return { store, icon, fmt, fmtSigned, closeSheet, showToast } },
  data(){
    return {
      terms:TERMS,
      bank:'招商银行', name:'', principal:'', rate:'3.25', termMonths:36,
      startAt:DEMO_TODAY, certificateNo:'', note:'', sourceAccountId:''
    }
  },
  computed: {
    editing(){ return store.sheet === '编辑存单' && !!accountById(store.depositId) },
    defaultName(){ return this.bank + termLabel(this.termMonths) + '存单' },
    maturityAt(){ return addMonths(this.startAt || DEMO_TODAY, this.termMonths) },
    interest(){
      const p = parseFloat(this.principal) || 0
      const r = parseFloat(this.rate) || 0
      return Math.round(p * r / 100 * this.termMonths / 12 * 100) / 100
    },
    sourceAccounts(){ return accounts.filter(a => ['bank','ewallet','cash'].includes(a.type)) }
  },
  created(){
    if(this.editing){
      const a = accountById(store.depositId)
      const d = a.deposit
      this.bank = a.institution || '招商银行'
      this.name = a.name
      this.principal = String(d.principal)
      this.rate = String(d.rateBp / 100)
      this.termMonths = d.termMonths
      this.startAt = d.startAt
      this.certificateNo = d.certificateNo || ''
      this.note = d.note || ''
    }
  },
  methods: {
    save(){
      const p = parseFloat(this.principal) || 0
      const r = parseFloat(this.rate) || 0
      if(!this.bank.trim()){ showToast('请填写银行'); return }
      if(p <= 0){ showToast('请输入本金'); return }
      if(r < 0){ showToast('请输入正确的利率'); return }
      if(!this.startAt){ showToast('请选择起存日'); return }
      const data = {
        bank:this.bank.trim(), name:this.name.trim() || this.defaultName,
        principal:p, rateBp:Math.round(r * 100), termMonths:this.termMonths,
        startAt:this.startAt, certificateNo:this.certificateNo.trim(), note:this.note.trim()
      }
      if(this.editing){
        updateDeposit(accountById(store.depositId), data)
        closeSheet(); showToast('已更新存单')
      } else {
        if(this.sourceAccountId){
          const src = accountById(this.sourceAccountId)
          if(!src || p > src.balance){ showToast('资金来源余额不足'); return }
        }
        const created = createDeposit(Object.assign({}, data, { sourceAccountId:this.sourceAccountId || null }))
        if(!created){ showToast('资金来源余额不足'); return }
        closeSheet(); showToast('已添加存单')
      }
    }
  }
}
</script>
