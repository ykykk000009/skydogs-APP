# 接入与发布说明

## 1. 总体方案

### 客户端

- Flutter（Dart）
- 本地播放：`just_audio`
- 本地提醒：`flutter_local_notifications`
- 本地存储：`shared_preferences`
- 传感器追踪：`sensors_plus`

### 服务端

- 推荐默认方案：腾讯云 CloudBase / 自有云函数
- 数据模型：
  - 用户信息
  - 睡眠偏好
  - 睡眠会话记录
  - 冥想文本 / TTS 音频任务
  - 设备与同步状态

### 音频与语音

- 白噪音 / 自然音：
  - V1 推荐使用自有授权音效包或自建 CDN
  - 如果要接入第三方音乐平台，务必先确认版权、缓存、离线播放和商用条款
- 冥想语音：
  - 推荐由服务端代理百度 TTS 或讯飞 TTS
  - 客户端只接收可下载音频链接，再保存到本地缓存

## 2. 推荐的国内化技术路线

### 云同步

- 默认建议：腾讯云 CloudBase
- 理由：
  - 文档数据库、云函数、存储、鉴权一体化
  - 对移动端友好，适合快速上线 MVP
  - 更适合作为 TTS 代理层与同步层

### 睡眠数据

- 基础版：仅依赖手机加速度计，做轻量 movement score
- 进阶版：
  - Android 中国区可优先评估华为 Health Kit / Health Service Kit
  - iOS 通过 Apple HealthKit 读取睡眠数据

### 监控与分析

- Crash 监控：
  - 腾讯 Bugly
  - 或自有日志上报
- 用户行为分析：
  - 友盟+
  - 或 CloudBase / 自建埋点

## 3. 隐私与合规

### 必做原则

- 首次启动先展示隐私政策与用户协议概要
- 只在用户主动开启功能时申请相应权限
- 睡眠追踪、通知、健康数据、分析埋点分别独立授权
- 拒绝权限后不影响基础助眠播放
- 提供清晰的数据删除、退出登录、关闭同步入口

### 重点法规关注

- 《个人信息保护法》
- 《网络安全法》
- 《数据安全法》
- 各 Android 应用市场的隐私合规审查要求
- iOS App Store 的隐私营养标签与权限说明

### 建议的数据分类

- 必要数据：
  - 基础账户标识
  - 本地播放偏好
  - 用户主动保存的睡眠记录
- 可选数据：
  - 健康 SDK 睡眠数据
  - 设备传感器数据
  - 行为分析埋点

## 4. 原生配置待补充

### Android

- `POST_NOTIFICATIONS`
- `INTERNET`
- 如使用精确定时提醒，评估 `SCHEDULE_EXACT_ALARM`
- 按 `just_audio` 官方说明配置 `usesCleartextTraffic` 或仅对白名单 `localhost` 放行

### iOS

- `NSMotionUsageDescription`
- `NSUserTrackingUsageDescription`（若引入跨应用广告跟踪，助眠应用通常建议不做）
- 通知权限说明
- HealthKit 权限说明（若接入）

## 5. 环境变量建议

通过 `--dart-define` 注入：

```text
CLOUD_SYNC_ENDPOINT=
TTS_ENDPOINT=
ANALYTICS_ENDPOINT=
CRASH_ENDPOINT=
```

如果采用服务端代理百度/讯飞：

- 客户端不要存放供应商密钥
- 客户端只调用自有后端
- 后端统一鉴权、限流、审计与计费

## 6. 发布节奏建议

### MVP

- 一键播放
- 4 到 8 个内置音景
- 2 到 4 个冥想音频
- 睡前提醒
- 30 / 45 / 60 分钟睡眠定时器
- 简单睡眠会话记录

### V1.1

- 缓存下载管理
- 账号登录与云同步
- TTS 自定义冥想
- 行为埋点与崩溃监控

### V1.2

- Health Kit / HealthKit 数据同步
- 个性化推荐
- 睡眠周报
- 会员内容与精细化运营

## 7. 官方参考

- [腾讯云 CloudBase 产品概述](https://cloud.tencent.com/document/product/876/18431)
- [华为 Health Kit](https://developer.huawei.com/consumer/en/hms/huaweihealth/)
- [华为 Health Service Kit](https://developer.huawei.com/consumer/cn/sdk/health-service-kit/)
- [百度智能云语音技术文档](https://cloud.baidu.com/doc/SPEECH/TTS-API.html)
- [just_audio on pub.dev](https://pub.dev/packages/just_audio)
- [flutter_local_notifications on pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [sensors_plus on pub.dev](https://pub.dev/packages/sensors_plus)
