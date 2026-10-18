<template>
  <div class="sheet sheet--bottom">
    <div class="sheet-handle"></div>
    <div class="sheet-head"><div class="h1">备份与恢复</div>
      <button class="icon-btn" @click="closeSheet" aria-label="关闭"><span v-html="icon('close',20)"></span></button>
    </div>
    <div class="sheet-body">
      <div class="caption" style="color:var(--color-text-secondary);margin-bottom:var(--space-3)">服务器上的备份（保留最近 5 份）</div>
      <div v-for="(b,i) in backupsData" :key="b.name" class="backup-item" :class="{active:sel===i}" @click="sel=i">
        <span class="backup-radio" v-html="sel===i?icon('check',14):''"></span>
        <div class="backup-main">
          <div class="backup-name">{{b.name}}</div>
          <div class="backup-sub">{{b.at}} · {{b.size}}</div>
        </div>
      </div>
      <div class="backup-hint">恢复会覆盖当前数据；恢复前会自动备份当前库。备份损坏时不会触碰本地数据。</div>
    </div>
    <div class="sheet-foot">
      <button class="btn btn-secondary" @click="closeSheet">取消</button>
      <button class="btn btn-primary" :disabled="!backupsData.length || sel<0" @click="restore">恢复选中备份</button>
    </div>
  </div>
</template>

<script>
import { backupsData, icon, closeSheet, showToast, askConfirm } from '../store.js'

/* 备份恢复 Sheet：选择服务器备份 + 二次确认（设置页二级交互） */
export default {
  name: 'BackupSheet',
  setup(){ return { backupsData, icon, closeSheet, showToast } },
  data(){ return { sel: 0 } },
  methods: {
    restore(){
      const b = backupsData[this.sel]
      if(!b) return
      askConfirm('将用「' + b.at + '」的备份覆盖当前数据，恢复前会自动备份当前库。', function(){
        closeSheet()
        showToast('恢复成功')
      }, { title:'确认恢复', confirmText:'恢复' })
    }
  }
}
</script>
