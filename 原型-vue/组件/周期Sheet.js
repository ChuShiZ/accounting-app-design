/* ③ 周期 Sheet 组：周期详情 + 周期编辑 + 提前还款（store.sheet 区分） */
window.周期Sheet = {
  setup(){ return { store: window.store, periodicData: window.periodicData, fmt: window.fmt, icon: window.icon, openSheet: window.openSheet, closeSheet: window.closeSheet, showToast: window.showToast } },
  data(){ return {
    peName:'', peAmount:'¥0.00', peFreq:'月付', pePaid:0, peTotal:0, peRemain:0,
    prepayAmount:''
  } },
  watch: {
    'store.sheet'(v){
      const p = window.periodicData[window.store.periodicDetailIdx]
      if(v==='周期编辑' && window.store.periodicDetailIdx>=0 && p){
        this.peName=p.name; this.peAmount=window.fmt(p.per); this.peFreq=p.freq||'月付'
        this.pePaid=p.paid||0; this.peTotal=p.total||0; this.peRemain=p.remain||0
      }
      if(v==='提前还款' && p){
        this.prepayAmount=''
      }
    }
  },
  computed: {
    detail(){ return window.periodicData[window.store.periodicDetailIdx] || null },
    prepayAfter(){ const amt=parseFloat(this.prepayAmount)||0; return this.detail?Math.max(0,this.detail.remain-amt):0 }
  },
  methods: {
    iconOf(p){ return p.name==='房贷'?'mortgage':(p.name==='停车费'?'parking':(p.name==='装修贷'?'building':'car')) },
    pct(p){ return p ? Math.round(p.paid/p.total*100) : 0 },
    editAmount(e){
      let v = e.target.value.replace(/[^\d.]/g,'')
      const parts = v.split('.')
      if(parts.length>2) v = parts[0]+'.'+parts.slice(1).join('')
      this.peAmount = (v===''||v==='.') ? '¥0.00' : '¥'+((parseFloat(v)||0).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2}))
    },
    openEdit(){ window.closeSheet(); window.openSheet('周期编辑') },
    openPrepay(){ window.closeSheet(); window.openSheet('提前还款') },
    saveEdit(){
      const p = window.periodicData[window.store.periodicDetailIdx]; if(!p) return
      p.name=(this.peName||p.name).trim()
      p.per = parseFloat(this.peAmount.replace(/[^\d.]/g,'')) || 0
      if(p.freq){ p.freq=this.peFreq }
      else {
        p.paid=parseInt(this.pePaid,10)||0; p.total=parseInt(this.peTotal,10)||p.total; p.remain=parseFloat(this.peRemain)||0
        if(p.paid>=p.total){ p.paid=p.total; p.remain=0; p.state='已结清'; p.next='—' }
        else { p.state='进行中'; if(p.next==='—') p.next='07-01' }
      }
      window.closeSheet(); window.showToast('已更新')
    },
    confirmPrepay(){
      const p = window.periodicData[window.store.periodicDetailIdx]; if(!p) return
      const amt = parseFloat(this.prepayAmount)||0
      if(amt<=0){ window.showToast('请输入还款金额'); return }
      p.remain = Math.max(0, p.remain - amt)
      p.paid = Math.min(p.total, p.paid + Math.max(1, Math.round(amt/p.per)))
      if(p.remain<=0){ p.remain=0; p.paid=p.total; p.state='已结清'; p.next='—' }
      window.homeData.unshift({group:'今天',icon:p.name==='房贷'?'mortgage':'car',cls:'liability',cat:'提前还款',remark:p.name+' · 剩余本金'+window.fmt(p.remain),time:'刚刚',amount:amt,catKey:'周期'})
      window.closeSheet(); window.showToast('还款成功')
    }
  },
  template: `
  <div>
    <!-- 周期详情 -->
    <div v-if="store.sheet==='周期详情'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">{{detail?detail.name:'周期详情'}}</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <template v-if="detail">
          <!-- freq 型 -->
          <template v-if="detail.freq">
            <div class="card"><div class="flow-item" style="padding:0">
              <div class="badge badge--liability" v-html="icon(iconOf(detail),20)"></div>
              <div class="flow-main"><div class="cat">{{detail.name}}</div><div class="sub">{{detail.note}}</div></div>
              <div class="flow-amount amount amount-lg amount--liability">{{fmt(detail.per)}}</div>
            </div></div>
            <div style="margin-top:var(--space-3)"><button class="btn btn-ghost" style="border-width:1.5px;height:42px" @click="openEdit">编辑</button></div>
            <div class="field-label">扣款方式</div><div class="card">按月自动扣款，无需手动操作</div>
          </template>
          <!-- 已结清 -->
          <template v-else-if="detail.state==='已结清'">
            <div class="card" style="opacity:.7"><div class="flow-item" style="padding:0">
              <div class="badge badge--done" v-html="icon(iconOf(detail),20)"></div>
              <div class="flow-main"><div class="cat" style="color:var(--color-text-disabled)">{{detail.name}}</div><div class="sub">每期 {{fmt(detail.per)}} · 已全部还清</div></div>
              <span class="chip" style="pointer-events:none;background:var(--color-surface-2);color:var(--color-text-disabled)">已结清</span>
            </div>
            <div class="progress-wrap"><div class="progress-top"><span style="color:var(--color-text-disabled)">已还 {{detail.paid}} / 共 {{detail.total}} 期</span><span style="color:var(--color-text-disabled)">100%</span></div>
            <div class="progress-track"><div class="progress-fill progress-fill--done" style="width:100%"></div></div></div></div>
            <div class="field-label">每期金额</div><div class="card"><div class="amount amount-lg" style="color:var(--color-text-disabled)">{{fmt(detail.per)}}</div></div>
            <div class="field-label">起始日</div><div class="card body">{{detail.start}}</div>
            <div class="field-label">已还期数</div><div class="card body">{{detail.paid}} / {{detail.total}} 期（已全部还清）</div>
            <div style="margin-top:var(--space-3)"><button class="btn btn-ghost" style="border-width:1.5px;height:42px" @click="openEdit">编辑</button></div>
          </template>
          <!-- 进行中 -->
          <template v-else>
            <div class="card"><div class="progress-wrap">
              <div class="progress-top"><span>已还 {{detail.paid}} / 共 {{detail.total}} 期</span><span>{{pct(detail)}}%</span></div>
              <div class="progress-track"><div class="progress-fill" :style="{width:pct(detail)+'%'}"></div></div>
              <div class="progress-bottom"><span class="label">剩余金额</span><span class="amount amount-md amount--liability">{{fmt(detail.remain)}}</span></div>
            </div></div>
            <div style="margin-top:var(--space-3);display:flex;gap:var(--space-3)">
              <button class="btn btn-ghost" style="border-width:1.5px;height:42px" @click="openEdit">编辑</button>
              <button class="btn btn-ghost" style="border-width:1.5px;height:42px" @click="openPrepay">提前还款</button>
            </div>
            <div class="field-label">每期金额</div><div class="card"><div class="amount amount-lg amount--liability">{{fmt(detail.per)}}</div></div>
            <div class="field-label">起始日</div><div class="card body">{{detail.start}}</div>
            <div class="field-label">剩余期数</div><div class="card body">{{detail.total-detail.paid}} 期</div>
            <div class="field-label">下次扣款</div><div class="card body">{{detail.next}}</div>
          </template>
        </template>
      </div>
    </div>

    <!-- 周期编辑（二级） -->
    <div v-if="store.sheet==='周期编辑'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">编辑周期支出</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div class="field-label">名称</div>
        <input class="ledger-input" v-model="peName" type="text" placeholder="如：房贷" />
        <div class="field-label">每期金额</div>
        <input class="record-amount" v-model="peAmount" inputmode="decimal" @input="editAmount" />
        <div v-if="detail&&detail.freq">
          <div class="field-label">周期</div>
          <div class="chips">
            <button v-for="f in ['月付','周付','季付','年付']" :key="f" class="chip" :class="{active:peFreq===f}" @click="peFreq=f">{{f}}</button>
          </div>
        </div>
        <div v-else>
          <div class="field-label">已还期数</div>
          <input class="ledger-input" v-model.number="pePaid" type="number" inputmode="numeric" />
          <div class="field-label">总期数</div>
          <input class="ledger-input" v-model.number="peTotal" type="number" inputmode="numeric" />
          <div class="field-label">剩余金额</div>
          <input class="ledger-input" v-model.number="peRemain" type="number" inputmode="decimal" placeholder="0.00" />
        </div>
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="saveEdit">保存</button>
      </div>
    </div>

    <!-- 提前还款（二级） -->
    <div v-if="store.sheet==='提前还款'" class="sheet sheet--bottom">
      <div class="sheet-handle"></div>
      <div class="sheet-head"><div class="h1">提前还款</div>
        <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
      </div>
      <div class="sheet-body">
        <div class="field-label">还款金额</div>
        <input class="ledger-input" v-model="prepayAmount" type="number" placeholder="0" inputmode="decimal" style="font-size:22px;font-weight:600;font-variant-numeric:tabular-nums;" />
        <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2);min-height:20px;">剩余本金 {{detail?fmt(detail.remain):''}} → {{fmt(prepayAfter)}}</div>
        <div class="card" style="margin-top:var(--space-3);border-color:var(--color-primary-light);background:var(--color-primary-light);">
          <div class="caption" style="color:var(--color-text-secondary)">还款后剩余本金</div>
          <div class="amount amount-lg amount--liability">{{fmt(prepayAfter)}}</div>
        </div>
      </div>
      <div class="sheet-foot">
        <button class="btn btn-secondary" @click="closeSheet">取消</button>
        <button class="btn btn-primary" @click="confirmPrepay">确认还款</button>
      </div>
    </div>
  </div>`
}
