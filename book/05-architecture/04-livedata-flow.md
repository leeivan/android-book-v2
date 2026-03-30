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

这一点在 Vainigli 的《Ultimate Android Design Patterns》里讲得很直白：`LiveData` 仍然适合以 Activity / Fragment 生命周期为中心的观察场景，而在现代 Kotlin-first 项目里，持久 UI state 更常由 `StateFlow` 承接，异步数据通道则更适合交给 `Flow`。把这三者先按“状态形态”分清，选型就不再是“谁更新”，而是“谁更贴合当前这类数据”。

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

对应到实现上，一个很稳的实践是：对外暴露稳定状态时，优先使用只读 `StateFlow` / `LiveData`；对外暴露一次性 effect 时，使用单独的事件流或 effect 通道，而不是把 UI 动作伪装成状态字段。这样页面每次重建时，真正会被重新消费的只有“现在是什么状态”，而不是“刚刚做过什么动作”。

Socorro 的聊天项目则把“状态”和“事件/消息流”分开的好处讲得很具体：`ChatViewModel` 不只暴露一个 `messages: StateFlow<List<Message>>`，还额外维护一个 `uiState: StateFlow<Chat>` 来承接聊天室标题、头像和初始化信息；Compose 侧再用 `collectAsState()` 分别收集它们，并用 `LaunchedEffect(Unit)` 触发首次加载。这个例子特别适合提醒读者：不是所有屏幕信息都该塞进同一个流里，稳定页面状态和持续到来的消息流往往需要分开建模。

如果把“稳定状态”和“一次性事件”再压成一个完整示例，会更容易看清为什么它们必须分流：

```kotlin
data class ProfileUiState(
    val isLoading: Boolean = false,
    val username: String = "",
    val isLoggedIn: Boolean = false
)

sealed interface ProfileEffect {
    data class ShowSnackbar(val message: String) : ProfileEffect
    data object OpenLogin : ProfileEffect
}

class ProfileViewModel(
    private val repository: ProfileRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ProfileUiState(isLoading = true))
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    private val _effects = MutableSharedFlow<ProfileEffect>()
    val effects: SharedFlow<ProfileEffect> = _effects.asSharedFlow()

    fun refresh() {
        viewModelScope.launch {
            runCatching { repository.fetchProfile() }
                .onSuccess { profile ->
                    _uiState.value = ProfileUiState(
                        isLoading = false,
                        username = profile.username,
                        isLoggedIn = true
                    )
                }
                .onFailure {
                    _uiState.update { it.copy(isLoading = false) }
                    _effects.emit(ProfileEffect.ShowSnackbar("加载失败，请重试"))
                }
        }
    }

    fun requireLogin() {
        viewModelScope.launch {
            _effects.emit(ProfileEffect.OpenLogin)
        }
    }
}
```

配套到 UI 层时，最稳的收集方式通常也是两条线分开：

```kotlin
viewLifecycleOwner.lifecycleScope.launch {
    viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
        launch {
            viewModel.uiState.collect { state ->
                progressBar.isVisible = state.isLoading
                usernameView.text = state.username
            }
        }

        launch {
            viewModel.effects.collect { effect ->
                when (effect) {
                    is ProfileEffect.ShowSnackbar -> {
                        Snackbar.make(rootView, effect.message, LENGTH_SHORT).show()
                    }
                    ProfileEffect.OpenLogin -> {
                        findNavController().navigate(R.id.loginFragment)
                    }
                }
            }
        }
    }
}
```

这里最关键的教学点是：新的观察者应该立刻拿到当前 `uiState`，却不应该把“刚刚弹过的 Snackbar”或“刚刚执行过的跳转”再重放一次。也正因为如此，稳定状态和 effect 通道不能混用。很多看起来像“Flow 又重复发了一次”的问题，根本不是 Flow 的错，而是建模时把状态和事件塞进了同一个出口。

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

### 11. 冷上游最好先在 ViewModel 里收成热状态，再交给 UI

Bennett 和 Socorro 的例子里都有一个容易被忽略的共识：Repository 暴露出来的往往是一条冷流，但屏幕真正需要的是一份“随时可读的当前状态”。如果直接让多个 UI 位置各自去 `collect` 同一条冷流，上游查询、网络或数据库转换就可能被重复触发。更稳的做法，是先在 ViewModel 里把它收成热状态，再提供给 UI。

