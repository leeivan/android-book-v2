# MVC / MVP / MVVM

很多人第一次接触架构模式，是从三张缩写表开始的：`MVC`、`MVP`、`MVVM`。结果学完以后，脑子里多了几个名词，项目里却还是同样的问题: 页面越来越重，状态越来越散，谁在改数据说不清，改一个功能就要连带改很多地方。原因并不复杂，因为架构模式从来不是为了让类图更好看，而是为了回答一个非常现实的问题: 当页面、状态、数据来源和交互复杂度不断上升时，代码到底应该怎样分工，才能不失控。

这一章不把三种模式当成概念史来讲，而是把它们放回 Android 真实开发现场。你会看到它们分别试图解决什么问题，为什么有些模式在 Android 里容易长歪，为什么现代 Android 更自然地走向 `MVVM + 单向数据流 + 状态建模`，以及为什么“用了 ViewModel”不等于架构已经成立。

## 学习目标

- 理解架构模式真正要解决的不是名词，而是职责失控问题。
- 理解 `MVC`、`MVP`、`MVVM` 在 Android 中的典型落点和常见失败方式。
- 理解为什么现代 Android 更常以 `MVVM` 为主线。
- 为后续 `ViewModel`、`Repository`、`UseCase` 和依赖注入章节建立共同背景。

## 前置知识

- 已理解 Activity、Fragment、Compose 页面和基本数据流。
- 已接触过页面里同时出现网络请求、状态字段和渲染逻辑的情况。

## 正文

### 1. 没有架构时，页面会怎样慢慢失控

想象一个最开始很简单的列表页。第一版只有“加载数据并显示列表”。第二版加了搜索。第三版加了下拉刷新和错误重试。第四版加了收藏、排序和分页。到了这一步，如果所有逻辑都还堆在 Activity 或 Fragment 里，页面类通常会同时承担这些职责:

- 接收用户输入。
- 发起网络或数据库调用。
- 持有加载、空态、错误等状态。
- 解释数据层异常。
- 组织页面跳转和弹窗反馈。

问题不在于“页面不能写逻辑”，而在于这些逻辑的生命周期、变化频率和抽象层次完全不同，硬塞进同一个类里后，代码就会越来越难维护。架构模式的价值，就是把这种混合物重新拆开。

### 2. MVC 解决的是最初级的职责分离

`MVC` 的核心想法很直接: 把数据、界面和控制逻辑分开。它在桌面应用和早期 Web 框架中很自然，因为界面相对稳定，控制层可以集中处理输入和流程。

放到 Android 里，最常见的变体往往是:

- `View`: XML、View 树、Compose UI。
- `Model`: 数据对象和一部分业务逻辑。
- `Controller`: Activity 或 Fragment。

这能解决一部分问题，因为至少页面不再只是“所有东西都挤在 View 里”。但 Android 很快暴露出一个现实: Activity 和 Fragment 天生就已经承担了很多系统生命周期职责，再把“控制器”的大量业务组织逻辑也塞进去，控制层会迅速膨胀。

### 3. 为什么 Android 里的 MVC 经常退化成“巨型页面类”

很多初学项目自认为是 `MVC`，实际上只是把页面类命名成了 Controller。真正的问题在于 Android 组件本身并不是纯粹的控制器，它们还必须:

- 响应生命周期回调。
- 处理配置变化。
- 管理视图层绑定。
- 协调导航和系统权限。

一旦再把请求发起、数据转换、状态保存、错误解释都堆进去，Activity 或 Fragment 很容易膨胀成几百上千行的巨型类。此时架构名词仍然在，结构收益却已经消失。

所以理解 `MVC` 在 Android 中的局限很重要。它不是“错误模式”，而是在平台现实下，很容易让控制层变得过重。

### 4. MVP 想解决的，就是页面控制器过重

`MVP` 的出现，很大程度上是在回应 `MVC` 的这个问题。它尝试把原本堆在页面类里的控制逻辑抽到 `Presenter`，让 View 更专注于显示和转发用户事件。

在 Android 中，典型的 `MVP` 结构往往是:

