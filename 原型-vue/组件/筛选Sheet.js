/* ⑥ 筛选抽屉（顶部 Sheet） */
window.筛选Sheet = {
  setup(){ return { store: window.store, icon: window.icon, closeSheet: window.closeSheet, showToast: window.showToast } },
  methods: {
    toggle(key, v){
      const arr = window.store.searchFilter[key]
      const i = arr.indexOf(v)
      if(i>=0) arr.splice(i,1); else arr.push(v)
    },
    reset(){
      window.store.searchFilter = { cat:[], type:[], time:[] }
      window.store.filterMin=''; window.store.filterMax=''
    },
    apply(){ window.closeSheet(); window.showToast('已应用筛选') }
  },
  template: `
  <div class="sheet sheet--top">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">筛选</div>
      <button class="icon-btn" @click="closeSheet"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="field-label">类别</div>
      <div class="chips">
        <button v-for="c in ['餐饮','交通','购物','居家','工资','周期']" :key="c" class="chip" :class="{active:store.searchFilter.cat.includes(c)}" @click="toggle('cat',c)">{{c}}</button>
      </div>
      <div class="field-label">类型</div>
      <div class="chips">
        <button v-for="t in ['支出','收入','周期扣款','卡片消费']" :key="t" class="chip" :class="{active:store.searchFilter.type.includes(t)}" @click="toggle('type',t)">{{t}}</button>
      </div>
      <div class="field-label">时间</div>
      <div class="chips">
        <button v-for="t in ['本周','本月','本季','本年']" :key="t" class="chip" :class="{active:store.searchFilter.time.includes(t)}" @click="toggle('time',t)">{{t}}</button>
      </div>
      <div class="field-label">金额区间</div>
      <div style="display:flex;gap:var(--space-3)">
        <input class="ledger-input" v-model="store.filterMin" type="number" placeholder="最小 ¥" />
        <input class="ledger-input" v-model="store.filterMax" type="number" placeholder="最大 ¥" />
      </div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="reset">重置</button>
      <button class="btn btn-primary" @click="apply">应用</button>
    </div>
  </div>`
}
