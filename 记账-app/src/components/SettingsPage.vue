<template>
  <div class="page">
  <header class="app-header">
    <button class="icon-btn" @click="backToTab" aria-label="返回"><span v-html="icon('back',22)"></span></button>
    <div class="title h1">设置</div>
  </header>
  <div class="app-content">
    <div class="section-title">WebDAV 备份</div>
    <div class="card">
      <div class="field-label" style="margin-top:0">服务器地址</div>
      <input class="ledger-input" v-model.trim="settingsData.webdavUrl" type="url" inputmode="url" placeholder="https://dav.example.com" />
      <div class="field-label">用户名</div>
      <input class="ledger-input" v-model.trim="settingsData.webdavUser" type="text" placeholder="user@example.com" />
      <div class="field-label">密码（应用密码）</div>
      <div class="pass-wrap">
        <input class="ledger-input" v-model="settingsData.webdavPass" :type="showPass?'text':'password'" placeholder="应用密码" style="padding-right:44px" />
        <button class="pass-toggle" @click="showPass=!showPass" :aria-label="showPass?'隐藏密码':'显示密码'" v-html="icon('eye',18)"></button>
      </div>
      <div class="field-label">备份目录</div>
      <input class="ledger-input" v-model.trim="settingsData.webdavDir" type="text" placeholder="/记账备份/" />
      <div class="btn-row" style="margin-top:var(--space-4)">
        <button class="btn btn-ghost" :disabled="testing" @click="testConnection">{{testing?'连接中…':'保存并测试连接'}}</button>
      </div>
      <div class="status-line">
        <span class="status-dot" :class="{off:!settingsData.connected}"></span>
        {{settingsData.connected?'已连接 · 配置校验通过':'未连接 · 请检查配置'}}
      </div>
      <div class="setting-hint" style="margin-top:var(--space-2)">密码仅保存在系统 Keystore，不随备份导出。</div>
    </div>

    <div class="section-gap"></div>
    <div class="section-title">备份与恢复</div>
    <div class="card">
      <div class="setting-row">
        <span class="setting-label">上次备份</span>
        <span class="setting-value">{{settingsData.lastBackup}}</span>
      </div>
      <div class="setting-row">
        <div>
          <div class="setting-label">自动备份</div>
          <div class="setting-hint">启动时距上次备份超过 24 小时自动执行</div>
        </div>
        <div class="toggle" :class="{on:settingsData.autoBackup}" @click="settingsData.autoBackup=!settingsData.autoBackup"></div>
      </div>
      <div class="btn-row" style="margin-top:var(--space-4)">
        <button class="btn btn-primary" :disabled="busy" @click="backupNow">{{busy?'备份中…':'立即备份'}}</button>
        <button class="btn btn-ghost" @click="openSheet('备份')">恢复备份</button>
      </div>
      <div class="setting-hint" style="margin-top:var(--space-3)">备份为 zip（数据库 + 图片），服务器仅保留最近 5 份；恢复前会自动备份当前库。</div>
    </div>

    <div class="section-gap"></div>
    <div class="section-title">删除默认行为</div>
    <div class="card">
      <div class="setting-item">
        <div class="setting-head"><span class="setting-label">删除类别</span><span class="setting-hint">保留流水则归【其他】</span></div>
        <div class="segmented segmented--full">
          <button :class="{active:settingsData.delCategory==='keep'}" @click="settingsData.delCategory='keep'">保留（默认）</button>
          <button :class="{active:settingsData.delCategory==='delete'}" @click="settingsData.delCategory='delete'">删除流水</button>
        </div>
      </div>
      <div class="setting-item">
        <div class="setting-head"><span class="setting-label">删除储值卡</span><span class="setting-hint">充值支出默认保留</span></div>
        <div class="segmented segmented--full">
          <button :class="{active:settingsData.delCard==='keep'}" @click="settingsData.delCard='keep'">保留（默认）</button>
          <button :class="{active:settingsData.delCard==='delete'}" @click="settingsData.delCard='delete'">删除流水</button>
        </div>
      </div>
      <div class="setting-item">
        <div class="setting-head"><span class="setting-label">删除周期支出</span><span class="setting-hint">还款流水默认保留</span></div>
        <div class="segmented segmented--full">
          <button :class="{active:settingsData.delPeriod==='keep'}" @click="settingsData.delPeriod='keep'">保留（默认）</button>
          <button :class="{active:settingsData.delPeriod==='delete'}" @click="settingsData.delPeriod='delete'">删除流水</button>
        </div>
      </div>
      <div class="setting-hint" style="margin-top:var(--space-3)">这里只设置默认选项，每次删除仍会二次确认。</div>
    </div>

    <div class="section-gap"></div>
    <div class="section-title">关于</div>
    <div class="card">
      <div class="setting-row"><span class="setting-label">版本</span><span class="setting-value">1.0.0 · v15 原型</span></div>
      <div class="setting-row"><span class="setting-label">数据存储</span><span class="setting-value">本机 SQLite</span></div>
      <div class="setting-row"><span class="setting-label">备份格式</span><span class="setting-value">zip（db + images）</span></div>
    </div>
    <div class="section-gap"></div>
  </div>
  </div>
</template>

<script>
import { settingsData, icon, backToTab, showToast, openSheet } from '../store.js'

/* 设置页：WebDAV 配置 + 手动/自动备份 + 恢复入口 + 删除默认行为（批次9 原型） */
export default {
  name: 'SettingsPage',
  setup(){ return { settingsData, icon, backToTab, showToast, openSheet } },
  data(){ return { showPass:false, testing:false, busy:false, seq:0 } },
  methods: {
    testConnection(){
      if(this.testing) return
      const url = (settingsData.webdavUrl || '').trim()
      const user = (settingsData.webdavUser || '').trim()
      const pass = settingsData.webdavPass || ''
      if(!url || !user || !pass){ settingsData.connected = false; showToast('连接失败：请填写完整配置'); return }
      if(!/^https?:\/\//i.test(url)){ settingsData.connected = false; showToast('连接失败：地址需以 http(s):// 开头'); return }
      this.testing = true
      const self = this
      setTimeout(function(){
        self.testing = false
        settingsData.connected = true
        showToast('连接成功')
      }, 600)
    },
    backupNow(){
      if(this.busy) return
      this.busy = true
      const self = this
      setTimeout(function(){
        self.seq++
        const mm = String(20 + self.seq).padStart(2, '0')
        const at = '2026-06-22 10:' + mm
        backupsData.unshift({ name:'backup_20260622_10' + mm + '00.zip', at:at, size:'2.4 MB' })
        if(backupsData.length > 5) backupsData.splice(5)
        settingsData.lastBackup = at
        self.busy = false
        showToast('备份成功')
      }, 700)
    }
  }
}
</script>
