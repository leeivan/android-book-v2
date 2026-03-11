# ViewModel

ViewModel 是现代 Android 架构中最关键的组件之一。它的重要性并不是因为“官方推荐”，而是因为它非常准确地击中了 Android 页面开发的现实痛点：页面实例会反复变化，但页面级状态和与页面相关的业务逻辑不能每次都从零开始。只要你做过列表加载、搜索条件保留、选项切换、表单输入恢复，就会很快感受到这个问题。

很多人第一次使用 ViewModel 时，只把它理解成“比 Activity 活得久一点的类”。这种理解虽然不完全错，但太浅。Android 官方现在把 ViewModel 定义为 screen level state holder，并明确强调它应暴露状态给 UI、封装相关业务逻辑。也就是说，ViewModel 的价值不仅在“保存几个变量”，更在于它是页面级状态和 UI 层业务逻辑的承载点。

## 学习目标

- 理解 ViewModel 的核心职责、生命周期和边界。
- 理解 ViewModel 与 Activity、Fragment、Navigation、Compose 的关系。
- 理解为什么 ViewModel 适合承接页面状态，而不适合持有所有层级的复杂逻辑。
- 理解 `SavedStateHandle`、`viewModelScope` 和 `uiState` 在实践中的位置。

## 前置知识

- 已理解 Android 中 MVVM 的职责主线。
- 已理解页面实例并不是长期可靠的状态容器。

## 正文

### 1. ViewModel 解决的是“页面会变，状态不能总跟着丢”

Android 页面最棘手的地方之一，是界面实例并不稳定。旋转屏幕、语言切换、多窗口、返回栈恢复，都会导致 Activity 或 Fragment 重建。如果所有状态都存在这些页面实例里，那么：

- 加载结果会丢失。
- 输入中的关键字会重置。
- 筛选条件会消失。
- 正在进行的异步流程难以正确承接。

ViewModel 的作用，就是把这些页面级状态从页面实例里拿出来，放到一个生命周期更稳定的位置。官方文档明确指出，ViewModel 会一直保留到其 `ViewModelStoreOwner` 真正消失为止，而不是随着一次普通配置变化立刻销毁。

### 2. ViewModel 最适合承接什么

一个更实用的判断标准是：ViewModel 最适合承接“某个屏幕在运行过程中需要维持的状态与逻辑”。例如：

- 列表当前是 Loading、Content、Empty 还是 Error。
- 当前搜索关键字、筛选条件、分页状态。
- 页面中某个操作是否正在提交。
- 从多个数据源拼装出来的屏幕显示结果。

它不适合直接替代：

- 持久化数据库。
- 全局应用状态中心。
- 完整的数据层实现。
- 纯 UI 局部瞬时状态，例如某个按钮是否正在按下。

ViewModel 的位置，始终是“屏幕级”而不是“应用级”。

### 3. ViewModel 的作用域为什么必须弄清楚

Android 官方专门提供了 ViewModel scoping APIs 文档来说明作用域问题，因为它直接决定状态到底和谁绑定。一个 ViewModel 可以作用于：

- Activity。
- Fragment。
- Navigation graph。
- NavBackStackEntry。
- Compose 中当前的 `ViewModelStoreOwner`。

这意味着两个名字相同的 ViewModel，如果作用域不同，行为会完全不同。很多“为什么这个页面共用了不该共用的状态”或者“为什么返回后状态没了”的问题，根源都在作用域判断错误。

### 4. ViewModel 既保存状态，也承接 UI 层业务逻辑

这一点比很多人想象得更重要。Android 官方文档明确指出，ViewModel 不只是数据缓存容器，也可以承担 UI 层的业务逻辑，例如处理事件、组合多个仓库结果、生成屏幕状态。

这正是为什么现代写法常常是：

- ViewModel 暴露一个 `StateFlow<UiState>`。
- UI 把点击、输入和重试转成事件回调给 ViewModel。
- ViewModel 使用 `viewModelScope` 执行异步操作。

只要这一层建立起来，页面本身就能明显变轻。

### 5. ViewModel 不应该知道 UI 细节

虽然 ViewModel 与 UI 紧密协作，但它不应该持有具体 View、Lifecycle、Activity `Context` 等带生命周期的对象。官方文档明确提醒：ViewModel 不应引用视图、Lifecycle 或可能持有 Activity 引用的类，否则会引发内存泄漏风险。

