<template>
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">添加</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="add-list">
        <button class="add-option" @click="choose('deposit')">
          <span class="add-ic" v-html="icon('deposit',22)"></span>
          <span class="add-main"><span class="add-title">添加存单</span><span class="add-sub">本金、利率、存期，到期提醒</span></span>
          <span v-html="icon('chevron',18)"></span>
        </button>
        <button class="add-option" @click="choose('bank')">
          <span class="add-ic" v-html="icon('bank',22)"></span>
          <span class="add-main"><span class="add-title">添加银行卡</span><span class="add-sub">名称、开户行、期初余额</span></span>
          <span v-html="icon('chevron',18)"></span>
        </button>
        <button class="add-option" @click="choose('stored')">
          <span class="add-ic" v-html="icon('cart',22)"></span>
          <span class="add-main"><span class="add-title">添加储值卡</span><span class="add-sub">商户、余额、默认消费类别</span></span>
          <span v-html="icon('chevron',18)"></span>
        </button>
        <button class="add-option" @click="choose('loan')">
          <span class="add-ic" v-html="icon('mortgage',22)"></span>
          <span class="add-main"><span class="add-title">添加贷款</span><span class="add-sub">本金、利率、期数、还款日</span></span>
          <span v-html="icon('chevron',18)"></span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { icon, closeSheet, openSheet, openAccountForm } from '../store.js'

export default {
  name: 'AddSheet',
  setup(){ return { icon, closeSheet, openSheet, openAccountForm } },
  methods: {
    choose(kind){
      closeSheet()
      if(kind === 'deposit') openSheet('添加存单')
      else openAccountForm(kind)
    }
  }
}
</script>
