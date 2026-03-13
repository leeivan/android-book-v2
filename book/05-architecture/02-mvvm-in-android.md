# Android 中的 MVVM

上一章解决的是“为什么现代 Android 更常采用 MVVM”，这一章开始回答另一个更实在的问题: 它在代码里到底怎样落地。很多开发者知道 `View`、`ViewModel`、`Model` 这三个词，却很难把它们和 Activity、Fragment、Compose、Repository、Room、网络接口这些现实对象对应起来。结果往往是，概念上似乎已经在用 MVVM，代码上却仍然由页面类承担大部分复杂度。

这章的重点不是再解释一遍缩写，而是把 MVVM 还原成 Android 项目里的职责链路。你会看到它为什么总和单向数据流、页面状态、Repository、`StateFlow` 一起出现，也会看到它并不是“把所有逻辑都搬进 ViewModel”这么简单。

## 学习目标

- 理解 `View`、`ViewModel`、`Model` 在 Android 项目中的真实落点。
- 理解 MVVM 在页面状态组织、数据流方向和生命周期协作上的优势。
- 理解为什么 `uiState` 是 MVVM 在 Android 中最重要的落地形式之一。
- 为后续 `Repository`、`UseCase`、`Hilt` 等章节建立统一语境。

## 前置知识

- 已理解 MVC、MVP、MVVM 的整体差异。
- 已接触 Activity、Fragment、Compose 和 ViewModel。

## 正文

### 1. 先从一个实际页面开始，而不是从三层定义开始

假设你正在做一个新闻列表页。页面打开后要拉取数据，支持搜索、收藏、下拉刷新、错误重试和跳转详情。到了这个复杂度，最关键的问题已经不是“页面能不能跑”，而是:

- 搜索关键字放哪儿。
- 加载中和错误态由谁持有。
- 网络和本地数据由谁协调。
- 页面重建后状态由谁接住。

MVVM 的价值，就是给这些问题提供一套稳定分工。

### 2. View 在 Android 里不是“布局文件”，而是整块显示层

在 MVVM 中，`View` 指的不是 XML 文件本身，而是用户直接面对的那层界面呈现系统。在 Android 里，它通常包括:

- Activity 或 Fragment。
- Compose 的 screen-level composable。
- 负责渲染、事件收集和部分纯 UI 反馈的代码。

`View` 的职责应该尽量聚焦于两件事:

- 把当前状态显示出来。
- 把用户动作转成事件往上交。

这意味着 View 不应直接承担网络请求、数据库协调和长期状态持有。它可以很忙，但不应该很重。

### 3. ViewModel 是 MVVM 在 Android 中真正站稳的关键

如果没有 `ViewModel`，MVVM 在 Android 里往往会变成一套概念，而不是稳定结构。原因很简单: Activity 和 Fragment 的实例生命周期并不稳定，但页面状态不能跟着它们一起随意丢失。

`ViewModel` 在 Android 中最重要的价值，就是提供了一个屏幕级状态持有点。它更适合承接:

- 页面当前的 `uiState`。
- 搜索词、筛选条件、分页位置等页面语义状态。
- 页面触发的加载、刷新、重试、提交等行为组织。

它不是为了“替页面多活一会儿”，而是为了让页面状态和页面实例解耦。

### 4. Model 在现代 Android 中往往是一整块数据与规则层

很多人会把 `Model` 误解成“几个 data class”。在现代 Android 项目里，这个理解太窄。更真实的情况通常是:

- `Repository` 负责对外提供统一数据入口。
- 本地数据源和远程数据源负责各自访问。
- 映射逻辑把 DTO、Entity、UI model 区分开。
- 某些业务规则或用例负责封装跨页面可复用逻辑。

也就是说，`Model` 在真实项目里通常是一整块数据与规则体系，而不是几个单纯的数据对象。

### 5. Android 中一条健康的 MVVM 链路长什么样

更符合现代 Android 的 MVVM 链路通常是这样:

1. View 收到用户动作，例如点击刷新或输入搜索词。
2. View 把动作交给 ViewModel。
3. ViewModel 调用 Repository 或 UseCase。
4. 数据层协调本地、远程、缓存和错误处理。
5. ViewModel 把结果转换为页面可消费的 `uiState`。
6. View 只根据 `uiState` 渲染。

这条链路的关键不是“谁调用谁”，而是状态从上游一路被整理，直到页面只面对一个清晰的状态出口。

### 6. 单向数据流为什么几乎总和 MVVM 一起出现

只要项目走到 MVVM，迟早都会遇到单向数据流。原因很现实: 如果页面、ViewModel、Repository 都在同时修改同一份状态，状态来源会很快失控。

更稳的方式通常是:

- 事件向上流: View -> ViewModel。
- 数据结果向内流: 数据层 -> ViewModel。
- 页面状态向下流: ViewModel -> View。

这样做的好处不是“理论更优雅”，而是你终于能解释清楚: 这次页面为什么变了，是谁触发的，变化经过了哪些层。

### 7. `uiState` 是 MVVM 落地的关键接口，不是附属写法

很多团队说自己在用 MVVM，但页面仍然靠多个布尔值、若干独立 LiveData 或一堆可变字段来驱动。这样的状态结构很容易碎掉，因为页面并没有一个真正稳定的“当前状态”模型。

