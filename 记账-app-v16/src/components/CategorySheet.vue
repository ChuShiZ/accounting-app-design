<template>
  <div class="sheet sheet--bottom sheet--tall">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{editing?'编辑类别':'新增类别'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="field-label" style="margin-top:0">收支类型</div>
      <div class="segmented" style="display:flex;width:100%">
        <button :class="{active:type==='expense'}" style="flex:1;justify-content:center" @click="type='expense'">支出</button>
        <button :class="{active:type==='income'}" style="flex:1;justify-content:center" @click="type='income'">收入</button>
      </div>

      <div class="field-label">名称</div>
      <input class="ledger-input" v-model="name" type="text" placeholder="如：咖啡、宠物、房租" maxlength="20" />

      <div class="field-label">图标</div>
      <div class="icon-grid">
        <button v-for="ic in iconChoices" :key="ic.key" class="icon-choice" :class="{active:iconKey===ic.key}" @click="iconKey=ic.key" :aria-label="ic.label">
          <span class="icon-choice-icon" :style="{color:iconColor(ic.key)}" v-html="icon(ic.key,24)"></span>
          <span class="icon-label">{{ic.label}}</span>
        </button>
      </div>

      <button v-if="editing" class="delete-link" @click="remove">删除类别</button>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" @click="save">保存</button>
    </div>
  </div>
</template>

<script>
import { store, categories, categoryIconChoices, transactions, icon, iconColor, closeSheet, showToast, askConfirm } from '../store.js'

export default {
  name: 'CategorySheet',
  setup(){ return { store, icon, iconColor, closeSheet, showToast } },
  data(){ return { name:'', iconKey:'cart', type:'expense', iconChoices:categoryIconChoices } },
  computed: {
    editing(){ return !!store.categoryEditId },
    cat(){ return categories.find(c => c.id === store.categoryEditId) || null }
  },
  created(){
    if(this.editing && this.cat){
      this.name = this.cat.name
      this.iconKey = this.cat.icon
      this.type = this.cat.type
    } else {
      this.type = store.categoryType || 'expense'
      this.iconKey = this.type === 'income' ? 'salary' : 'cart'
    }
  },
  methods: {
    save(){
      const name = this.name.trim()
      if(!name){ showToast('请输入类别名称'); return }
      const duplicate = categories.some(c => c.type === this.type && c.name === name && c.id !== store.categoryEditId)
      if(duplicate){ showToast('该类别已存在'); return }
      if(this.editing && this.cat){
        const oldName = this.cat.name
        const oldType = this.cat.type
        this.cat.name = name
        this.cat.icon = this.iconKey
        this.cat.type = this.type
        if(oldName !== name){
          const txType = oldType === 'income' ? 'income' : 'expense'
          transactions.forEach(t => {
            if(t.category === oldName && t.type === txType) t.category = name
          })
        }
        closeSheet(); showToast('类别已更新')
      } else {
        categories.push({ id:'c' + Date.now(), name:name, type:this.type, icon:this.iconKey })
        closeSheet(); showToast('类别已添加')
      }
    },
    remove(){
      if(!this.cat) return
      const cat = this.cat
      askConfirm('删除类别「' + cat.name + '」？已有流水会保留原类别名。', function(){
        const i = categories.indexOf(cat)
        if(i >= 0) categories.splice(i, 1)
        closeSheet(); showToast('类别已删除')
      }, { title:'删除类别', confirmText:'删除' })
    }
  }
}
</script>
