/* ④ 卡片页：顶部固定"默认账户"条目（无余额/有效期）+ 卡片列表
   ⭐v14：点击"默认账户" → 弹窗只设置默认账户开关（选卡片互斥）；无"现金"账户 */
window.卡片页 = {
  setup(){ return { store: window.store, cardsData: window.cardsData, fmt: window.fmt, icon: window.icon, validDisplay: window.validDisplay, openSheet: window.openSheet } },
  computed: {
    defAccName(){
      if(!window.store.defAcc) return '未设置（默认第一张卡）'
      return window.store.defAcc
    }
  },
  methods: {
    openEdit(i){ window.store.cardEditIdx = i; window.openSheet('卡片') }
  },
  template: `
  <header class="app-header">
    <div class="title h1">我的卡片</div>
    <button class="icon-btn" @click="openSheet('添加卡片')" aria-label="添加卡片"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
    <!-- 固定"默认账户"条目：无余额/有效期，仅默认账户设置入口 -->
    <div class="card" @click="openSheet('默认账户')" style="display:flex;align-items:center;gap:var(--space-3);cursor:pointer">
      <div class="badge badge--income" v-html="icon('bank',20)"></div>
      <div class="flow-main"><div class="cat">默认账户</div><div class="sub">{{defAccName}}</div></div>
      <span v-html="icon('chevron',18)"></span>
    </div>
    <div style="height:var(--space-4)"></div>
    <!-- 卡片列表 -->
    <template v-for="(c,i) in cardsData" :key="i">
      <div class="stored-card" @click="openEdit(i)" style="cursor:pointer">
        <div class="row"><span class="name">{{c.name}}</span><span class="type-badge">{{c.type}}</span></div>
        <div><div class="balance-label">可用余额</div><div class="amount amount-md">{{fmt(c.balance)}}</div></div>
        <div class="valid" style="opacity:1" v-html="validDisplay(c)"></div>
      </div>
      <div v-if="i<cardsData.length-1" style="height:var(--space-3)"></div>
    </template>
    <div class="section-gap"></div>
  </div>`
}
