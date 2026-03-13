# Clean Architecture 示例

很多读者第一次接触 `Clean Architecture`，会立刻被同心圆、依赖倒置、实体模型这些词压住。于是常见的误解有两种：一种把它看成离真实项目很远的理论图示，另一种把它机械理解成“每个功能都必须配齐 entity、use case、repository、data source”。这两种理解都抓错了重点。真正有价值的 Clean Architecture，不是强行增加层数，而是在项目越来越复杂时，把真正需要长期稳定的边界保护下来。

把这一章放在综合项目部分的最后，不是为了额外引入一套新宗教，而是为了回头整理整本书已经讲过的主线。你前面学过的 ViewModel、Repository、UseCase、Hilt、模块化和测试，并不是彼此独立的知识点；它们其实都在围绕同一件事服务：让变化优先停留在外层，让业务规则尽量留在更稳定的内层。更偏架构与可扩展工程的本地资料也反复说明，成熟项目的关键从来不是“层越多越高级”，而是“变化来了以后，哪些地方需要改，哪些地方不该被连带拖动”，以及当应用继续扩大时，这些边界又怎样进一步长进 `feature` 模块和共享 `core` 模块的层级里。

## 学习目标

- 理解 Clean Architecture 真正要保护的是依赖方向和业务边界。
- 理解 Domain、UseCase、Repository、DTO、模块化之间的分工关系。
- 学会判断什么场景值得引入 Domain 层，什么场景不必模板化拆层。
- 能把前面章节的 MVVM、数据层和工程化内容组织成一套更稳的项目结构。

## 前置知识

- 已理解 ViewModel、Repository、依赖注入和基本分层。
- 已接触过 Room、Retrofit、StateFlow 或 LiveData 等现代 Android 开发常见组件。
- 最好已经完成过待办、新闻或聊天这类中等复杂度案例。

## 正文

### 1. Clean Architecture 试图解决的，是复杂度失控

项目小的时候，页面层多写一点判断、数据层顺手塞一点业务规则、网络响应直接映射给 UI，往往也不会立刻出大问题。真正的问题出现在项目开始持续演进以后。列表和详情开始共享数据，收藏、同步、搜索、分页、权限、后台任务逐渐叠加，多个开发者同时修改同一条功能链路，这时原来“凑合能跑”的结构会迅速暴露出代价：

- 页面层混入越来越多业务判断。
- 数据来源策略泄漏到 UI，导致页面必须知道“从网还是从库拿”。
- 同一条业务规则在多个入口重复实现。
- 一次替换网络库、数据库或页面框架，会牵动并不该变化的业务代码。

Clean Architecture 想解决的正是这种局面。它的价值不在于画出更漂亮的架构图，而在于让复杂项目里的变化有边界、有方向、有承接点。

### 2. 它的核心不是“有几层”，而是“依赖朝哪里指”

教材里最值得记住的，不是 Presentation、Domain、Data 这几个名字本身，而是一个更根本的判断：越靠近业务核心的代码，越不应该依赖越靠外、越容易变化的实现细节。UI、数据库、网络库、序列化注解、页面框架、系统 API 都属于外层实现细节；业务规则、业务动作和面向业务的模型则应该更靠内。

这就是经典的 Dependency Rule。依赖箭头应该从外向内指，而不是从内向外反咬实现细节。UI 可以依赖 UseCase，UseCase 可以依赖仓库接口，数据层再去实现这些接口并接住 Retrofit、Room 或 DataStore。这样一来，外层可以换技术方案，内层业务规则却不需要跟着动。

如果把这个原则讲得再直白一点，就是：

- 页面负责展示状态和接收事件。
- 业务层负责解释“这次动作对业务意味着什么”。
- 数据层负责回答“数据从哪来、怎么存、怎么同步”。
- 具体技术框架只负责把实现做出来，不应该反过来主导业务设计。

### 3. Domain 层是手段，不是仪式

参考资料里有一个很重要的提醒：并不是所有应用、所有页面、所有流程都必须有 Domain 层。如果某个功能几乎没有真正的业务规则，只是“调用仓库取数据，然后展示”，那让 ViewModel 直接依赖 Repository 往往就足够了。Domain 层真正适合出现的时机，是你已经能够明确看见可重复、可复用、值得独立命名的一段业务动作。

换句话说，`UseCase` 不该为了分层而出现，而应该为了业务动作而出现。比如：

- “刷新新闻并合并本地收藏状态”
- “按用户位置筛选附近门店”
- “退出登录时清理本地会话并上报埋点”
- “提交表单前做权限、字段和重复请求校验”

这些动作都不是简单的透传调用，它们包含业务判断、顺序控制、错误处理或复用价值。只有在这种地方，Domain 层才真正开始产生收益。否则，盲目拆出一层只会制造更多空转发代码。

