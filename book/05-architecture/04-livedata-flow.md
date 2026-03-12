# LiveData 与 Flow

很多开发者第一次学这一章时，脑子里只有一个问题：“`LiveData` 和 `Flow` 到底哪个更高级？”这个问题并不重要。真正决定页面质量的，不是你选了哪个名词，而是你有没有把“页面当前状态”“一次性事件”“生命周期收集”和“数据流方向”理顺。只要这四件事没有理顺，哪怕 API 用得再新，页面一样会出现重复加载、界面闪烁、旋转后重复弹消息、返回页面后状态错乱这些问题。

这一章不把 `LiveData` 和 `Flow` 当成两份 API 说明书来讲，而是把它们放回页面状态传播这件事本身。你会看到：为什么 Android 早期需要 `LiveData`，为什么今天的新项目更常以 `Flow` 和 `StateFlow` 为主线，以及它们在一个真实页面里分别该承担什么职责。

## 学习目标

- 理解页面状态为什么需要持续可观察，而不是“一次取值”。
- 理解 `LiveData`、`Flow`、`StateFlow`、`SharedFlow` 各自更适合承接什么信息。
- 理解为什么现代 Android 项目通常在数据层和 ViewModel 层优先使用 `Flow`。
- 掌握 UI 层安全收集状态的基本方式。

## 前置知识

- 已理解 `ViewModel` 是屏幕级状态持有者。
- 已具备协程的基本概念。
- 已接触过列表页、加载态、错误态这类常见 UI 状态。

## 正文

### 1. 页面状态不是一份结果，而是一条持续变化的线

先看一个常见页面：新闻列表页。页面打开时需要请求网络，成功后显示列表；用户下拉刷新时会再次进入加载态；搜索关键字变化后列表会过滤；本地收藏状态改变后某一项的图标也要刷新。这个页面并不是“拿到一次数据就结束”，而是在运行过程中不断进入新状态。

这正是“可观察状态”存在的原因。UI 层真正需要的，不是一次函数返回值，而是一个能持续通知变化的状态来源。只要页面状态会变，UI 就必须知道“什么时候变了”“变成了什么”“当前值是什么”。

如果开发者仍然把页面写成“一次请求，一次回调，一次 setText()”，状态来源很快就会分散到多个回调和多个字段里。界面最开始还能跑，复杂度一上来，问题就会集中爆发。

### 2. 先区分三类东西：稳定状态、一次性事件、数据流

为了避免后面混乱，先把三种经常被混在一起的东西分开。

稳定状态指的是“当前页面应该长什么样”。例如列表内容、是否正在加载、是否为空态、当前错误文案。这类信息应该能被新观察者直接拿到，因为它描述的是“现在”。

一次性事件指的是“某个动作刚刚发生过一次”。例如跳转详情页、弹出 Snackbar、打开登录页。这类信息如果被新观察者再次收到，往往就是 bug。

数据流则是状态产生和传递的过程。数据库、网络结果、用户输入、过滤条件都可能是流的一部分。开发者要做的，不是把所有流都直接丢给 UI，而是先在 ViewModel 中把它们整理成页面真正需要消费的状态。

理解这三个层次之后，再看 `LiveData` 和 `Flow`，思路就会清晰很多。

### 3. 为什么 Android 早期需要 LiveData

`LiveData` 在 Jetpack 早期的价值并不是“语法简单”，而是它第一次把“生命周期感知的可观察状态”放进了 Android 官方主线。以前页面经常手工注册监听、手工注销监听，或者把各种回调直接写在 Activity、Fragment 里。页面一重建，很多状态就对不上了。

`LiveData` 带来的改进很直接：

- 它和 `LifecycleOwner` 配合时会自动感知生命周期。
- 它很适合承接“当前页面有一个最新值”的场景。
- 它帮助 `ViewModel` 真正成为 UI 状态的上游。

所以理解 `LiveData` 仍然很重要，因为你会在大量存量项目里看到它。很多团队不是“不知道 Flow”，而是历史包袱、库兼容性、团队经验让它们仍然保留 `LiveData` 主线。

### 4. 为什么今天的新项目更常选择 Flow

如果说 `LiveData` 的价值主要在页面层，那么 `Flow` 的价值在于它贯穿了 Kotlin 协程主线。它不只是一个“能观察数据”的容器，更是整个异步数据管道的统一语言。数据库可以返回 `Flow`，网络结果可以被包进 `Flow`，用户输入可以转换成 `Flow`，多个来源还能组合、变换、节流、重试。

这意味着 `Flow` 不只是 UI 层工具，而是从数据层到 ViewModel 的公共抽象。对于 Kotlin-first 项目，这一点非常关键。你不必在每一层都切换一套不同的异步模型，整个系统都可以在协程语义下工作。

