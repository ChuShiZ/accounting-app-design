<template>
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">近期待办</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div v-if="!list.length" class="empty" style="padding:var(--space-8) 0">
        <div class="ic" v-html="icon('check',24)"></div>
        <div class="t">暂无待办</div>
      </div>
      <div v-else class="menu">
        <div class="item" v-for="d in list" :key="d.kind+d.account.id" @click="openItem(d)">
          <span class="mi" :style="{color:iconColor(d.kind==='deposit'?'deposit':(d.kind==='credit'?'credit':d.account.icon))}" v-html="icon(d.kind==='deposit'?'deposit':(d.kind==='credit'?'credit':d.account.icon),24)"></span>
          <div class="flow-main">
            <div class="mt">{{d.title}}</div>
            <div class="caption" style="color:var(--color-text-secondary);margin-top:2px">{{d.sub}}</div>
          </div>
          <span class="chip" :class="d.status ? (d.status.key==='matured'?'chip--warn':(d.status.key==='due'?'chip--due':'')) : 'chip--due'" style="pointer-events:none">{{d.kind==='deposit'?d.status.label:'待还款'}}</span>
          <span v-html="icon('chevron',18)"></span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { store, dueItems, icon, iconColor, closeSheet, openSheet } from '../store.js'

export default {
  name: 'DueSheet',
  setup(){ return { store, icon, iconColor, closeSheet, openSheet } },
  computed: { list(){ return dueItems() } },
  methods: {
    openItem(d){
      if(d.kind === 'deposit'){ store.depositId = d.account.id; openSheet('存单详情') }
      else if(d.kind === 'credit'){ store.cardId = d.account.id; openSheet('卡片详情') }
      else { store.loanId = d.account.id; openSheet('贷款详情') }
    }
  }
}
</script>