### 4. UseCase 真正封装的是“可重复的业务动作”

UseCase 适合承载的，不是所有代码，而是与某个应用动作或业务流程强相关、而且有重复价值的逻辑。它通常处在 Presentation 和 Data 之间，接受上层的意图，协调下层的数据能力，然后输出更符合业务语义的结果。

例如在新闻应用里，首页打开时并不是简单执行一次网络请求。一个更像真实项目的动作可能包含：

1. 先读取本地缓存，让页面快速进入可展示状态。
2. 再向远程请求最新内容。
3. 把返回结果映射成数据库实体并落库。
4. 在新内容里保留本地字段，例如收藏状态或最近阅读时间。
5. 由数据库变化反向驱动页面刷新。

如果这条链路只写在 ViewModel 里，页面层就会迅速变成业务调度中心。把它抽成 `RefreshHeadlinesUseCase` 或 `ObserveHeadlinesUseCase` 后，ViewModel 只需要表达“我现在想刷新”或“我现在想观察某个主题的新闻”，而不必承担这条流程内部的策略判断。

### 5. Domain Model 不该和 DTO 混成一类东西

很多项目初期图省事，会直接让一份数据类同时承担三种职责：既是 Retrofit 的响应体，又是 Room 的实体，又直接给 UI 当显示模型。这样短期很方便，长期问题很明显。远程响应需要序列化注解，本地实体需要数据库注解，UI 还可能需要本地字段，例如 `isBookmarked`、`lastViewedAt` 或 `readProgress`。一旦这些职责全压在一个类上，模型就会被各种实现细节绑死。

更稳妥的做法是把 Domain model 和 DTO 分开：

- Remote DTO 只关心接口实际返回的字段和序列化需求。
- Local Entity 只关心本地存储需要的字段和数据库注解。
- Domain model 只表达业务上真正关心的数据结构，不依赖某个特定库。

这样一来，远程接口没有返回的本地字段就不会被硬塞进网络模型里；以后就算从 Retrofit 换到其他网络库，或者从 Room 换到别的本地存储，真正面向业务的模型和用例也不需要被迫一起改。

```kotlin
// domain/model/Article.kt
data class Article(
    val id: String,
    val title: String,
    val summary: String,
    val isBookmarked: Boolean,
)

// data/remote/RemoteArticleDto.kt
data class RemoteArticleDto(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("summary") val summary: String,
)

// data/local/LocalArticleEntity.kt
@Entity(tableName = "articles")
data class LocalArticleEntity(
    @PrimaryKey val id: String,
    val title: String,
    val summary: String,
    val isBookmarked: Boolean,
)
```

这三个类型看起来更啰嗦，但它们分别承担了远程、存储和业务语义，长期维护成本反而更低。

### 6. Repository 的接口更适合放在内层，实现在外层

很多团队会不自觉写出这样的关系：UseCase 依赖具体的 `NewsRepositoryImpl`，而 `NewsRepositoryImpl` 又内部拿着 Retrofit、Room 和各种 mapper。这种写法表面也能工作，但它已经让 Domain 层反向依赖了外层实现，违反了 Dependency Rule。

更健康的做法是把仓库接口定义在更靠内的地方，让数据层来实现。这样 UseCase 依赖的是业务语义上的数据能力，而不是某个具体实现类。

```kotlin
// domain/repository/ArticleRepository.kt
interface ArticleRepository {
    fun observeHeadlines(topic: String): Flow<List<Article>>
    suspend fun refreshHeadlines(topic: String)
}

// domain/usecase/RefreshHeadlinesUseCase.kt
class RefreshHeadlinesUseCase(
    private val repository: ArticleRepository,
) {
    suspend operator fun invoke(topic: String) {
        repository.refreshHeadlines(topic)
    }
}
```

随后由数据层实现 `ArticleRepository`，把 Retrofit、Room、mapper 和缓存策略都留在外层。这样业务层看到的是“我需要一个能够刷新和观察文章的边界”，而不是“我必须依赖某个带着网络库细节的类”。

### 7. 一个更像真实项目的目录组织

Clean Architecture 真正落地时，通常会和 MVVM、依赖注入、模块化一起工作。一个新闻应用的结构可以像下面这样：

```text
presentation/
  news/
    NewsViewModel.kt
    NewsUiState.kt
domain/
  model/
    Article.kt
  repository/
    ArticleRepository.kt
  usecase/
    ObserveHeadlinesUseCase.kt
    RefreshHeadlinesUseCase.kt
data/
  remote/
    RemoteArticleDto.kt
    NewsApi.kt
  local/
    LocalArticleEntity.kt
    ArticleDao.kt
  repository/
    ArticleRepositoryImpl.kt
  mapper/
    ArticleMapper.kt
```

