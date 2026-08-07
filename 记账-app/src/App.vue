<template>
  <div class="device">
    <div class="screen">
      <div class="statusbar">
        <span>9:41</span>
        <span class="right">
          <svg width="17" height="12" viewBox="0 0 17 12" fill="none"><rect x="0" y="7" width="3" height="5" rx="1" fill="currentColor"/><rect x="4.5" y="4.5" width="3" height="7.5" rx="1" fill="currentColor"/><rect x="9" y="2" width="3" height="10" rx="1" fill="currentColor"/><rect x="13.5" y="0" width="3" height="12" rx="1" fill="currentColor" opacity=".4"/></svg>
          <svg width="16" height="12" viewBox="0 0 16 12" fill="none"><path d="M8 11.5c2.5 0 4.8-1 6.4-2.6A8 8 0 0 0 1.6 8.9 8 8 0 0 0 8 11.5Z" fill="currentColor"/><path d="M8 7.2c1.2 0 2.3-.5 3.1-1.3A3.9 3.9 0 0 0 4.9 5.9 3.9 3.9 0 0 0 8 7.2Z" fill="currentColor" opacity=".5"/></svg>
          <svg width="26" height="12" viewBox="0 0 26 12" fill="none"><rect x=".5" y=".5" width="21" height="11" rx="3" stroke="currentColor"/><rect x="2" y="2" width="16" height="8" rx="1.5" fill="currentColor"/><rect x="23" y="4" width="2" height="4" rx="1" fill="currentColor" opacity=".5"/></svg>
        </span>
      </div>

      <div class="screens">
        <section class="app-screen" :class="{active:store.tab==='home'}"><home-page/></section>
        <section class="app-screen" :class="{active:store.tab==='report'}"><report-page/></section>
        <section class="app-screen" :class="{active:store.tab==='cards'}"><cards-page/></section>
        <section class="app-screen" :class="{active:store.tab==='profile'}"><profile-page/></section>
        <section class="app-screen" :class="{active:store.tab==='periodic'}"><periodic-page/></section>
        <section class="app-screen" :class="{active:store.tab==='search'}"><search-page/></section>
      </div>

      <button class="fab" v-show="store.tab==='home'" @click="openSheet('记录')" aria-label="记一笔">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
      </button>

      <div class="backdrop" :class="{show:store.sheet}" @click="closeSheet"></div>

      <record-sheet v-if="store.sheet==='记录'"/>
      <card-sheet v-if="['卡片','充值','添加卡片','有效期'].includes(store.sheet)"/>
      <periodic-sheet v-if="['周期详情','周期编辑','提前还款'].includes(store.sheet)"/>
      <filter-sheet v-if="store.sheet==='筛选'"/>
      <confirm-dialog/>

      <div class="toast" :class="{show:store.toastShow}">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5 10 17l9-10"/></svg>
        <span>{{store.toastMsg}}</span>
      </div>

      <nav class="tabbar">
        <button class="tab" :class="{active:tabActive('home')}" @click="closeSheet();switchTab('home')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20h14V9.5"/></svg>首页
        </button>
        <button class="tab" :class="{active:tabActive('report')}" @click="closeSheet();switchTab('report')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M21 20H3"/></svg>报表
        </button>
        <button class="tab" :class="{active:tabActive('cards')}" @click="closeSheet();switchTab('cards')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h4"/></svg>卡片
        </button>
        <button class="tab" :class="{active:tabActive('profile')}" @click="closeSheet();switchTab('profile')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>我的
        </button>
      </nav>
    </div>
  </div>
</template>

<script setup>
import { store, icon, openSheet, closeSheet, switchTab, showToast } from './store.js'
import HomePage from './components/HomePage.vue'
import ReportPage from './components/ReportPage.vue'
import CardsPage from './components/CardsPage.vue'
import ProfilePage from './components/ProfilePage.vue'
import PeriodicPage from './components/PeriodicPage.vue'
import SearchPage from './components/SearchPage.vue'
import RecordSheet from './components/RecordSheet.vue'
import CardSheet from './components/CardSheet.vue'
import PeriodicSheet from './components/PeriodicSheet.vue'
import FilterSheet from './components/FilterSheet.vue'
import ConfirmDialog from './components/ConfirmDialog.vue'

function tabActive(t){ return store.tabBar===t }
</script>
