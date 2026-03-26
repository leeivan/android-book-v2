# Flow

如果说协程解决的是“异步任务怎样被组织”，那么 `Flow` 更进一步解决的是“异步结果怎样以持续数据流的方式被表达和组合”。很多读者第一次接触 Flow 时，会把它当成“会连续返回值的 suspend 函数”或者“协程版本的观察者模式”。这两种理解都能抓住一点表面，但都不够深入。Flow 真正的价值，在于它把一连串随时间变化的数据，用一种可组合、可取消、可变换的方式表达出来。

这一章和前面“LiveData 与 Flow”的页面状态章节不同，这里更关注 Flow 作为并发和数据流工具本身。你会看到它为什么特别适合描述数据库变化、用户输入流、网络轮询、去抖和多个来源合并，也会看到为什么它一旦用错，就会把原本清楚的异步关系弄得更难读。

## 学习目标

- 理解 Flow 真正适合表达的是“随时间变化的数据流”。
- 理解冷流、热流、背压直觉和常见操作符在工程中的意义。
- 理解 Flow 和协程、ViewModel、页面状态之间的关系。
- 学会判断什么时候该用 Flow，什么时候不必强行上 Flow。

## 前置知识

- 已理解协程和作用域的基本概念。
- 已接触页面状态或数据库观察流。

## 正文

### 1. 什么时候你真正需要 Flow

想象三个场景。

第一个场景是“刷新一次文章列表”。这更像一次性动作，`suspend` 函数就可能够用。

第二个场景是“持续观察 Room 中的任务列表变化”。这不是一次性动作，而是数据可能不断变化。

第三个场景是“用户输入搜索词，系统对输入做去抖，再结合数据库内容实时更新结果”。这里不仅有持续变化，还要组合多个来源。

只要进入第二、第三类场景，Flow 的价值就会非常明显。它解决的不是“拿一次结果”，而是“结果会持续变化，而且这些变化需要被组织”。

### 2. 冷流为什么是 Flow 最重要的直觉之一

Flow 默认是冷的，这意味着只有在被收集时，它才真正开始生产数据。这个特性非常重要，因为它决定了:

- 数据什么时候开始流动。
- 每个收集者是否触发一次新的执行。
- 某段逻辑到底是“共享状态”还是“重新计算过程”。

例如数据库查询流、网络请求封装的流，通常都很适合用冷流表达，因为它们本质上是“有人需要时再执行”。

如果这一点没理解清楚，后面一遇到重复收集、重复请求或多次执行，你就很难判断问题出在哪里。

### 3. Flow 为什么比“回调不断触发”更适合复杂数据变化

你当然可以用回调表达连续变化，但问题在于，一旦需要做节流、去抖、过滤、组合、重试或取消，回调代码很快就会变得凌乱。Flow 的优势在于，这些关系都可以被声明出来。

例如:

- 输入流可以 `debounce`。
- 多个来源可以 `combine`。
- 某些事件可以 `map` 成新的结构。
- 某些错误可以统一处理。

也就是说，Flow 不只是“连续发数据”，而是让数据变化本身具备可组合性。

### 4. Flow 最适合描述哪些来源

在 Android 中，Flow 特别适合这几类来源:

- Room 持续观察结果。
- 用户输入事件流。
- 内部状态变化流。
- 多个异步来源组合后的结果流。

它不一定总适合最简单的一次性请求。如果某个动作只是“点一下 -> 发一次请求 -> 回来更新一次状态”，有时 `suspend` 就足够了。真正成熟的判断不是“到处都用 Flow”，而是“只有持续变化和组合关系明显时，才让它发挥优势”。

### 5. 常见操作符背后真正解决的是什么

学习 Flow 时，最容易掉进“背操作符清单”的坑里。更有效的学习方式是，把操作符和问题配对起来。

`map` 解决的是数据形态转换。

`filter` 解决的是筛掉不关心的变化。

`combine` 解决的是多个来源一起决定结果。

`debounce` 解决的是输入过快导致的无意义高频触发。

`flatMapLatest` 解决的是“新任务来了，旧任务应该失效”的场景，例如搜索。