```kotlin
class DashboardViewModel(
    private val repository: DashboardRepository,
) : ViewModel() {

    private val filter = MutableStateFlow(DashboardFilter.ALL)

    private val articles = repository.observeArticles()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList(),
        )

    val uiState: StateFlow<DashboardUiState> = combine(
        articles,
        filter,
    ) { items, currentFilter ->
        DashboardUiState(
            items = items.filter { currentFilter.accept(it) },
            currentFilter = currentFilter,
            isLoading = false,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = DashboardUiState(isLoading = true),
    )

    fun updateFilter(value: DashboardFilter) {
        filter.value = value
    }
}
```

这段代码真正回答的是“谁来持有当前状态”。Repository 负责提供原始数据流，ViewModel 把它们整理成当前屏幕真正要消费的热状态，UI 再通过生命周期感知方式读取这份结果。只要先在 ViewModel 把冷上游收热，页面里“同一个状态被多次订阅、重复触发上游工作”的问题就会少很多。需要共享事件生产过程时，再考虑 `shareIn()`；而需要共享当前页面状态时，优先想 `stateIn()`。

### 12. 需要共享同一条昂贵上游时，再考虑 `shareIn()`

前面说过 `stateIn()` 更适合承接当前页面状态，但它不是唯一答案。如果上游本身是一条昂贵且持续的流，比如 WebSocket 连接状态、长轮询结果或实时分析事件，而页面里又有多个位置都要消费同一条上游，那么更适合先把“生产过程”共享出去，再由不同消费者各自处理。这个场景下，`shareIn()` 往往比直接让每个收集者各跑一遍上游更稳。

```kotlin
class ChatViewModel(
    repository: ChatRepository,
) : ViewModel() {

    private val incomingMessages = repository.observeIncomingMessages()
        .shareIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            replay = 0,
        )

    val messages: StateFlow<List<Message>> = incomingMessages
        .scan(emptyList<Message>()) { items, message -> items + message }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList(),
        )

    val unreadCount: StateFlow<Int> = incomingMessages
        .scan(0) { count, _ -> count + 1 }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = 0,
        )
}
```

这段代码体现的是另一种边界：`shareIn()` 共享的是“上游生产过程”，而 `stateIn()` 承接的是“某个消费者视角下的当前状态”。消息流只连一次上游，但可以分别整理成消息列表和未读数。只要读者把这两个角色分清，就不容易在页面状态和共享事件生产之间混用 API。

### 13. 旧页面迁移时，可以先在 ViewModel 边界桥接 `Flow` 和 `LiveData`

很多真实项目不会在一周内把所有旧页面都迁成 `StateFlow + Compose`。Vainigli 和 Bennett 在谈迁移时都给过一个很务实的建议：与其在 UI 层到处临时把 `Flow` 和 `LiveData` 混着拼，不如先在 ViewModel 边界上把新旧出口都准备好，让新页面逐步吃 `Flow`，旧页面继续吃 `LiveData`。这样迁移成本会小很多，状态建模也不会因为过渡期而重新发散。

```kotlin
class ProfileViewModel(
    repository: ProfileRepository,
) : ViewModel() {

    private val uiStateFlow = repository.observeProfile()
        .map { profile ->
            ProfileUiState(
                isLoading = false,
                name = profile.displayName,
                email = profile.email,
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ProfileUiState(isLoading = true),
        )

    val uiState: StateFlow<ProfileUiState> = uiStateFlow

    val uiStateLiveData: LiveData<ProfileUiState> = uiStateFlow.asLiveData()
}
```

这段代码的重点不是“同时暴露两个字段”，而是迁移边界终于被收在了一处。新页面可以直接 `collectAsStateWithLifecycle()`，旧 Fragment 也还能继续 `observe(viewLifecycleOwner)`；真正的状态来源仍然只有一份，桥接只是为了兼容旧消费方式，而不是允许每个页面再各自造一条状态线。只要这层边界守住，Flow 迁移就会更像稳定替换承载容器，而不是全项目一起改写的硬切换。

### 14. 搜索和筛选这类用户输入，最好先做去抖和去重，再接上游数据流

