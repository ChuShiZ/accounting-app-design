/* 我的页：资料 + 菜单入口 */
window.我的页 = {
  setup(){ return { store: window.store, icon: window.icon, showScreen: window.showScreen, switchTab: window.switchTab, closeSheet: window.closeSheet, showToast: window.showToast } },
  methods: {
    nav(name){
      window.closeSheet()
      if(name==='cards') window.switchTab('cards')
      else window.showScreen(name)
    }
  },
  template: `
  <header class="app-header"><div class="title h1">我的</div></header>
  <div class="app-content">
    <div class="profile-top">
      <div class="avatar">林</div>
      <div><div class="pn">林晓</div><div class="ps">已记账 386 天 · 本月结余 ¥10,660</div></div>
    </div>
    <div class="menu">
      <div class="item" @click="nav('periodic')">
        <span class="mi" v-html="icon('refresh',20)"></span>
        <span class="mt">周期性支出</span><span class="mv">4 笔</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="nav('cards')">
        <span class="mi" v-html="icon('card2',20)"></span>
        <span class="mt">卡片管理</span><span class="mv">4 张</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="nav('search')">
        <span class="mi" v-html="icon('search',20)"></span>
        <span class="mt">明细搜索</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="showToast('预算提醒（示例）')">
        <span class="mi" v-html="icon('clock',20)"></span>
        <span class="mt">预算提醒</span><span class="mv">已开启</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>
    <div class="section-gap"></div>
    <div class="menu">
      <div class="item" @click="showToast('帮助与反馈（示例）')">
        <span class="mi" v-html="icon('help',20)"></span>
        <span class="mt">帮助与反馈</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="showToast('设置（示例）')">
        <span class="mi" v-html="icon('edit',20)"></span>
        <span class="mt">设置</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>
    <div class="section-gap"></div>
  </div>`
}
