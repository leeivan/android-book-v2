# ViewModel

几乎每个 Android 初学者都会在某个时刻写出这样一个页面：列表数据放在 Fragment 里，搜索关键字也放在 Fragment 里，点击刷新就直接在页面里发请求。它在第一次运行时看起来没有问题，直到你旋转屏幕、切到后台再回来，或者让页面和另一个页面共享部分状态。这个时候，原本“够用”的写法会很快暴露出问题：状态丢了，请求重复发了，页面类越来越重，谁在更新什么也越来越说不清。

ViewModel 正是为这种场景出现的。它不是为了让代码看起来更现代，也不只是为了“跨旋转保存对象”。它的真正价值，是给屏幕级状态和与屏幕直接相关的逻辑找到一个比 Activity 或 Fragment 更稳定的承载点。本章就从这个现实问题出发，讲清楚 ViewModel 为什么存在、应该承接什么、不该承接什么，以及它怎样和 `StateFlow`、`SavedStateHandle`、`viewModelScope` 一起组成现代 Android 页面层的骨架。

## 学习目标

- 理解 ViewModel 作为屏幕级状态持有者的核心职责。
- 理解 ViewModel 与 Activity、Fragment、Navigation、Compose 的作用域关系。
- 理解 ViewModel、Repository 和纯 UI 状态之间的边界。
- 学会用 `uiState`、`viewModelScope` 和 `SavedStateHandle` 组织一个最小页面。

## 前置知识

- 已理解 Android 中 MVVM 的职责主线。
- 已理解页面实例并不是长期可靠的状态容器。

## 正文

### 1. 一个没有 ViewModel 的页面，会怎样慢慢失控

先看一个很常见的页面：新闻列表页打开后要加载远程数据，用户可以输入搜索词，可以切换排序方式，还可能在失败时点击重试。如果这些状态都直接放在 Fragment 里，刚开始似乎也能工作。但随着功能增加，你会越来越频繁地遇到几个问题。

第一个问题是页面实例不稳定。配置变化、分屏、多窗口、语言切换，都会让 Activity 或 Fragment 重建。第二个问题是状态来源混乱。列表内容、加载状态、搜索词、错误提示、分页位置，很容易散落在多个字段里。第三个问题是页面承担了过多工作。它既要渲染 UI，又要发请求、拼数据、判断错误、做重试，还要处理生命周期。

ViewModel 的意义，就在于把“屏幕真正关心的状态和逻辑”从页面实例里拿出来。这样页面负责显示和转发用户意图，ViewModel 负责维护当前屏幕状态、触发异步动作、把结果组织成 UI 能消费的形式。这不是教条式分层，而是在解决一个非常现实的问题：页面实例会反复变化，但屏幕状态不应该每次都跟着从零开始。
Big Nerd Ranch 在 `GeoQuiz` 里演示 ViewModel 的方式非常适合入门：一开始题目索引 `currentIndex` 直接放在 `MainActivity`，旋转屏幕后状态丢失；接着把它挪进 `QuizViewModel`，用 `by viewModels()` 让同一份屏幕状态跨配置变化保留下来；最后再用 `SavedStateHandle` 只保存 `currentIndex` 这种“恢复界面所必需的最小信息”。这个案例特别值得借鉴，因为它没有一上来就搬出复杂架构，而是让读者直接看到 ViewModel 解决的就是一个非常具体的屏幕状态问题。

### 2. 什么叫“屏幕级状态持有者”

Android 官方现在把 ViewModel 放在 state holder 语境里理解，这是很准确的。所谓屏幕级状态持有者，可以先把它想成“站在页面前面的一层控制台”。UI 不直接面对数据库、网络接口和各种零散变量，而是面对一个更稳定的状态出口。

这里最重要的不是定义，而是边界。ViewModel 最适合承接的是“某个屏幕在一段交互过程中持续关心的状态”。例如列表页的 `Loading / Content / Empty / Error`，搜索页的当前关键字和筛选条件，表单页的提交中状态和校验结果，详情页当前选中的 tab 或 section。这些东西本质上都属于屏幕语义，而不是单个控件语义。

与之对应，ViewModel 不适合承接两类东西。第一类是太底层、太全局的状态，例如数据库实体存储、整个应用的基础设施对象，这些更适合数据层或依赖注入容器。第二类是太局部、太短命的 UI 状态，例如某个按钮按下时的涟漪效果、一个输入框当前是否获取焦点、某个下拉菜单是否短暂展开。这些通常应留在 UI 层本地管理。