- `View`: Activity、Fragment 或一个 View 接口实现。
- `Presenter`: 接收 View 事件、调用数据层、回推 UI 结果。
- `Model`: 数据和业务规则。

它的优点很明显: 页面类可以瘦下来，展示逻辑和控制逻辑分离得更清楚。在没有 `ViewModel` 和状态容器时，这曾经是非常有价值的实践。

### 5. 为什么很多 Android 项目的 MVP 也会变重

`MVP` 的问题不在概念，而在落地成本。随着页面状态变复杂，Presenter 往往要手动维护:

- 当前页面持有什么数据。
- 页面附着或分离时怎样同步。
- 旋转或重建后怎样恢复。
- 异步回调回来时 View 是否还有效。

结果就是，原来从页面类搬走的复杂度，很可能又集中到了 Presenter。尤其在响应式状态管理还没建立时，Presenter 很容易变成新的“大脑”，而且仍然要频繁和 Android 生命周期打架。

这也是为什么不少团队后来逐渐从 `MVP` 转向 `MVVM`。不是因为 `MVP` 完全错误，而是因为现代 Android 平台提供了更适合页面状态持有的官方工具。

Luca Vainigli 在同一本书里用同一个 articles 场景连续演示了三种模式，这个对比特别适合放在这里看：在 MVC 版本中，`ArticleListActivity` 自己持有 `ArticleRepository` 并直接触发 `repository.getArticles()`；到了 MVP，Activity 退成 `ArticleView` 接口实现，`ArticlePresenter(view, repository)` 负责 `loadArticles()` 并调用 `view.showArticles()` / `view.showError()`；到了 MVVM，`ArticleViewModel` 改为持有 `ArticleRepository`，并把结果通过 `MutableStateFlow` 暴露给 `ArticleListScreen`。同一份“文章列表”需求，在三种写法里数据来源几乎没变，真正变化的是页面与状态的关系：职责先从 Activity 被抽到 Presenter，最后再收束成可观察状态。

### 6. MVVM 在 Android 中为什么更自然

`MVVM` 在 Android 中之所以更自然，不是因为它名字更流行，而是因为平台已经给了它很合适的支点: `ViewModel`、生命周期感知组件、`Flow`、`StateFlow`、`Room`、Compose。

它的基本关系可以先这样理解:

- `View`: 负责显示状态和转发用户动作。
- `ViewModel`: 负责承接页面事件、组织页面状态、对接下层。
- `Model`: 负责数据来源和业务规则，通常由 `Repository`、数据源、数据库、网络层等组成。

这套结构特别适合 Android，因为页面实例会反复重建，而页面状态不能每次都从零开始。`ViewModel` 正好提供了一个比 Activity / Fragment 更稳定的屏幕级状态持有点。

### 7. 同一个列表页，在三种模式里会怎样演变

为了把区别看得更清楚，可以用同一个列表页来对比。

在 `MVC` 里，Activity 或 Fragment 往往既接按钮点击，又发请求，又更新列表，还直接处理错误提示。

在 `MVP` 里，这些流程会被 Presenter 接走，页面类主要负责把事件交给 Presenter，再接收 Presenter 的显示指令。

在 `MVVM` 里，页面更像一个状态消费者。用户动作交给 ViewModel，ViewModel 调数据层，最后只暴露一个统一的 `uiState` 给页面。页面不再接收一连串“命令式更新”，而是根据当前状态直接渲染。

这就是三种模式的核心差别: 不是谁更高级，而是谁更适合当前平台和状态复杂度。

如果把同一个“文章列表页”压成最小对照代码，三种写法的差别会更直观：

```kotlin
// MVC: 页面自己既拿数据又改界面
class ArticleListActivity : AppCompatActivity() {
    private val repository = ArticleRepository()

    fun onRefreshClicked() {
        showLoading()
        repository.getArticles(
            onSuccess = { articles -> renderArticles(articles) },
            onError = { message -> showError(message) },
        )
    }
}

// MVP: Presenter 接走流程，页面退成指令接收者
interface ArticleListView {
    fun showLoading()
    fun showArticles(items: List<Article>)
    fun showError(message: String)
}

class ArticleListPresenter(
    private val view: ArticleListView,
    private val repository: ArticleRepository,
) {
    fun refresh() {
        view.showLoading()
        repository.getArticles(
            onSuccess = { view.showArticles(it) },
            onError = { view.showError(it) },
        )
    }
}

// MVVM: 页面只发事件并消费 uiState
@HiltViewModel
class ArticleListViewModel @Inject constructor(
    private val repository: ArticleRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow(ArticleListUiState())
    val uiState: StateFlow<ArticleListUiState> = _uiState.asStateFlow()

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val articles = repository.getArticles()
            _uiState.update { it.copy(isLoading = false, articles = articles) }
        }
    }
}
```

