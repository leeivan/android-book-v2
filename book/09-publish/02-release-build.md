# Release 构建

很多项目在开发期运行得很好，真正切到 `release` 之后才开始暴露问题：调试入口没关、日志还在输出敏感信息、资源收缩后页面空白、反射代码被 R8 改写后崩溃、正式环境地址和测试配置混在一起。造成这些问题的根本原因，通常不是 Gradle 不会写，而是团队从一开始就没有把 release 当成“交给真实用户的正式产物”，而只是把它当成 debug 的导出形态。

从工程视角看，release 构建不是单个开关，而是一整条正式产物生成链：签名、压缩、混淆、资源收缩、日志策略、候选验证、线上定位材料，都在这里汇合。只要这条链里有任何一环仍然沿用调试期心态，应用一旦进入真实用户环境，就会暴露出之前被 IDE 和本地调试掩盖的问题。

这一章会把 release 放回“正式交付”语境里理解。重点不是记住几个 DSL 字段，而是建立三个判断：为什么 release 必须独立验证、为什么 AAB 与 APK 的角色不同、为什么映射文件、候选版本和线上监控应该在发布前就准备好，而不是等用户报错后再回头补。

## 学习目标

- 理解 release 是独立的构建目标，而不是 debug 的附属产物。
- 理解 AAB、APK、混淆、资源收缩和签名在 release 中各自扮演什么角色。
- 学会为 release 建立最小可执行的构建配置和验证清单。
- 理解为什么候选版本、映射文件和线上监控要在正式发布前准备好。

## 前置知识

- 已理解应用签名、构建变体和 Google Play 分发流程。
- 已接触日志、崩溃监控和基础 CI 流程。

## 正文

### 1. release 和 debug 面向的是两种完全不同的使用者

debug 面向开发者，所以它优先保证可调试、可观察、可快速迭代。release 面向用户，所以它优先保证稳定、精简、安全、可持续分发。只要视角切换到用户，你就会发现很多开发期看起来“问题不大”的东西，在 release 中都必须重新判断：是否还允许调试菜单存在，是否还需要详细日志，是否还应该保留测试服务器地址，是否还能容忍手动开关和假数据入口残留。

也正因为如此，debug 能跑从来不等于 release 就安全。正式构建的质量门槛更高，排障条件却更差。你拿不到像本地一样完整的实时调试能力，所以必须提前把 release 独有风险尽量压平，并为问题追踪保留最基本的材料。

### 2. 先分清楚 AAB 和 APK 的角色

截至 2026 年 3 月，Google Play 对新应用的发布主格式仍然是 Android App Bundle（AAB）。这条主线自 2021 年 8 月起就已经生效，并且今天仍然是正式分发的默认路径。AAB 不是直接安装到用户设备上的最终文件，而是提交给 Google Play 的发布产物，Play 会基于它为不同设备生成更合适的 APK 组合。

这意味着两件事。第一，准备 Google Play 发布时，主线产物通常应是 AAB。第二，如果你要在本地设备上直接安装测试，往往还需要生成签名 APK，或借助 Android Studio / `bundletool` 从 bundle 派生可安装 APK。把这条边界分清楚，可以避免很多“为什么 bundle 不能像 APK 一样直接装”的困惑。

### 3. release 构建配置要明确表达正式产物意图

一个最小可维护的 release 配置，至少应该表达三件事：它使用正式签名，它关闭调试相关能力，它开启面向正式发布的压缩与优化。下面是一个精简但实用的 Kotlin DSL 示例：

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH"))
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

这段配置真正重要的，不是字段名本身，而是它表达的工程边界。签名信息来自受控输入而不是硬编码；release 明确关闭可调试性；R8 和资源收缩被纳入正式产物生成过程；项目也因此必须对反射、序列化、依赖注入和动态资源访问做 release 条件下的真实验证。

### 4. 构建命令只是起点，候选验证才是正式开始

当配置准备好之后，最常见的命令通常是：

```bash
./gradlew bundleRelease
```

如果你需要用于本地安装或渠道分发的签名 APK，则通常还会补充：

```bash
./gradlew assembleRelease
```

但真正容易出错的地方不是命令，而是团队往往在打出产物后就默认“可以发了”。更成熟的做法应该是把这一步视为候选版本生成，而不是正式发布完成。产物出来以后，要在真机上按关键路径做最小验证：登录、首页加载、深链接、通知跳转、上传、缓存、崩溃上报、退出重进、升级安装，这些路径往往比“把每个页面点开看一眼”更有价值。

### 5. 混淆和资源收缩不是单纯瘦身，而是运行环境变化

初学者很容易把 `isMinifyEnabled` 和 `isShrinkResources` 理解成“让包小一点”。它们当然有减包体的作用，但更本质的影响是：它们改变了运行环境。类名、方法名、资源保留状态和可达路径都会变化，因此反射、序列化、动态加载、WebView 桥接、三方 SDK 配置都可能因此受影响。

这也是为什么正式项目里 `proguard-rules.pro` 不是“有空再补的兼容文件”，而是 release 质量的一部分。任何依赖反射或运行时查找的地方，都应该在 release 条件下实际跑过，而不是只在 debug 下“感觉没问题”。

