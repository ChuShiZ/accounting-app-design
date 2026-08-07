<template>
  <div class="page">
  <header class="app-header">
    <div class="title h1">我的卡片</div>
    <button class="icon-btn" @click="openSheet('添加卡片')" aria-label="添加卡片"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
    <!-- 卡片列表（"默认账户"为虚拟账户：无余额、不可编辑/删除，不可左滑） -->
    <template v-for="(c,i) in cardsData" :key="i">
      <div v-if="c.name==='默认账户'" class="stored-card" style="cursor:default">
        <div class="row"><span class="name">{{c.name}}</span><span class="type-badge">默认</span></div>
        <div><div class="balance-label">记账时默认使用的账户</div></div>
      </div>
      <SwipeDelete v-else round @delete="confirmDeleteCard(i)">
        <div class="stored-card" @click="openEdit(i)" style="cursor:pointer">
          <div class="row"><span class="name">{{c.name}}</span><span class="type-badge">{{c.type}}</span></div>
          <div><div class="balance-label">可用余额</div><div class="amount amount-md">{{fmt(c.balance)}}</div></div>
          <div class="valid" style="opacity:1" v-html="validDisplay(c)"></div>
        </div>
      </SwipeDelete>
      <div v-if="i<cardsData.length-1" style="height:var(--space-3)"></div>
    </template>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { store, cardsData, fmt, icon, validDisplay, openSheet, showToast, askConfirm } from '../store.js'
import SwipeDelete from './SwipeDelete.vue'

/* ④ 卡片页：卡片列表（"默认账户"为虚拟账户不可删；普通卡左滑删除） */
export default {
  name: 'CardsPage',
  components: { SwipeDelete },
  setup(){ return { store, cardsData, fmt, icon, validDisplay, openSheet } },
  methods: {
    openEdit(i){ store.cardEditIdx = i; openSheet('卡片') },
    confirmDeleteCard(i){
      const self = this
      askConfirm('确定删除这张卡吗？', function(){ self.deleteCard(i) })
    },
    deleteCard(i){
      if(i>=0 && i<cardsData.length) cardsData.splice(i,1)
      showToast('已删除')
    }
  }
}
</script>
