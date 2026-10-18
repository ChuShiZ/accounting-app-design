# 设计-WebDAV同步

> 状态：定稿 ｜ 版本：v15 ｜ 关联：D5

## 定位

1 台设备 + WebDAV 仅作**换机备份/防丢安全网**。备份式：数据库文件即真相，无行级同步、无冲突处理。

## 备份内容

```
backup_YYYYMMDD_HHMMSS.zip
├─ jizhang.sqlite      # drift SQLite（先 checkpoint 再拷贝）
├─ manifest.json
└─ receipts/           # 可选：记账图片目录，默认不打包
```

- **db 一致性**：备份前执行 `PRAGMA wal_checkpoint(TRUNCATE)`
- 图片为可选项，默认关闭以节省坚果云上传流量；开启后才打包 `receipts/`
- 暂不加密（自用 + 凭据已安全存储）

## 保留策略

- 服务器上**保留最近 5 份**：上传新备份成功后，列出同目录 `backup_*.zip`，删除最早的超出份数
- 防占满 WebDAV 空间（坚果云等有上传流量限制）

## 完整性校验

- 上传前：manifest 记录格式与创建时间；恢复时校验 zip CRC、SQLite 文件头，失败不触碰本地数据

## 恢复流程（有保护）

```
确认 → 下载目标备份 → 校验 → 写入待恢复 zip
    → 下次启动 App 时（数据库打开前）备份当前库 → 替换 db 与 receipts → 启动
```

- 恢复前自动备份当前库为 `jizhang.before-restore.sqlite`，防止"恢复后想回退"
- 恢复在下次启动时生效，避免运行中替换 SQLite 文件
- 备份未包含图片时，恢复保留本地现有 `receipts/`

## 凭据与配置

- 存储：`flutter_secure_storage`（Android Keystore 加密），**不用** SharedPreferences
- 配置项（设置页）：服务器地址 / 用户名 / 密码（应用密码）/ 备份目录（默认 `记账备份`，不写根目录）
- 配置保存时立即 `PROPFIND` 测通，失败提示不改配置

## 触发时机

- 手动：设置页"立即备份" / "恢复备份"
- 自动：App 启动或回到前台时检查距上次备份是否超过间隔（24h/3天/7天，默认 3 天），满足且已保存凭据则静默备份；失败跳过，下次再试（不做 WorkManager 常驻任务）
- 不做逐操作同步；记账/账户操作只写本地 SQLite
