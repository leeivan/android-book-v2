# Repository 模式

当页面开始同时面对网络、数据库、缓存和用户本地操作时，最容易发生的一件事，就是数据入口失控。一个列表页从 Room 读缓存，刷新时直接打 Retrofit，收藏状态又自己改数据库，错误处理还散落在页面和 ViewModel 里。功能勉强能跑，但一旦需求继续增长，你会发现几乎没人能完整解释“这份数据到底从哪来、谁说了算、失败后应该怎么办”。

`Repository` 模式的价值，就在于给上层提供一个稳定、可理解的数据入口。它本质上是内外层之间的重要接缝：内层只声明自己需要什么样的数据能力，外层再去接住网络、数据库、文件或缓存实现。因此 Repository 不是“多包一层”那么简单，而是在回答：某个页面或某项业务，应该通过什么统一边界去拿数据、写数据、决定缓存和同步策略。

## 学习目标

- 理解 Repository 真正解决的是数据入口和数据策略混乱问题。
- 理解 Repository 与数据源、数据库、网络接口之间的区别。
- 理解单一可信来源和数据映射在 Repository 中的作用。
- 学会判断哪些逻辑该留在 Repository，哪些不该放进去。

## 前置知识

- 已理解 ViewModel 的页面状态职责。
- 已接触 Room、网络请求和本地缓存。

## 正文

### 1. 没有 Repository 时，上层为什么会越来越乱

先看一个很常见的页面。打开列表页时，页面先查本地缓存；用户下拉刷新时，再发网络请求；点击收藏按钮时，直接更新数据库；失败后，页面自己判断是显示旧数据还是错误提示。

表面上看，每一步都“做对了”。真正的问题在于，上层已经开始直接处理这些底层问题：

- 先查本地还是先查远程。
- 刷新失败时保留旧数据还是报错。
- 收藏状态写回后，列表怎样同步刷新。
- DTO、Entity、UI model 该在什么地方转换。

一旦这些判断散落在多个页面或多个 ViewModel 中，项目很快就会出现同一份数据被不同地方以不同规则处理的情况。Repository 就是为了把这些规则收回来。

### 2. Repository 不是数据源本身，而是对上层的统一入口

这条边界很重要。`RemoteDataSource` 负责访问远程接口，`LocalDataSource` 负责访问数据库或文件，它们解决的是“怎么拿到数据”。Repository 解决的是另一层问题：“对当前业务来说，应该怎样组织这些来源并对外暴露”。

可以把它理解成：

- 数据源负责和具体媒介打交道。
- Repository 负责决定上层该如何感知数据。

这也是为什么 Repository 不应该只是简单透传 Retrofit 或 DAO 的调用。如果它什么都不做，那么上层仍然必须自己理解所有数据来源和规则，分层收益就不存在了。

### 3. Repository 真正承接的是“数据策略”

Repository 最有价值的地方，不在“调用了几个接口”，而在它承接了数据策略。例如：

- 先读本地，再决定是否刷新。
- 写操作成功后同步更新本地。
- 失败时优先保留旧数据。
- 多个来源的数据怎样合并。
- 上层到底拿到流式数据还是一次性结果。

这些判断之所以适合放在 Repository，是因为它们既不属于页面显示逻辑，也不属于底层访问细节，而是介于两者之间的数据组织规则。

### 4. 单一可信来源为什么经常和 Repository 一起出现

现代 Android 架构里，Repository 往往和“单一可信来源”一起讲。原因很现实：如果网络结果、数据库结果和内存状态都可以各自直接驱动页面，那么页面迟早会被多个来源撕裂。

更稳定的方式通常是：

- 明确一份数据最终以哪一层为准。
- 让上层只从一个主要出口读取状态。
- 其他来源通过同步和更新机制去影响这个出口。

在很多本地优先项目里，这个可信来源往往是本地数据库。网络结果不是直接喂给页面，而是先写入数据库，再由数据库流驱动上层。这样页面永远知道该看谁，而不是同时盯着多条链路。

### 5. Repository 也常常是映射发生的地方

DTO、Entity、Domain model、UI model 这几类对象如果混在一起，代码会很快变得脆弱。Repository 很适合承接一部分映射工作，因为它正处在“下层原始数据”和“上层可消费数据”之间。

但要注意边界：

- 从网络 DTO 到本地 Entity 的映射，通常适合在数据层完成。
- 从数据层对象到页面专用 UI model 的映射，常常更适合在 ViewModel 附近完成。

