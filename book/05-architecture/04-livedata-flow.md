# LiveData 与 Flow

在 Android 状态传播体系里，LiveData 和 Flow 都扮演过重要角色。很多学习者第一次接触这一章时，会把它理解成“两个可观察对象 API 的比较”。这种理解太浅。真正重要的是：页面状态和异步数据流究竟应该如何暴露、如何收集，以及为什么今天的新项目更常把 StateFlow / Flow 作为主线，而 LiveData 更多出现在已有项目或兼容场景中。

只要这个问题没想清楚，开发者就很容易陷入一些典型误区，例如把页面状态和一次性事件混在一起，把 Flow 当成“换个语法的 LiveData”，或者直接在 UI 中无生命周期地收集数据，最终制造出重复消费、页面闪烁和状态来源不清的问题。本章要解决的，正是这些现实边界。

## 学习目标

- 理解 LiveData、Flow、StateFlow 各自更适合解决什么问题。
- 理解冷流、热流、状态流和事件流的基本差异。
- 理解为什么现代 Android 更常以 StateFlow / Flow 为主线。
- 理解生命周期感知收集为什么仍然重要。

## 前置知识

- 已理解 ViewModel 是屏幕级状态容器。
- 已具备协程和异步操作的基本认知。

## 正文

### 1. 页面状态之所以需要“可观察”，是因为它会持续变化

页面状态不是一次性产物。网络返回、本地数据库变化、用户输入、刷新、重试、筛选和分页，都会让屏幕在运行中不断进入新状态。因此，UI 层真正需要的是一种持续接收更新的能力，而不是“拿一次结果然后结束”。

这也解释了为什么状态传播工具在 Android 中如此重要。它们的价值不是“API 更现代”，而是帮助 UI：

- 持续接收新状态。
- 与生命周期协作。
- 更自然地连接异步数据和页面渲染。

LiveData 和 Flow 都是在解决这类问题，只是它们所在的技术背景和主线不同。

### 2. LiveData 的历史价值非常大

LiveData 在 Jetpack 早期的重要价值，是让 Activity 和 Fragment 拥有了生命周期感知的可观察状态来源。它解决了过去 Android 页面层里大量手动注册、反注册、状态同步的问题，也推动了 ViewModel 在页面层的落地。

即使今天的新项目更常使用 Flow，LiveData 的历史价值仍然值得理解，因为很多旧项目和现有库仍然使用它。而且 StateFlow 与 LiveData 在“可观察状态容器”这个方向上确实有相近之处。

### 3. Flow 更适合现代 Kotlin-first 项目的根本原因

Flow 的意义并不只是“也能观察数据”，而是它天然属于 Kotlin 协程体系。这意味着它更适合描述持续异步流，并具备更好的组合、变换、错误处理和与数据层协作能力。

Android 官方对 Kotlin Flow 的推荐，也正是建立在这一点上。架构建议里明确提出，层与层之间优先使用 coroutines and flows 进行通信。原因很现实：

- Repository 更容易暴露持续变化的数据流。
- Room 可以直接返回 `Flow`。
- ViewModel 可以用 `stateIn`、`shareIn`、`combine` 等操作符组织状态。
- UI 层可以用生命周期感知方式安全收集。

Flow 的价值在于它贯穿了整条现代 Kotlin 主线。

### 4. StateFlow 为什么更适合表达页面状态

Android 官方的 StateFlow 指南明确指出，`StateFlow` 是一个 state-holder observable flow，非常适合维护可观察的可变状态。它的几个特征恰好和页面状态高度匹配：

- 它始终有当前值。
- 新收集者会先拿到最近一次状态。
- 它非常适合在 ViewModel 中作为 `uiState` 暴露。

一个列表页当前是 Loading、Content、Empty 还是 Error，本质上就是“当前值明确”的状态，因此特别适合用 `StateFlow` 表达。

### 5. LiveData 和 StateFlow 相似，但并不完全等价

Android 官方文档也专门强调了两者的重要差异。一个更实用的理解方式是：

- LiveData 更像早期 Jetpack 页面层的生命周期感知状态容器。
- Flow 是更通用的异步流抽象。
- StateFlow 是 Flow 世界里更适合承接当前状态的那一类。

尤其要注意的一点是：LiveData 的 `observe()` 会自动跟随生命周期取消，而 Flow / StateFlow 如果直接在 UI 中 `launch` 收集，并不会自动停止。官方明确警告：不要直接从普通 `launch` 或 `launchIn` 中收集并更新 UI，而应配合 `repeatOnLifecycle` 或 `collectAsStateWithLifecycle()` 这类机制。

### 6. 页面状态和一次性事件必须分开

这是状态传播设计中最容易混乱的地方。页面状态表示“当前屏幕应该是什么样”，例如：

- 当前是否加载中。
- 当前列表内容是什么。
- 当前是否为空态。

一次性事件则更像：