这条边界很关键，因为它决定了 ViewModel 是“和 UI 协作”，而不是“变成 UI 的延长部分”。更稳妥的做法通常是：

- ViewModel 暴露抽象状态和事件接口。
- 页面决定具体控件如何显示。
- 页面处理纯 UI 层动作，例如打开键盘、权限弹窗、导航组件调用。

### 6. `SavedStateHandle` 解决的是更深一层的状态恢复

普通 ViewModel 能帮助你跨越配置变化保存状态，但如果进程被系统回收，仅靠内存中的 ViewModel 仍然不够。`SavedStateHandle` 的价值在于，它让某些关键页面状态可以在进程重建后继续恢复，例如：

- 当前搜索关键字。
- 某个详情页的当前选项卡。
- 用户尚未提交的关键输入。

它不应该被滥用成万能存储，但对真正需要恢复的少量页面状态来说，是非常合适的工具。

### 7. `viewModelScope` 为什么是现代 ViewModel 的默认搭档

ViewModel 之所以能成为异步逻辑的稳定承载点，很大程度上离不开协程和 `viewModelScope`。它的意义不是“少写线程代码”，而是让异步任务生命周期自然依附于 ViewModel：

- 页面重建时，不必重新启动所有任务。
- ViewModel 被清除时，相关协程也能一起取消。
- 与 StateFlow、Flow、Repository 的组合更自然。

这使得 ViewModel 不只是“保存状态的盒子”，而是真正能组织页面行为的状态控制点。

### 8. 一个更接近真实项目的最小示例

下面的示例重点不是功能多少，而是观察 ViewModel 应该暴露什么、处理什么：

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
                    _uiState.update { it.copy(isLoading = false) }
                }
                is ApiResult.Empty -> {
                    _uiState.update { it.copy(isLoading = false, articles = emptyList()) }
                }
                else -> {
                    _uiState.update { it.copy(isLoading = false, errorMessage = "Load failed") }
                }
            }
        }
    }
}
```

这个例子最值得注意的是：

- ViewModel 暴露的是状态，而不是具体控件操作。
- 异步逻辑由 `viewModelScope` 承接。
- 页面层不需要直接依赖 Repository 的内部实现细节。

### 9. 实践任务

起点条件：

- 已有一个包含列表、搜索或表单状态的页面。

步骤：

1. 列出这个页面当前所有页面级状态。
2. 判断哪些状态应由 ViewModel 持有，哪些只属于瞬时 UI。
3. 为该页面定义一个统一的 `UiState` 数据类。
4. 把一个页面中的异步操作迁移到 ViewModel 的 `viewModelScope` 中。
5. 检查是否有任何 Activity、Fragment、View 或 `Context` 被直接持有在 ViewModel 里。

预期结果：

- 你能把 ViewModel 用成屏幕级状态容器，而不是临时变量盒子。
- 页面类会明显变轻，状态来源更可追踪。
- 你会为后续 Flow 和 Hilt 的使用建立更稳定的落点。

自检方式：

- 你能解释：ViewModel 为什么能跨越配置变化保留状态。
- 你能判断：哪些状态属于 ViewModel，哪些只属于 UI 局部瞬时交互。
- 你能确认：ViewModel 没有直接引用 View、Lifecycle 或 Activity `Context`。
- 你能说出：`SavedStateHandle` 与普通 ViewModel 内存状态的区别。

调试提示：

- 如果 ViewModel 里直接持有 Activity、Fragment 或 View，优先检查是否存在内存泄漏风险。
- 如果页面仍然自己发请求和管理加载态，说明 ViewModel 还没真正成为状态容器。
- 如果所有状态都用零散字段表示，页面逻辑很快会失控，优先考虑统一的 `UiState`。

### 10. 常见误区

- 把 ViewModel 理解成“带状态的 Activity 替身”。
- 把所有复杂度机械搬进 ViewModel。
- 让 ViewModel 持有 UI 细节对象。
- 把它当成数据库或全局单例使用。

## 小结

ViewModel 的真正价值，在于让页面级状态和 UI 层业务逻辑获得一个比页面实例更稳定的承载点。只要作用域、状态边界和异步协作都清楚，它就会成为整个 Android 架构里最稳的一块基础。


## 参考资料

- ViewModel overview：<https://developer.android.com/topic/libraries/architecture/viewmodel>
- ViewModel scoping APIs：<https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-apis>
- Create ViewModels with dependencies：<https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-factories>