这组代码最值得比较的，不是类名，而是状态到底停在哪一层。MVC 里，页面本身就是流程中心；MVP 里，页面把流程让给 Presenter，但页面仍然要接收一连串命令式回调；MVVM 里，页面不再逐条接命令，而是只消费 `uiState`。这就是为什么现代 Android 一旦进入状态驱动 UI，MVVM 会显得更顺手。

### 8. 为什么现代 Android 更强调单向数据流

只要项目进入 `MVVM` 主线，就几乎一定会遇到“单向数据流”这个概念。原因很现实: 如果页面、ViewModel、数据层都能随手改同一份状态，状态来源很快就会变得不可追踪。

更稳定的方式通常是:

- 用户事件从 View 流向 ViewModel。
- 数据变化经由数据层返回 ViewModel。
- 页面状态从 ViewModel 流向 View。

这会让页面不再像一个同时接受多路信号的黑箱，而更像沿着一条清晰管线工作的状态终点。现代 Android 之所以把 `MVVM` 和单向数据流经常一起讲，就是因为它们在工程上互相支撑。

也正因为如此，架构模式不应被机械翻译成文件夹模仿游戏。一个项目把目录命名成 `model/view/viewmodel`，并不代表职责真的已经拆开；真正关键的是状态是否有单一出口、页面是否仍然直接协调多个数据来源、以及某个类是否同时承担了不止一种生命周期和抽象层级的责任。模式名称只是提示，状态边界才是落地标准。

### 9. 真正让 MVVM 稳下来的，是状态合同而不是多一个 ViewModel

如果把单向数据流继续往下落，`MVVM` 最关键的其实不是“页面拿到了一个 ViewModel”，而是页面和 ViewModel 之间有没有一份稳定合同。Vainigli、Bennett 和 Big Nerd Ranch 的例子虽然语法风格不同，但共同点都很明确：页面不再直接读写零散字段，而是围绕 `uiState`、用户 action 和一次性 effect 协作。

```kotlin
data class ArticleListUiState(
    val isLoading: Boolean = false,
    val keyword: String = "",
    val articles: List<Article> = emptyList(),
)

sealed interface ArticleListAction {
    data object Refresh : ArticleListAction
    data class KeywordChanged(val value: String) : ArticleListAction
    data class ArticleClicked(val id: Long) : ArticleListAction
}

sealed interface ArticleListEffect {
    data class OpenArticle(val id: Long) : ArticleListEffect
    data class ShowMessage(val text: String) : ArticleListEffect
}

@HiltViewModel
class ArticleListViewModel @Inject constructor(
    private val repository: ArticleRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow(ArticleListUiState())
    val uiState: StateFlow<ArticleListUiState> = _uiState.asStateFlow()

    private val _effect = MutableSharedFlow<ArticleListEffect>()
    val effect: SharedFlow<ArticleListEffect> = _effect.asSharedFlow()

    fun onAction(action: ArticleListAction) {
        when (action) {
            ArticleListAction.Refresh -> refresh()
            is ArticleListAction.KeywordChanged -> {
                _uiState.update { it.copy(keyword = action.value) }
            }
            is ArticleListAction.ArticleClicked -> {
                viewModelScope.launch {
                    _effect.emit(ArticleListEffect.OpenArticle(action.id))
                }
            }
        }
    }

    private fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val articles = repository.getArticles(keyword = _uiState.value.keyword)
            _uiState.update { it.copy(isLoading = false, articles = articles) }
        }
    }
}
```

