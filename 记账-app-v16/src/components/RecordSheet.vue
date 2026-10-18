<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{editing ? '编辑流水' : '记一笔'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="segmented" style="display:flex;width:100%">
        <button :class="{active:type==='expense'}" style="flex:1;justify-content:center" @click="setType('expense')">支出</button>
        <button :class="{active:type==='income'}" style="flex:1;justify-content:center" @click="setType('income')">收入</button>
      </div>

      <div class="record-amount-wrap">
        <span class="record-currency">¥</span>
        <input class="record-amount" v-model="amount" inputmode="decimal" placeholder="0.00"
               @input="onAmountInput" @blur="onAmountBlur" />
      </div>

      <div class="field-label">类别</div>
      <div class="chips">
        <button v-for="c in categoryNames" :key="c" class="chip" :class="{active:cat===c}" @click="cat=c">{{c}}</button>
      </div>

      <div class="field-label">账户 / 卡片</div>
      <div style="position:relative">
        <select class="ledger-input" :value="accId" @change="selectAcc($event.target.value)" style="appearance:none;padding-right:32px;cursor:pointer">
          <option v-for="a in accList" :key="a.id" :value="a.id">{{a.name}}</option>
        </select>
        <span style="position:absolute;right:12px;top:50%;transform:translateY(-50%);pointer-events:none;color:var(--color-text-secondary)" v-html="icon('chevron',16)"></span>
      </div>
      <div class="caption" v-if="acc" style="color:var(--color-text-secondary);margin-top:var(--space-2)">
        {{hint}}
      </div>

      <div class="field-label">日期</div>
      <input class="ledger-input" type="date" v-model="date" />

      <div class="field-label">添加图片</div>
      <div v-if="!imgOn" class="img-upload" @click="imgOn=true">
        <span v-html="icon('upload',24)"></span><span class="micro" style="color:var(--color-text-secondary)">添加图片</span>
      </div>
      <div v-else class="img-preview">
        <span v-html="icon('img',40)"></span><span class="micro" style="color:var(--color-text-secondary)">图片已选</span>
        <span class="remove-btn" @click.stop="imgOn=false"><span v-html="icon('close',12)"></span></span>
      </div>

      <div class="field-label">备注</div>
      <input class="ledger-input" v-model="note" type="text" placeholder="添加备注（选填）" />

      <div v-if="editing" class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-4);line-height:1.5">
        修改金额、账户或日期后，账户余额与报表会同步重算。
      </div>
      <button v-if="editing" class="delete-link" @click="remove">删除这笔流水</button>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="save">保存</button>
    </div>
  </div>
</template>

<script>
import { store, icon, addExpense, addIncome, updateTransaction, deleteTransaction, transactions, expenseAccounts, incomeAccounts, accountById, settingsData, closeSheet, showToast, askConfirm, DEMO_TODAY, categoryOptions } from '../store.js'

export default {
  name: 'RecordSheet',
  setup(){ return { store, icon, closeSheet, showToast } },
  data(){
    return { type:'expense', cat:'餐饮', accId:'', amount:'', date:DEMO_TODAY, note:'', imgOn:false }
  },
  computed: {
    editing(){ return store.txEditId != null },
    tx(){ return transactions.find(t => t.id === store.txEditId) || null },
    categoryNames(){
      const names = categoryOptions(this.type).map(c => c.name)
      if(this.cat && !names.includes(this.cat)) names.unshift(this.cat)
      return names
    },
    accList(){
      const list = this.type === 'expense' ? expenseAccounts() : incomeAccounts()
      return list
    },
    acc(){ return accountById(this.accId) },
    storedAvailable(){
      if(!this.acc) return 0
      let bal = this.acc.balance
      if(this.tx && this.tx.accountId === this.accId){
        bal += this.tx.type === 'expense' ? this.tx.amount : -this.tx.amount
      }
      return Math.round(bal * 100) / 100
    },
    hint(){
      if(!this.acc) return ''
      if(this.type === 'expense' && this.acc.type === 'stored') return '储值卡消费只扣余额，不再计支出（充值已计）'
      if(this.type === 'expense' && this.acc.type === 'credit') return '信用卡消费计入支出；还款不再计支出'
      if(this.type === 'income' && this.acc.type === 'deposit') return '存单利息计入收入；本金不计收入'
      return '记录一笔实际' + (this.type === 'expense' ? '支出' : '收入')
    }
  },
  watch: {
    type(){
      this.cat = this.categoryNames[0]
      const list = this.accList
      if(!list.some(a => a.id === this.accId)) this.accId = list.length ? list[0].id : ''
    }
  },
  created(){
    if(this.tx){
      const t = this.tx
      this.type = t.type
      this.cat = t.category || ''
      this.accId = t.accountId || ''
      this.amount = String(t.amount)
      this.date = t.date || DEMO_TODAY
      this.note = t.note || ''
      return
    }
    this.accId = settingsData.defaultAccountId || (expenseAccounts()[0] && expenseAccounts()[0].id) || ''
  },
  methods: {
    setType(t){
      this.type = t
    },
    onAmountInput(e){
      let v = String(e.target.value || '').replace(/[^\d.]/g, '')
      const parts = v.split('.')
      if(parts.length > 2) v = parts[0] + '.' + parts.slice(1).join('')
      if(v.includes('.')) {
        const p = v.split('.')
        v = p[0] + '.' + p[1].slice(0, 2)
      }
      if(v.startsWith('.')) v = '0' + v
      this.amount = v
    },
    onAmountBlur(){
      if(this.amount === '' || this.amount === '.') { this.amount = ''; return }
      this.amount = (Math.round((parseFloat(this.amount) || 0) * 100) / 100).toFixed(2)
    },
    selectAcc(id){
      this.accId = id
      const a = accountById(id)
      if(this.type === 'expense' && a && a.type === 'stored' && a.defaultCategory){
        this.cat = a.defaultCategory
      }
    },
    save(){
      const num = parseFloat(this.amount) || 0
      if(num <= 0){ showToast('请输入金额'); return }
      if(!this.acc){ showToast('请选择账户'); return }
      if(!this.date){ showToast('请选择日期'); return }
      if(this.type === 'expense' && this.acc.type === 'stored' && num > this.storedAvailable){
        showToast('储值卡余额不足')
        return
      }
      if(this.editing){
        const updated = updateTransaction(store.txEditId, {
          type:this.type, amount:num, category:this.cat, accountId:this.accId, date:this.date, note:this.note
        })
        if(!updated){ showToast('保存失败，请检查账户余额'); return }
        closeSheet()
        showToast('已更新')
        return
      }
      let tx = null
      if(this.type === 'expense'){
        tx = addExpense({ amount:num, category:this.cat, accountId:this.accId, date:this.date, note:this.note })
      } else {
        tx = addIncome({ amount:num, category:this.cat, accountId:this.accId, date:this.date, note:this.note })
      }
      if(!tx){ showToast('记账失败，请检查账户余额'); return }
      closeSheet()
      showToast('已记一笔 ' + (this.type === 'expense' ? '支出 ' : '收入 ') + '¥' + num.toFixed(2))
    },
    remove(){
      if(!this.tx) return
      const id = this.tx.id
      askConfirm('删除这笔流水？删除后账户余额会同步回退。', function(){
        deleteTransaction(id)
        closeSheet()
        showToast('已删除')
      }, { title:'删除流水', confirmText:'删除' })
    }
  }
}
</script>
