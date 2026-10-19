# VolumeHUD Expanded 0.1.0（测试版）

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
通过 sizeForState: 判断宽窄，记录首次按键路径的宽状态，仅在后续按键上下文把窄状态改回宽状态。
不猜测私有状态枚举；不锁定 frame；不阻止自动隐藏；不改控制中心亮度条。

**尚未在真实 17.2.1 设备验证。** 若该版本在不同调用路径触发收窄，此版可能不生效；需要日志确认后调整，不能保证一次成功。
没有提供 iSH 交叉编译 deb：先前该环境的伪 arm64e 切片导致过 SpringBoard 安全模式，此次避免重复风险。

## 诊断与回退

日志（Filza 查看）：`/var/mobile/Library/Accessibility/volumehudexpanded.log`
如无效果，提供日志和实际表现；正常命中应出现 `block compact`。
日志会记录状态切换，测试后建议卸载或升级关闭日志版本。
卸载 VolumeHUD Expanded 后注销即可还原。
若进入安全模式，在安全模式用 Sileo 移除本插件，再注销。
