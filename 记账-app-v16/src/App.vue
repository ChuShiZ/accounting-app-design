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
        <section class="app-screen" :class="{active:store.tab==='assets'}"><assets-page/></section>
        <section class="app-screen" :class="{active:store.tab==='profile'}"><profile-page/></section>
        <section class="app-screen" :class="{active:store.tab==='categories'}"><categories-page/></section>
        <section class="app-screen" :class="{active:store.tab==='settings'}"><settings-page/></section>
      </div>

      <div class="backdrop" :class="{show:store.sheet}" @click="closeSheet"></div>

      <record-sheet v-if="store.sheet==='记一笔'"/>
      <add-sheet v-if="store.sheet==='添加'"/>
      <deposit-form-sheet v-if="store.sheet==='添加存单' || store.sheet==='编辑存单'"/>
      <deposit-detail-sheet v-if="store.sheet==='存单详情'"/>
      <deposit-settle-sheet v-if="store.sheet==='存单支取'"/>
      <deposit-renew-sheet v-if="store.sheet==='存单转存'"/>
      <card-detail-sheet v-if="store.sheet==='卡片详情'"/>
      <recharge-sheet v-if="store.sheet==='充值'"/>
      <credit-repay-sheet v-if="store.sheet==='信用卡还款'"/>
      <loan-detail-sheet v-if="store.sheet==='贷款详情'"/>
      <loan-repay-sheet v-if="store.sheet==='贷款还款'"/>
      <backup-sheet v-if="store.sheet==='备份'"/>
      <category-sheet v-if="store.sheet==='类别编辑'"/>
      <due-sheet v-if="store.sheet==='待办'"/>
      <confirm-dialog/>

      <div class="toast" :class="{show:store.toastShow}">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5 10 17l9-10"/></svg>
        <span>{{store.toastMsg}}</span>
      </div>

      <nav class="tabbar">
        <button class="tab" :class="{active:store.tabBar==='home'}" @click="closeSheet();switchTab('home')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20h14V9.5"/></svg>首页
        </button>
        <button class="tab" :class="{active:store.tabBar==='report'}" @click="closeSheet();switchTab('report')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M21 20H3"/></svg>报表
        </button>
        <button class="tab tab--add" @click="closeSheet();openRecord()" aria-label="记一笔">
          <span class="tab-add-circle">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
          </span>
          <span class="tab-add-label">记一笔</span>
        </button>
        <button class="tab" :class="{active:store.tabBar==='assets'}" @click="closeSheet();switchTab('assets')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M16 14h2"/></svg>资产
        </button>
        <button class="tab" :class="{active:store.tabBar==='profile'}" @click="closeSheet();switchTab('profile')">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>我的
        </button>
      </nav>
    </div>
  </div>
</template>

<script setup>
import { store, openRecord, closeSheet, switchTab } from './store.js'
import HomePage from './components/HomePage.vue'
import ReportPage from './components/ReportPage.vue'
import AssetsPage from './components/AssetsPage.vue'
import ProfilePage from './components/ProfilePage.vue'
import CategoriesPage from './components/CategoriesPage.vue'
import SettingsPage from './components/SettingsPage.vue'
import RecordSheet from './components/RecordSheet.vue'
import AddSheet from './components/AddSheet.vue'
import DepositFormSheet from './components/DepositFormSheet.vue'
import DepositDetailSheet from './components/DepositDetailSheet.vue'
import DepositSettleSheet from './components/DepositSettleSheet.vue'
import DepositRenewSheet from './components/DepositRenewSheet.vue'
import CardDetailSheet from './components/CardDetailSheet.vue'
import RechargeSheet from './components/RechargeSheet.vue'
import CreditRepaySheet from './components/CreditRepaySheet.vue'
import LoanDetailSheet from './components/LoanDetailSheet.vue'
import LoanRepaySheet from './components/LoanRepaySheet.vue'
import BackupSheet from './components/BackupSheet.vue'
import CategorySheet from './components/CategorySheet.vue'
import DueSheet from './components/DueSheet.vue'
import ConfirmDialog from './components/ConfirmDialog.vue'
</script>
