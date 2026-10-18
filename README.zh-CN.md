# Locus

Locus 是一款免费、开源的 iPhone 模拟定位应用。你可以在地图上选点、搜索地点或规划路线。Locus 通过 Apple 的**开发者定位模拟服务**向 `locationd` 注入坐标，让地图和其他应用读取模拟位置，而不是只修改可能被 GPS 覆盖的 Wi‑Fi 定位结果。

[English](README.md)

<p align="center">
  <img src="docs/screenshots/map.png" alt="Locus 地图与标记" width="180" />
  <img src="docs/screenshots/spoofing.png" alt="Locus 模拟定位" width="180" />
  <img src="docs/screenshots/joystick.png" alt="Locus 摇杆" width="180" />
  <img src="docs/screenshots/route.png" alt="Locus 路线" width="180" />
</p>

## 功能

- 一键定位到地图标记或搜索结果
- 实时摇杆移动：步行、跑步、骑行或驾车，并带有轻微速度变化
- 使用 MapKit 规划步行或驾车路线
- 绘制路线，或导入、导出 GPX 文件
- 后台保活、实时状态显示和定位中断提醒
- 收藏和最近位置；地图上的手动标记也可以命名并收藏
- 英文和简体中文界面
- 可选坐标转换，在发送定位前转换坐标
- 首次使用引导
- 所有数据均保留在设备上；不含分析功能，也不会上传数据

## 安装与首次使用

从 [GitHub Releases](https://github.com/ChrisMack32/Locus/releases) 下载 IPA，并使用 Feather、SideStore、AltStore、Sideloadly 或 LiveContainer 等侧载工具安装。也可以按下文从源码构建。

应用 Bundle ID：`com.chrismack.locus`

### 配对 iPhone

RPPairing 文件是 Locus 连接 iPhone 开发者定位服务所需的配对凭据，不是定位数据。通常只需导入一次，请妥善保管，不要公开分享。

- **iOS 27：**打开 Locus 的“设置 → 在此 iPhone 上配对 → 开始配对”，允许所需权限；然后前往 iPhone“设置 → 隐私与安全性 → 开发者模式 → 与主机配对”，选择 Locus 并按提示输入设备密码和 Locus 显示的六位验证码。配对完成后，文件会保存在设备上，无需电脑。
- **iOS 18–26：**在电脑上使用 [idevice_pair](https://github.com/jkcoxson/idevice_pair/releases) 生成 RPPairing 文件。连接并信任 iPhone 后，将文件通过 AirDrop 或分享菜单打开到 Locus，再导入；也可以在 Locus 中从剪贴板粘贴文件内容。请导入 **RPPairing** 文件，不要使用 lockdown 或 SideStore 的 `.mobiledevicepairing` 文件代替。

### 连接隧道并开始定位

安装并连接 [LocalDevVPN](https://apps.apple.com/us/app/localdevvpn/id6755608044)，默认隧道 IP 为 `10.7.0.1`。首次启动模拟定位时请连接 Wi‑Fi；启动后可以切换到蜂窝网络继续使用。

在地图上点选位置，然后点击“模拟定位”。也可以先搜索地点。模拟定位启动后可使用摇杆、路线和 GPX 功能。

### LiveContainer 文件选择器

如果 LiveContainer 中的文件选择器无法正常工作，可以在 LiveContainer 中长按 Locus，打开设置并启用 **Fix File Picker**；也可以通过 iOS 分享菜单将配对文件直接交给 LiveContainer 中的 Locus，或复制 plist 完整内容后在 Locus 的设置或首次设置页面粘贴。

## 语言

Locus 支持英文和简体中文，**应用内目前没有语言切换按钮**。界面语言跟随 iOS 的首选语言。要使用简体中文，请前往 iPhone“设置 → 通用 → 语言与地区”，添加“简体中文”并将其设为首选语言。若 iOS 为 Locus 提供单独的语言设置，也可以在系统设置中单独选择。

## 地图标记与收藏

点击地图可放置标记。选中标记后，点击“收藏此位置”并确认名称；也可以使用地图上方的星形按钮。名称留空时会以坐标作为名称。收藏会保存在“地点”中，重启应用后仍可使用。搜索地点仍会自动保存搜索结果。

## 中国大陆坐标转换

在 **设置 → 坐标转换** 中选择转换方式。默认是“关闭”，因此安装后需要按坐标来源和接收定位的应用主动选择；开始模拟定位后需先停止，才能更改该选项。

- **GCJ-02 → WGS-84：**当输入地图标记使用 GCJ-02，而定位服务需要 WGS-84 时使用。中国大陆地图标记与系统定位之间若相差数百米，可以先尝试此项；Locus 在一个实际大陆使用场景中已验证此设置可消除偏移。
- **WGS-84 → GCJ-02：**输入坐标为 WGS-84，而接收方需要 GCJ-02 时使用。
- **WGS-84 → BD-09：**输入坐标为 WGS-84，而接收方使用百度 BD-09 坐标时使用。
- **关闭：**不改变输入坐标。

请根据**坐标来源和接收方**选择方向，不能只根据界面语言或所在地区判断。选错方向可能让偏移变得更大。坐标转换只发生在发送定位时；地图标记、收藏、最近位置和 GPX 文件会保留原坐标。转换算法离线运行，使用经纬度范围粗略判断中国大陆区域，不是精确国界，也不会自动识别地图提供方的坐标系。边境区域及其他地区建议关闭转换。有关不同坐标类型的说明可参阅[百度地图坐标系文档](https://lbsyun.baidu.com/docs/webapi?title=mapadjustment%2Furi%2Fweb)。

转换会应用于 Teleport、路线、摇杆更新和定时重发。单元算法检查可在 macOS 上运行：

```sh
xcrun swiftc -module-cache-path /tmp/locus-swift-module-cache \
  Locus/Engine/CoordinateTransform.swift Tests/CoordinateTransformChecks.swift \
  -o /tmp/locus-coordinate-checks
/tmp/locus-coordinate-checks
```

## 工作原理

Locus 使用 MIT 许可的 [idevice](https://github.com/jkcoxson/idevice) FFI，通过设备上的开发者隧道与 Apple DVT 定位模拟服务通信。这与 Xcode 使用的定位模拟机制属于同一类方式。

## 从源码构建

从源码构建需要 Apple Developer 账号（免费或付费均可）用于代码签名。下载发布版 IPA 后，可以通过侧载工具完成安装。

1. 如尚未安装 XcodeGen，可运行 `brew install xcodegen`。
2. 在 `project.yml` 中设置开发者 **Team ID**（`DEVELOPMENT_TEAM`），或生成工程后在 Xcode 的“Signing & Capabilities”中选择团队。
3. 生成并打开 Xcode 工程：

```sh
xcodegen generate
open Locus.xcodeproj
```

也可以在命令行构建（将 `YOUR_TEAM_ID` 替换为 Apple Developer 账号 Membership 页面显示的 Team ID）：

```sh
xcodegen generate
xcodebuild -project Locus.xcodeproj -scheme Locus -configuration Release \
  -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=YOUR_TEAM_ID build
```

构建成功不代表真机配对或定位隧道已验证。真机使用还需要导入配对凭据并连接 LocalDevVPN。

## 许可证

Locus 使用 MIT 许可证。[Vendor/idevice](Vendor/idevice) 中包含 MIT 许可的 idevice FFI。Locus 是独立开源项目，与 Mirage / Wapixel 无隶属关系。
