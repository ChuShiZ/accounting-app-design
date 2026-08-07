/* ⭐v14 默认账户 Sheet：只设置默认账户开关（卡片列表互斥单选，无其他字段） */
window.默认账户Sheet = {
  setup(){ return { store: window.store, cardsData: window.cardsData, icon: window.icon, closeSheet: window.closeSheet, showToast: window.showToast } },
  methods: {
    toggle(name){
      window.store.defAcc = (window.store.defAcc===name) ? null : name
    },
    save(){
      window.closeSheet()
      window.showToast(window.store.defAcc ? '默认账户：'+window.store.defAcc : '未设置（默认第一张卡）')
    }
  },
  template: `
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">默认账户</div>
      <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="caption" style="color:var(--color-text-secondary);margin-bottom:var(--space-3)">设置默认记账账户：记账时"账户 / 卡片"默认选中该项。全不选则默认第一张卡。</div>
      <div class="group-card">
        <div v-for="(c,i) in cardsData" :key="i" class="validity-row" style="margin-top:0;border-top:none" :style="i>0?{borderTop:'1px solid var(--color-divider)'}:{}">
          <span class="vl">{{c.name}}</span>
          <span class="vr">
            <span class="caption" style="color:var(--color-text-secondary)">{{c.type}}</span>
            <div class="toggle" :class="{on:store.defAcc===c.name}" @click="toggle(c.name)"></div>
          </span>
        </div>
      </div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="save">保存</button>
    </div>
  </div>`
}