这段代码真正强化的，是“稳定状态”和“一次性动作”终于被拆开了。`uiState` 负责页面持续可见的状态，例如加载中、搜索词和列表内容；`effect` 负责页面不该重复消费的一次性动作，例如导航和提示消息。只要这层合同清楚，ViewModel 就不会再退化成“把原来 Activity 的代码平移过去”。

这也是为什么今天很多团队虽然口头上说自己在用 `MVVM`，但项目里仍然会失控。只要页面继续直接改多个数据源、ViewModel 同时输出稳定状态和一次性事件却没有边界、或 UI 要靠大量命令式回调才能工作，那么代码只是换了类名，并没有真正进入状态驱动结构。

### 10. 如果页面动作越来越多，把状态更新收成 reducer 会更稳

Bennett 和 Vainigli 在单向数据流示例里都在强调同一件事：页面动作一旦开始变多，真正先失控的往往不是 `ViewModel` 类名，而是状态改动散落在多个分支里。今天这里 `copy(isLoading = true)`，明天那里 `copy(keyword = ...)`，后天又在错误分支里补一段 `copy(errorMessage = ...)`，几轮迭代后，页面就很难说清“哪些动作会把状态改成什么样”。

这时一个很实用的办法，就是先把“状态怎么变”收成一个 reducer，再把真正的异步副作用留给单独函数处理：

```kotlin
private fun reduce(
    old: ArticleListUiState,
    action: ArticleListAction,
): ArticleListUiState {
    return when (action) {
        ArticleListAction.Refresh -> old.copy(
            isLoading = true,
            errorMessage = null,
        )
        is ArticleListAction.KeywordChanged -> old.copy(
            keyword = action.value,
        )
        is ArticleListAction.ArticleClicked -> old
    }
}

fun onAction(action: ArticleListAction) {
    _uiState.update { old -> reduce(old, action) }

    when (action) {
        ArticleListAction.Refresh -> refresh()
        is ArticleListAction.KeywordChanged -> refresh()
        is ArticleListAction.ArticleClicked -> {
            viewModelScope.launch {
                _effect.emit(ArticleListEffect.OpenArticle(action.id))
            }
        }
    }
}
```

这段代码的价值，不是把 `when` 挪了个地方，而是把“状态变化规则”和“副作用执行时机”明确拆开。前者更像页面状态合同，后者才是请求、导航、提示消息这类会跟外部世界交互的动作。只要读者先把这层边界写清楚，后面无论页面继续变复杂，还是从 View 系统迁到 Compose，状态流向都会更容易维护。

### 11. 不要把架构模式理解成模板答案

这一章最容易产生的误解，是把三种模式当成“必须选一个照搬”的固定模板。真实项目里，架构模式更像一组取舍原则:

- 页面该不该同时承担渲染和复杂业务流程。
- 页面状态有没有单一出口。
- 数据层和 UI 层有没有清楚边界。
- 生命周期变化时，状态有没有稳定承载点。

如果这些问题已经回答清楚，那么模式名称本身反而没有那么重要。相反，如果这些问题没有解决，哪怕满项目都在写 `ViewModel`，也不代表真的进入了良好架构。

### 12. 当状态合同能被单测时，MVVM 才真正不只是换名字

Bennett 在讲单向数据流和状态测试时有一个很实用的提醒：如果页面状态变化只能靠真机点一遍才知道对不对，那么所谓“架构更清楚”往往还只是口头说法。真正稳的状态合同，应该能在不启动 Activity、Fragment 或 Compose 树的前提下，直接验证某个动作会把状态改成什么样。

```kotlin
class ArticleListReducerTest {

    @Test
    fun keywordChanged_only_updates_keyword() {
        val old = ArticleListUiState(
            keyword = "android",
            isLoading = false,
        )

        val new = reduce(
            old = old,
            action = ArticleListAction.KeywordChanged("compose"),
        )

        assertEquals("compose", new.keyword)
        assertEquals(false, new.isLoading)
    }
}
```

这段测试看起来很小，但它正好说明了为什么现代 Android 越来越强调状态合同。只要 `action -> state` 的关系被写成稳定函数，你就能先验证状态规则，再去验证副作用和 UI 渲染。这样一来，MVVM 真正带来的收益就不只是“多了一个 ViewModel 类”，而是页面复杂度第一次能被拆成可测试的几层。

