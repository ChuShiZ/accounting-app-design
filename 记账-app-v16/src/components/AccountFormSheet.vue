<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{title}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="field-label" style="margin-top:0">名称</div>
      <input class="ledger-input" v-model="name" type="text" maxlength="20" :placeholder="namePlaceholder" />

      <template v-if="!isLoan">
        <div class="field-label">{{ isStored ? '商户 / 平台' : '开户行 / 平台' }}</div>
        <input class="ledger-input" v-model="institution" type="text" maxlength="20" :placeholder="isStored ? '如：银座' : '如：招商银行'" />

        <template v-if="!editing">
          <div class="field-label">当前余额</div>
          <input class="ledger-input" v-model="balance" type="number" inputmode="decimal" placeholder="0.00" />
          <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">创建后余额随流水变化，这里作为期初余额。</div>
        </template>
        <div v-else class="computed-box">
          <div class="computed-row"><span>当前余额</span><strong>{{fmt(account.balance)}}</strong></div>
          <div class="computed-row" style="border-top:none;padding-top:0"><span style="color:var(--color-text-secondary)">余额由流水自动变化，不在资料里直接修改</span></div>
        </div>

        <template v-if="isStored">
          <div class="field-label">默认消费类别</div>
          <select class="ledger-input" v-model="defaultCategory">
            <option value="">不设置</option>
            <option v-for="c in expenseCategories" :key="c.id" :value="c.name">{{c.name}}</option>
          </select>
          <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">记账选择这张储值卡时，默认选中该类别。</div>
        </template>
      </template>

      <template v-else>
        <div class="field-label">贷款类型</div>
        <div class="segmented" style="display:flex;width:100%">
          <button v-for="k in loanKinds" :key="k.key" :class="{active:loanKind===k.key}" style="flex:1;justify-content:center" @click="loanKind=k.key">{{k.label}}</button>
        </div>

        <div class="field-label">贷款机构</div>
        <input class="ledger-input" v-model="institution" type="text" maxlength="20" placeholder="如：建设银行" />

        <div class="field-label">原始本金</div>
        <input class="ledger-input" v-model="originalPrincipal" type="number" inputmode="decimal" placeholder="0.00" />

        <div class="field-label">剩余本金</div>
        <input class="ledger-input" v-model="remainingPrincipal" type="number" inputmode="decimal" placeholder="默认等于原始本金" />

        <div class="field-label">年利率（%）</div>
        <input class="ledger-input" v-model="rate" type="number" inputmode="decimal" step="0.01" placeholder="如：4.10" />

        <div class="field-label">总期数（月）</div>
        <input class="ledger-input" v-model="termMonths" type="number" inputmode="numeric" placeholder="如：360" />

        <div class="field-label">起贷日</div>
        <input class="ledger-input" v-model="startAt" type="date" />

        <div class="field-label">下次还款日</div>
        <input class="ledger-input" v-model="nextDueAt" type="date" />

        <div class="field-label">每期还款额（选填）</div>
        <input class="ledger-input" v-model="perAmount" type="number" inputmode="decimal" placeholder="如：6800.00" />

        <div class="field-label">还款方式</div>
        <select class="ledger-input" v-model="repaymentMethod">
          <option v-for="m in repayMethods" :key="m.key" :value="m.key">{{m.label}}</option>
        </select>

        <div class="computed-box">
          <div class="computed-row"><span>剩余本金</span><strong>{{fmt(previewRemaining)}}</strong></div>
        </div>
      </template>

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
import { store, accounts, categories, accountById, icon, fmt, closeSheet, showToast, createBankAccount, createStoredAccount, createLoanAccount, updateBankAccount, updateStoredAccount, updateLoanAccount, addMonths, DEMO_TODAY } from '../store.js'

const LOAN_KINDS = [
  { key:'mortgage', label:'房贷' },
  { key:'car', label:'车贷' },
  { key:'consumer', label:'消费贷' },
  { key:'other', label:'其他' }
]
const REPAY_METHODS = [
  { key:'equal_principal_interest', label:'等额本息' },
  { key:'equal_principal', label:'等额本金' },
  { key:'interest_only', label:'先息后本' },
  { key:'other', label:'其他' }
]

