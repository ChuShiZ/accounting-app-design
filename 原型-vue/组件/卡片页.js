/* ④ 卡片页：卡片列表 + 添加卡片入口 */
window.卡片页 = {
  setup(){ return { store: window.store, cardsData: window.cardsData, fmt: window.fmt, icon: window.icon, validDisplay: window.validDisplay, openSheet: window.openSheet } },
  methods: {
    openEdit(i){ window.store.cardEditIdx = i; window.openSheet('卡片') }
  },
  template: `
  <header class="app-header">
    <div class="title h1">我的卡片</div>
    <button class="icon-btn" @click="openSheet('添加卡片')" aria-label="添加卡片"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
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