这里最关键的不是目录名字，而是关系是否清楚：Presentation 只依赖 Domain，Data 也依赖 Domain，Domain 自己不直接依赖 Retrofit、Room 或 Compose。对更大的项目来说，这一层目录关系往往还会继续上升为模块关系，例如 `feature:news`、`feature:bookmark` 再各自拥有 presentation-domain-data 的局部组织，而网络、数据库、设计系统等稳定共享能力则沉到更小的 `core` 模块中。模块化进一步把这种边界从“约定”变成“构建时约束”，测试也会因此更容易写，因为业务层可以在不启动整套 Android 环境的情况下独立验证。

### 8. 它和本书前面所有内容，其实是一条线

如果你回头看前面章节，会发现本书已经在为这套结构做铺垫：

- ViewModel 让页面状态有清晰承载点。
- Repository 让多个数据源和上层 UI 解耦。
- UseCase 把复杂动作从页面事件里抽出来。
- Hilt 把依赖关系的装配从业务代码里拿走。
- 模块化让边界从概念变成编译时现实。
- 测试则反过来验证这些边界是否真的清楚。

也就是说，Clean Architecture 并不是一套突然降临的新语法，而是把这些东西收束成一个更稳定的工程判断：谁依赖谁，谁负责什么，变化来了以后先动哪一层。

### 9. 更稳妥的落地顺序，是从痛点开始而不是从模板开始

如果你想在自己的项目里引入更干净的结构，不要一上来就全面翻修。更现实的顺序通常是：

1. 先挑一条已经明显变得难改、难测、难协作的功能链路。
2. 画出它当前的依赖方向，看业务逻辑是否已经塞进 UI 或数据实现里。
3. 找出其中真正可重复的业务动作，把它抽成 UseCase。
4. 把面向业务的仓库接口挪到更靠内的位置，由数据层实现。
5. 再判断 Domain model、DTO 和本地实体是否已经值得拆开。
6. 最后才考虑通过模块化把边界进一步强制化。

这样的重构是“为了解决具体复杂度”，而不是“为了让项目更像某张架构图”。只要你始终围绕痛点推进，Clean Architecture 会成为减负工具；如果你只是为了形式补齐模板，它很快就会变成维护负担。

## 实践任务

起点条件：

- 已有一个使用 ViewModel 和 Repository 的中等复杂度案例。

步骤：

1. 选一条已经出现多入口复用或状态调度复杂的问题链路，例如搜索、同步、收藏或权限校验。
2. 画出现在的依赖图，标出页面层、业务规则和数据实现混在一起的位置。
3. 判断是否真的存在一段可命名、可复用的业务动作，若存在再抽出 UseCase。
4. 检查仓库接口是否依赖了外层实现细节，并把接口收敛到内层。
5. 审视当前模型是否同时承担远程、本地和业务三种职责，必要时拆出 DTO 与 Domain model。

预期结果：

- 你会更清楚地知道哪些边界值得保护。
- 你会把 Clean Architecture 理解成依赖治理，而不是分层模板。
- 你会发现测试和模块化会自然跟着变容易。

自检方式：

- 你能说明为什么 Domain 层在没有业务逻辑时是可选的。
- 你能区分 UseCase、Repository 接口、DTO 和 Domain model 各自承接什么问题。
- 你能判断某个抽象到底是在减耦合，还是只是在增加文件数量。

调试提示：

- 如果一个功能拆出很多层以后仍然没人说得清每层存在的理由，通常已经开始过度模板化。
- 如果业务层仍然直接依赖 Retrofit、Room 或其他外层框架，说明依赖方向还没有真正理顺。
- 如果页面必须知道数据到底来自网络还是数据库，说明边界还没有被正确承接。

### 常见误区

- 把 Clean Architecture 当成固定四件套模板。
- 不看项目复杂度，强行给每个简单功能都套 UseCase。
- 让 Domain model 带着数据库注解和网络序列化注解到处跑。
- 只谈层数，不谈依赖方向和变化成本。

## 小结

Clean Architecture 真正要保护的，不是某张教科书架构图，而是复杂项目里的依赖方向和业务边界。只要你把它理解成“把真正会长期变化和长期稳定的部分分开”，它就会自然和本书前面学过的 ViewModel、Repository、UseCase、Hilt、测试与模块化连成一条完整工程主线；如果把它当模板照抄，它很快就会退化成一堆没有收益的空转发代码。

## 参考资料

- 参考并改写自本地 PDF：`Clean Android Architecture`，Dependency Rule、UseCase、Repository 接口与 Domain model 拆分相关章节。
- 参考并整理自本地 PDF：Bennett M.，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，feature module、module hierarchy、Navigation Compose 与多模块应用结构相关章节。
- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>
- Guide to app modularization: <https://developer.android.com/topic/modularization>
- Now in Android: <https://github.com/android/nowinandroid>
