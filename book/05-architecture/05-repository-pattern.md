# Repository 模式

Repository 是现代 Android 项目里最常见、也最容易被形式化使用的一层。很多人知道“架构里应该有 Repository”，却说不清它为什么存在、它到底应该封装什么，以及哪些东西其实不该塞进去。于是就会出现两种常见问题：一种是页面和 ViewModel 仍然直接依赖数据库、网络接口和 DataStore，Repository 形同虚设；另一种是 Repository 被用成了“什么逻辑都能放”的大杂烩。

本章的目标，就是把 Repository 从“为了分层多加一层”还原为它真正的价值：统一数据入口、隐藏来源细节、稳定上层依赖，并为离线缓存和单一可信来源提供清晰落点。

## 学习目标

- 理解 Repository 为什么会成为现代 Android 架构的关键一层。
- 理解 Repository 与 ViewModel、DataSource、网络层和本地数据库的边界。
- 理解什么场景值得引入 Repository，什么场景不必过度抽象。
- 理解 Repository 为什么是离线优先和缓存设计的核心落点。

## 前置知识

- 已理解网络层、本地数据层和 ViewModel 的基本角色。
- 已知道页面不应直接依赖多个底层数据来源。

## 正文

### 1. Repository 最核心的价值，是给上层一个稳定的数据入口

Android 官方架构建议中明确写到，数据层应通过 repository 暴露应用数据，UI 层组件不应直接和数据源交互。这里的数据源包括数据库、DataStore、SharedPreferences、GPS、网络状态提供者等。这个建议之所以重要，是因为上层真正关心的往往不是“数据从哪里来”，而是“我现在能拿到什么、该显示什么”。

如果没有 Repository，常见情况通常会是：

- ViewModel 直接调用 Retrofit。
- 页面又直接读 Room 或 DataStore。
- 某些地方额外读取内存缓存。

这种结构一开始看似直接，随着功能增加就会迅速失控，因为页面上层开始知道越来越多来源细节。

### 2. Repository 在屏蔽的，不只是技术细节，还有来源竞争

很多人把 Repository 理解成“把网络和数据库包起来”。这当然是它的一部分，但更重要的是：它帮助你阻止多个来源同时直接推到上层，避免出现来源竞争。

比如一个新闻列表页，如果页面既直接看网络返回，又直接订阅数据库，再从别处读一个缓存，就很难保证 UI 到底以谁为准。Repository 的价值正在于把这些来源统一进来，再以一个更稳定的出口暴露给上层。

### 3. 一个健康的 Repository 通常具备哪些特征

Repository 的职责边界可以用四个关键词概括：

- 面向某类业务数据，而不是面向某个底层技术。
- 对上暴露稳定 API，而不是直接暴露数据源细节。
- 对下可以协调本地、远程、缓存和刷新策略。
- 尽量不直接承载页面文案和 UI 细节。

例如，`ArticleRepository` 应该表达“文章数据”这一类业务能力，而不是变成“统一什么都管”的全局工具类。

### 4. Repository 与 DataSource 的区别必须弄清

很多项目同时有 `RemoteDataSource`、`LocalDataSource` 和 `Repository`，但如果不理解它们的差异，就很容易写成三层转发。

一个更实用的区分方式是：

- DataSource 更贴近某个具体来源，例如 Retrofit API、Room DAO、DataStore、文件读写器。
- Repository 更贴近某类业务数据的统一入口。

Repository 可以组合多个 DataSource，但它不应退化成“只是调用一个 DataSource 再原样返回”的薄壳。如果它没有在统一来源、隐藏细节或稳定接口方面提供价值，那这层通常还没有站住。

### 5. Repository 为什么是离线缓存的关键节点

Android 官方的 offline-first 指南建议 Repository 在有网络访问时始终同时拥有本地和远程数据源，并把本地数据源作为规范读取入口。这条建议几乎直接点出了 Repository 的位置：它是协调来源的最佳落点。

例如，Repository 可以统一回答：

- 页面读取时是先看本地还是等远程。
- 远程结果回来后如何写回数据库。
- 网络失败时是否保留旧内容。
- 下拉刷新时是否强制更新。

这些都不应该由页面自己处理，也不应完全塞给 DAO 或 Retrofit 接口。