也就是说，Repository 负责的是“把来源整理成稳定数据结构”，不是把一切映射全塞进自己内部。

### 6. 一个更接近真实项目的 Repository

下面这个例子展示的是新闻数据在本地优先结构中的一个最小 Repository:

```kotlin
class NewsRepository(
    private val remoteDataSource: NewsRemoteDataSource,
    private val localDataSource: NewsLocalDataSource
) {

    fun observeArticles(): Flow<List<Article>> {
        return localDataSource.observeArticles()
    }

    suspend fun refreshArticles(): ApiResult<Unit> {
        return when (val result = remoteDataSource.fetchArticles()) {
            is ApiResult.Success -> {
                localDataSource.replaceAll(result.data.map { dto ->
                    dto.toEntity()
                })
                ApiResult.Success(Unit)
            }
            is ApiResult.Failure -> result
        }
    }

    suspend fun toggleBookmark(id: String) {
        localDataSource.toggleBookmark(id)
    }
}
```

这个例子里，Repository 承接的不是“所有逻辑”，而是三件关键事：

- 对上层隐藏了本地和远程来源。
- 明确了页面观察的主要出口是本地流。
- 在刷新时决定如何把远程结果写回可信来源。

### 7. 不是什么都该放进 Repository

Repository 也很容易被滥用。常见错误包括：

- 把页面专属逻辑硬塞进去。
- 把完全不相干的业务动作放进同一个 Repository。
- 让 Repository 同时承担复杂流程编排和业务规则判断。

更稳的判断标准是：如果某段逻辑的核心问题是“数据从哪来、怎么合并、怎么同步、谁是可信来源”，它通常适合 Repository；如果核心问题是“某个页面怎样显示”或“一个跨页面业务动作如何编排”，那通常应该交给 ViewModel 或 UseCase。也正因为如此，Repository 最值得保护的不是某个具体 Retrofit 或 Room 调用，而是那条对上层稳定暴露的数据能力边界。

### 8. 为什么 Repository 经常让测试变容易

只要上层不再直接依赖 Retrofit 和 DAO，测试就会容易很多。因为 ViewModel 面对的是一个更稳定的抽象入口，它不需要知道底层到底是网络、数据库还是内存假数据。

这也是 Repository 的工程价值之一：它不只是让代码看起来分层，更让上层逻辑具备更明确的替换点和测试边界。

### 9. 实践任务

起点条件：

- 已有一个页面会同时接触网络和本地数据。

步骤:

1. 画出当前页面的数据来源图，标明它分别直接调用了哪些对象。
2. 判断这些来源中，哪些应被收回到统一 Repository。
3. 明确一份数据的主要可信来源是什么。
4. 把一次刷新流程改成“远程拉取 -> 更新可信来源 -> 上层重新观察”的结构。
5. 检查对象映射是否仍然混在页面层。

预期结果:

- 你会更清楚页面到底该从哪里拿数据。
- 数据来源策略会从上层回收到数据层。
- 上层状态组织会更容易保持稳定。

自检方式:

- 你能解释 Repository 和数据源之间的区别。
- 你能说明为什么“多来源直接驱动页面”很危险。
- 你能判断某段逻辑属于数据策略还是页面状态逻辑。

调试提示:

- 如果 ViewModel 同时依赖多个 DAO 和多个接口，优先考虑是否缺少 Repository。
- 如果远程和本地数据都能各自直接改页面，优先先确定可信来源。
- 如果 Repository 里开始充满页面文案和导航判断，说明边界又混了。

### 10. 常见误区

- 把 Repository 写成对 DAO 或接口的机械透传。
- 不区分 Repository 和数据源。
- 没有可信来源，多个来源同时驱动页面。
- 把页面逻辑和流程编排一并塞进 Repository。

## 小结

Repository 模式真正解决的是“数据入口和数据策略混乱”的问题。它让上层不必同时理解本地、远程、缓存和同步规则，而只面对一个更稳定的数据边界。只要边界清晰、可信来源明确、映射职责合适，Repository 就会成为连接页面状态和数据层的关键中枢。

## 参考资料

- 参考并改写自本地 PDF：`Clean Android Architecture`，Repository 接口、数据边界、Dependency Rule 与数据层实现相关章节。
- 参考并整理自本地 PDF：Bennett M.，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，data-domain-presentation 分层、feature 模块与数据能力组织相关章节。
- Data layer guide: <https://developer.android.com/topic/architecture/data-layer>
- Offline-first architecture: <https://developer.android.com/topic/architecture/data-layer/offline-first>
- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>

