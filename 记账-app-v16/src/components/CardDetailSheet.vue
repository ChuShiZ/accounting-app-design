<template>
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">{{a ? a.name : '账户详情'}}</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body" v-if="a">
      <div class="card">
        <div class="detail-top">
          <div>
            <div class="asset-sub">{{a.institution || typeLabel(a)}} · {{typeLabel(a)}}</div>
            <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-1)">{{a.type==='credit'?'待还金额':(a.type==='stored'?'卡内余额':'当前余额')}}</div>
          </div>
          <span class="chip chip--asset" style="pointer-events:none">{{typeLabel(a)}}</span>
        </div>
        <div class="amount amount-xl" :class="a.type==='credit'?'amount--liability':''" style="margin-top:var(--space-3)">
          {{a.type==='credit' ? fmt(Math.abs(a.balance)) : fmtSigned(a.balance)}}
        </div>
        <div class="caption" style="color:var(--color-text-secondary);margin-top:var(--space-2)">
          {{a.type==='credit' ? '信用卡消费计入支出；还款不再计支出' : (a.type==='stored' ? '充值计支出；卡内消费不再重复计支出' : '余额只作展示，收支以流水为准')}}
        </div>
      </div>

      <div class="action-grid action-grid--single" v-if="a.type==='stored' || a.type==='credit'">
        <button v-if="a.type==='stored'" class="btn btn-primary" @click="openSheet('充值')">充值</button>
        <button v-if="a.type==='credit'" class="btn btn-primary" @click="openSheet('信用卡还款')">还款</button>
      </div>

      <div class="field-label">最近流水</div>
      <div v-if="!list.length" class="caption" style="color:var(--color-text-secondary)">暂无流水</div>
      <div v-else class="group-card">
        <div class="flow-item" v-for="t in list" :key="t.id" @click="editFlow(t)">
          <div class="badge" :style="{color:colorForCategory(t.category,t.type)}" v-html="icon(iconForCategory(t.category,t.type),24)"></div>
          <div class="flow-main">
            <div class="cat">{{t.category}}</div>
            <div class="sub">{{t.note || '—'}} · {{t.date}} {{t.time}}</div>
          </div>
          <div class="flow-amount amount amount-md" :class="t.type==='income'?'amount--income':'amount--expense'">
            {{t.type==='income'?'+':'-'}}{{fmt(t.amount)}}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { store, accountById, transactions, icon, fmt, fmtSigned, typeLabel, openSheet, openRecord, closeSheet, iconForCategory, colorForCategory } from '../store.js'

export default {
  name: 'CardDetailSheet',
  setup(){ return { store, icon, iconForCategory, colorForCategory, fmt, fmtSigned, typeLabel, openSheet, closeSheet } },
  computed: {
    a(){ return accountById(store.cardId) },
    list(){ return this.a ? transactions.filter(t => t.accountId === this.a.id).slice(0, 6) : [] }
  },
  methods: {
    editFlow(t){ openRecord(t.id) }
  }
}
</script>