### 6. 映射文件和符号材料，是 release 排障的最低保障

一旦 release 出问题，你不一定还能拿到和 debug 一样完整的上下文。因此正式构建至少要保留两类材料。第一类是构建身份信息，例如版本号、构建时间、commit 对应关系。第二类是还原材料，例如 R8 生成的 mapping 文件，以及需要时的 native symbol。

Android 官方文档把这些材料视为线上排障的重要部分。原因很实际：没有 mapping 文件，混淆后的堆栈很难读；没有版本与构建对应关系，崩溃报告也很难落回到具体代码状态。很多团队的问题不是“不会上报崩溃”，而是上报回来后并没有足够材料解释崩溃。

### 7. release 验证要围绕关键路径，而不是围绕页面数量

更有效的 release 验证，不是“把每个页面点开一遍”，而是先找应用真正的关键路径。对新闻应用来说，关键路径可能是启动、列表加载、详情页、收藏和离线缓存；对聊天应用来说，是会话列表、发消息、通知跳转和媒体发送；对待办应用来说，是新建、编辑、完成、提醒和通知回跳。

只要关键路径在正式构建下是稳定的，大多数用户最容易感知的风险就已经被覆盖。反过来，如果只做页面清点式测试，很多只会在正式构建和真实环境里暴露的问题反而会漏掉。

### 8. 一个更稳妥的最小发布清单

在第一次正式发版前，可以把 release 清单压缩成下面几个核心问题：

- 当前构建是否使用正式签名与正式环境配置。
- release 是否关闭调试入口、宽松日志和测试开关。
- 关键路径是否在真机和 release 条件下验证通过。
- 当前版本是否保留了 mapping 文件和构建身份记录。
- 崩溃、ANR 和基础指标是否有上线后可用的回看入口。

这份清单的意义不在于“把文档写漂亮”，而在于确保 release 不再是“导一个包试试看”，而是开始拥有真正可复现、可验证、可追踪的工程闭环。

### 9. 实践任务

起点条件：

- 已有稳定运行的 debug 构建，并准备生成第一个候选 release。

步骤：

1. 检查项目中的 release `buildType` 是否已经独立表达签名、压缩、资源收缩和日志边界。
2. 通过 `bundleRelease` 生成候选 AAB；如需本地安装，再通过 `assembleRelease` 生成签名 APK。
3. 为当前应用写一份关键路径清单，并在真机上完成一次 release 验证。
4. 保存本次构建对应的版本号、mapping 文件和构建时间。
5. 记录 release 独有问题，并反推需要补充的规则或 keep 配置。

预期结果：

- 你会把 release 当成独立的正式产物，而不是 debug 的导出模式。
- 你能清楚区分 AAB 和 APK 在发布链路中的角色。
- 你会为线上问题预先准备最低限度的定位材料。

自检方式：

- 你能解释为什么 debug 能跑不代表 release 安全。
- 你能说明 `bundleRelease` 和 `assembleRelease` 分别更适合什么场景。
- 你能回答“当前版本出线上崩溃时，团队靠什么把堆栈还原回来”。

调试提示：

- release 一开混淆就出问题，优先检查反射、序列化和动态资源访问。
- 只有本地 debug 验证，没有候选 release 验证，说明发布链路还太粗。
- 没有保存 mapping 文件，就等于主动放弃了重要的排障线索。

### 10. 常见误区

- 把 release 理解成 debug 的导出模式。
- 以为开启压缩和混淆只是为了减包体。
- 不保留 mapping 文件和构建身份信息。
- 第一次看到 release 真正行为时，场景已经是正式用户环境。

## 小结

Release 构建真正代表的是“准备交给真实用户的正式产物”。只要把它当成独立的工程目标，你就会自然开始重视签名输入方式、AAB 与 APK 的角色、混淆与资源收缩的边界、候选版本验证以及线上问题的还原材料。

下一章进入 Google Play 上架时，这条链路会继续往前延伸：产物本身准备好了，还要确认它能否进入平台分发体系、测试轨道和正式放量流程。

## 练习题

1. 概念理解题：为什么 `bundleRelease` 生成的 AAB 不能简单等同于“用户手机上安装的最终文件”？
2. 编码实现题：为当前项目补齐一个最小可用的 release `buildType`，并通过环境变量注入签名信息。
3. 拓展思考题：如果某个问题只会在 release 构建下出现，你会优先从哪些配置或运行时边界开始排查？

## 参考资料

- 参考并改写自本地 PDF：Neil Smyth，《Android Studio Narwhal Essentials: Java Edition》(2025)，release 构建、AAB / APK、发布准备与 Play 交付相关章节。
- 参考并整理自本地 EPUB：`Android Security - Attacks and Defenses`，正式构建中的日志、凭证与暴露面控制相关内容。
- Build for release: <https://developer.android.com/build/build-for-release>
- Shrink, obfuscate, and optimize your app: <https://developer.android.com/build/shrink-code>
- App Bundle support FAQ: <https://developer.android.com/guide/app-bundle/faq>
