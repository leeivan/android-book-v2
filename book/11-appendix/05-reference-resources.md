# 参考资源

学习 Android 最大的难点之一，不是资源太少，而是资源太多且质量参差不齐。教程、视频、博客、短帖和碎片化问答会不断提供各种“能跑的做法”，但真正值得长期依赖的资料，必须同时满足三个条件：权威、可追溯、足够贴近当前平台。附录的这份资源清单，不是为了越多越好，而是帮助你建立一个更可靠的学习与查阅路线。

本书整体技术主线虽然以 Android 官方资料为基础，但如果长期只看 API 文档，内容很容易变成“说明书口吻”。更适合教材化学习的做法，是把规则类资料、路径化课程、示例项目、语言文档和高质量一手库文档组合起来使用。这样你不仅知道“现在推荐什么”，也更容易理解“为什么这样做、实际怎么组织”。

## 学习目标

- 建立一条可靠的 Android 持续学习路径。
- 知道哪些资料适合查规则，哪些适合学实践，哪些适合看项目结构。
- 理解为什么单看 Android 官网文档容易像说明书，而多源组合更像教材。
- 避免长期依赖过时或二手转述资料。

## 正文

### 1. 把来源先分成“规则源”和“教学源”

一个很实用的区分方式是：

- 规则源：确认平台行为、权限边界、发布规则和 API 语义。
- 教学源：帮助你理解一条能力如何从概念落到代码和项目结构。

Android Developers 官方文档非常适合做规则源，但并不总擅长承担教材角色。真正更适合教学的，通常还需要配合 codelab、课程、示例项目和语言官方教程。

### 2. 第一层：平台与规则主依据

下面这些资料适合优先用来确认“事实边界”：

- Android Developers：平台行为、权限、系统组件、架构建议、发布规则。
- Kotlin Documentation：语言特性、协程、互操作、语法边界。
- Google Play / Play Console 官方帮助：发布、政策、签名与商店流程。
- Material Design 官方文档：设计系统、组件语义和交互规范。

这类资料的特点是权威、更新快、边界清楚，但它们经常偏“说明书”语气，因此适合确认规则，不一定适合作为唯一学习材料。

### 3. 第二层：路径化课程与 codelab

如果你刚接触一个新主题，官方课程和 codelab 往往比 API 文档更像老师在带你做练习。更值得优先使用的包括：

- Android Basics with Compose 课程。
- Jetpack Compose basics 等官方 codelab。
- Android codelabs 总入口。

这类资料的价值在于：

- 它们有明确起点、步骤和预期结果。
- 更适合第一次把概念真正跑起来。
- 更容易形成“从不会到会”的过程感。

### 4. 第三层：官方示例项目

当你已经理解单个主题后，最值得看的通常不是再搜一篇博客，而是看官方示例项目如何把多条主线组织到一起。推荐优先关注：

- `android/architecture-samples`
- `android/nowinandroid`

前者更适合看可测试架构和经典待办案例，后者更适合看现代 Android 综合项目如何组织模块、数据层、UI、同步与工程化。

### 5. 第四层：语言与基础库的一手文档

很多 Android 章节如果只看 Android 官方文档，会缺少语言和基础库本身的解释。例如：

- 协程和 Flow 最终仍要回到 Kotlin / JetBrains 文档。
- OkHttp、Retrofit、Serialization 这类库应优先看它们自己的官方文档。

这类资料的价值在于：它们通常比二手文章更准确，也更能解释库本身的设计意图。

### 6. 第五层：设计和体验资源

Android 教材如果只谈 API 而不谈设计语言，也很容易失去“为什么这样组织界面”的解释能力。适合补这一层的资料包括：

- Material 3 官方文档。
- Compose 设计相关 codelab 与示例。

这类资料尤其适合 UI、交互反馈、组件语义和设计系统章节。

### 7. 如何把这些资料组合成更像教材的学习路径

一个更稳妥的顺序通常是：

1. 先用课程或 codelab 建立最小实践路径。
2. 再用官方文档确认规则和边界。
3. 再看官方示例项目如何在真实结构中落地。
4. 最后再回到自己的项目里做复现和改写。

这种顺序比“先看一堆 API，再搜博客补理解”更容易建立真正稳定的知识结构。

### 8. 如何避免被过时资料带偏

一个很实用的判断标准是：

- 看发布日期。
- 看是否仍引用旧 API 作为正文主线。
- 看是否与当前官方推荐明显冲突。
- 看是否解释“为什么这样做”，而不只是贴一段代码。
- 看它是否引用了一手资料，而不是只转述别人的结论。

如果一份资料仍然把早已不推荐的 API 当默认主线，或者完全不解释背景和边界，就应该非常谨慎。

## 推荐资料清单

### 平台与官方文档

- Android Developers：<https://developer.android.com/>
- Android Build 文档：<https://developer.android.com/build>
- Android Architecture 文档：<https://developer.android.com/topic/architecture>
- Google Play 发布文档：<https://developer.android.com/studio/publish>

### 官方课程与 Codelabs

- Android Basics with Compose：<https://developer.android.com/codelabs/build-your-first-android-app-kotlin>
- Android Codelabs 总入口：<https://developer.android.com/get-started/codelabs>
- Jetpack Compose basics：<https://developer.android.com/codelabs/jetpack-compose-basics>
- Basic layouts in Compose：<https://developer.android.com/codelabs/jetpack-compose-layouts>

### 官方示例项目

- Now in Android：<https://github.com/android/nowinandroid>
- Architecture Samples：<https://github.com/android/architecture-samples>

### Kotlin 与语言主线

- Kotlin Documentation：<https://kotlinlang.org/docs/home.html>
- Kotlin basic syntax：<https://kotlinlang.org/docs/basic-syntax.html>
- Java / Kotlin 互操作：<https://kotlinlang.org/docs/java-to-kotlin-interop.html>

### 设计与交互

- Material 3：<https://m3.material.io/>
- Jetpack Compose：<https://developer.android.com/compose>

### 常用基础库一手文档

- OkHttp：<https://square.github.io/okhttp/>
- Retrofit：<https://square.github.io/retrofit/>

## 小结

参考资源章节真正想做的，不是列更多链接，而是帮你建立一个可靠的信息过滤器和学习顺序。只要规则类资料、教学类资料、示例项目和语言文档能被组合起来使用，内容就不容易继续滑向“说明书口吻”，而会更接近真正可教、可学、可实践的教材。
