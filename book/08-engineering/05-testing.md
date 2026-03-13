# 测试

很多团队在项目早期不写测试，并不是因为不知道测试重要，而是因为“先把功能做出来更紧急”。这种选择在最开始往往看起来没有问题，直到项目进入另一个阶段：功能越来越多，改动越来越频繁，线上回归开始出现，某些 bug 总要靠手工点一遍才能安心。到了这个阶段，测试的价值会突然变得非常具体。它不是为了补流程，也不是为了让仓库看起来更规范，而是为了让团队敢于继续修改代码。

参考资料里有一个很值得保留的顺序：先讨论什么风险值得自动化保护，再讨论用什么工具来写测试。这个顺序比背测试分类更重要。因为测试真正保护的，从来不是覆盖率数字，而是变化边界。本章就沿着这个思路展开：先判断风险，再决定写哪层测试，再讨论如何让 Android 项目里的测试既稳定又有收益。

## 学习目标

- 理解测试真正要保护的是变化风险，而不是形式化流程。
- 理解网络层、ViewModel 层和 UI 层各自更适合用什么方式验证。
- 理解为什么可测试性和清晰的架构边界高度相关。
- 学会用更少但更高信号的测试覆盖项目中最怕回归的行为。

## 前置知识

- 已理解 ViewModel、Repository、协程、Flow 和基本 UI 状态管理。
- 已接触过 Retrofit、Room 或至少一种常见数据来源。
- 最好已经写过简单的单元测试或看过 JUnit 基本用法。

## 正文

### 1. 测试不是为了证明“项目永远没 bug”

很多初学者对测试有一种不现实的期待：只要测试够多，项目就应该不会再出错。这个期待本身就会把测试推向两个极端。要么因为做不到“完全正确”而干脆不做，要么为了追求“什么都测到”写出大量价值很低的脚本。更稳妥的理解是，测试的目标不是证明代码绝对正确，而是在你改动之后，尽快告诉你关键行为有没有被破坏。

只要抓住这点，你对测试的判断标准就会发生变化。你不会再问“是不是每个函数都要有测试”，而会问“如果这段行为坏掉，谁会最痛，代价有多大，是否值得用自动化把它保护起来”。测试真正提供的是改动时的信心，而不是抽象意义上的完美。

### 2. 先围绕风险分层，再围绕工具选型

教材最容易误导人的地方，是先把“单元测试、集成测试、UI 测试”列成清单，再让读者自己决定写什么。更成熟的顺序应该是先判断风险类型：

- 哪些逻辑经常改。
- 哪些错误一旦上线影响最大。
- 哪些行为最难靠手工稳定回归。
- 哪些问题一旦出错会牵涉多个层次。

判断完这些问题之后，再选更合适的测试层。纯状态转换和规则判断，通常更适合单元测试；跨网络和数据库的数据链路，更适合集成测试；真正面向用户、路径价值极高的交互，再交给 UI 测试。这样得到的测试组合，会比“看到工具就想写一遍”更有性价比。

### 3. 网络和数据层测试，重点是验证链路而不是只测接口函数名

Android 项目里非常值得优先保护的一类风险，是“接口响应和本地处理链路是否仍然正确”。参考资料在这里给出的做法很实用：用 `MockWebServer` 模拟网络请求，让测试真正走 Retrofit 或 OkHttp 的解析流程；同时把响应 JSON 放进测试资源目录，尽量复用接近生产结构的样本，而不是随手拼一个理想化字符串。

这样做的意义很直接。你不是在验证“仓库方法有没有被调用”，而是在验证“真实结构的响应进来以后，这条链路能不能正常被解析、映射、落库，再输出给上层”。测试资源中的 JSON 结构越接近生产数据，你越有可能提前发现字段名、空值、列表结构和类型转换上的问题。

```kotlin
@Test
fun `repository maps response correctly`() = runTest {
    val body = javaClass.classLoader!!
        .getResource("news_response.json")!!
        .readText()

    mockWebServer.enqueue(MockResponse().setResponseCode(200).setBody(body))

    val items = repository.fetchLatest()

    assertThat(items).isNotEmpty()
    assertThat(items.first().title).isEqualTo("Jetpack Compose 1.8")
}
```

