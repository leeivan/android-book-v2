# Android 中的 MVVM

上一章解决的是“为什么现代 Android 更常采用 MVVM”，这一章开始解决“它在代码里到底怎样落地”。很多开发者知道 View、ViewModel、Model 这三个词，却很难把它们和 Activity、Fragment、Compose、Repository、Room、网络接口这些现实对象对应起来。结果往往是：概念上似乎已经在用 MVVM，代码上却仍然由页面类承担大部分复杂度。

本章的目标，就是把 MVVM 从抽象缩写还原成 Android 项目中可执行的职责分工。你会看到它为什么总和单向数据流、页面状态、ViewModel、Repository 一起出现，也会看到它并不是“所有逻辑都搬进 ViewModel”这么简单。

## 学习目标

- 理解 MVVM 在 Android 项目中的具体职责分工。
- 理解 View、ViewModel、Model 与 Repository、页面状态的关系。
- 理解单向数据流为什么几乎总和 MVVM 一起出现。
- 为后续 ViewModel、Flow、Repository 和 Hilt 打基础。

## 前置知识

- 已理解 MVC、MVP、MVVM 的整体差异。
- 已知道 Activity / Fragment 不应成为所有逻辑的容器。

## 正文

### 1. Android 中的 View，不只是 XML 或 Composable 本身

在 MVVM 里，View 并不是单纯指布局文件。更准确地说，View 指的是整个界面呈现层，也就是用户直接交互的那一侧。在 Android 里，这通常包括：

- Activity 或 Fragment。
- Compose 的 screen-level composable。
- 与渲染和输入直接相关的 UI 适配代码。

View 的职责应尽量聚焦于：

- 展示当前状态。
- 把用户输入转成事件。
- 触发导航、系统选择器或权限请求这类 UI 相关动作。

它不应长期持有复杂业务状态，也不应直接协调多个数据来源。

### 2. ViewModel 是 Android 中 MVVM 的核心支点

Android 官方对 ViewModel 的定义非常明确：它是 business logic or screen level state holder，也就是屏幕级状态容器和 UI 层业务逻辑承载点。这个定位非常关键，因为 Android 页面实例本身并不稳定：

- 旋转会重建 Activity。
- Fragment 视图会销毁和重建。
- 进程回收后页面可能再次恢复。

页面实例不稳定，但页面状态又不能每次都从零开始，这恰恰是 ViewModel 在 Android 中变得如此重要的原因。它让 MVVM 不只是概念，而是和平台现实紧密贴合的架构落点。

### 3. Model 在现代 Android 中，往往是“数据与业务层”而不是几个数据类

很多入门者会把 Model 理解成“几个 data class”。这种理解太窄。对今天的 Android 项目来说，Model 更接近整个非 UI 侧的能力集合，通常包括：

- Repository。
- 本地数据源和远程数据源。
- 数据转换逻辑。
- 某些业务规则与用例。

这也是为什么 MVVM 不该被简化成“View + ViewModel + 几个 DTO”。真正稳定的 MVVM，一定有清晰的数据层支撑。

### 4. Android 中更自然的 MVVM 链路是什么

更符合现代 Android 的 MVVM 链路通常是：

1. View 接收用户动作。
2. View 把动作交给 ViewModel。
3. ViewModel 调用 Repository 或 UseCase。
4. Repository 协调本地、远程和缓存策略。
5. ViewModel 把结果转换成 `uiState`。
6. View 只根据 `uiState` 渲染。

Android 官方架构建议强调 UI should be driven from data models and follow unidirectional data flow。这意味着 View 不应被多个下层对象同时直接推动，而应从单一状态入口读取结果。MVVM 在 Android 中之所以自然，就是因为这条链路恰好能落地这种单向结构。

### 5. 单向数据流是 MVVM 在 Android 中最重要的配套原则

很多项目嘴上说自己是 MVVM，实际上页面、ViewModel、Repository 都在修改同一份状态。这样做最后会让状态来源非常混乱。更稳定的方式通常是：

- 事件从 View 流向 ViewModel。
- 状态从 ViewModel 流向 View。
- 数据变化先进入数据层，再被 ViewModel 转换成页面状态。

这样做的好处非常直接：

- 状态来源可追踪。
- 生命周期重建时更容易恢复。
- 页面层不需要自己拼装复杂逻辑。
- 调试时更容易定位“这次状态变化到底从哪来”。

### 6. View 应该“轻”到什么程度

“页面要轻”是一句很常见但也很空泛的话。更具体地说，页面层可以负责：

- 绑定 UI。
- 读取和渲染 `uiState`。
- 收集点击、输入、滑动、刷新等事件。
- 执行纯 UI 层动作，例如显示 Snackbar 或发起权限请求。