更可维护的做法通常是把页面状态正式建模成一个 `UiState`:

```kotlin
data class ArticleListUiState(
    val isLoading: Boolean = false,
    val query: String = "",
    val items: List<ArticleUiModel> = emptyList(),
    val errorMessage: String? = null
)
```

这样做的意义在于，页面终于可以围绕“当前状态是什么”来思考，而不是围绕“现在该去改哪几个字段”来思考。

与这件事配套的，还有“只暴露只读状态”的纪律。ViewModel 内部可以维护 `MutableStateFlow` 或其他可变状态容器，但对外更稳妥的接口通常应该是 `StateFlow<UiState>` 或其他只读视图。这样做不是形式主义，而是在明确：页面负责消费状态，不负责绕过 ViewModel 直接改状态。

### 8. View 应该轻到什么程度

“页面要轻”这句话很容易说空。更具体一点，View 可以负责:

- 绑定 UI 和生命周期。
- 读取并渲染 `uiState`。
- 收集点击、输入、滑动、刷新等事件。
- 执行导航、权限请求、打开系统选择器这类纯 UI 动作。

但 View 不应负责:

- 直接访问网络和数据库。
- 维护长期业务状态。
- 同时协调多个数据来源。
- 解释底层错误并决定业务策略。

只要这些职责还留在页面里，MVVM 就还没有真正站稳。

### 9. ViewModel 也不是“新的业务垃圾桶”

MVVM 在 Android 中最常见的误用，就是把所有复杂度从页面类挪到 ViewModel。这样做短期看似清爽，长期只是把巨型 Fragment 变成巨型 ViewModel。

更合理的边界是:

- ViewModel 组织页面状态。
- Repository 组织数据入口和来源策略。
- UseCase 组织跨页面可复用的业务动作。

如果 ViewModel 里塞满 SQL 细节、HTTP 细节、复杂对象装配和无关页面的业务规则，说明你不是在落实 MVVM，而是在转移混乱。

### 10. 一个最小的 MVVM 页面结构

下面这个例子展示的是 MVVM 在 Android 中更接近真实项目的最小形态:

```kotlin
class ArticleListViewModel(
    private val repository: ArticleRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ArticleListUiState(isLoading = true))
    val uiState: StateFlow<ArticleListUiState> = _uiState

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            when (val result = repository.refreshArticles()) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(isLoading = false, items = result.data)
                    }
                }
                is ApiResult.Failure -> {
                    _uiState.update {
                        it.copy(isLoading = false, errorMessage = result.message)
                    }
                }
            }
        }
    }
}
```

这个例子最重要的不是语法，而是分工:

- 页面不直接处理 Repository。
- 页面不直接解释错误。
- 页面最终只消费 `uiState`。

这就是 MVVM 在 Android 中最有价值的部分: 把复杂页面重新收束成清晰状态。

### 11. 实践任务

起点条件:

- 已有一个包含列表、详情或表单交互的 Android 页面。

步骤:

1. 把当前页面职责拆成 View、ViewModel、数据层三组。
2. 找出页面里还在直接持有数据源或解释错误的位置。
3. 为页面建立一个统一的 `UiState` 数据类。
4. 把一个原本散落在页面里的异步流程收回 ViewModel。
5. 检查状态变化是否已经形成单向流向。

预期结果:

- 你能把 MVVM 真正落到 Android 组件上，而不是停留在抽象名词。
- 页面层会更聚焦于显示和交互。
- 你会更容易发现哪些逻辑该留在 ViewModel，哪些该下沉到数据层。

自检方式:

- 你能解释为什么 Android 中的 ViewModel 对 MVVM 特别关键。
- 你能判断某段逻辑属于页面状态组织，还是数据来源协调。
- 你能说出 `uiState` 为什么是 MVVM 的关键接口。

调试提示:

- 如果页面直接拿 DTO 渲染，通常说明 Model 和 UI 边界还没立住。
- 如果 ViewModel 里同时出现网络、数据库和复杂流程编排细节，通常说明数据层职责不够清楚。
- 如果页面状态仍然靠很多零散字段拼装，优先补状态建模，而不是继续加回调。

### 12. 常见误区

- 把 MVVM 简化成“页面 + ViewModel”。
- 认为只要有 ViewModel 就自动拥有良好架构。
- 页面层仍直接处理网络、数据库和复杂业务流程。
- 把所有复杂度机械搬进 ViewModel。

## 小结

Android 中的 MVVM，本质上是一种围绕页面状态组织起来的职责分工方式。View 负责显示和事件转发，ViewModel 负责状态与流程组织，Model 负责数据来源和业务规则。只要这条链路真正建立起来，页面就不再是被多路逻辑撕扯的中心，而会变成一个稳定消费状态的终点。

## 参考资料

- 参考并改写自：`Clean Android Architecture`，MVVM、页面状态和数据层边界相关章节。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，route/content 分层、只读状态暴露与屏幕组织相关章节。
- 参考并改写自：Costeira R.，《Real-World Android by Tutorials, 2nd Edition》(2022)，ViewModel 与 UI 状态在真实项目中的协作相关章节。

- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>
- ViewModel overview: <https://developer.android.com/topic/libraries/architecture/viewmodel>
- State holders and UI state: <https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Now in Android: <https://github.com/android/nowinandroid>

