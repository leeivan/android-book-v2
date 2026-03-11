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

### 2. 什么叫“屏幕级状态持有者”

Android 官方现在把 ViewModel 放在 state holder 语境里理解，这是很准确的。所谓屏幕级状态持有者，可以先把它想成“站在页面前面的一层控制台”。UI 不直接面对数据库、网络接口和各种零散变量，而是面对一个更稳定的状态出口。

这里最重要的不是定义，而是边界。ViewModel 最适合承接的是“某个屏幕在一段交互过程中持续关心的状态”。例如列表页的 `Loading / Content / Empty / Error`，搜索页的当前关键字和筛选条件，表单页的提交中状态和校验结果，详情页当前选中的 tab 或 section。这些东西本质上都属于屏幕语义，而不是单个控件语义。

与之对应，ViewModel 不适合承接两类东西。第一类是太底层、太全局的状态，例如数据库实体存储、整个应用的基础设施对象，这些更适合数据层或依赖注入容器。第二类是太局部、太短命的 UI 状态，例如某个按钮按下时的涟漪效果、一个输入框当前是否获取焦点、某个下拉菜单是否短暂展开。这些通常应留在 UI 层本地管理。

### 3. 作用域判断，决定了你的状态到底跟谁走

很多 ViewModel 相关问题并不是“不会写 ViewModel”，而是没想清楚它到底应该跟谁绑定。一个 ViewModel 可以绑定到 Activity，可以绑定到 Fragment，也可以绑定到某个 Navigation graph 或 Compose 当前的 `ViewModelStoreOwner`。作用域一旦判断错，后面的体验就会直接出问题。

举个最常见的例子。假设一个搜索页和搜索结果页属于同一个导航流程，而且你希望它们共享同一份搜索词和筛选条件。这种状态更适合绑定到共同的导航作用域或共同宿主，而不是分别绑在两个页面自己身上。相反，如果两个列表页虽然长得像，但它们的数据完全独立，就不该错误地共用同一个 Activity 级 ViewModel。

所以理解 ViewModel，不能只停留在“它比 Activity 活得久”。更关键的问题是：它到底应该跟哪个屏幕语义一起存活。只要这个问题想清楚，很多共享状态和返回后状态丢失的问题都会自然少掉。

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

### 7. ViewModel 最容易越界的地方

真正写项目时，ViewModel 很容易从“页面状态持有者”变成“什么都往里塞的地方”。最常见的越界有三种。第一种是直接持有 `Activity`、`Fragment`、`View` 或 `Context`，这通常会把生命周期边界搅乱，甚至带来内存泄漏风险。第二种是把所有数据层和业务层细节都机械搬进 ViewModel，结果只是把原来的胖页面换成了胖 ViewModel。第三种是反过来太保守，什么都不敢放进去，导致页面仍然自己发请求、自己处理状态。

更稳妥的判断方式是：只要某段逻辑是在回答“这个屏幕现在应该处于什么状态”，通常就适合放在 ViewModel；只要某段逻辑是在回答“这个应用的数据从哪里来、怎样存、怎样同步”，通常就更适合放在 Repository 或数据层；只要某段逻辑是在回答“某个控件怎么展开、动画怎么做、键盘怎么弹”，通常就留在 UI 层。

这套边界不是为了让每个类看起来干净，而是为了让问题真正回到最适合被解决的位置。

### 8. 实践任务

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
- 你能说清楚当前页面到底有哪些状态，以及它们为什么要交给 ViewModel。
- 配置变化后，关键页面状态会比原来更稳定。

自检方式：

- 你能解释：这个页面的哪些状态属于 ViewModel，哪些只属于局部 UI。
- 你能确认：ViewModel 没有直接持有 `Activity`、`Fragment`、`View` 或生命周期对象。
- 你能说明：为什么这个页面的异步动作更适合放在 `viewModelScope`，而不是直接写在页面里。

调试提示：

- 如果页面仍然自己发请求和切换加载态，说明 ViewModel 还没有真正成为状态持有者。
- 如果 ViewModel 里开始出现大量数据库、网络和框架细节，先回头检查 Repository 边界。
- 如果你什么状态都往 `SavedStateHandle` 里塞，说明它已经被误当成持久化存储了。

### 9. 常见误区

- 把 ViewModel 理解成“比 Activity 活得久一点的对象”。
- 让 ViewModel 直接持有 UI 细节对象。
- 把所有业务和数据层复杂度机械搬进 ViewModel。
- 不区分屏幕级状态和局部 UI 瞬时状态。

## 小结

ViewModel 真正解决的，不是一个 API 问题，而是页面状态如何在不稳定页面实例之上获得稳定承载的问题。只要你能把屏幕状态、异步动作和作用域边界理顺，ViewModel 就会自然成为 Android 页面层最可靠的骨架之一。下一章继续讨论可观察状态时，你会发现 Flow、StateFlow 和页面状态之所以容易组合，正是因为这一章先把“状态归谁持有”讲清楚了。

## 参考资料

- ViewModel overview：<https://developer.android.com/topic/libraries/architecture/viewmodel>
- ViewModel APIs and scopes：<https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-apis>
- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Architecture Samples：<https://github.com/android/architecture-samples>
- Now in Android：<https://github.com/android/nowinandroid>