但页面层不应负责：

- 直接调用网络和数据库。
- 持有长期业务状态。
- 协调多个 Repository。
- 解释底层异常。

只要这些问题还留在 Activity、Fragment 或 screen composable 里，MVVM 就还没有真正站稳。

### 7. ViewModel 也不是“新的业务垃圾桶”

这是 Android 中最常见的 MVVM 误用之一。很多项目从页面类中抽逻辑时，只是把所有东西机械搬进 ViewModel，结果只是把巨型 Activity 变成巨型 ViewModel。

ViewModel 的重点应是：

- 组织页面状态。
- 承接页面事件。
- 触发对下层的调用。
- 把数据层结果转换成 UI 能理解的状态。

如果 ViewModel 里开始堆满 SQL、HTTP 拼接、对象构造细节和各种完全不相干的业务分支，就说明你需要 Repository、UseCase 或更明确的数据边界，而不是继续扩大 ViewModel。

### 8. 一个列表页在 Android MVVM 中该怎样流动

以文章列表页为例，一个比较健康的 MVVM 链路通常是：

- 页面启动时触发 `load` 或 `refresh` 事件。
- ViewModel 把 `uiState` 更新为 Loading。
- Repository 返回 Flow 或结果包装。
- ViewModel 把数据转换为 Content、Empty 或 Error 状态。
- 页面根据当前 `uiState` 渲染列表、空态或错误态。

这个过程中，页面不需要知道数据到底来自 Room 还是 Retrofit，也不应直接处理 `IOException` 和 `HttpException`。这些都是 MVVM 在 Android 中能否真正落地的关键细节。

### 9. 实践任务

起点条件：

- 已有一个包含列表、详情或表单页面的练习项目。

步骤：

1. 选一个页面，写出 View、ViewModel、Repository 三层各自现在承担的职责。
2. 检查页面是否仍直接持有数据源对象或直接解释异常。
3. 选出一个页面状态，把它正式建模为 `uiState`，不要再只用零散布尔值。
4. 画出“事件从哪来、状态往哪去”的单向流向图。
5. 找出一段放错层级的逻辑，决定它应留在 ViewModel 还是下沉到 Repository。

预期结果：

- 你能把 MVVM 落到具体 Android 组件上，而不是只停留在名词层面。
- 你会更容易识别页面过重和 ViewModel 过重的边界。
- 你能为后续 Flow、Repository 和 Hilt 章节建立统一主线。

自检方式：

- 你能解释：为什么 ViewModel 在 Android 中尤其关键。
- 你能判断：某段逻辑属于 UI 层业务逻辑还是数据层职责。
- 你能说出：单向数据流为什么是 MVVM 稳定落地的前提。

调试提示：

- 如果页面直接拿 DTO 渲染，通常说明 Model 和 UI 边界没有立住。
- 如果 ViewModel 里充满网络与数据库细节，说明只是把复杂度搬了位置。
- 如果多个对象都能直接修改页面状态，后面一定会出现“来源不明的 UI 变化”。

### 10. 常见误区

- 把 MVVM 简化成“Activity + ViewModel”。
- 认为只要有 ViewModel 就自动拥有良好架构。
- 页面层仍直接处理网络、数据库和复杂业务分支。
- 把所有复杂度机械搬进 ViewModel。

## 小结

Android 中的 MVVM，本质上是一种围绕 ViewModel、Repository 和页面状态展开的职责组织方式。它真正想解决的，是页面实例不稳定、状态持续变化、数据来源复杂这三类现实问题。只要 View 聚焦展示，ViewModel 聚焦状态，数据层聚焦来源与规则，这条链路就会逐渐稳定下来。

### 教材化延伸：为什么 MVVM 在 Android 里不能只看图示

很多 MVVM 介绍会画出一张 View、ViewModel、Model 三层图，然后读者以为自己已经“懂了架构”。但 Android 里的 MVVM 真正难点不在图，而在页面生命周期、异步请求和页面状态如何真正交给 ViewModel 管理。教材写法必须把模式图、状态持有者和数据流示例绑在一起，否则 MVVM 很容易退化成“把逻辑从 Activity 挪到别处”。

### 资料路线

- 先用本章最小页面示例理解 View 与 ViewModel 的数据边界。
- 再对照 Android ViewModel、state holders 和 architecture recommendations 文档，确认官方推荐的职责划分。
- 最后阅读 `architecture-samples` 或 `Now in Android`，观察 MVVM 如何和 Repository、UI state 共同工作。

## 参考资料

- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
- ViewModel overview：<https://developer.android.com/topic/libraries/architecture/viewmodel>
- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
