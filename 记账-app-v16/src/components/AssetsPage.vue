<template>
  <div class="page">
  <header class="app-header">
    <div class="title h1">资产</div>
    <button class="icon-btn" @click="openSheet('添加')" aria-label="添加"><span v-html="icon('plus',22)"></span></button>
  </header>
  <div class="app-content">
    <template v-if="groups.accounts.length">
      <div class="section-title" style="margin-top:var(--space-3)">账户</div>
      <div class="menu">
        <div class="item" v-for="a in groups.accounts" :key="a.id" @click="openAccount(a)">
          <span class="mi" :style="{color:iconColor(a.icon)}" v-html="icon(a.icon,24)"></span>
          <div class="asset-main">
            <div class="mt">{{a.name}}</div>
            <div class="asset-sub">{{accountSubtitle(a)}}</div>
          </div>
          <div class="asset-amount">{{fmtSigned(a.balance)}}</div>
          <span v-html="icon('chevron',18)"></span>
        </div>
      </div>
    </template>

    <template v-if="groups.stored.length">
      <div class="section-gap"></div>
      <div class="section-title">储值卡</div>
      <div class="menu">
        <div class="item" v-for="a in groups.stored" :key="a.id" @click="openAccount(a)">
          <span class="mi" :style="{color:iconColor(a.icon)}" v-html="icon(a.icon,24)"></span>
          <div class="asset-main">
            <div class="mt">{{a.name}}</div>
            <div class="asset-sub">{{accountSubtitle(a)}}</div>
          </div>
          <div class="asset-amount">{{fmtSigned(a.balance)}}</div>
          <span v-html="icon('chevron',18)"></span>
        </div>
      </div>
    </template>

    <div class="section-gap"></div>
    <div class="section-head">
      <div class="section-title" style="margin:0">存单</div>
      <button class="link-btn" @click="openSheet('添加存单')">添加存单</button>
    </div>
    <div v-if="!groups.deposits.length" class="empty" style="padding:var(--space-8) 0">
      <div class="ic" v-html="icon('deposit',24)"></div>
      <div class="t">还没有存单</div>
      <div class="d">添加一张存单，到期前会提醒你。</div>
    </div>
    <div v-else class="deposit-list">
      <div v-for="a in groups.deposits" :key="a.id" class="deposit-card" :class="{closed:a.deposit.closedAt}" @click="openAccount(a)">
        <div class="deposit-head">
          <div class="deposit-title">
            <span class="asset-icon" :style="{color:iconColor('deposit')}"><span class="asset-icon-inner" v-html="icon('deposit',24)"></span></span>
            <div>
              <div class="asset-name">{{a.name}}</div>
              <div class="asset-sub">{{a.institution}} · {{fmtRate(a.deposit.rateBp)}} · {{termLabel(a.deposit.termMonths)}}</div>
            </div>
          </div>
          <span class="chip" :class="statusCls(a)" style="pointer-events:none">{{depositStatus(a).label}}</span>
        </div>
        <div class="deposit-main">
          <div>
            <div class="caption" style="color:var(--color-text-secondary)">本金</div>
            <div class="amount amount-md">{{fmt(a.deposit.principal)}}</div>
          </div>
          <div style="text-align:right">
            <div class="caption" style="color:var(--color-text-secondary)">预计利息</div>
            <div class="amount amount-md amount--income">{{fmt(expectedInterest(a))}}</div>
          </div>
        </div>
        <div class="deposit-foot">
          <span>{{a.deposit.startAt}} → {{a.deposit.maturityAt}}</span>
          <span v-if="!a.deposit.closedAt">{{daysToMaturity(a) >= 0 ? '剩余 '+daysToMaturity(a)+' 天' : '已到期'}}</span>
          <span v-else>{{a.deposit.closeType==='renew'?'已转存':'已支取'}}</span>
        </div>
        <div class="progress-track" v-if="!a.deposit.closedAt">
          <div class="progress-fill progress-fill--asset" :style="{width:depositProgress(a)+'%'}"></div>
        </div>
      </div>
    </div>

    <template v-if="groups.credit.length">
      <div class="section-gap"></div>
      <div class="section-title">信用卡</div>
      <div class="menu">
        <div class="item" v-for="a in groups.credit" :key="a.id" @click="openAccount(a)">
          <span class="mi" :style="{color:iconColor('credit')}" v-html="icon('credit',24)"></span>
          <div class="asset-main">
            <div class="mt">{{a.name}}</div>
            <div class="asset-sub">{{accountSubtitle(a)}}</div>
          </div>
          <div class="asset-amount amount--liability">{{fmtSigned(a.balance)}}</div>
          <span v-html="icon('chevron',18)"></span>
        </div>
      </div>
    </template>

    <template v-if="groups.loans.length">
      <div class="section-gap"></div>
      <div class="section-title">贷款</div>
      <div class="menu">
        <div class="item" v-for="a in groups.loans" :key="a.id" @click="openAccount(a)">
          <span class="mi" :style="{color:iconColor(a.icon)}" v-html="icon(a.icon,24)"></span>
          <div class="asset-main">
            <div class="mt">{{a.name}}</div>
            <div class="asset-sub">{{accountSubtitle(a)}}</div>
          </div>
          <div class="asset-amount amount--liability">{{fmtSigned(a.balance)}}</div>
          <span v-html="icon('chevron',18)"></span>
        </div>
      </div>
    </template>

    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { accounts, store, icon, iconColor, fmt, fmtSigned, fmtRate, accountSubtitle, depositStatus, expectedInterest, daysToMaturity, depositProgress, termLabel, openSheet } from '../store.js'

export default {
  name: 'AssetsPage',
  setup(){ return { store, icon, iconColor, fmt, fmtSigned, fmtRate, accountSubtitle, depositStatus, expectedInterest, daysToMaturity, depositProgress, termLabel, openSheet } },
  computed: {
    groups(){
      return {
        accounts: accounts.filter(a => ['cash','bank','ewallet'].includes(a.type)),
        stored: accounts.filter(a => a.type === 'stored'),
        deposits: accounts.filter(a => a.type === 'deposit'),
        credit: accounts.filter(a => a.type === 'credit'),
        loans: accounts.filter(a => a.type === 'loan')
      }
    }
  },
  methods: {
    openAccount(a){
      if(a.type === 'deposit'){ store.depositId = a.id; openSheet('存单详情') }
      else if(a.type === 'loan'){ store.loanId = a.id; openSheet('贷款详情') }
      else { store.cardId = a.id; openSheet('卡片详情') }
    },
    statusCls(a){
      const s = depositStatus(a)
      if(s.key === 'matured') return 'chip--warn'
      if(s.key === 'due') return 'chip--due'
      if(s.key === 'closed') return 'chip--muted'
      return 'chip--asset'
    }
  }
}
</script>