只要把操作符和它背后的问题绑定起来，Flow 就不会再像一份难背的函数表。

还有一类操作符，只有放到“上游发得太快，下游来不及处理”这个问题里，价值才会变得明显。Smyth 在 Flow 章节里把 `buffer()`、`conflate()`、`collectLatest()` 放到同一组里讲，本质上都是在处理背压：生产速度和消费速度不一致时，你想保留全部中间值，还是只保留最新值，还是一有新值就取消旧处理。Android 里最典型的场景不是数据库，而是输入联想、滚动预览、图片缩略图和进度刷新这类“新结果会迅速让旧结果失效”的 UI 数据流。

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    viewLifecycleOwner.lifecycleScope.launch {
        viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
            viewModel.thumbnailFlow
                .conflate()
                .collectLatest { thumbnail ->
                    previewRenderer.render(thumbnail)
                }
        }
    }
}
```

这段代码里，`conflate()` 表达的是“如果上游连着来了很多张缩略图，中间值可以被跳过，只保留较新的结果”；`collectLatest` 表达的是“如果上一张图还没渲染完，而更新的图又到了，就取消旧渲染，直接处理新图”。它们并不总该一起用，但都在回答同一个工程问题：当 UI 只关心最近状态时，旧中间值还值不值得完整处理。只要把这一点想清楚，背压就不再是抽象术语，而会回到非常具体的产品体验判断。

### 6. 一个更接近真实项目的例子: 搜索输入流

下面这个例子展示了 Flow 在“搜索输入 -> 去抖 -> 查询结果”场景中的典型价值:

```kotlin
class SearchViewModel(
    private val repository: ArticleRepository
) : ViewModel() {

    private val query = MutableStateFlow("")

    val uiState: StateFlow<SearchUiState> = query
        .debounce(300)
        .filter { it.isNotBlank() }
        .flatMapLatest { keyword ->
            repository.searchArticles(keyword)
        }
        .map { articles ->
            SearchUiState(
                query = query.value,
                isLoading = false,
                items = articles
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = SearchUiState(isLoading = true)
        )

    fun updateQuery(value: String) {
        query.value = value
    }
}
```

这个例子最关键的，不是链式调用本身，而是它清楚表达了数据关系:

- 输入会持续变化。
- 高频输入要去抖。
- 新关键词到来时，旧搜索要失效。
- 最终页面只消费统一状态。

### 7. Flow 与页面状态之间是什么关系

Flow 本身不是页面状态容器，但它很适合成为页面状态的上游。Repository 可以返回 Flow，ViewModel 再把这些流整理成 `StateFlow` 或其他适合 UI 消费的状态出口。

这条链路非常重要，因为它让页面不需要直接面对很多原始流。页面最理想的状态，仍然是消费“已经整理好的当前状态”，而不是自己去拼一堆数据流关系。

这也是 `StateFlow` 和 `SharedFlow` 需要被分开理解的原因。前者更适合承载“当前状态是什么”，强调始终有最新值；后者更适合表达“有一件事发生了”，例如一次性 effect、事件广播或多消费者信号。只要把这两类需求混在一起，页面就会很快陷入“状态像事件、事件又像状态”的混乱。

Socorro 在聊天页里没有让界面直接面对一组零散回调，而是把“会话头部信息”和“消息列表”拆成 `uiState` 与 `messages` 两个 `StateFlow` 出口。`loadChatInformation(id)` 先在 `Dispatchers.IO` 拉取初始会话，再回到主线程一次性写入 `_uiState` 和 `_messages`；页面最终消费的不是仓库、WebSocket 和本地缓存的细节，而是两个已经整理好的状态入口。这个例子很适合说明 Flow / StateFlow 在工程里的真正作用：它们不只是“会持续发值”的类型，更是把多个异步来源收束成稳定 UI 合约的方式。

对应的最小 Kotlin 结构可以写成：

```kotlin
data class ChatUiState(
    val title: String = "",
    val avatarUrl: String? = null
)

class ChatViewModel(
    private val repository: ChatRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    private val _messages = MutableStateFlow<List<MessageUi>>(emptyList())
    val messages: StateFlow<List<MessageUi>> = _messages.asStateFlow()

    fun loadChatInformation(id: String) {
        viewModelScope.launch(Dispatchers.IO) {
            val room = repository.getInitialChatRoom(id)
            withContext(Dispatchers.Main) {
                _uiState.value = room.toUiState()
                _messages.value = room.lastMessages.map { it.toUi() }
            }
        }
    }
}
```

这里的重点不是机械地拆成两个 `StateFlow`，而是让“页面整体状态”和“持续滚动变化的消息列表”各自有清楚出口，UI 收集时才不会重新拼装一堆来源关系。

如果把这条链路补完整，UI 侧的收集边界也应该写得同样明确：

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    viewLifecycleOwner.lifecycleScope.launch {
        viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
            launch {
                viewModel.uiState.collect { state ->
                    binding.toolbar.title = state.title
                }
            }

            launch {
                viewModel.messages.collect { messages ->
                    messagesAdapter.submitList(messages)
                }
            }
        }
    }
}
```

这一段代码经常被低估，但它其实正好说明了 Flow 的另一半价值。`repeatOnLifecycle(...)` 保证页面不可见时自动停止收集、可见时再恢复；两个 `collect` 被分别放进子 `launch`，是因为每个收集都是长生命周期操作，如果写在同一个协程里，前一个 `collect` 就会一直挂住，后一个根本执行不到。也就是说，Flow 不只是“上游怎么发数据”，还包括“下游怎样在正确生命周期里接数据”。

当上游的 `StateFlow` 边界已经清楚，下游的收集边界也写对时，Flow 才会真正体现出它的工程价值：数据变化路径清晰，生命周期行为明确，UI 只消费整理后的状态，而不是自己重新发明一套订阅逻辑。

再往前走一步，很多真实项目还会遇到一个拐点：上游来源根本不是 Flow，而是系统回调、WebSocket 监听器、SDK listener 或数据库以外的观察接口。这时最常用的桥接方式就是 `callbackFlow`。Socorro 在消息流封装里用它把监听器变成 `Flow<Message>`，而 Smyth 和 Wangereka 在更偏教学的例子里则反复强调：一旦你把回调桥接成流，就要同时把“如何开始监听”和“何时停止监听”写在同一个地方，否则内存泄漏和重复订阅很快就会出现。

下面这个网络状态监听例子，正好能把 `callbackFlow` 和 `stateIn` 放到一条链路里理解：

```kotlin
enum class NetworkStatus {
    Available,
    Unavailable
}

class ConnectivityRepository(
    private val connectivityManager: ConnectivityManager
) {
    fun observeNetworkStatus(): Flow<NetworkStatus> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(NetworkStatus.Available)
            }

            override fun onLost(network: Network) {
                trySend(NetworkStatus.Unavailable)
            }
        }

        connectivityManager.registerDefaultNetworkCallback(callback)

        val initialStatus = if (connectivityManager.activeNetwork != null) {
            NetworkStatus.Available
        } else {
            NetworkStatus.Unavailable
        }
        trySend(initialStatus)

        awaitClose {
            connectivityManager.unregisterNetworkCallback(callback)
        }
    }.distinctUntilChanged()
}

class SyncBannerViewModel(
    connectivityRepository: ConnectivityRepository
) : ViewModel() {

    val networkStatus: StateFlow<NetworkStatus> =
        connectivityRepository.observeNetworkStatus()
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.WhileSubscribed(5_000),
                initialValue = NetworkStatus.Unavailable
            )
}
```

这段代码最值得观察的不是语法，而是三个边界。第一，`callbackFlow` 只负责把回调世界翻译成 Flow 世界，不承担 UI 状态职责；第二，`awaitClose { ... }` 是这类桥接里绝对不能省的清理出口，否则 collector 结束后监听还会残留；第三，`stateIn(...)` 把原本“每收集一次就重新注册一次回调”的冷流，提升成了 `ViewModel` 持有的热状态。也就是说，`callbackFlow` 解决的是“怎么接进来”，`stateIn` 解决的是“接进来之后谁来长期持有和共享”。只要把这两个问题分开想，Flow 在真实项目里就会清楚很多。

Smyth 在 SharedFlow 教程里还专门提醒了另一个很常见的误区：同一个冷流如果会被多个 collector 同时消费，而你又没有先把它共享化，上游生产逻辑就会被重复执行。例如一个 socket 事件流同时驱动 badge、snackbar 和列表刷新，如果三个地方都各自直接 collect 原始 Flow，就可能发生重复建连、重复解析，甚至彼此看见的还是三条不完全一致的时间线。遇到这种需求时，`shareIn()` 往往比继续堆 `stateIn()` 更准确，因为你要共享的是“事件流本身”，不是某个当前状态。

```kotlin
class InboxSyncViewModel(
    repository: InboxRepository
) : ViewModel() {

    val syncEvents: SharedFlow<SyncEvent> =
        repository.observeSyncSocket()
            .shareIn(
                scope = viewModelScope,
                replay = 1,
                started = SharingStarted.WhileSubscribed(5_000)
            )
}
```

这段代码的重点不是把所有 Flow 都改成热流，而是把语义分清。`stateIn()` 更适合“页面任何时刻都需要一个当前值”的场景；`shareIn()` 更适合“上游代价不低、但多个下游想共享同一条事件时间线”的场景；`MutableSharedFlow` 则更适合自己主动发射事件。只要把这三类问题拆开，Flow 就不再只是“冷流、热流、StateFlow、SharedFlow 的名词表”，而会重新回到工程判断：我到底要共享状态，还是共享事件生产过程？

Bennett 在 UDF / side effect 的讨论里还指出了另一个很容易混淆的边界：有些信息不是“当前状态”，而是“一次性要通知控制器去做的动作”，例如导航、弹 toast、打开系统分享面板。这类东西如果错误地塞进 `StateFlow`，新的 collector 一订阅就会把旧 effect 再吃一遍；如果直接塞进普通冷流，又会因为重新收集而把历史动作重新执行一遍。所以很多团队会把这种一次性 effect 单独放到 `Channel.receiveAsFlow()` 这一条通道里。

```kotlin
sealed interface ArticleEffect {
    data class OpenArticle(val articleId: String) : ArticleEffect
    data class ShowMessage(val text: String) : ArticleEffect
}

class ArticleListViewModel : ViewModel() {
    private val _effect = Channel<ArticleEffect>(Channel.BUFFERED)
    val effect: Flow<ArticleEffect> = _effect.receiveAsFlow()

    fun onArticleClicked(articleId: String) {
        viewModelScope.launch {
            _effect.send(ArticleEffect.OpenArticle(articleId))
        }
    }
}
```

这个例子最想帮读者建立的，不是“到底该永远用 Channel 还是 SharedFlow”，而是更底层的判断：状态和 effect 不是同一种东西。状态强调“此刻页面是什么样”；effect 强调“有一件一次性的动作需要被控制器消费”。只要这两类通道混在一起，Flow 再现代，页面行为也会很快变得不可预测。

Big Nerd Ranch 在 `PhotoGalleryViewModel` 里把 `storedQuery` 和 `isPolling` 分开收集，已经足够说明“一页 UI 往往不只有一个上游”。如果想把这类多源数据进一步收成一份稳定的 UI 合约，`combine` 往往是最直接的工具。

```kotlin
data class PhotoGalleryUiState(
    val query: String = "",
    val isPolling: Boolean = false,
    val images: List<GalleryItem> = emptyList()
)

class PhotoGalleryViewModel(
    private val preferencesRepository: PreferencesRepository,
    private val galleryRepository: GalleryRepository
) : ViewModel() {

    val uiState: StateFlow<PhotoGalleryUiState> =
        combine(
            preferencesRepository.storedQuery,
            preferencesRepository.isPolling
        ) { query, isPolling ->
            query to isPolling
        }
            .flatMapLatest { (query, isPolling) ->
                galleryRepository.observeGallery(query)
                    .map { images ->
                        PhotoGalleryUiState(
                            query = query,
                            isPolling = isPolling,
                            images = images
                        )
                    }
            }
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.WhileSubscribed(5_000),
                initialValue = PhotoGalleryUiState()
            )
}
```

这段代码最适合拿来讲“多源收束”这件事。`storedQuery` 和 `isPolling` 都是持续变化的状态来源，它们任何一个变化，页面都应该重新得到一份新的 `PhotoGalleryUiState`。如果把这类拼装工作放到 Fragment 里，页面很快就会变成“自己订阅两三个流，再手动拼一遍状态”的控制器；而把它收进 `ViewModel` 之后，UI 依然只面对一个稳定出口。换句话说，`combine` 真正解决的不是“语法更炫”，而是“多条时间线怎样被整理成一份可消费的当前事实”。

### 8. 什么情况下不必强行上 Flow

Flow 很强，但不是所有异步问题都需要它。以下场景通常不必硬用 Flow:

- 一次性动作，没有持续变化。
- 没有组合关系，只是普通请求。
- 引入 Flow 只会让简单流程更绕。

如果只是为了“显得现代”而到处上 Flow，代码很快会从“清晰的状态流”退化成“到处在收集的神秘数据河流”。

### 9. 实践任务

起点条件:

- 已有一个存在持续数据变化的页面，例如搜索、过滤列表或数据库观察页面。

步骤:

1. 找出页面里一个真正“随时间变化”的数据来源。
2. 判断它是否适合用 Flow，而不是一次性结果。
3. 选一个最关键的问题，例如去抖、合并、取消旧任务或过滤无效值。
4. 用合适的 Flow 操作符表达这个问题。
5. 把最终结果收束为页面更容易消费的状态。

预期结果:

- 读者会把 Flow 看成数据变化关系的表达工具。
- 读者应能把操作符和具体问题联系起来。
- 读者会更自然地区分“原始数据流”和“页面最终状态”。

自检方式:

- 读者应能解释 Flow 为什么特别适合持续变化的数据。
- 读者应能判断某个场景需不需要 `flatMapLatest` 或 `debounce`。
- 读者应能说明为什么页面不应直接拼装过多原始流。

调试提示:

- 如果一个简单一次性请求被写成很长的 Flow 链，优先问自己是否过度设计了。
- 如果重复收集导致重复执行，优先先判断这是不是冷流带来的自然结果。
- 如果页面层直接组合太多流，优先把整理逻辑收回 ViewModel。

### 10. 常见误区

- 把 Flow 当成所有异步场景的默认答案。
- 把操作符当清单背，却说不出在解决什么问题。
- 页面层直接处理太多原始流。
- 不理解冷流，导致重复执行时无法排查。

## 小结

Flow 在 Android 中真正提供的，是一种表达“持续变化数据关系”的方式。它让输入、数据库变化、异步结果和状态转换变得可组合、可取消、可推理。只要理解它真正适合的是“流”，而不是所有异步动作，Flow 就会成为现代 Android 数据与状态链路里非常自然的一环。

## 参考资料

- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，第 12 章中 `Flow` / `StateFlow` 与单向数据流相关部分。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，状态流、UI 状态组织与数据流建模相关章节。
- 参考并改写自：Guilherme Socorro，《Thriving in Android Development Using Kotlin》(2024)，`StateFlow`、聊天状态组织与异步消息链路相关章节。
- 参考并改写自：Humphrey Wangereka，《Mastering Kotlin for Android 14》(2024)，`StateFlow`、`collectAsStateWithLifecycle()` 与 `stateIn()` 相关章节。
- 参考并改写自：Neil Smyth，《Jetpack Compose 1.7 Essentials》(2025)，`shareIn()`、热流共享与 Flow 生命周期相关章节。

- Kotlin flows on Android: <https://developer.android.com/kotlin/flow>
- StateFlow and SharedFlow: <https://developer.android.com/kotlin/flow/stateflow-and-sharedflow>
- Kotlin Flow guide: <https://kotlinlang.org/docs/flow.html>