把这件事说得更直白一些：`Flow` 胜出的原因不是“新”，而是“整条链路统一”。这也是为什么现代 Android 官方架构建议里，层与层之间更推荐使用 `coroutines` 与 `flows` 协作。

### 5. 冷流、热流、StateFlow、SharedFlow 到底在解决什么

这一组概念常被单独拿出来背定义，但如果脱离页面场景，很快就会忘。

冷流可以理解为“有人收集时才开始生产数据”。例如一次数据库查询流或某个网络请求转换成的流，只有在被收集时，代码才真正执行。它适合描述数据是怎样被计算和传递出来的。

热流则意味着“数据源本身就在持续存在”。例如应用里某个全局状态、一个长期存在的计数器、一个消息广播通道。收集者加入时，流并不会因此重新开始。

`StateFlow` 是热流里最适合页面稳定状态的那一类，因为它始终有一个当前值。页面一旦开始观察，就能拿到“此刻是什么状态”。这和列表页、详情页、设置页的 UI 状态天然契合。

`SharedFlow` 更适合广播型信息，尤其是那些不一定需要“最新值覆盖旧值”的场景。例如一类一次性消息流、应用内广播、分析事件分发。它不是专门为页面当前状态设计的，所以不要把它当 `StateFlow` 的随手替代品。

### 6. 什么时候还会继续使用 LiveData

如果一个项目已经大量围绕 `LiveData` 构建，并且页面层配套稳定，那么继续使用它并不等于“写错了”。教材里必须讲清楚这一点，否则读者很容易产生错误判断：仿佛只要看到 `LiveData` 就应该立即重构。

更稳妥的判断是：

- 新项目、Kotlin-first 项目、数据层已经大量使用协程时，优先考虑 `Flow` 和 `StateFlow`。
- 老项目已有大量 `LiveData` 观察链路，且团队当前目标是稳定交付时，可以先在新模块里逐步引入 `Flow`。
- 如果某些库或 UI 组件对 `LiveData` 集成更直接，也可以短期保留。

技术选型不是比谁新，而是比哪种方案能让当前系统更统一、更少出错。

### 7. 页面状态为什么通常落在 StateFlow，而不是把所有 Flow 直接暴露给 UI

很多初学者学到 `Flow` 后，容易把 Repository 返回的各种流直接扔给 Fragment 或 Compose 页面去拼。这样做的结果是，页面自己知道了太多数据来源，也承担了太多合成逻辑。只要筛选条件、分页状态、刷新动作一复杂，UI 层就会迅速失控。

更合理的做法是：Repository 暴露原始数据流，ViewModel 负责把这些流整理成页面真正要消费的 `UiState`，UI 只关心如何渲染 `UiState`。这样一来，屏幕状态就只有一个主要入口，页面代码会稳定很多。

下面这个例子展示了 ViewModel 怎样把多个来源收束成单一页面状态：

```kotlin
data class NewsUiState(
    val isLoading: Boolean = false,
    val items: List<ArticleUiModel> = emptyList(),
    val query: String = "",
    val errorMessage: String? = null
)

class NewsViewModel(
    private val repository: NewsRepository
) : ViewModel() {

    private val query = MutableStateFlow("")

    val uiState: StateFlow<NewsUiState> = combine(
        repository.observeArticles(),
        query
    ) { articles, currentQuery ->
        val filtered = articles.filter {
            it.title.contains(currentQuery, ignoreCase = true)
        }
        NewsUiState(
            isLoading = false,
            items = filtered.map { article ->
                ArticleUiModel(
                    id = article.id,
                    title = article.title,
                    isFavorite = article.isFavorite
                )
            },
            query = currentQuery
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = NewsUiState(isLoading = true)
    )

    fun updateQuery(newQuery: String) {
        query.value = newQuery
    }
}
```

这里最值得学习的不是 `combine()` 的语法，而是状态组织方式。数据源可以有多个，但 UI 最终面对的是一个统一的 `uiState`。这就是教材里反复强调“先整理状态，再渲染页面”的原因。

### 8. 一次性事件不要伪装成页面状态

如果把 Snackbar 文案、导航动作、文件选择器打开动作都塞进 `UiState`，页面在重建或重新收集时就很容易重复执行这些动作。很多“怎么旋转一下页面又弹了一次提示”的问题，根本原因就在这里。

一个更稳妥的做法是：

- 用 `StateFlow` 或 `LiveData` 承接稳定页面状态。
- 用单独的事件通道承接一次性动作。
- 让 UI 在明确的位置消费事件，而不是把事件写成页面常驻字段。

这件事说起来像编码技巧，实际上是教材里必须讲透的建模问题。因为很多 UI bug 不是出在语法，而是出在你把“状态”和“动作”当成了同一类东西。

### 9. Flow 并不会自动替你解决生命周期问题

