# SkyDogs

`SkyDogs` 是一个面向国内市场的助眠 App Flutter 骨架，默认采用“本地优先、云同步可扩展”的实现方式，覆盖以下核心能力：

- 白噪音 / 自然音播放
- 睡前冥想音频
- 睡眠定时与睡前提醒
- 基于手机加速度计的浅睡眠追踪
- 用户自定义资源与缓存预留
- 云同步、Crash 监控、行为分析能力占位
- 隐私同步、权限最小化设计

## 当前完成度

- 完整 Flutter 业务代码骨架：主题、状态管理、音频、通知、追踪、同步等
- 暖色系首页与设置页，强调一键播放和低学习成本
- 本地数据持久化与云同步占位
- 百度 / 讯飞 TTS、腾讯 CloudBase、华为 Health Kit 的接入预留
- 国内合规说明文档

## 设计取舍

- 冥想内容支持两条路径：
  - 直接使用本地冥想音频
  - 通过服务端调用开源音频库，生成并缓存到本地离线播放
- 睡眠监测同步优先采用“手机加速度计 + 华为 Health Kit / Apple HealthKit 扩展”的方式。
- 云同步默认预留腾讯 CloudBase，可替换为云函数 / 云数据库方案。

## 目录结构

```text
lib/
  app/                 App 装配
  config/              环境配置
  data/                模型与示例数据
  repositories/        本地快照仓库
  services/            音频/缓存/通知/同步/追踪服务
  state/               ChangeNotifier 状态层
  theme/               颜色主题
  ui/                  界面
docs/
  integration_and_release.md
```

## 本地运行

当前仓库里已经写入完整 Flutter 应用代码。如果环境已安装 Flutter：

```bash
flutter pub get
flutter run
```

## 需要替换的真实资源

- `assets/audio/ambient/*.wav`
- `assets/audio/meditation/*.wav`
- App 图标、启动图
- 云同步与 TTS 接口地址

当前示例资源是占位音频，替换为真实音效后即可继续体验优化。

## 推荐的后续步骤

1. 增加 Apple HealthKit 与华为 Health Kit 原生桥接。
2. 接入 Bugly / 听云等国内监控服务。
3. 增加订阅、会员权益、离线缓存、AB 实验与灰度发布。
