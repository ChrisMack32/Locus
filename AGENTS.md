# Locus 代理开发指南

本文件适用于整个仓库。项目名称为 **Locus**：通过 idevice FFI 和设备开发者隧道调用 Apple 的定位模拟服务，界面使用 SwiftUI，地图与路线使用 MapKit。

## 开始工作

- 了解功能和构建流程时阅读 [README.md](README.md)；修改配对、首次设置或安装流程时，同时阅读 [SETUP.md](SETUP.md)。
- 先检查 `git status --short`，保留已有改动，让本次修改集中在用户要求的范围。
- 平台、部署版本、链接参数及签名配置以 `project.yml` 为准；当前仅有应用 target，没有自动化测试 target。

## 代码入口与职责

- `Locus/App/LocusApp.swift`：应用入口、共享状态注入、首次设置分流和外部文件打开。
- `Locus/Features/`：地图、摇杆、路线、设置与首次设置界面。视图通过共享状态调用业务逻辑。
- `Locus/Engine/SpoofSession.swift`：定位会话状态、移动控制、路线执行、保活及收藏与历史记录。
- `Locus/Engine/LocationEngine.swift`：定位模拟的 Swift / C FFI 边界，管理隧道及原生句柄。
- `Locus/Engine/PairingStore.swift`：配对文件导入与本地保存；`PairOnDeviceService.swift` 和 `PairableHostAdvertiser.swift` 实现设备内配对与服务广播。
- `Locus/Engine/RouteBuilder.swift`：路线采样及 GPX 编解码；`Locus/Support/` 放置主题、文件选择器与其他共享支持代码。
- `Locus/Resources/`：权限声明、entitlements 与资源；`Vendor/idevice/` 包含配套头文件、模块映射和预编译静态库。

## 修改约定

- 沿用现有 Swift 风格：四空格缩进，类型使用 UpperCamelCase，成员使用 lowerCamelCase。界面支持英文和简体中文；新增文案使用 `String(localized:)` 或 SwiftUI 本地化键，并同步维护 `Locus/Resources/en.lproj` 与 `zh-Hans.lproj`。
- 保持 `SpoofSession`、`PairingStore` 等可观察状态的 `@MainActor` 隔离；阻塞的配对工作放在后台执行，界面状态更新回到主 actor。
- 修改 `LocationEngine` 时保持原生操作的串行执行。逐一核对句柄和错误对象的所有权、释放及失败路径，特别注意创建模拟服务后的 remote server 所有权转移。
- 修改会话、路线或保活时，检查停止、取消、失败和重连路径中的计时器、任务及后台活动清理。
- 配对文件属于敏感数据：保持本地存储与受限文件权限，日志及仓库中不包含真实配对内容。导入外部文件时保留 security-scoped resource 的成对获取与释放。
- 修改配对导入时保留文件选择、分享打开和剪贴板入口；LiveContainer 的文件选择器兼容路径见 `SETUP.md`。
- 持久化键名沿用已有 `locus.*` 约定；变更现有键名或数据格式时处理已保存数据的兼容性。
- 依赖优先使用现有 Apple 框架。调整 idevice 接口前核对 `Vendor/idevice/idevice.h`，头文件、模块映射和静态库必须保持兼容。

## 工程配置与构建

工程配置修改先落到 `project.yml`，再在仓库根目录运行 `xcodegen generate`，检查并保留对应的 `Locus.xcodeproj` 变更。仅修改生成的工程文件会在下次生成时丢失。`AppIcon.icon` 作为完整资源包处理。

常规编译检查可使用不签名的 iOS 设备构建：

```sh
xcodebuild -project Locus.xcodeproj -scheme Locus -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath .DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

安装到真机的签名构建见 `README.md`，通过本地设置或命令行传入开发者 Team ID，保持仓库中的团队配置可供其他开发者使用。构建依赖完整 Xcode 和可用的 iOS SDK；若工具链或资源格式不兼容，记录具体错误。

## 验证与交付

- Swift 或工程配置变更后执行相关构建检查。纯文档修改检查内容、路径及差异即可。
- 当前没有可直接运行的自动化测试套件；不要将构建通过描述为功能测试通过。
- 涉及定位隧道、配对或后台行为时，需要按 `SETUP.md` 在真机验证。模拟器或不签名构建不能验证这些行为。
- 根据改动选择手动验证路径：首次设置与配对导入、Teleport 和停止、摇杆、路线及 GPX 导入导出、进入后台与恢复、隧道断开后的状态和重连。
- 交付前检查 `git diff --check` 和变更范围，说明修改结果、实际执行的验证及尚未验证的真机行为。