### 6. Repository 不应该直接写死页面语义

Repository 是数据边界，不是 UI 层替代物。它可以返回 `ApiResult`、业务模型、Flow 或组合后的数据结果，但通常不应该直接返回“这里弹红色 Toast”“这里显示空页面插图”。这些决定仍然属于 ViewModel 和 UI 层。

换句话说，Repository 可以解释来源和数据，但不应过早替页面决定呈现方式。否则一旦多个页面对同一结果的展示策略不同，你就会发现 Repository 被 UI 语义污染得越来越严重。

### 7. 什么时候需要引入 Repository，什么时候不需要过度抽象

Android 官方建议 even if they just contain a single data source，也就是说即使只有一个来源，也建议为数据层创建 Repository。这个建议主要是为了让上层一开始就依赖稳定接口，而不是直接依赖底层工具。

但这不意味着你需要为每一个极小功能都造复杂的 Repository 体系。更合理的判断是：

- 如果上层已经开始依赖多个来源，Repository 几乎一定需要。
- 如果某类数据会被多个页面复用，Repository 很有价值。
- 如果页面还非常小、来源非常单一，也可以先保持简单，但仍应保留清晰的数据入口设计意识。

### 8. 一个更接近真实项目的最小示例

下面的示例展示 Repository 如何统一协调本地与远程来源，而不是简单转发：

```kotlin
class ArticleRepository(
    private val articleDao: ArticleDao,
    private val articleApi: ArticleApi
) {
    fun observeArticles(): Flow<List<Article>> {
        return articleDao.observeAll()
            .map { entities -> entities.map { it.toArticle() } }
    }

    suspend fun refreshArticles(): ApiResult<Unit> {
        return try {
            val remote = articleApi.getArticles()
            articleDao.replaceAll(remote.map { it.toEntity() })
            ApiResult.Success(Unit)
        } catch (e: IOException) {
            ApiResult.NetworkError(e)
        } catch (e: HttpException) {
            ApiResult.HttpError(e.code(), e.message())
        }
    }
}
```

这个例子里最重要的不是某个方法签名，而是：

- 页面读取并不直接依赖远程接口。
- Repository 统一处理来源协调。
- 远程结果不会直接跳过本地写回 UI。

### 9. 实践任务

起点条件：

- 已有一个页面直接或间接依赖网络、本地数据库、DataStore 中的至少一种来源。

步骤：

1. 列出这个页面当前直接接触的所有数据来源。
2. 判断哪些来源本应由 Repository 统一协调。
3. 设计一个以“业务数据”为中心的 Repository 接口，而不是以底层技术为中心。
4. 检查现有 Repository 是否已经承载了明显属于页面层的逻辑。
5. 把一个页面中的直接数据源调用替换成 Repository 调用。

预期结果：

- 上层会明显减少对底层来源的了解。
- 数据来源会更容易统一，缓存和离线策略也更容易落地。
- 你能更清楚地区分 DataSource 和 Repository 的边界。

自检方式：

- 你能解释：为什么 UI 层不应直接和 DAO、Retrofit、DataStore 打交道。
- 你能判断：某个 Repository 是否真的提供了统一入口，还是只是转发壳层。
- 你能说出：Repository 为什么是离线优先设计的关键节点。

调试提示：

- 如果 ViewModel 同时持有 API、DAO、Preferences 对象，说明 Repository 这一层还没真正建立。
- 如果 Repository 内部写满页面文案和导航决定，说明它已经越界到 UI 层。
- 如果一个 Repository 名字极大但职责不清，优先按业务数据边界重新拆分。

### 10. 常见误区

- 认为 Repository 只是“为了分层多加一层”。
- Repository 只做简单转发，没有真正统一来源。
- 所有业务代码都往 Repository 里塞。
- ViewModel 或页面仍直接依赖多个底层来源。

## 小结

Repository 的真正价值，不在于目录里多一个名字，而在于它是否成为上层稳定依赖的数据入口。只要这层站稳，ViewModel 就能专注于页面状态，数据层也更容易承接缓存、离线和结果包装等复杂职责。


## 参考资料

- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
- Build an offline-first app：<https://developer.android.com/topic/architecture/data-layer/offline-first>
- Data layer：<https://developer.android.com/topic/architecture/data-layer>
