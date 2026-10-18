<template>
  <div class="page">
  <header class="app-header">
    <button class="icon-btn" @click="backToTab" aria-label="返回"><span v-html="icon('back',22)"></span></button>
    <div class="title h1">类别管理</div>
    <button class="icon-btn" @click="addNew" aria-label="新增类别"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
    <div style="display:flex;justify-content:center">
      <div class="segmented">
        <button :class="{active:type==='expense'}" @click="type='expense'">支出</button>
        <button :class="{active:type==='income'}" @click="type='income'">收入</button>
      </div>
    </div>

    <div class="section-gap"></div>
    <div class="menu">
      <div class="item" v-for="c in list" :key="c.id" @click="edit(c)">
        <span class="mi" :style="{color:colorForCategory(c.name,c.type)}" v-html="icon(c.icon,24)"></span>
        <div class="asset-main">
          <div class="mt">{{c.name}}</div>
          <div class="asset-sub">已用 {{usage(c)}} 笔</div>
        </div>
        <span v-html="icon('chevron',18)"></span>
      </div>
    </div>

    <div class="caption" style="color:var(--color-text-secondary);padding:var(--space-3) 0;line-height:1.5">
      点击类别可修改名称和图标；右上 + 新增类别。
    </div>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { store, categories, transactions, icon, colorForCategory, openSheet, backToTab } from '../store.js'

export default {
  name: 'CategoriesPage',
  setup(){ return { store, categories, transactions, icon, colorForCategory, openSheet, backToTab } },
  data(){ return { type:'expense' } },
  computed: {
    list(){ return categories.filter(c => c.type === this.type) }
  },
  methods: {
    usage(c){
      const txType = c.type === 'income' ? 'income' : 'expense'
      return transactions.filter(t => t.category === c.name && t.type === txType).length
    },
    addNew(){
      store.categoryEditId = null
      store.categoryType = this.type
      openSheet('类别编辑')
    },
    edit(c){
      store.categoryEditId = c.id
      store.categoryType = c.type
      openSheet('类别编辑')
    }
  }
}
</script>