### 3. 作用域判断，决定了你的状态到底跟谁走

很多 ViewModel 相关问题并不是“不会写 ViewModel”，而是没想清楚它到底应该跟谁绑定。一个 ViewModel 可以绑定到 Activity，可以绑定到 Fragment，也可以绑定到某个 Navigation graph 或 Compose 当前的 `ViewModelStoreOwner`。作用域一旦判断错，后面的体验就会直接出问题。

举个最常见的例子。假设一个搜索页和搜索结果页属于同一个导航流程，而且你希望它们共享同一份搜索词和筛选条件。这种状态更适合绑定到共同的导航作用域或共同宿主，而不是分别绑在两个页面自己身上。相反，如果两个列表页虽然长得像，但它们的数据完全独立，就不该错误地共用同一个 Activity 级 ViewModel。

所以理解 ViewModel，不能只停留在“它比 Activity 活得久”。更关键的问题是：它到底应该跟哪个屏幕语义一起存活。只要这个问题想清楚，很多共享状态和返回后状态丢失的问题都会自然少掉。
Big Nerd Ranch 后面在 `CriminalIntent` 里又给了第二层例子：`CrimeListFragment` 通过 `private val crimeListViewModel: CrimeListViewModel by viewModels()` 拿到和当前 Fragment 作用域绑定的 ViewModel。这个例子很有价值，因为它把“Activity 级保留状态”和“Fragment 级屏幕状态”区分开了。也就是说，ViewModel 不是只会“跨旋转保存变量”，它真正要回答的是：这份状态到底属于整个宿主流程，还是只属于当前这一个内容页面。

### 4. ViewModel 真正做的，不只是保存变量

如果你把 ViewModel 只当作“多存几个字段”的地方，那么页面的复杂度其实不会真正下降。现代 Android 项目里，ViewModel 更重要的职责是把用户意图转成状态变化。用户点击刷新、输入关键字、切换排序、重试加载，这些动作不应该在 Fragment 或 Compose 页面里直接展开成一长串逻辑，而更适合收束进 ViewModel。

这也是为什么现在常见的页面结构都会围绕 `uiState` 和事件展开。页面把点击和输入事件传给 ViewModel，ViewModel 调用 Repository 或 UseCase，把结果解释成状态，再把状态暴露给 UI。只要这条链路建立起来，UI 层就会明显变轻，因为它终于只需要回答一件事：根据当前状态，该显示什么。

这里可以先把思路固定成一句话：ViewModel 不是“帮页面多活一会儿的类”，而是“帮页面把状态和逻辑稳定组织起来的地方”。

### 5. 一个更像真实项目的最小页面结构

假设我们要做一个文章列表页。页面打开时会加载文章，失败时显示错误，成功时显示列表，空结果时显示空态。页面本身并不想知道 Retrofit 返回了什么，也不想自己处理 `IOException` 或业务错误码。它只想知道：现在应该显示哪个状态。

这种情况下，ViewModel 最自然的写法是暴露一个统一的状态模型，而不是暴露零散字段：

```kotlin
data class ArticleListUiState(
    val isLoading: Boolean = false,
    val articles: List<Article> = emptyList(),
    val errorMessage: String? = null
)

class ArticleListViewModel(
    private val repository: ArticleRepository,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleListUiState())
    val uiState: StateFlow<ArticleListUiState> = _uiState

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            when (val result = repository.refreshArticles()) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            articles = result.data,
                            errorMessage = null
                        )
                    }
                }

                is ApiResult.Empty -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            articles = emptyList(),
                            errorMessage = null
                        )
                    }
                }

                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = "加载失败，请稍后重试"
                        )
                    }
                }
            }
        }
    }
}
```

这段代码可以放在页面对应的 ViewModel 文件里，例如 `ArticleListViewModel.kt`。它最值得观察的地方不是语法，而是职责边界。页面层不再自己解释网络结果，Repository 不再直接面对 UI 控件，ViewModel 则负责把“结果”翻译成“屏幕状态”。运行后，你应该能在页面里稳定地看到加载、内容、空态和失败之间的切换，而不是只能拿到一堆 DTO 再临时拼装。