不少开发者从 `LiveData` 迁移到 `Flow` 时，会误以为“现在换成协程了，生命周期问题自然没了”。这是很危险的误解。`Flow` 负责的是数据如何流动，不负责 UI 应该在什么时候开始、什么时候停止收集。

在 View 系统里，最常见的安全写法是用 `repeatOnLifecycle()` 在合适的生命周期状态里收集；在 Compose 里，则更常用 `collectAsStateWithLifecycle()`。这不是为了代码“显得新”，而是为了让不可见页面停止不必要的 UI 更新，避免资源浪费和异常状态。

例如 Fragment 中的典型写法会是这样：

```kotlin
viewLifecycleOwner.lifecycleScope.launch {
    viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { state ->
            progressBar.isVisible = state.isLoading
            emptyView.isVisible = state.items.isEmpty() && !state.isLoading
            recyclerView.isVisible = state.items.isNotEmpty()
            adapter.submitList(state.items)
        }
    }
}
```

这段代码的教学重点同样不是语法本身，而是“页面只有在合适生命周期里才接收状态”。UI 不是日志系统，不能在不可见时还持续消费所有更新。

### 10. Compose 场景下为什么更容易理解 StateFlow

在 Compose 中，声明式 UI 天然强调“状态决定界面”。这让 `StateFlow` 的角色变得特别直观：ViewModel 提供状态，Composable 根据状态重组。页面每次显示什么，不再靠一连串手动 `setText()` 和 `setVisibility()` 拼出来，而是根据当前状态直接声明。

这也是为什么很多读者会在学习 Compose 后，突然更理解 ViewModel 和 `StateFlow` 的组合。并不是 Compose 让概念变了，而是它把“UI 只是状态的函数”这件事表现得更明显。

### 11. 实践任务

起点条件：

- 已有一个会显示加载态、列表态和错误态的页面。

步骤：

1. 把页面当前所有字段分成“稳定状态”和“一次性事件”两组。
2. 为稳定状态创建一个 `UiState` 数据类。
3. 如果当前使用的是多个分散字段，把它们收束进 ViewModel 中的一个主状态出口。
4. 如果项目已经用 `Flow`，检查 UI 是否通过生命周期感知方式收集。
5. 如果项目仍主要使用 `LiveData`，写出一段迁移计划，说明哪些新页面可以优先转为 `StateFlow`。

预期结果：

- 页面状态来源会比以前集中。
- 你会更容易判断某段逻辑属于状态还是事件。
- 页面重建、返回、重新订阅时的重复消费问题会明显减少。

自检方式：

- 你能解释为什么 `StateFlow` 适合承接页面当前状态。
- 你能说出 `LiveData` 和 `Flow` 在生命周期协作上的一个关键差异。
- 你能指出当前页面里至少一个原本被错误建模为状态的事件。

调试提示：

- 页面旋转后又弹了一次消息，优先检查是否把事件塞进了 `UiState`。
- 页面不可见时仍在持续收集数据，优先检查是否缺少生命周期感知收集。
- UI 层如果同时拼接太多流，优先把整理逻辑收回 ViewModel。

### 12. 常见误区

- 把这一章理解成两个 API 的表面对比。
- 以为只要用了 `Flow`，页面状态设计就自然合理。
- 把一次性事件塞进稳定状态模型。
- 直接在 UI 层拼装多个数据流。

## 小结

`LiveData` 与 `Flow` 真正要解决的，不是“谁更先进”，而是页面状态如何稳定地从上游流向 UI。`LiveData` 让 Android 页面层第一次拥有官方支持的生命周期感知状态容器；`Flow` 则把异步数据、状态转换和跨层协作统一进了 Kotlin 主线。对今天的新项目来说，`StateFlow` 往往是页面状态最自然的承载方式，但真正决定页面质量的，始终是状态建模、事件边界和生命周期收集这三件事。

## 参考资料

- 参考并改写自：Harun Wangereka，《Mastering Kotlin for Android 14》(2024)，第 5 章。
- 参考并改写自：Kickstart Modern Android Development With Jetpack And Kotlin (2024)，第 2、7-9、12 章。
- 参考并改写自：Damilola Panjuta、Linda Nwokike，《Tiny Android Projects Using Kotlin》(2024)，第 8 章。
- 参考并改写自：Gabriel Socorro，《Thriving in Android Development Using Kotlin》(2024)，第 1 章。

- Kotlin flows on Android：<https://developer.android.com/kotlin/flow>
- StateFlow and SharedFlow：<https://developer.android.com/kotlin/flow/stateflow-and-sharedflow>
- Collect flows safely in Android UI：<https://developer.android.com/kotlin/flow/stateflow-and-sharedflow#collect>
- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Kotlin Flow documentation：<https://kotlinlang.org/docs/flow.html>