Socorro 和 Bennett 在聊天页、列表页这些实时搜索例子里其实都在说明同一个问题：用户输入是高频变化的，而上游查询、数据库检索或网络搜索通常不是。只要把文本输入原样一路往上游传，Flow 再优雅也会被你用成“每按一个字就重跑一次整条链”。更稳的做法，是先把输入流做去抖、去重，再进入真正昂贵的上游工作。

```kotlin
class ArticleSearchViewModel(
    private val repository: ArticleRepository,
) : ViewModel() {

    private val query = MutableStateFlow("")

    val uiState: StateFlow<SearchUiState> = query
        .debounce(300)
        .map { it.trim() }
        .distinctUntilChanged()
        .mapLatest { keyword ->
            val items = repository.search(keyword)
            SearchUiState(
                keyword = keyword,
                items = items,
                isLoading = false,
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = SearchUiState(isLoading = true),
        )

    fun updateQuery(value: String) {
        query.value = value
    }
}
```

这段代码真正讲清的是“输入流”和“数据流”不是一回事。输入流需要先被整理，避免每次击键都重跑昂贵上游；真正进入 `repository.search()` 的，应该已经是一条更克制、更像业务输入的流。对这一章来说，这也是 Flow 很重要的一层价值：它不只是替代 `LiveData` 的容器，更让“输入怎样被加工后再进入上游”有了稳定写法。

### 15. 把“刷新请求”本身也建成一条流，会比散落的 reload 调用更稳

前面已经讨论过状态流和输入流，但还有一种经常被写散的东西：用户点击刷新、页面首次进入、登录态恢复后重拉数据，这些“请重新计算一次”的动作。Bennett 和 Socorro 的写法里都能看到一个共同点：与其在多个函数里直接调用同一个加载方法，不如把刷新请求本身也收成一条流，再让它统一触发上游重算。这样一来，刷新就不再是散落的命令，而会成为状态系统的一部分。

```kotlin
class DashboardViewModel(
    private val repository: DashboardRepository,
) : ViewModel() {

    private val refreshRequests = MutableSharedFlow<Unit>(replay = 1)

    val uiState: StateFlow<DashboardUiState> = refreshRequests
        .onStart { emit(Unit) }
        .flatMapLatest {
            repository.observeDashboard()
                .onStart {
                    emit(DashboardResult.Loading)
                }
        }
        .map { result ->
            when (result) {
                DashboardResult.Loading -> DashboardUiState(isLoading = true)
                is DashboardResult.Content -> DashboardUiState(
                    isLoading = false,
                    sections = result.sections,
                )
            }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = DashboardUiState(isLoading = true),
        )

    fun refresh() {
        refreshRequests.tryEmit(Unit)
    }
}
```

这段代码真正稳定下来的，是“重新触发上游计算”也有了自己的入口契约。页面不再需要知道底层到底是哪一条流该重跑、哪一段逻辑该重建；它只表达“我现在要刷新”，剩下的统一交给 Flow 链路去组织。对这一章来说，这也是 Flow 很值得学走的一点：它不仅承接结果，也能承接触发结果重算的动作。

### 16. 对高频子状态做投影和去重，会比把整份页面状态一路下发更稳

前面已经补了输入流和刷新流，这一章还差最后一个很实用的判断：并不是所有 UI 都需要整份页面状态。Bennett 和官方状态文档都在强调，如果某个控件只关心“提交按钮能不能点”，那就没必要每次整份 `uiState` 变化都让它重新解释一遍。把高频子状态先投影出来，再配上 `distinctUntilChanged()`，会比 UI 自己到处判断更稳。

```kotlin
class ProfileEditorViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileEditorUiState())
    val uiState: StateFlow<ProfileEditorUiState> = _uiState.asStateFlow()

    val submitEnabled: StateFlow<Boolean> = uiState
        .map { state ->
            state.name.isNotBlank() &&
                state.email.contains("@") &&
                !state.isSubmitting
        }
        .distinctUntilChanged()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = false,
        )
}
```

这里的关键不是优化某个按钮，而是状态系统开始分层了。页面主状态仍然存在，但像“按钮是否可点”这种高频、局部、可投影的子状态，不必每次都让 UI 自己重新算。这样做既让 View 更轻，也能让 Flow 真正承担“整理状态出口”的职责，而不是只充当一个运输管道。