### 6. `SavedStateHandle` 和 `viewModelScope`，分别补上了哪块能力

ViewModel 本身已经比页面实例稳定，但它仍然主要活在内存里。如果进程被系统回收，纯内存状态还是会消失。这就是 `SavedStateHandle` 的位置。它更像给 ViewModel 提供了一小块“可以恢复的页面关键状态”，适合保存搜索词、筛选值、当前 tab、尚未提交但值得保留的关键输入，而不是拿来替代数据库。

`viewModelScope` 则解决了另一块问题：异步工作应该跟谁一起存活。页面重建时，加载任务不该因为页面实例换了就立刻重来；但当整个 ViewModel 真的结束时，这些任务又应该跟着一起取消。`viewModelScope` 让这条生命周期关系变得自然，也让 Flow、Repository 和 UI state 更容易接起来。

所以可以把这三者的关系记成一句更实用的话：ViewModel 负责持有屏幕状态，`SavedStateHandle` 负责补关键恢复，`viewModelScope` 负责让异步工作和屏幕状态站在同一条生命周期线上。

如果把这条边界再压实一点，可以得到一个很实用的规则：凡是“重新进入这个屏幕后，用户理应继续看到”的轻量关键参数，才值得进 `SavedStateHandle`；凡是“应用彻底关闭后仍要长期存在”的数据，则应进入数据库、DataStore 或其他持久层。`SavedStateHandle` 最容易被误用成半吊子存储层，这一点必须提前防住。

《Thriving in Android Development Using Kotlin》里的 `ChatViewModel` 则把这条边界落成了很具体的工程形态：它通过构造函数接住 `RetrieveMessages`、`SendMessage`、`DisconnectMessages` 和 `GetInitialChatRoomInformation`，内部维护 `_messages` 与 `_uiState` 两个 `MutableStateFlow`，再在 `viewModelScope.launch(Dispatchers.IO)` 中先拉取聊天初始化信息，再开始收集消息流。这个结构很值得参考，因为它说明 ViewModel 最合适做的是“接住屏幕初始化、编排用例、向外暴露状态”，而不是自己去持有 WebSocket、REST 客户端或数据库细节。

如果把 `SavedStateHandle`、屏幕状态和一次性事件放进同一个最小例子里，结构通常会长成这样：

```kotlin
sealed interface ArticleListEvent {
    data class OpenArticle(val id: String) : ArticleListEvent
    data class ShowSnackbar(val message: String) : ArticleListEvent
}

class ArticleListViewModel(
    private val repository: ArticleRepository,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val query: StateFlow<String> =
        savedStateHandle.getStateFlow("query", "")

    private val _events = MutableSharedFlow<ArticleListEvent>()
    val events: SharedFlow<ArticleListEvent> = _events.asSharedFlow()

    val uiState: StateFlow<ArticleListUiState> = query
        .flatMapLatest { keyword -> repository.observeArticles(keyword) }
        .map { articles ->
            ArticleListUiState(
                isLoading = false,
                articles = articles,
                errorMessage = null
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ArticleListUiState(isLoading = true)
        )

    fun updateQuery(value: String) {
        savedStateHandle["query"] = value
    }

    fun onArticleClick(id: String) {
        viewModelScope.launch {
            _events.emit(ArticleListEvent.OpenArticle(id))
        }
    }
}
```

这段代码正好把三个常被混淆的边界拆开了。第一，`query` 是“重新回到这个屏幕后用户理应继续看到”的轻量关键状态，所以它值得进入 `SavedStateHandle`。第二，真正长期驱动页面显示的是 `uiState`，它描述的是“现在页面长什么样”。第三，点击文章后的跳转不是页面常驻状态，而是一次性事件，所以它被单独放进 `SharedFlow`。只要把这三层分清，ViewModel 就不会再被迫把“可恢复参数”“稳定状态”“瞬时动作”全揉进一个字段里。

### 7. ViewModel 最容易越界的地方

真正写项目时，ViewModel 很容易从“页面状态持有者”变成“什么都往里塞的地方”。最常见的越界有三种。第一种是直接持有 `Activity`、`Fragment`、`View` 或 `Context`，这通常会把生命周期边界搅乱，甚至带来内存泄漏风险。第二种是把所有数据层和业务层细节都机械搬进 ViewModel，结果只是把原来的胖页面换成了胖 ViewModel。第三种是反过来太保守，什么都不敢放进去，导致页面仍然自己发请求、自己处理状态。