### 13. 当页面同时要服务 View 系统和 Compose 时，把页面合同单独收出来会更稳

Vainigli 在模式演进里强调过一个很容易被低估的点：真正能跨技术栈复用的，往往不是某个 Activity、Fragment 或 Composable，而是“这个页面到底有哪些状态、动作和副作用”。Bennett 在 Compose 路线里进一步把这件事讲得更具体：一旦 `UiState`、`Action` 和 `Effect` 先被单独收成页面合同，页面从 RecyclerView 迁到 Compose、从 Fragment 拆成 Route / Content 时，真正稳定的那一层就不会被 UI 技术选择牵着走。

```kotlin
object ArticleListContract {

    data class UiState(
        val isLoading: Boolean = false,
        val keyword: String = "",
        val articles: List<ArticleCardUiModel> = emptyList(),
    )

    sealed interface Action {
        data object Refresh : Action
        data class KeywordChanged(val value: String) : Action
        data class ArticleClicked(val id: Long) : Action
    }

    sealed interface Effect {
        data class OpenArticle(val id: Long) : Effect
        data class ShowMessage(val text: String) : Effect
    }
}

class ArticleListViewModel(
    private val repository: ArticleRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleListContract.UiState())
    val uiState: StateFlow<ArticleListContract.UiState> = _uiState.asStateFlow()

    private val _effect = MutableSharedFlow<ArticleListContract.Effect>()
    val effect: SharedFlow<ArticleListContract.Effect> = _effect.asSharedFlow()

    fun onAction(action: ArticleListContract.Action) {
        when (action) {
            ArticleListContract.Action.Refresh -> refresh()
            is ArticleListContract.Action.KeywordChanged -> {
                _uiState.update { it.copy(keyword = action.value) }
                refresh()
            }
            is ArticleListContract.Action.ArticleClicked -> {
                viewModelScope.launch {
                    _effect.emit(ArticleListContract.Effect.OpenArticle(action.id))
                }
            }
        }
    }

    private fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val cards = repository.getArticles(
                keyword = _uiState.value.keyword,
            )
            _uiState.update {
                it.copy(isLoading = false, articles = cards)
            }
        }
    }
}
```

这段代码真正守住的是“页面合同先于页面实现”这件事。只要合同稳定，Fragment 可以继续拿它更新 RecyclerView，Compose 也可以拿它驱动 `LazyColumn`；UI 技术可以变，页面状态语义和动作入口却不用跟着重新发明。对初学者来说，这也是理解模式演进最实际的一步：`MVVM` 真正比 `MVC`、`MVP` 更稳的地方，不是又多了一个类，而是页面终于开始围绕一份可复用、可测试的合同组织。

### 14. 从 MVP 迁到 MVVM 时，真正要迁的是状态出口，而不是类名

Vainigli 在比较 `MVP` 和 `MVVM` 时一直在强调一件很容易被忽略的事：迁移不是把 `Presenter` 机械改名成 `ViewModel`，而是把原来那串回调式 View 合同，收束成更稳定的状态出口和副作用出口。Bennett 在单向数据流章节里把这件事讲得更直接：只要页面还在同时接 `showLoading()`、`showArticles()`、`showError()` 这一类分散回调，所谓迁到 `MVVM` 往往还只是换了类名。