这类测试的价值，在于它既不需要真网络，也不会退化成纯 mock 断言。它能把“请求是否发出”“响应是否按预期解析”“映射逻辑是否正确”放在一条可重复、可控的测试链路里。

### 4. ViewModel 测试要盯住状态变化，不要盯实现细节

在现代 Android 项目里，ViewModel 往往是最值得优先写单元测试的层之一。原因很简单：它承接页面事件，管理异步请求，最终把数据整理成 UI 状态。一旦这里的状态切换错了，页面就会直接表现异常。但它又比 UI 层更容易隔离、更快执行，因此测试性价比很高。

参考资料给出的做法也很清晰：用 `runTest` 驱动协程测试，用 `Dispatchers.setMain` 和 `Dispatchers.resetMain` 控制主线程调度器，用 `mockk` 或 fake repository 替代真实依赖，然后断言 ViewModel 在不同输入下的 `uiState` 是否按预期变化。重点不是验证内部调用了多少个函数，而是验证“加载、成功、错误、重试、搜索切换”这些用户真正会感知到的状态迁移。

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class NewsViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val repository = FakeNewsRepository()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `load emits content when repository returns data`() = runTest(dispatcher) {
        repository.articles = listOf(Article(id = "1", title = "Compose", summary = "UI", isBookmarked = false))
        val viewModel = NewsViewModel(repository)

        viewModel.load()
        advanceUntilIdle()

        assertEquals(NewsUiState.Content(repository.articles), viewModel.uiState.value)
    }
}
```

这类测试真正保护的，是状态机是否仍然健康，而不是某个私有实现有没有按你预想的顺序执行。

### 5. UI 测试要守住关键路径，而不是把每个控件都点一遍

UI 测试最常见的误区，是试图把所有界面元素都点过一遍。这样得到的脚本往往又慢又脆，还未必能保护真正重要的行为。更成熟的做法是只围绕高价值主路径写 UI 测试，例如：

- 登录是否能完成。
- 搜索和筛选是否还能走通。
- 待办的创建和完成是否稳定。
- 新闻列表点击后能否进入详情并显示关键内容。

Jetpack Compose 的测试支持让这件事比传统视图时代轻很多。你可以通过语义节点、`testTag`、文本和 `contentDescription` 来定位组件，再用 `createComposeRule()` 驱动交互和断言。这里的关键不是“把所有像素都验证一遍”，而是守住用户最在意、产品最不能坏的几条主路径。

```kotlin
@get:Rule
val composeRule = createComposeRule()