更稳妥的判断方式是：只要某段逻辑是在回答“这个屏幕现在应该处于什么状态”，通常就适合放在 ViewModel；只要某段逻辑是在回答“这个应用的数据从哪里来、怎样存、怎样同步”，通常就更适合放在 Repository 或数据层；只要某段逻辑是在回答“某个控件怎么展开、动画怎么做、键盘怎么弹”，通常就留在 UI 层。

这套边界不是为了让每个类看起来干净，而是为了让问题真正回到最适合被解决的位置。

Big Nerd Ranch 在这里给过一个特别值得直接记住的提醒：Activity 或 Fragment 可以持有 ViewModel，但 ViewModel 不应该反过来持有 Activity、Fragment 或 View 的引用。原因不是抽象洁癖，而是生命周期事实本身。ViewModel 会跨配置变化继续活着，旧页面实例却会被销毁；如果 ViewModel 留着旧页面引用，就既会泄漏旧实例，也可能在后续状态更新时操作一块已经失效的界面。也因此，`onCleared()` 真正该做的是取消观察、断开连接、清理与当前屏幕绑定的资源，而不是再去碰 UI。

### 8. 把轻量可恢复参数直接建成 `StateFlow`，会比手动同步更稳

Big Nerd Ranch 在 `GeoQuiz` 里保存的只是 `currentIndex`，而不是整题库；这个例子最值得记住的地方，不是 API 名字，而是“只保存最少且必须恢复的信息”。放到今天更常见的页面里，这些信息往往是搜索词、当前 tab、筛选条件，而不是整个列表结果。

```kotlin
enum class ArticleTab { ALL, BOOKMARKED }

data class ArticleFeedUiState(
    val isLoading: Boolean = false,
    val selectedTab: ArticleTab = ArticleTab.ALL,
    val articles: List<Article> = emptyList(),
)

class ArticleFeedViewModel(
    private val repository: ArticleRepository,
    private val savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val query = savedStateHandle.getStateFlow("query", "")
    private val selectedTab = savedStateHandle.getStateFlow(
        key = "selected_tab",
        initialValue = ArticleTab.ALL,
    )

    val uiState: StateFlow<ArticleFeedUiState> = combine(
        query,
        selectedTab,
    ) { keyword, tab ->
        keyword to tab
    }
        .flatMapLatest { (keyword, tab) ->
            repository.observeArticles(keyword = keyword, tab = tab)
                .map { articles ->
                    ArticleFeedUiState(
                        isLoading = false,
                        selectedTab = tab,
                        articles = articles,
                    )
                }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ArticleFeedUiState(isLoading = true),
        )

    fun updateQuery(value: String) {
        savedStateHandle["query"] = value
    }

    fun selectTab(tab: ArticleTab) {
        savedStateHandle["selected_tab"] = tab
    }
}
```

这里真正值得读者学走的有两点。第一，`SavedStateHandle` 存的是“重新回来时还应该记得什么”，所以只保留关键轻量参数，不保留大对象和长期数据；第二，`getStateFlow()` 让这些参数从一开始就能自然参与 `combine`、`flatMapLatest` 和 `stateIn` 这条现代状态链，而不必再靠手动同步多个字段。只要这条线立住，ViewModel 就更像一个屏幕状态骨架，而不是一堆临时变量仓库。

### 9. SavedStateHandle 的另一个好处，是状态恢复可以被直接测试

Big Nerd Ranch 在 `QuizViewModel` 里不只演示了 `SavedStateHandle` 的用法，还顺手展示了它为什么更容易测试。因为状态恢复逻辑不再分散在 Activity 的回调里，而是被收回到 ViewModel 构造和属性计算中，你就可以直接用一个带初始值的 `SavedStateHandle` 去验证“恢复后应该看到什么”。

```kotlin
class ArticleFeedViewModelTest {

    @Test
    fun restores_selected_tab_from_saved_state() = runTest {
        val handle = SavedStateHandle(
            mapOf("selected_tab" to ArticleTab.BOOKMARKED)
        )
        val viewModel = ArticleFeedViewModel(
            repository = FakeArticleRepository(),
            savedStateHandle = handle,
        )

        assertEquals(ArticleTab.BOOKMARKED, handle.get<ArticleTab>("selected_tab"))
        assertEquals(
            ArticleTab.BOOKMARKED,
            viewModel.uiState.value.selectedTab,
        )
    }
}
```