```kotlin
interface ArticleListView {
    fun showLoading()
    fun showArticles(items: List<ArticleCardUiModel>)
    fun showError(message: String)
    fun openArticle(id: Long)
}

class ArticleListPresenter(
    private val repository: ArticleRepository,
) {
    suspend fun bind(view: ArticleListView) {
        view.showLoading()
        runCatching { repository.getArticles() }
            .onSuccess(view::showArticles)
            .onFailure { view.showError("加载失败") }
    }

    fun onArticleClicked(view: ArticleListView, id: Long) {
        view.openArticle(id)
    }
}

data class ArticleListUiState(
    val isLoading: Boolean = false,
    val articles: List<ArticleCardUiModel> = emptyList(),
    val errorMessage: String? = null,
)

sealed interface ArticleListEffect {
    data class OpenArticle(val id: Long) : ArticleListEffect
}

class ArticleListViewModel(
    private val repository: ArticleRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleListUiState())
    val uiState: StateFlow<ArticleListUiState> = _uiState.asStateFlow()

    private val _effect = MutableSharedFlow<ArticleListEffect>()
    val effect: SharedFlow<ArticleListEffect> = _effect.asSharedFlow()

    fun load() {
        viewModelScope.launch {
            _uiState.value = ArticleListUiState(isLoading = true)
            runCatching { repository.getArticles() }
                .onSuccess { articles ->
                    _uiState.value = ArticleListUiState(articles = articles)
                }
                .onFailure {
                    _uiState.value = ArticleListUiState(errorMessage = "加载失败")
                }
        }
    }

    fun onArticleClicked(id: Long) {
        viewModelScope.launch {
            _effect.emit(ArticleListEffect.OpenArticle(id))
        }
    }
}
```

这组代码真正拉开的差距，不是 `Presenter` 和 `ViewModel` 的名字，而是页面接口终于从“等别人按时回调我”变成了“我始终可以读取当前状态”。导航这类一次性动作也不再跟 `showLoading()`、`showError()` 混在一处，而是单独走 effect 通道。只要读者把这一点看清，迁移路径就会稳很多：先收状态出口，再谈 UI 技术和类名变化。

### 15. 实践任务

起点条件:

- 已有一个包含列表、搜索、刷新或表单能力的页面。

步骤:

1. 写出当前页面分别承担了哪些职责。
2. 判断这些职责中，哪些是渲染职责，哪些是页面状态职责，哪些属于数据层职责。
3. 试着用 `MVC`、`MVP`、`MVVM` 三种角度去描述这个页面的可能拆法。
4. 观察哪一种拆法最符合你当前项目的状态复杂度和技术栈。
5. 把“页面状态是否有单一出口”作为最后的检查标准。

预期结果:

- 读者会把架构模式理解成职责分配问题，而不是缩写背诵题。
- 读者应能更清楚地解释为什么现代 Android 经常走向 `MVVM`。
- 读者会为后续章节中的具体模式落地建立判断基线。

自检方式:

- 读者应能说出 `MVC` 在 Android 中为什么容易让页面类膨胀。
- 读者应能解释 `MVP` 试图解决什么问题，以及它后来为什么也容易变重。
- 读者应能判断 `MVVM` 为什么更适合和现代 Android 组件配套。

调试提示:

- 如果页面类既管 UI，又管网络，又管状态保存，先别急着问用哪种模式，先承认职责已经混了。
- 如果你把所有逻辑都搬进 ViewModel，只是把页面类问题换了位置，不算真正落地 `MVVM`。
- 如果项目里状态来源超过两个且没有单一出口，优先补状态设计，而不是继续加类。

### 16. 常见误区

- 把架构模式当成缩写记忆题。
- 以为用了某个模式名字，代码自然就会变好。
- 只讨论类图，不讨论状态流向和生命周期边界。
- 把所有复杂度从页面搬到另一个类里，误以为完成了分层。

## 小结

`MVC`、`MVP`、`MVVM` 真正讨论的不是名词优劣，而是页面复杂度如何被拆开。对 Android 来说，`MVC` 最容易让页面控制层膨胀，`MVP` 试图把控制逻辑移走，但仍要和生命周期反复周旋，而 `MVVM` 则更容易借助 `ViewModel`、状态流和单向数据流形成稳定结构。理解这条演进线，后面讨论 `ViewModel`、`Repository` 和 `UseCase` 时，才不会只是记住一堆类名。

## 参考资料

- 参考并改写自：`Clean Android Architecture`，架构模式演进、职责边界与分层讨论相关章节。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，单向数据流、状态建模与屏幕结构相关章节。
- 参考并改写自：Luca Vainigli，《Ultimate Android Design Patterns》(2025)，`ArticleListActivity`、`ArticlePresenter`、`ArticleViewModel` 与 MVC / MVP / MVVM 对照相关章节。

- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>
- State holders and UI state: <https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Architecture Samples: <https://github.com/android/architecture-samples>





