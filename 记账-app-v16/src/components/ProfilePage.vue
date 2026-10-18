<template>
  <div class="page">
  <header class="app-header"><div class="title h1">我的</div></header>
  <div class="app-content">
    <div class="menu">
      <div class="item" @click="showScreen('settings')">
        <span class="mi" v-html="icon('settings',20)"></span>
        <span class="mt">设置</span><span class="mv">WebDAV · 备份</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="showScreen('categories')">
        <span class="mi" v-html="icon('database',20)"></span>
        <span class="mt">类别管理</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
      <div class="item" @click="showToast('Excel 导入在后续批次实现')">
        <span class="mi" v-html="icon('upload',20)"></span>
        <span class="mt">Excel 导入</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="menu">
      <div class="item" @click="showToast('帮助与反馈在后续批次实现')">
        <span class="mi" v-html="icon('help',20)"></span>
        <span class="mt">帮助与反馈</span>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>

    <div class="caption" style="text-align:center;color:var(--color-text-secondary);margin-top:var(--space-6)">记账 · v16 原型</div>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { icon, showScreen, showToast } from '../store.js'

export default {
  name: 'ProfilePage',
  setup(){ return { icon, showScreen, showToast } }
}
</script>