这里最值得学走的不是测试语法，而是结构收益。只要关键恢复状态被放进 ViewModel 和 `SavedStateHandle`，你就不必再启动完整页面去验证旋转或进程恢复后的行为。状态恢复一旦可测，ViewModel 就不再只是“理论上更稳”，而是能在开发阶段直接把很多页面级 bug 提前拦下来。

### 10. 多个页面共享同一份状态时，要共享 ViewModel 作用域，而不是退回单例

Big Nerd Ranch 在多 Fragment 协作页里一直提醒一个边界：多个页面如果在服务同一条业务流，应该共享同一份屏幕级状态，而不是各自拷贝一份，更不该为了图省事退回全局单例。放到今天更常见的导航图里，这意味着编辑页、预览页、确认页如果本质上都在操作同一份草稿，就应该共享同一个导航图作用域下的 ViewModel。

```kotlin
@Composable
fun ArticleEditorRoute(
    navController: NavHostController,
    onOpenPreview: () -> Unit,
) {
    val parentEntry = remember(navController) {
        navController.getBackStackEntry("article_editor_graph")
    }
    val viewModel: ArticleEditorViewModel = hiltViewModel(parentEntry)
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    ArticleEditorScreen(
        uiState = uiState,
        onTitleChanged = viewModel::updateTitle,
        onBodyChanged = viewModel::updateBody,
        onOpenPreview = onOpenPreview,
    )
}

@Composable
fun ArticlePreviewRoute(
    navController: NavHostController,
    onPublish: () -> Unit,
) {
    val parentEntry = remember(navController) {
        navController.getBackStackEntry("article_editor_graph")
    }
    val viewModel: ArticleEditorViewModel = hiltViewModel(parentEntry)
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    ArticlePreviewScreen(
        draft = uiState.draft,
        onPublish = {
            viewModel.publish()
            onPublish()
        },
    )
}
```

这段代码真正讲清的是“共享状态”不等于“全局状态”。`ArticleEditorViewModel` 只跟 `article_editor_graph` 这一段业务流共存，编辑页和预览页共享同一份草稿，但离开这条导航流后它就会自然释放。这样既避免了页面之间各写各的临时状态副本，也避免了用单例把局部编辑态误抬升成全局应用状态。对 ViewModel 来说，作用域判断始终比“类放在哪个包里”更重要。

### 11. 把导航参数验证收在 ViewModel 边界，页面会更轻也更稳

Big Nerd Ranch 在 `GeoQuiz` 和 `CriminalIntent` 系列例子里一直提醒一个朴素原则：页面应该尽早把“我到底要显示哪条数据”这件事确定下来，而不是让这个判断在多个回调和多个页面层函数之间来回漂移。放到今天更常见的 Navigation 和 Compose 页面里，一个很稳的做法是把导航参数验证直接收进 ViewModel 构造边界，让页面只负责把作用域和入口搭起来。

```kotlin
@HiltViewModel
class ArticleDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: ArticleRepository,
) : ViewModel() {

    private val articleId: Long = checkNotNull(
        savedStateHandle["article_id"]
    )

    val uiState: StateFlow<ArticleDetailUiState> = flow {
        emit(ArticleDetailUiState(isLoading = true))
        val article = repository.getArticle(articleId)
        emit(
            ArticleDetailUiState(
                isLoading = false,
                article = article,
            )
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ArticleDetailUiState(isLoading = true),
    )
}
```

这段代码的价值，不只是少写了一次参数传递，而是“入口验证”终于被收到了状态持有层。页面不再需要先判断参数有没有、再决定要不要发请求、再把错误转成各种临时 UI 分支；ViewModel 从一开始就知道自己服务的是哪条数据，也能围绕这个前提组织后续状态。只要导航参数确实属于屏幕身份的一部分，这种边界往往会让页面层和状态层都更稳。

### 12. 首次加载和重试最好做成显式入口，而不是在 `init` 里偷跑很多次

Socorro 和 Bennett 在实际项目里都更倾向于把“首次加载”和“用户重试”当成显式动作，而不是把一切都塞进 `init { ... }` 里偷偷开始。原因不是写法偏好，而是页面恢复、重复进入、作用域复用和测试都会被这种差异直接影响。只要 ViewModel 一初始化就无条件发起请求，后面很容易遇到“重复创建时重复加载”“用户重试和首次加载逻辑散在两处”的问题。

