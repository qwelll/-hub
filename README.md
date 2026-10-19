# VolumeHUD Expanded 0.1.2

作者 / 维护者：qwelll

目标：连续按音量键时保留首次出现的宽胶囊，不缩成细条；保留系统自动消失。
环境：iOS 17.2.1 / RootHide；只注入 SpringBoard。

## 编译安装

请使用你之前能正常编译 SpringBoard 插件的 **RootHide Theos + Apple arm64e 工具链**。

```sh
cd VolumeHUDExpanded
make clean
make package FINALPACKAGE=1
```

在 packages/ 找到 deb，用 Sileo 安装，再注销（Respring）。无需卸载现有外观插件。
这是 RootHide scheme 工程，不是普通 rootless 工程；如果提示不支持 roothide scheme，需换用已配置好的 RootHide Theos，不要简单改成 rootless。

## 验证

1. 首次按音量键，应显示宽胶囊。
2. 连续按音量加/减，观察是否一直保持宽形态，音量是否正常变化。
3. 停止按键，确认 HUD 正常消失。
4. 测试长按、锁屏、横屏、耳机，以及与现有音量外观插件共用时的表现。

## 设计与限制

依据 iOS 17 头文件，挂钩 SBElasticValueViewController 的
transitionStateContextuallyForValueChangeEvent 和 transitionToState:animated:completion:。
通过 sizeForState: 判断宽窄，记录首次展示的宽状态，仅在后续按键上下文把窄状态改回宽状态。
不猜测私有状态枚举；不锁定 frame；不阻止自动隐藏；不改控制中心亮度条。

0.1.1 核心逻辑已由用户在 iOS 17.2.1 / RootHide 确认可用。
0.1.2 保留该逻辑，删除所有日志写入和诊断字符串，并减少隐藏状态及无关转换的尺寸查询；更新后仍建议检查连续按键与自动隐藏。
通过 GitHub Actions / macOS / RootHide Theos 编译真正 arm64 + arm64e 双切片。

## 更新与回退

安装新 deb 覆盖升级，再注销。不需要设置，无后台轮询或定时器。
新版不再创建或写入日志。旧日志不会自动删除，可自行在 Filza 删除：
`/var/mobile/Library/Accessibility/volumehudexpanded.log`
卸载 VolumeHUD Expanded 后注销即可还原。
若进入安全模式，在安全模式用 Sileo 移除本插件，再注销。