export default {
  name: 'AccountFormSheet',
  setup(){ return { store, icon, fmt, closeSheet, showToast } },
  data(){
    return {
      name:'', institution:'', balance:'', defaultCategory:'', note:'',
      loanKind:'mortgage', originalPrincipal:'', remainingPrincipal:'', rate:'', termMonths:'',
      startAt:DEMO_TODAY, nextDueAt:addMonths(DEMO_TODAY, 1), perAmount:'', repaymentMethod:'equal_principal_interest',
      loanKinds:LOAN_KINDS, repayMethods:REPAY_METHODS
    }
  },
  computed: {
    account(){ return accountById(store.accountEditId) },
    editing(){ return !!this.account },
    formType(){ return this.account ? this.account.type : (store.accountFormType || 'bank') },
    isLoan(){ return this.formType === 'loan' },
    isStored(){ return this.formType === 'stored' },
    typeLabel(){ return ({ bank:'银行卡', ewallet:'电子钱包', stored:'储值卡', loan:'贷款' })[this.formType] || '账户' },
    title(){ return (this.editing ? '编辑' : '添加') + this.typeLabel },
    namePlaceholder(){
      if(this.isLoan) return '如：招商银行房贷'
      if(this.isStored) return '如：银座购物卡'
      return '如：招商银行卡'
    },
    expenseCategories(){ return categories.filter(c => c.type === 'expense') },
    previewRemaining(){
      const raw = this.remainingPrincipal === '' ? this.originalPrincipal : this.remainingPrincipal
      return Math.max(0, parseFloat(raw) || 0)
    }
  },
  created(){
    if(!this.account) return
    const a = this.account
    this.name = a.name || ''
    this.institution = a.institution || ''
    this.note = a.note || ''
    this.balance = String(a.balance || 0)
    this.defaultCategory = a.defaultCategory || ''
    if(a.loan){
      this.loanKind = a.loan.kind || 'mortgage'
      this.originalPrincipal = String(a.loan.originalPrincipal || 0)
      this.remainingPrincipal = String(Math.abs(a.balance || 0))
      this.rate = String((a.loan.rateBp || 0) / 100)
      this.termMonths = String(a.loan.termMonths || '')
      this.startAt = a.loan.startAt || DEMO_TODAY
      this.nextDueAt = a.loan.nextDueAt || DEMO_TODAY
      this.perAmount = a.loan.perAmount ? String(a.loan.perAmount) : ''
      this.repaymentMethod = a.loan.repaymentMethod || 'equal_principal_interest'
    }
  },
  methods: {
    save(){
      const name = this.name.trim()
      if(!name){ showToast('请输入账户名称'); return }
      if(accounts.some(a => a.id !== store.accountEditId && a.name === name)){ showToast('账户名称已存在'); return }

      if(this.isLoan){
        const original = Math.round((parseFloat(this.originalPrincipal) || 0) * 100) / 100
        const remainingRaw = this.remainingPrincipal === '' ? original : (parseFloat(this.remainingPrincipal) || 0)
        const remaining = Math.round(remainingRaw * 100) / 100
        const rate = parseFloat(this.rate) || 0
        const term = parseInt(this.termMonths, 10) || 0
        const per = Math.round((parseFloat(this.perAmount) || 0) * 100) / 100
        if(original <= 0){ showToast('请输入原始本金'); return }
        if(remaining < 0 || remaining > original){ showToast('剩余本金应在 0 到原始本金之间'); return }
        if(rate < 0){ showToast('请输入正确的利率'); return }
        if(term <= 0 || term > 600){ showToast('请输入正确的总期数'); return }
        if(!this.startAt || !this.nextDueAt){ showToast('请选择日期'); return }
        if(per < 0){ showToast('请输入正确的每期还款额'); return }
        const data = {
          name, institution:this.institution.trim(), kind:this.loanKind,
          originalPrincipal:original, remainingPrincipal:remaining,
          rateBp:Math.round(rate * 100), termMonths:term, startAt:this.startAt,
          nextDueAt:this.nextDueAt, perAmount:per, repaymentMethod:this.repaymentMethod,
          note:this.note.trim()
        }
        if(this.editing) updateLoanAccount(this.account, data)
        else createLoanAccount(data)
        closeSheet(); showToast(this.editing ? '已更新贷款' : '已添加贷款')
        return
      }

      if(!this.editing){
        const bal = Math.round((parseFloat(this.balance) || 0) * 100) / 100
        if(bal < 0){ showToast('余额不能为负'); return }
        if(this.isStored){
          createStoredAccount({ name, institution:this.institution.trim(), balance:bal, defaultCategory:this.defaultCategory, note:this.note.trim() })
        } else {
          createBankAccount({ name, institution:this.institution.trim(), balance:bal, note:this.note.trim() })
        }
        closeSheet(); showToast(this.isStored ? '已添加储值卡' : '已添加银行卡')
        return
      }

      const data = { name, institution:this.institution.trim(), defaultCategory:this.defaultCategory, note:this.note.trim() }
      if(this.isStored) updateStoredAccount(this.account, data)
      else updateBankAccount(this.account, data)
      closeSheet(); showToast('已更新账户')
    }
  }
}
</script>