```kotlin
@HiltViewModel
class ArticleTimelineViewModel @Inject constructor(
    private val repository: ArticleRepository,
    private val savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private var loadJob: Job? = null

    private val _uiState = MutableStateFlow(ArticleTimelineUiState())
    val uiState: StateFlow<ArticleTimelineUiState> = _uiState.asStateFlow()

    fun loadIfNeeded() {
        if (savedStateHandle["has_loaded"] == true) return
        refresh(force = false)
    }

    fun retry() {
        refresh(force = true)
    }

    private fun refresh(force: Boolean) {
        if (!force && loadJob?.isActive == true) return

        loadJob = viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            runCatching { repository.getTimeline() }
                .onSuccess { articles ->
                    savedStateHandle["has_loaded"] = true
                    _uiState.update {
                        it.copy(isLoading = false, items = articles)
                    }
                }
                .onFailure {
                    _uiState.update {
                        it.copy(isLoading = false, errorMessage = "加载失败")
                    }
                }
        }
    }
}
```

这段代码的价值，在于首次加载、主动重试和防重入终于被收成了一组明确入口。页面可以在合适的生命周期里调用 `loadIfNeeded()`，错误态按钮可以显式触发 `retry()`，而 ViewModel 自己也能防止并发重复加载。只要这一层入口清楚，ViewModel 就不再只是“保存状态的地方”，而会更像一个真正可控的屏幕状态持有者。

### 13. 大屏幕状态可以投影成多个只读子状态，别让 UI 自己到处 `map`

Bennett 在大页面和 Compose 屏幕组织里常做一个很实用的切分：屏幕仍然可以有一份主 `uiState`，但如果头部、表单区、预览区分别只关心状态的一小部分，就不要让每个 UI 片段自己临时去 `map` 原始状态。更稳的做法，是在 ViewModel 里直接投影出几个只读子状态，让 UI 消费它该看的那一份结果。

```kotlin
data class EditorHeaderUiState(
    val title: String,
    val canPublish: Boolean,
)

data class EditorPreviewUiState(
    val title: String,
    val content: String,
)

class ArticleEditorViewModel(
    private val repository: ArticleRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleEditorUiState())
    val uiState: StateFlow<ArticleEditorUiState> = _uiState.asStateFlow()

    val headerState: StateFlow<EditorHeaderUiState> = uiState
        .map { state ->
            EditorHeaderUiState(
                title = state.title,
                canPublish = state.title.isNotBlank() && state.content.isNotBlank(),
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = EditorHeaderUiState("", false),
        )

    val previewState: StateFlow<EditorPreviewUiState> = uiState
        .map { state ->
            EditorPreviewUiState(
                title = state.title,
                content = state.content,
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = EditorPreviewUiState("", ""),
        )
}
```

这段代码真正收紧的是“状态投影的责任”。View 仍然很轻，因为它只拿自己需要的 `headerState` 或 `previewState`；而状态投影逻辑又没有散落到多个 UI 片段里。对 ViewModel 来说，这也是一种更成熟的状态组织方式：主状态是一份，投影出口可以有多份，但映射职责仍然留在状态持有者这里。

### 14. 当页面动作越来越多时，把公开 API 收成单一入口会更稳

前面已经谈过状态持有和显式加载入口，但大型页面还会遇到另一个常见问题：公开方法越来越多。`updateTitle()`、`updateBody()`、`retry()`、`saveDraft()`、`publish()`、`delete()` 这些方法散着长下去以后，ViewModel 的对外接口会慢慢变成新的混乱源。Bennett 和很多现代状态容器写法里都会把这一层再收一次：让公开 API 尽量回到一个动作入口，内部再根据动作分流处理。

