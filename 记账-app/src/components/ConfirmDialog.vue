<template>
  <div v-if="confirmState.show" class="confirm-mask" @click="cancel">
    <div class="confirm-dialog" @click.stop>
      <div class="confirm-title">确认删除</div>
      <div class="confirm-msg">{{confirmState.message}}</div>
      <div class="confirm-actions">
        <button class="btn btn-secondary" @click="cancel">取消</button>
        <button class="btn btn-primary confirm-btn" @click="ok">删除</button>
      </div>
    </div>
  </div>
</template>

<script>
import { confirmState, closeConfirm } from '../store.js'

/* 删除确认弹窗（全局，由 askConfirm 触发） */
export default {
  name: 'ConfirmDialog',
  setup(){ return { confirmState } },
  methods: {
    cancel(){ closeConfirm() },
    ok(){
      const cb = confirmState.onOk
      closeConfirm()
      if(cb) cb()
    }
  }
}
</script>