@Test
fun `article row shows title and supports click`() {
    composeRule.setContent {
        ArticleRow(
            article = sampleArticle,
            onClick = {},
        )
    }

    composeRule.onNodeWithTag("article-row").assertExists()
    composeRule.onNodeWithText("Compose").assertIsDisplayed()
    composeRule.onNodeWithTag("article-row").performClick()
}
```

如果一个 UI 测试没有对应明确的业务价值，只是单纯在复述界面结构，它通常很快就会变成维护负担。

### 6. 可测试性首先是设计问题，其次才是测试问题

很多人一开始写测试就会觉得 Android 测试“很重”“很难”“总要拉起一堆环境”。这有时并不是测试框架本身的问题，而是代码设计已经把所有东西耦在了一起。页面直接 new Repository，Repository 直接连 Retrofit、Room、DataStore，业务规则散落在 Fragment、Compose 页面和网络回调中，这样的代码当然难测。

一旦边界清楚，测试难度会明显下降：

- 依赖注入让替换真实实现变得容易。
- Repository 边界让数据来源可以被 fake 或 mock。
- UseCase 让业务规则能在纯 Kotlin 环境里单独验证。
- 单向状态流让 ViewModel 的输入输出更容易断言。

所以测试写得顺不顺，往往是架构清不清楚的直接信号。很多时候，测试不是在“额外增加工作”，而是在逼你看见代码设计原本就存在的问题。

### 7. 保持测试稳定，比堆更多测试更重要

一个经常误报、偶尔才过、跑一次要等很久的测试套件，实际价值会迅速下降。团队最开始也许还会认真看失败原因，但只要红灯里混入太多噪音，大家很快就会对失败麻木。参考资料在这方面给出的启发很实际：尽量控制外部变量，让测试输入固定、时间可控、网络可模拟、数据可重复。

这也是为什么下面这些做法值得优先坚持：

- 用固定 JSON 资源文件而不是随机生成响应。
- 用 fake repository 或 mock 替代真实网络和数据库。
- 用测试调度器显式推进协程。
- 把 UI 测试限制在少数关键路径，而不是铺满所有页面。

测试少一点没关系，但必须值得信任。否则它不会成为工程支撑，只会成为新的噪音来源。

这也是为什么很多现代 Android 项目会优先使用 fake 而不是到处堆 mock。只要边界足够清楚，一个简单、可预测的 fake repository 往往比大量基于调用顺序的 mock 断言更稳。它更接近真实数据流，也更不容易因为内部重构、协程调度或实现细节变化而让测试变脆。测试最终要保护的是行为，不是某一版实现的调用姿势。

### 8. 一个更适合真实项目的推进顺序

如果你的项目现在几乎没有测试，最合理的推进方式通常不是先搭一套庞大体系，而是从一条最怕回归的链路开始。例如新闻应用里的“首次加载 -> 成功展示 -> 错误重试”，或者待办应用里的“创建 -> 勾选完成 -> 列表状态同步”。更现实的顺序通常是：

1. 先给状态变化最关键的 ViewModel 或 UseCase 写单元测试。
2. 再给网络或数据层补一条基于真实响应结构的链路测试。
3. 最后为用户最关键的一条交互路径补一条 UI 测试。

这样做的好处是，每加一层测试都立刻能感受到收益，而且不会因为套件膨胀太快而失去维护意愿。

## 实践任务

起点条件：

- 已有一个使用 ViewModel 和 Repository 的模块。

步骤：

1. 列出当前最怕回归的 3 个行为，而不是最容易写测试的 3 个函数。
2. 为其中一个状态切换明显的行为写一条 ViewModel 单元测试。
3. 为其中一个真实数据链路写一条基于 `MockWebServer` 和资源 JSON 的测试。
4. 再为用户最关键的一条交互补一条 Compose UI 测试。
5. 观察这些测试是否真正帮助你更敢重构，而不是只增加执行时间。

预期结果：

- 你会从风险和收益角度而不是从工具角度看测试。
- 你能更清楚地区分哪些测试该写在网络层、状态层和 UI 层。
- 你会更明显感受到边界清晰的代码为什么更容易被测。

自检方式：

- 你能说明为什么固定输入和可控环境对测试稳定性很关键。
- 你能解释一条好的 ViewModel 测试到底在保护什么状态变化。
- 你能判断某个 UI 测试是否真的对应高价值主路径。

调试提示：

- 一写测试就要启动大量真实依赖，优先回头检查代码边界是否过度耦合。
- 测试经常随机失败，优先检查时间、网络、线程调度和共享状态是否不可控。
- 写了很多测试却依然不敢改代码，通常说明测试重点没有落在高风险行为上。

### 常见误区

- 把测试理解成上线前补一层流程。
- 只追求覆盖率，不判断行为价值和风险等级。
- 大量依赖真实网络、真实时间和真实环境，导致测试又慢又脆。
- 用很多 UI 测试去覆盖原本更适合在 ViewModel 或数据层验证的逻辑。

## 小结

测试的真正价值，不是让项目显得更规范，而是为变化建立一条可重复、可依赖的安全边界。只要你先围绕高风险行为设计测试，再让边界清晰的架构支撑这些测试，Android 项目里的测试就不会只是额外成本，而会成为持续演进时最可靠的一层工程保险。

## 参考资料

- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，测试边界、fake 依赖与工程可测试性相关章节。
- 参考并改写自：`Clean Android Architecture`，UseCase、Repository、状态层与测试设计相关章节。
- 参考并改写自：Costeira R.，《Real-World Android by Tutorials, 2nd Edition》(2022)，网络层、ViewModel 与 Compose UI 测试相关章节。

- Test apps on Android: <https://developer.android.com/training/testing>
- Test your app's architecture: <https://developer.android.com/topic/architecture/testing>
- Testing in Jetpack Compose: <https://developer.android.com/develop/ui/compose/testing>