```kotlin
sealed interface ArticleEditorAction {
    data class TitleChanged(val value: String) : ArticleEditorAction
    data class BodyChanged(val value: String) : ArticleEditorAction
    data object SaveDraftClicked : ArticleEditorAction
    data object PublishClicked : ArticleEditorAction
}

class ArticleEditorViewModel(
    private val repository: ArticleRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleEditorUiState())
    val uiState: StateFlow<ArticleEditorUiState> = _uiState.asStateFlow()

    fun onAction(action: ArticleEditorAction) {
        when (action) {
            is ArticleEditorAction.TitleChanged -> {
                _uiState.update { it.copy(title = action.value) }
            }
            is ArticleEditorAction.BodyChanged -> {
                _uiState.update { it.copy(content = action.value) }
            }
            ArticleEditorAction.SaveDraftClicked -> saveDraft()
            ArticleEditorAction.PublishClicked -> publish()
        }
    }

    private fun saveDraft() {
        viewModelScope.launch { repository.saveDraft(uiState.value.title, uiState.value.content) }
    }

    private fun publish() {
        viewModelScope.launch { repository.publish(uiState.value.title, uiState.value.content) }
    }
}
```

这里真正收紧的是 ViewModel 的公开边界。页面只知道自己在发送什么动作，而不必跟着 ViewModel 的内部方法数量一起膨胀。对这一章来说，这也是 ViewModel 成熟后的一个自然演进：它不只是状态存放处，还应该有一条足够清楚的动作入口。

### 15. 实践任务

起点条件：

- 已有一个包含列表、搜索或表单状态的页面。
- 页面里至少存在一次异步请求或一次状态切换。

步骤：

1. 写下这个页面当前有哪些状态，例如加载中、内容、空态、失败、搜索词、当前筛选值。
2. 判断哪些状态属于“屏幕级”，哪些只是瞬时 UI 细节。
3. 为屏幕级状态定义一个统一的 `UiState` 数据类。
4. 把页面中的一次异步操作迁移到 ViewModel 的 `viewModelScope` 中。
5. 检查页面代码里是否还直接持有请求结果、错误解释或加载态切换逻辑。
6. 如果页面存在搜索词、tab 或筛选值，再判断它是否值得进入 `SavedStateHandle`。

预期结果：

- 页面类会明显变轻，状态来源更集中。
- 读者应能说清楚当前页面到底有哪些状态，以及它们为什么要交给 ViewModel。
- 配置变化后，关键页面状态会比原来更稳定。

自检方式：

- 读者应能解释：这个页面的哪些状态属于 ViewModel，哪些只属于局部 UI。
- 读者应能确认：ViewModel 没有直接持有 `Activity`、`Fragment`、`View` 或生命周期对象。
- 读者应能说明：为什么这个页面的异步动作更适合放在 `viewModelScope`，而不是直接写在页面里。

调试提示：

- 如果页面仍然自己发请求和切换加载态，说明 ViewModel 还没有真正成为状态持有者。
- 如果 ViewModel 里开始出现大量数据库、网络和框架细节，先回头检查 Repository 边界。
- 如果你什么状态都往 `SavedStateHandle` 里塞，说明它已经被误当成持久化存储了。

### 16. 常见误区

- 把 ViewModel 理解成“比 Activity 活得久一点的对象”。
- 让 ViewModel 直接持有 UI 细节对象。
- 把所有业务和数据层复杂度机械搬进 ViewModel。
- 不区分屏幕级状态和局部 UI 瞬时状态。

## 小结

ViewModel 真正解决的，不是一个 API 问题，而是页面状态如何在不稳定页面实例之上获得稳定承载的问题。只要你能把屏幕状态、异步动作和作用域边界理顺，ViewModel 就会自然成为 Android 页面层最可靠的骨架之一。下一章继续讨论可观察状态时，你会发现 Flow、StateFlow 和页面状态之所以容易组合，正是因为这一章先把“状态归谁持有”讲清楚了。

## 参考资料

- 参考并改写自：`Clean Android Architecture`，ViewModel、状态持有与 UseCase/Repository 协作相关章节。
- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，`QuizViewModel`、`CrimeListViewModel` 与 `SavedStateHandle` 相关章节。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，ViewModel 作用域、状态恢复与页面组织相关章节。
- 参考并改写自：Guilherme Socorro，《Thriving in Android Development Using Kotlin》(2024)，`ChatViewModel`、`viewModelScope`、`MutableStateFlow` 与屏幕初始化相关章节。

- ViewModel overview：<https://developer.android.com/topic/libraries/architecture/viewmodel>
- ViewModel APIs and scopes：<https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-apis>
- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Architecture Samples：<https://github.com/android/architecture-samples>
- Now in Android：<https://github.com/android/nowinandroid>

