<template>
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
      <div style="position:relative">
        <select class="ledger-input" :value="acc" @change="selectAcc($event.target.value)" style="appearance:none;padding-right:32px;cursor:pointer">
          <option v-for="a in accList" :key="a" :value="a">{{a}}</option>
        </select>
        <span style="position:absolute;right:12px;top:50%;transform:translateY(-50%);pointer-events:none;color:var(--color-text-secondary)" v-html="icon('chevron',16)"></span>
      </div>
      <div class="caption" v-if="accCard" style="color:var(--color-text-secondary);margin-top:var(--space-2)">
        {{accCard.type==='银行卡' ? '银行卡支付：记入支出（渠道仅记录）' : '储值卡消费：扣减余额，不计支出'}}
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
  </div>
</template>

<script>
import { store, homeData, cardsData, fmt, icon, closeSheet, showToast } from '../store.js'

/* ② 记账 Sheet：类型/类别/账户（仅卡片下拉）/金额/日期/图片/备注 + 保存（新增/编辑）
   ⭐v14 账户选择（ADR-020/021）：
   - 账户 = 卡片列表（动态渲染自 cardsData，无"现金"账户）
   - 默认账户 = 虚拟账户（cardsData[0]），记账默认选中第一张卡
   - 选储值卡 → 类别默认联动为卡片 default_category（未配则保持当前）
   - 保存：银行卡=expense+channel、储值卡=card(balance)；收入恒 income 不挂卡 */
export default {
  name: 'RecordSheet',
  setup(){ return { store, homeData, cardsData, fmt, icon, closeSheet, showToast } },
  data(){ return { type:'expense', cat:'餐饮', acc:'', amount:'¥0.00', note:'', imgOn:false, editing:false } },
  computed: {
    /* 账户列表：仅卡片（⭐v14 无"现金"账户） */
    accList(){ return cardsData.map(function(c){ return c.name }) },
    /* 当前选中卡片的类型 */
    accCard(){ return cardsData.find(function(c){ return c.name===this.acc },this) || null }
  },
  watch: {
    /* ⭐v15 immediate：组件 v-if 创建时值已就位，watch 不会触发回调，需创建即初始化 */
    'store.sheet': {
      immediate: true,
      handler(v){
      if(v!=='记录') return
      this.editing = store.flowEditIdx >= 0 && !!homeData[store.flowEditIdx]
      if(this.editing){
        const t = homeData[store.flowEditIdx]
        this.type = t.cls==='income' ? 'income' : 'expense'
        this.cat = t.catKey || '餐饮'
        this.acc = t.acc || (cardsData.length ? cardsData[0].name : '')
        this.amount = fmt(t.amount)
        this.note = t.remark || ''
        this.imgOn = !!t.hasImg
      } else {
        /* 默认账户为虚拟账户（cardsData[0]）：账户下拉默认选中第一张卡；储值卡联动默认类别 */
        this.type='expense'; this.cat='餐饮'; this.acc=(cardsData.length ? cardsData[0].name : ''); this.amount='¥0.00'; this.note=''; this.imgOn=false
        const card = cardsData.find(function(c){ return c.name===this.acc },this)
        if(card && card.type!=='银行卡' && card.defcat && ['餐饮','交通','购物','居家','工资','周期','其他'].includes(card.defcat)){
          this.cat = card.defcat
        }
      }
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
    /* ⭐v14 选账户/卡片：储值卡且有 default_category → 类别联动默认选中（可切换）；银行卡不改变类别 */
    selectAcc(a){
      this.acc = a
      if(this.type==='income') return
      const card = cardsData.find(function(c){ return c.name===a })
      if(!card || card.type==='银行卡') return
      if(card.defcat && ['餐饮','交通','购物','居家','工资','周期','其他'].includes(card.defcat)){
        this.cat = card.defcat
      }
    },
    save(){
      const num = parseFloat(this.amount.replace(/[^\d.]/g,'')) || 0
      if(num<=0){ showToast('请输入金额'); return }
      /* 支出类型判定：银行卡=expense（渠道仅记录）、储值卡/自定义卡=balance（卡片消费）；收入恒 income */
      let cls = 'expense'
      if(this.type==='income') cls = 'income'
      else {
        const card = cardsData.find(function(c){ return c.name===this.acc },this)
        cls = (card && card.type==='银行卡') ? 'expense' : 'balance'
      }
      if(this.editing){
        const t = homeData[store.flowEditIdx]
        t.amount=num; t.cls=cls; t.cat=this.cat+(this.type==='income'?'收入':''); t.catKey=this.cat; t.acc=this.acc
        t.remark = this.note || t.remark; t.hasImg=this.imgOn
        showToast('已更新')
      } else {
        homeData.unshift({group:'今天', icon: this.type==='income'?'salary':'food', cls:cls, cat:this.cat+(this.type==='income'?'收入':''), remark:(this.acc!==''?this.acc:'')+(this.note?('·'+this.note):''), time:'刚刚', amount:num, catKey:this.cat, timeGroup:'本周', acc:this.acc, hasImg:this.imgOn})
        showToast('已记一笔 '+fmt(num))
      }
      closeSheet()
    }
  }
}
</script>
