/* ② 记账 Sheet：类型/类别/账户/金额/日期/图片/备注 + 保存（新增/编辑） */
window.记账Sheet = {
  setup(){ return { store: window.store, homeData: window.homeData, fmt: window.fmt, icon: window.icon, closeSheet: window.closeSheet, showToast: window.showToast } },
  data(){ return { type:'expense', cat:'餐饮', acc:'现金', amount:'¥0.00', note:'', imgOn:false, editing:false } },
  watch: {
    'store.sheet'(v){
      if(v!=='记录') return
      this.editing = window.store.flowEditIdx >= 0 && !!window.homeData[window.store.flowEditIdx]
      if(this.editing){
        const t = window.homeData[window.store.flowEditIdx]
        this.type = t.cls==='income' ? 'income' : 'expense'
        this.cat = t.catKey || '餐饮'
        this.acc = t.acc || '现金'
        this.amount = window.fmt(t.amount)
        this.note = t.remark || ''
        this.imgOn = !!t.hasImg
      } else {
        this.type='expense'; this.cat='餐饮'; this.acc='现金'; this.amount='¥0.00'; this.note=''; this.imgOn=false
      }
    }
  },
  methods: {
    onAmountInput(e){
      let v = e.target.value.replace(/[^\d.]/g,'')
      const parts = v.split('.')
      if(parts.length>2) v = parts[0]+'.'+parts.slice(1).join('')
      this.amount = (v===''||v==='.') ? '¥0.00' : '¥'+((parseFloat(v)||0).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2}))
    },
    onAmountFocus(){ if(this.amount==='¥0.00') this.amount='¥' },
    save(){
      const num = parseFloat(this.amount.replace(/[^\d.]/g,'')) || 0
      if(num<=0){ window.showToast('请输入金额'); return }
      const cls = this.type==='income' ? 'income' : (this.acc.includes('卡') ? 'balance' : 'expense')
      if(this.editing){
        const t = window.homeData[window.store.flowEditIdx]
        t.amount=num; t.cls=cls; t.cat=this.cat+(this.type==='income'?'收入':''); t.catKey=this.cat; t.acc=this.acc
        t.remark = this.note || t.remark; t.hasImg=this.imgOn
        window.showToast('已更新')
      } else {
        window.homeData.unshift({group:'今天', icon: this.type==='income'?'salary':'food', cls:cls, cat:this.cat+(this.type==='income'?'收入':''), remark:(this.acc!=='现金'?this.acc:'')+(this.note?('·'+this.note):''), time:'刚刚', amount:num, catKey:this.cat, timeGroup:'本周', acc:this.acc, hasImg:this.imgOn})
        window.showToast('已记一笔 '+window.fmt(num))
      }
      window.closeSheet()
    }
  },
  template: `
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{editing?'编辑这笔':'记一笔'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="segmented" style="display:flex;width:100%">
        <button :class="{active:type==='expense'}" style="flex:1;justify-content:center" @click="type='expense'">支出</button>
        <button :class="{active:type==='income'}" style="flex:1;justify-content:center" @click="type='income'">收入</button>
      </div>
      <input class="record-amount" v-model="amount" inputmode="decimal" @focus="onAmountFocus" @input="onAmountInput" />
      <div class="field-label">类别</div>
      <div class="chips">
        <button v-for="c in ['餐饮','交通','购物','居家','工资','周期','其他']" :key="c" class="chip" :class="{active:cat===c}" @click="cat=c">{{c}}</button>
      </div>
      <div class="field-label">账户 / 卡片</div>
      <div class="chips">
        <button v-for="a in ['现金','银行卡','银座购物卡','理发卡','自定义卡']" :key="a" class="chip" :class="{active:acc===a}" @click="acc=a">{{a}}</button>
      </div>
      <div class="field-label">日期</div>
      <input class="ledger-input" type="text" value="2026-06-22（今天）" readonly />
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
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="save">保存</button>
    </div>
  </div>`
}