### 17. `SharingStarted` 其实是在决定上游该活多久

前面已经补过状态流、输入流和刷新流，但 Flow 在真实项目里还有一个经常被低估的决策点：上游到底该在没人看时停下来，还是继续活着。官方文档、Bennett 和 Socorro 都反复提到这层取舍，因为它直接影响资源占用和状态可见性。`SharingStarted` 不是一个装饰性参数，它本质上是在声明“这条热流该活多久”。

```kotlin
class TeamDashboardViewModel(
    repository: TeamRepository,
) : ViewModel() {

    val presence: StateFlow<TeamPresenceUiState> = repository.observePresence()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = TeamPresenceUiState.Loading,
        )

    val syncState: StateFlow<SyncUiState> = repository.observeCriticalSyncState()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.Eagerly,
            initialValue = SyncUiState.Unknown,
        )
}
```

这里有两个不同判断。在线成员状态只在页面可见时才值得持续维护，所以更适合 `WhileSubscribed`；关键同步状态则可能影响整块功能是否可用，所以可以更早启动并持续保留。只要把这层区别想清楚，`stateIn()` 和 `shareIn()` 的策略就不再是机械默认值，而会真正变成架构选择的一部分。

### 18. 实践任务

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
- 读者会更容易判断某段逻辑属于状态还是事件。
- 页面重建、返回、重新订阅时的重复消费问题会明显减少。

自检方式：

- 读者应能解释为什么 `StateFlow` 适合承接页面当前状态。
- 读者应能说出 `LiveData` 和 `Flow` 在生命周期协作上的一个关键差异。
- 读者应能指出当前页面里至少一个原本被错误建模为状态的事件。

调试提示：

- 页面旋转后又弹了一次消息，优先检查是否把事件塞进了 `UiState`。
- 页面不可见时仍在持续收集数据，优先检查是否缺少生命周期感知收集。
- UI 层如果同时拼接太多流，优先把整理逻辑收回 ViewModel。

### 19. 常见误区

- 把这一章理解成两个 API 的表面对比。
- 以为只要用了 `Flow`，页面状态设计就自然合理。
- 把一次性事件塞进稳定状态模型。
- 直接在 UI 层拼装多个数据流。

## 练习题

1. 概念理解题：稳定状态、一次性事件和数据流为什么必须先分开，才能正确理解 `LiveData`、`StateFlow` 和 `SharedFlow` 的分工？
2. 编码实现题：把一个页面里零散的可观察字段收束成单一 `UiState`，并为一次性动作补一条独立的 effect / event 通道。
3. 拓展思考题：如果项目当前大量使用 `LiveData`，你会如何规划向 `Flow` 的迁移，才能避免全项目同时硬切换？

## 小结

`LiveData` 与 `Flow` 真正要解决的，不是“谁更先进”，而是页面状态如何稳定地从上游流向 UI。`LiveData` 让 Android 页面层第一次拥有官方支持的生命周期感知状态容器；`Flow` 则把异步数据、状态转换和跨层协作统一进了 Kotlin 主线。对今天的新项目来说，`StateFlow` 往往是页面状态最自然的承载方式，但真正决定页面质量的，始终是状态建模、事件边界和生命周期收集这三件事。

## 参考资料

- 参考并改写自本地 PDF：`Clean Android Architecture`，LiveData、Flow 与状态边界相关章节。
- 参考并改写自本地 PDF：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，Flow、StateFlow 与响应式状态组织相关章节。
- 参考并改写自本地 PDF：Luca Vainigli，《Ultimate Android Design Patterns》(2025)，“LiveData, Flow, or StateFlow” 与 MVVM 状态管理相关章节。
- 参考并改写自本地 PDF：Guilherme Socorro，《Thriving in Android Development Using Kotlin》(2024)，`ChatViewModel`、`uiState` / `messages` 分流与 Compose `collectAsState()` 相关章节。

- Kotlin flows on Android：<https://developer.android.com/kotlin/flow>
- StateFlow and SharedFlow：<https://developer.android.com/kotlin/flow/stateflow-and-sharedflow>
- Collect flows safely in Android UI：<https://developer.android.com/kotlin/flow/stateflow-and-sharedflow#collect>
- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Kotlin Flow documentation：<https://kotlinlang.org/docs/flow.html>

