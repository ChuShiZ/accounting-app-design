<template>
  <div class="page">
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
        <span class="mt">卡片管理</span><span class="mv">{{cardsData.length}} 张</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="nav('search')">
        <span class="mi" v-html="icon('search',20)"></span>
        <span class="mt">明细搜索</span>
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
      <div class="item" @click="nav('settings')">
        <span class="mi" v-html="icon('settings',20)"></span>
        <span class="mt">设置</span><span class="mv">备份与恢复</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { cardsData, icon, showScreen, switchTab, closeSheet, showToast } from '../store.js'

/* 我的页：资料 + 菜单入口 */
export default {
  name: 'ProfilePage',
  setup(){ return { cardsData, icon, showScreen, switchTab, closeSheet, showToast } },
  methods: {
    nav(name){
      closeSheet()
      if(name==='cards') switchTab('cards')
      else showScreen(name)
    }
  }
}
</script>