- 导航到详情页。
- 弹出 Snackbar。
- 打开系统文件选择器。

如果把这两类东西混在一个状态模型里，页面就很容易在重建、重复收集或重新订阅后发生重复消费。更稳妥的做法通常是：稳定 UI 用 `StateFlow`，短暂事件使用单独的事件流或显式回调机制。

### 7. 生命周期感知收集依然是关键

很多人迁移到 Flow 后，以为“现在是协程了，生命周期问题自然解决”。这是一种很危险的错觉。Flow 只是定义了状态如何流动，至于 UI 在什么时候收集、什么时候停止，仍然需要开发者处理。

Android 官方建议使用 `repeatOnLifecycle` 来确保界面只有在合适生命周期状态下才收集 Flow。Compose 场景中，则更常使用 `collectAsStateWithLifecycle()`。这类 API 的意义不是语法好看，而是避免不可见界面仍在更新 UI，从而引发崩溃、浪费资源或产生错误渲染。

### 8. 一个更接近真实项目的最小结构

下面的示例演示 ViewModel 怎样用 `StateFlow` 暴露页面状态，UI 又如何以生命周期感知方式收集：

```kotlin
data class NewsUiState(
    val isLoading: Boolean = false,
    val items: List<Article> = emptyList(),
    val errorMessage: String? = null
)

class NewsViewModel(
    repository: NewsRepository
) : ViewModel() {

    val uiState: StateFlow<NewsUiState> = repository.observeArticles()
        .map { articles ->
            NewsUiState(isLoading = false, items = articles)
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = NewsUiState(isLoading = true)
        )
}
```

这个例子里最关键的，不是某个操作符名字，而是三点：

- 状态由 ViewModel 统一对外暴露。
- 状态有明确初始值和当前值。
- UI 不需要自己拼装多个来源，而是只消费 `uiState`。

### 9. 实践任务

起点条件：

- 已有一个用 ViewModel 暴露页面状态的页面，或至少已有列表页示例。

步骤：

1. 列出页面里哪些是“稳定状态”，哪些是“一次性事件”。
2. 把稳定状态收束成一个 `UiState` 数据类。
3. 使用 `MutableStateFlow` 或 `stateIn` 在 ViewModel 中暴露页面状态。
4. 在 View 层改用 `repeatOnLifecycle` 或 `collectAsStateWithLifecycle()` 收集状态。
5. 如果项目中仍大量使用 LiveData，明确哪些属于历史兼容，哪些值得逐步迁移到 Flow。

预期结果：

- 你能更清晰地区分状态、事件和生命周期边界。
- 页面状态来源会更统一，重复消费问题更少。
- 你会为后续并发和 WorkManager 章节建立更自然的状态主线。

自检方式：

- 你能解释：StateFlow 为什么适合承接页面状态。
- 你能说出：LiveData 和 StateFlow 最大的行为差异之一是什么。
- 你能判断：某个页面逻辑究竟属于状态还是事件。
- 你能确认：UI 没有在不安全的生命周期中持续收集 Flow。

调试提示：

- 如果旋转后 Snackbar 又弹了一次，优先检查是否把事件错误地建模成了状态。
- 如果页面不可见时仍在收集并更新 UI，优先检查是否缺少 `repeatOnLifecycle`。
- 如果你无法说清某个 Flow 是冷流还是热流，通常说明状态传播设计还不够稳。

### 10. 常见误区

- 把 LiveData 和 Flow 理解成“语法不同的同一件事”。
- 不区分页面状态和一次性事件。
- 使用 Flow 后忽略生命周期感知收集。
- 只知道收状态，不知道状态本身是否建模清楚。

## 小结

LiveData 与 Flow 章节真正要解决的，不是 API 对比，而是页面状态怎样稳定地从 ViewModel 流向 UI。对今天的新项目来说，StateFlow / Flow 更符合 Kotlin-first 和官方架构主线，但无论使用哪种工具，真正重要的始终是状态建模、事件边界和生命周期收集这三件事。

### 教材化延伸：为什么 LiveData 和 Flow 不能只做 API 对比

如果这一章只停在“哪个类型有什么函数”，读者很容易学成一张 API 对照表。教材更需要解释的是：状态流为什么会影响 UI 层组织，为什么 Flow 更自然地进入协程链路，为什么 LiveData 在现有项目里仍然需要识别和维护。只有把这些放回数据流和页面状态语境里，对比才有意义。

### 资料路线

- 先用本章示例理解“可观察数据”到底在解决什么 UI 同步问题。
- 再对照 Kotlin Flow 文档和 Android UI state 文档，确认流式状态的正式用法。
- 最后结合样例项目，观察 Flow 在 Repository、ViewModel 和 Compose/UI 中是怎样贯通的。

## 参考资料

- Kotlin flows on Android：<https://developer.android.com/kotlin/flow>
- StateFlow and SharedFlow：<https://developer.android.com/kotlin/flow/stateflow-and-sharedflow>
- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
