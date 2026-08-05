/* ④ 卡片 Sheet 组：卡片编辑 + 充值 + 添加卡片 + 有效期（store.sheet 区分） */
window.卡片Sheet = {
  setup(){ return { store: window.store, cardsData: window.cardsData, fmt: window.fmt, icon: window.icon, validDisplay: window.validDisplay, openSheet: window.openSheet, closeSheet: window.closeSheet, showToast: window.showToast } },
  data(){ return {
    editType:'银行卡', editDefcat:'不设置', editName:'', editBalance:0,
    addType:'银行卡', addDefcat:'不设置', addName:'', addBalance:'',
    rechargePaid:'', rechargeCredit:'', rechargeNote:'',
    vvOn:false, vvMM:'', vvYY:''
  } },
  watch: {
    'store.sheet'(v){
      if(v==='卡片' && window.store.cardEditIdx>=0){
        const c = window.cardsData[window.store.cardEditIdx]
        this.editType=c.type; this.editDefcat=c.defcat||'不设置'; this.editName=c.name; this.editBalance=c.balance
      }
      if(v==='有效期' && window.store.cardEditIdx>=0){
        const c = window.cardsData[window.store.cardEditIdx]
        this.vvOn = c.valid==null
        this.vvMM = c.valid ? c.valid.split('/')[0] : ''
        this.vvYY = c.valid ? c.valid.split('/')[1] : ''
      }
    }
  },
  computed: {
    curCard(){ return window.cardsData[window.store.cardEditIdx] || null },
    flows(){ return this.curCard ? (this.curCard.flows || [
      {icon:'cart',cls:'balance',cat:this.curCard.name+'消费',sub:'超市',amt:50},
      {icon:'coffee',cls:'balance',cat:this.curCard.name+'消费',sub:'便利店',amt:18},
      {icon:'card',cls:'balance',cat:'充值',sub:'微信',amt:200}
    ]) : [] },
    giftAmount(){ const p=parseFloat(this.rechargePaid)||0, c=parseFloat(this.rechargeCredit)||0; return c>p ? c-p : 0 }
  },
  methods: {
    openRecharge(){ window.store.rechargeIdx = window.store.cardEditIdx; this.rechargePaid=''; this.rechargeCredit=''; this.rechargeNote=''; window.openSheet('充值') },
    saveRecharge(){
      const paid=parseFloat(this.rechargePaid)||0, credit=parseFloat(this.rechargeCredit)||0
      if(paid<=0){ window.showToast('请输入实付金额'); return }
      if(credit<paid){ window.showToast('到账金额不能小于实付'); return }
      const c = window.cardsData[window.store.rechargeIdx]; if(!c) return
      c.balance = Math.round(((c.balance||0)+credit)*100)/100
      c.flows = c.flows||[]
      c.flows.unshift({icon:'card',cls:'balance',cat:'充值',sub:'实付 ¥'+window.fmt(paid)+(credit>paid?' 赠送 ¥'+window.fmt(credit-paid):''),amt:credit})
      window.closeSheet(); window.showToast('充值成功')
    },
    saveEdit(){
      if(window.store.cardEditIdx<0) return
      const c = window.cardsData[window.store.cardEditIdx]
      c.type=this.editType; c.name=(this.editName||c.name).trim(); c.balance=parseFloat(this.editBalance)||0
      c.icon = c.type==='储值卡' ? 'card' : (c.type==='自定义' ? 'coffee' : 'bank')
      c.defcat = this.editDefcat==='不设置' ? null : this.editDefcat
      window.closeSheet(); window.showToast('已更新')
    },
    saveAdd(){
      const name=(this.addName||'未命名卡片').trim()
      const bal=parseFloat(this.addBalance)||0
      window.cardsData.push({name:name,type:this.addType,icon:this.addType==='储值卡'?'card':(this.addType==='自定义'?'coffee':'bank'),balance:bal,valid:null,defcat:this.addDefcat==='不设置'?null:this.addDefcat})
      window.closeSheet(); window.showToast('已添加卡片')
    },
    saveValid(){
      if(window.store.cardEditIdx<0) return
      window.cardsData[window.store.cardEditIdx].valid = this.vvOn ? null : ((this.vvMM||'--')+'/'+(this.vvYY||'--'))
      window.closeSheet(); window.showToast('有效期已更新')
    }
  },
  template: `
  <div>
    <!-- 卡片编辑 -->
    <div v-if="store.sheet==='卡片'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">{{curCard?curCard.name:'卡片'}}</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div v-if="curCard" class="stored-card">
          <div class="row"><span class="name">{{curCard.name}}</span><span class="type-badge">{{curCard.type}}</span></div>
          <div><div class="balance-label">可用余额</div><div class="amount amount-md">{{fmt(curCard.balance)}}</div></div>
          <div class="valid" style="opacity:1" v-html="validDisplay(curCard)"></div>
        </div>
        <div class="field-label">卡片类型</div>
        <div class="chips">
          <button v-for="t in ['银行卡','储值卡','自定义']" :key="t" class="chip" :class="{active:editType===t}" @click="editType=t">{{t}}</button>
        </div>
        <div class="field-label">默认消费类别</div>
        <div class="chips">
          <button v-for="c in ['不设置','餐饮','交通','购物','居家','其他']" :key="c" class="chip" :class="{active:editDefcat===c}" @click="editDefcat=c">{{c}}</button>
        </div>
        <div class="field-label">卡片名称</div>
        <input class="ledger-input" v-model="editName" type="text" placeholder="如：咖啡储值卡" />
        <div class="field-label">可用余额</div>
        <input class="ledger-input" v-model.number="editBalance" type="number" inputmode="decimal" placeholder="0.00" />
        <div class="validity-row">
          <span class="vl">有效期</span>
          <span class="vr"><span v-if="curCard">{{curCard.valid||'永久有效'}}</span><span class="edit-link" @click="openSheet('有效期')">编辑</span></span>
        </div>
        <div class="field-label">消费记录</div>
        <div class="group-card">
          <div class="flow-item" v-for="(f,i) in flows" :key="i" style="cursor:default">
            <div class="badge" :class="'badge--'+f.cls" v-html="icon(f.icon,20)"></div>
            <div class="flow-main"><div class="cat">{{f.cat}}</div><div class="sub">{{f.sub}}</div></div>
            <div class="flow-amount amount amount-lg" :class="'amount--'+f.cls">{{f.amt>=0?'+':'-'}}{{fmt(Math.abs(f.amt))}}</div>
          </div>
        </div>
        <button class="btn btn-primary" style="margin-top:var(--space-4)" @click="openRecharge">充值</button>
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="saveEdit">保存</button>
      </div>
    </div>

    <!-- 充值（二级） -->
    <div v-if="store.sheet==='充值'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">充值</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div class="field-label">实付金额</div>
        <input class="ledger-input" v-model="rechargePaid" type="number" placeholder="0.00" inputmode="decimal" style="font-size:22px;font-weight:600;font-variant-numeric:tabular-nums;" />
        <div class="field-label" style="margin-top:var(--space-4)">到账金额</div>
        <input class="ledger-input" v-model="rechargeCredit" type="number" placeholder="0.00" inputmode="decimal" style="font-size:22px;font-weight:600;font-variant-numeric:tabular-nums;" />
        <div class="caption" v-if="giftAmount>0" style="color:var(--color-primary);margin-top:var(--space-2)">赠送 ¥{{fmt(giftAmount)}}</div>
        <div class="validity-row">
          <span class="vl">日期</span><span class="vr">今天</span>
        </div>
        <div class="field-label">备注</div>
        <input class="ledger-input" v-model="rechargeNote" type="text" placeholder="如：充值送礼品" />
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="saveRecharge">确认充值</button>
      </div>
    </div>

    <!-- 添加卡片 -->
    <div v-if="store.sheet==='添加卡片'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">添加卡片</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div class="field-label">卡片类型</div>
        <div class="chips">
          <button v-for="t in ['银行卡','储值卡','自定义']" :key="t" class="chip" :class="{active:addType===t}" @click="addType=t">{{t}}</button>
        </div>
        <div class="field-label">默认消费类别</div>
        <div class="chips">
          <button v-for="c in ['不设置','餐饮','交通','购物','居家','其他']" :key="c" class="chip" :class="{active:addDefcat===c}" @click="addDefcat=c">{{c}}</button>
        </div>
        <div class="field-label">卡片名称</div>
        <input class="ledger-input" v-model="addName" type="text" placeholder="如：咖啡储值卡" />
        <div class="field-label">初始余额</div>
        <input class="ledger-input" v-model="addBalance" type="number" placeholder="0.00" />
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="saveAdd">保存</button>
      </div>
    </div>

    <!-- 有效期（二级） -->
    <div v-if="store.sheet==='有效期'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">设置有效期</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div class="field-label">有效期（MM / YY）</div>
        <div style="display:flex;gap:var(--space-3);align-items:center">
          <input class="ledger-input" v-model="vvMM" type="text" placeholder="MM" maxlength="2" style="width:70px;text-align:center" :disabled="vvOn" />
          <span style="color:var(--color-text-secondary);font-weight:600">/</span>
          <input class="ledger-input" v-model="vvYY" type="text" placeholder="YY" maxlength="2" style="width:70px;text-align:center" :disabled="vvOn" />
        </div>
        <div class="field-label">无有效期</div>
        <div class="toggle-wrap">
          <div class="toggle" :class="{on:vvOn}" @click="vvOn=!vvOn"></div>
          <span class="caption" style="color:var(--color-text-secondary)">{{vvOn?'永久有效':'关闭'}}</span>
        </div>
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="saveValid">保存</button>
      </div>
    </div>
  </div>`
}
