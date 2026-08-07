<template>
  <div class="swipe" :class="{disabled, 'swipe--round':round}">
    <div v-if="!disabled" class="swipe-action" @click.stop="emitDelete"><span>删除</span></div>
    <div class="swipe-content" :style="contentStyle" @click.capture="onContentTap"
         @touchstart.passive="onStart" @touchmove.passive="onMove" @touchend="onEnd">
      <slot></slot>
    </div>
  </div>
</template>

<script>
/* 左滑删除组件：手指左滑露出"删除"按钮，点击触发 delete 事件；点击外部自动收起
   round=true 时（卡片场景）：外层 .swipe 圆角裁剪，消除渐变卡圆角缝隙 & 四角露红 */
export default {
  name: 'SwipeDelete',
  props: {
    disabled: { type: Boolean, default: false },   /* true 时禁止左滑（如默认账户卡） */
    round: { type: Boolean, default: false }        /* true 时卡片场景：外层圆角裁剪 */
  },
  emits: ['delete'],
  data(){ return { offset:0, base:0, startX:0, startY:0, open:false, moved:false, dragging:false, suppressClick:false, WIDTH:64 } },
  computed: {
    contentStyle(){
      return { transform:'translateX('+this.offset+'px)', transition:this.dragging?'none':'transform .2s ease' }
    }
  },
  watch: {
    open(v){
      if(v) document.addEventListener('click', this.onDocClick, true)
      else document.removeEventListener('click', this.onDocClick, true)
    }
  },
  beforeUnmount(){
    document.removeEventListener('click', this.onDocClick, true)
  },
  methods: {
    onStart(e){
      if(this.disabled) return
      this.dragging = false
      this.moved = false
      this.startX = e.touches[0].clientX
      this.startY = e.touches[0].clientY
      this.base = this.open ? -this.WIDTH : 0
      this.offset = this.base
    },
    onMove(e){
      if(this.disabled || !e.touches || !e.touches.length) return
      const dx = e.touches[0].clientX - this.startX
      const dy = e.touches[0].clientY - this.startY
      if(!this.dragging){
        if(Math.abs(dx) < 8 && Math.abs(dy) < 8) return
        if(Math.abs(dy) > Math.abs(dx)) return   /* 垂直滚动不处理 */
        this.dragging = true
      }
      if(Math.abs(dx) > 4) this.moved = true
      this.offset = Math.max(-this.WIDTH, Math.min(0, this.base + dx))
    },
    onEnd(){
      if(this.disabled) return
      this.dragging = false
      this.open = this.offset < -this.WIDTH/2
      this.offset = this.open ? -this.WIDTH : 0
      /* 若发生过滑动，标记下一次 click 由 touch 派生，需抑制（避免误收起/误触内容） */
      if(this.moved) this.suppressClick = true
    },
    onContentTap(e){
      /* 1) touch 派生出的 click：仅抑制（不触发内容、不收起左滑） */
      if(this.suppressClick){ this.suppressClick = false; e.preventDefault(); e.stopPropagation(); return }
      /* 2) 残留 moved 标志：抑制 */
      if(this.moved){ this.moved = false; e.preventDefault(); e.stopPropagation(); return }
      /* 3) 已处于左滑打开态：点击内容 = 收起左滑（不打开编辑） */
      if(this.open){ this.close(); e.preventDefault(); e.stopPropagation(); return }
    },
    onDocClick(e){
      if(!this.$el.contains(e.target)) this.close()
    },
    close(){
      this.open = false
      this.offset = 0
    },
    emitDelete(){ this.$emit('delete') }
  }
}
</script>
