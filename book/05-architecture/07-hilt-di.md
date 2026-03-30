# Hilt 与依赖注入

很多 Android 项目在最初只有几个页面时，并不会立刻觉得依赖管理有多痛苦。页面里自己 new 一个 Repository，Repository 里自己 new 一个 Retrofit 或 DAO，似乎也能跑。问题往往要等项目开始增长以后才集中爆发: 同一个依赖被多处重复创建，构造链越来越长，测试替换困难，生命周期和对象作用域开始对不上。到了这一步，你会发现真正麻烦的已经不是“少写了几行代码”，而是对象组装这件事完全失控了。

依赖注入要解决的，就是“对象怎么被创建、怎么被复用、怎么在不同生命周期里稳定地交给需要它的地方”。放到更完整的架构语境里看，`Hilt` 的价值还在于它把“依赖朝哪里流动”和“对象该活多久”这两件事同时收回来，让 Repository、UseCase、数据源和 ViewModel 的组装关系不再散落在页面里。它并不只是帮你少写模板，而是把原本分散在各个页面和工厂里的装配逻辑收回到一个更清晰的系统里。

## 学习目标

- 理解依赖注入真正解决的是对象组装和作用域问题。
- 理解 Hilt 在 Android 中为什么特别有价值。
- 理解 `@Inject`、`@Module`、`@Provides`、`@Singleton`、`@HiltViewModel` 的基本职责。
- 学会判断哪些对象该交给 Hilt 管，哪些对象不值得过度注入。

## 前置知识

- 已理解 ViewModel、Repository、UseCase 和数据层边界。
- 已接触模块构建和基础工程结构。

## 正文

### 1. 没有依赖注入时，问题通常不是马上爆炸，而是慢慢扩散

设想一个文章列表页。最开始它自己创建 Repository，Repository 再创建远程接口和本地数据库包装。第一版代码看起来很直接。等到第二个页面也需要同一个 Repository，第三个页面又要加 UseCase，第四个页面还要在测试里替换假实现时，问题就来了:

- 对象创建散落在多个地方。
- 同一依赖可能被重复初始化。
- 测试时很难注入替身对象。
- 生命周期谁长谁短越来越说不清。

依赖注入不是为了“显得高级”，而是为了解决这些对象组装和替换问题。

### 2. 依赖注入真正做的是“把创建和使用分开”

这是依赖注入最核心的想法。一个类最理想的状态，是只声明自己需要什么，而不亲自决定这些对象怎么被创建。这样一来:

- 类的职责更单一。
- 依赖关系更容易看清。
- 替换实现会更容易。

在 Android 里，这件事尤其重要，因为页面、ViewModel、Repository、数据库、网络客户端各自拥有不同生命周期。只要创建和使用不分开，生命周期问题很快就会缠在一起。

### 3. 为什么 Hilt 在 Android 中特别自然

纯粹从 Java / Kotlin 角度看，依赖注入框架并不是 Android 独有。但 Android 的组件模型让这件事变得更复杂:

- Activity 和 Fragment 由系统创建。
- ViewModel 需要和页面作用域协调。
- Application、Activity、Fragment、ViewModel 生命周期不同。
- 测试和生产实现往往需要替换。

Hilt 的价值在于，它已经把这些 Android 组件边界考虑进来了。你不必再手写大量工厂和组件装配代码，就可以把对象创建放到更稳定的位置。

### 4. 先把 Hilt 看成“对象装配系统”，而不是注解清单

很多初学者学 Hilt 时，注意力会被注解淹没。更好的理解方式是，先把 Hilt 看成一个对象装配系统:

- `@Inject` 表示“这个对象可以通过构造函数注入”。
- `@Module` / `@Provides` 用于提供那些无法直接构造函数注入的对象。
- `@InstallIn` 说明这些提供规则属于哪个组件作用域。
- `@HiltViewModel` 表示这个 ViewModel 由 Hilt 负责提供依赖。

只要先理解“它在帮你装配对象”，注解就不再只是机械记忆。

### 5. 作用域是 Hilt 在 Android 中最值得认真理解的部分

依赖注入真正难的地方，从来不是写注解，而是决定对象该活多久。对 Android 来说，这一点尤其关键。比如:

- `OkHttpClient`、数据库实例通常适合应用级单例。
- Repository 往往也适合较长生命周期复用。
- 页面状态对象则不应该被做成全局单例。

如果作用域划错，就会出现两类问题:

- 本该复用的对象被反复创建，浪费资源。
- 本该短命的对象活得太久，状态污染或内存泄漏风险变高。

所以学 Hilt 时，真正要学的是对象生命周期判断。只有当作用域判断和架构边界一起成立时，依赖注入才会真正减轻复杂度，而不是只把创建代码搬到别处。

### 6. 一个最小但真实的 Hilt 配置

下面这个例子展示 Hilt 如何把网络和 Repository 的装配从页面里拿走:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder().build()

    @Provides
    @Singleton
    fun provideRetrofit(client: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://api.example.com/")
            .client(client)
            .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
            .build()
    }
}

@HiltViewModel
class ArticleListViewModel @Inject constructor(
    private val repository: ArticleRepository
) : ViewModel()
```

这段代码最重要的不是注解名字，而是组装边界终于被收回来了:

如果把 Hilt 放回一个最小页面链路里，它的装配路径会更清楚：

```kotlin
@HiltAndroidApp
class TodoBookApp : Application()

interface ArticleRepository {
    suspend fun getArticles(): List<Article>
}

class DefaultArticleRepository @Inject constructor(
    private val service: ArticleService,
) : ArticleRepository {
    override suspend fun getArticles(): List<Article> = service.fetchArticles()
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindArticleRepository(
        impl: DefaultArticleRepository,
    ): ArticleRepository
}

@AndroidEntryPoint
class ArticleListActivity : AppCompatActivity() {
    private val viewModel: ArticleListViewModel by viewModels()
}
```

这组代码把 Hilt 在 Android 里的最小闭环串起来了：`Application` 打开注入系统，`Module` 或 `@Binds` 决定接口该绑定到哪个实现，`ViewModel` 只声明依赖，Activity 则通过 `@AndroidEntryPoint` 接入这条装配链。这样一来，对象创建终于不再散落在页面里，而是沿着统一入口流动。

- 页面不再负责 new Repository。
- 网络客户端有统一入口和统一生命周期。
- ViewModel 只声明自己需要什么。

### 7. 什么适合交给 Hilt，什么不适合

Hilt 很强，但不是所有东西都该丢给它。更适合交给 Hilt 的通常是:

- 跨页面复用的基础设施对象。
- Repository、UseCase、数据源等稳定依赖。
- 需要和 Android 生命周期明确协作的对象。

不必过度交给 Hilt 的通常是:

- 只在一个局部函数里临时使用的小对象。
- 纯数据对象。
- 没有复用和生命周期管理价值的简单工具值。

依赖注入的目标是管理复杂组装，不是把所有 new 都消灭掉。

### 8. Hilt 为什么会让测试更好写

只要对象组装不再散落在页面和工具类里，测试就会容易很多。因为测试可以在统一装配点替换实现，而不需要深入业务代码内部修改构造过程。

这也是 Hilt 的工程价值之一: 它让“替换一个实现”变成架构允许的事情，而不是测试里的特殊黑科技。

### 9. 当同一种类型有多个实现时，要靠限定符和测试模块保持依赖图清晰

真正稍微复杂一点的项目，很快就会遇到一个问题：两个依赖类型明明一样，但角色完全不同。最典型的是多个 `OkHttpClient`、多个 `String` 配置值，或者同一个接口在生产和测试环境下有不同实现。这时如果只靠“类型相同就自动注入”，依赖图会立刻变得模糊，所以必须用限定符和测试替换把意图写明白。

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class AuthClient

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class UploadClient

@Module
@InstallIn(SingletonComponent::class)
object NetworkClientsModule {

    @AuthClient
    @Provides
    @Singleton
    fun provideAuthClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .callTimeout(10, TimeUnit.SECONDS)
            .build()
    }

    @UploadClient
    @Provides
    @Singleton
    fun provideUploadClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .writeTimeout(60, TimeUnit.SECONDS)
            .build()
    }
}

class SessionApi @Inject constructor(
    @AuthClient private val client: OkHttpClient,
)

class AttachmentUploader @Inject constructor(
    @UploadClient private val client: OkHttpClient,
)
```

这段代码的重点不是“又多写了两个注解”，而是同样是 `OkHttpClient`，现在终于写清楚了谁服务登录鉴权，谁服务大文件上传。限定符一旦站稳，依赖图就不会再退化成“只看类型猜语义”。Socorro 用 `@Named` 区分 API client 和 websocket client，Codwell 用 Hilt testing 替换模块，它们其实都在强调同一件事：依赖图要能表达角色，而不只是表达类型。

如果再往测试走一步，`@TestInstallIn` 会把这种清晰度继续延伸到测试环境：

```kotlin
@Module
@TestInstallIn(
    components = [SingletonComponent::class],
    replaces = [NetworkClientsModule::class],
)
object TestNetworkClientsModule {

    @AuthClient
    @Provides
    @Singleton
    fun provideFakeAuthClient(): OkHttpClient {
        return OkHttpClient.Builder().build()
    }
}

@HiltAndroidTest
class LoginRepositoryTest {
    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var repository: LoginRepository

    @Before
    fun setUp() {
        hiltRule.inject()
    }
}
```

这组测试代码说明，测试替换不该靠“偷偷改构造链”来完成，而应当仍然沿着同一套依赖图去做。只要生产实现和测试实现都通过 Hilt 明确声明，Repository 和 ViewModel 的代码就不用因为测试而额外开后门。

### 10. 作用域要跟对象语义对齐，而不是都标成 `@Singleton`

前面已经说过作用域很重要，但真正落地时最容易犯的错，是图省事把一切都做成 `@Singleton`。Socorro 和 Codwell 在依赖装配章节里都反复提醒：Hilt 的作用域不是“哪个能复用就都单例”，而是“对象应该跟谁同生共死”。如果草稿状态只服务当前编辑流程，它就不该活到整个应用生命周期里。

```kotlin
@ActivityRetainedScoped
class ArticleDraftStore @Inject constructor()

@ViewModelScoped
class ArticleEditor @Inject constructor(
    private val draftStore: ArticleDraftStore,
    private val repository: ArticleRepository,
) {
    suspend fun load(id: Long): ArticleDraft = repository.getDraft(id)
}

@HiltViewModel
class ArticleEditorViewModel @Inject constructor(
    private val editor: ArticleEditor,
) : ViewModel()
```

这组代码最值得记住的是三层寿命。`@Singleton` 适合数据库、网络客户端这类全局基础设施；`@ActivityRetainedScoped` 更适合在同一 Activity 范围内跨配置变化继续存在的状态；`@ViewModelScoped` 则适合只服务一个 ViewModel 的协作者。只要作用域跟对象语义对齐，依赖图才不会一边到处复用，一边又在不该共享的地方把状态串到别的页面去。

### 11. 当上层依赖接口时，用 `@Binds` 维护依赖方向会更清楚

Socorro 在聊天项目里用了一个很好的做法：Repository 的实现留在 data 层，但 ViewModel 和 UseCase 依赖的却是 domain 层接口。这样一来，依赖方向就不会从上层反过来指回具体实现。放到 Hilt 里，最自然的接法通常就是用 `@Binds` 把实现绑定到接口上。

```kotlin
interface IChatRoomRepository {
    suspend fun getInitialChatRoom(id: String): ChatRoom
}

class ChatRoomRepository @Inject constructor(
    private val dataSource: ChatRoomDataSource,
) : IChatRoomRepository {
    override suspend fun getInitialChatRoom(id: String): ChatRoom {
        return dataSource.getInitialChatRoom(id).toDomain()
    }
}

@Module
@InstallIn(ViewModelComponent::class)
abstract class ChatBindingsModule {

    @Binds
    abstract fun bindChatRoomRepository(
        impl: ChatRoomRepository,
    ): IChatRoomRepository
}
```

这组代码真正收紧的是依赖方向，而不只是少写几行创建代码。UseCase 或 ViewModel 面对的是接口，data 层提供的是实现，Hilt 负责在装配阶段把两者接起来。只要这条线立住，后面无论你要替换远程实现、补本地缓存，还是给测试换 fake，都不用把上层代码重新牵回具体实现类。

### 12. 遇到 Hilt 不能直接创建的系统对象时，用 EntryPoint 补齐边界

大多数页面、ViewModel、Service 都能直接走 `@AndroidEntryPoint`，但真实项目总会碰到一些框架自己创建的对象，例如 `AppWidgetProvider`、自定义 `ContentProvider` 或第三方 SDK 回调入口。Hilt 官方文档和 Codwell 的测试装配案例都在提醒同一个边界：这类对象不适合为了注入方便就硬改成全局单例，更稳的做法是通过 `EntryPoint` 在边界处拿到需要的依赖。

```kotlin
@EntryPoint
@InstallIn(SingletonComponent::class)
interface TodayTasksWidgetEntryPoint {
    fun taskRepository(): TaskRepository
}

class TodayTasksWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            TodayTasksWidgetEntryPoint::class.java,
        )
        val repository = entryPoint.taskRepository()

        appWidgetIds.forEach { appWidgetId ->
            updateWidget(
                context = context,
                appWidgetManager = appWidgetManager,
                appWidgetId = appWidgetId,
                repository = repository,
            )
        }
    }
}
```

这段代码最重要的工程判断，是 Hilt 仍然在管理依赖图，但边界对象不必为了注入而伪装成普通页面类。`EntryPoint` 适合用在“系统先创建对象，我只能在回调里补拿依赖”的场景；它不应该取代正常的 `@Inject` / `@AndroidEntryPoint`，却能很好地补上那一小块 Hilt 无法直接接管的系统边角。只要这层边界讲清楚，依赖图就不会在框架入口处突然失控。

### 13. 协程调度器也应该注入，而不是在业务代码里写死 `Dispatchers.IO`

Socorro、Codwell 和很多现代 Android 样板都会顺手做一件小事：把协程调度器也放进依赖图里。这看起来像细节，但它正好说明依赖注入真正关心的是“对象和环境从哪里来”。如果 Repository、UseCase 里到处直接写 `Dispatchers.IO`，测试环境就很难稳定替换，代码也会越来越依赖某个写死的运行上下文。

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Module
@InstallIn(SingletonComponent::class)
object CoroutineDispatchersModule {

    @IoDispatcher
    @Provides
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO
}

class ArticleRepository @Inject constructor(
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
    private val articleDao: ArticleDao,
) {
    suspend fun bookmark(id: Long) = withContext(ioDispatcher) {
        articleDao.markBookmarked(id)
    }
}
```

这段代码的重要性，不在于“少写一个 `Dispatchers.IO`”，而在于运行环境终于也成了可替换依赖。生产代码里它是 `Dispatchers.IO`，测试里可以换成 `StandardTestDispatcher` 或其他受控实现；Repository 本身只关心“我要一个适合做 IO 的调度器”，而不用知道这个环境是怎么来的。只要这种边界立住，Hilt 的价值就会从对象创建进一步延伸到执行环境管理。

### 14. 运行时参数不是依赖图天然拥有的东西，这时更适合用 `@AssistedInject`

前面已经补过 `EntryPoint`，那是处理“对象由系统创建”的边界；还有另一类常见情况是：对象的大部分依赖都来自图里，但有一两个参数只能在运行时才知道，比如导出路径、草稿 ID、当前用户选中的文件。Codwell 和很多现代样板都会用 `@AssistedInject` 处理这种情形，因为它刚好表达了一个很重要的事实：不是所有构造参数都应该被硬塞进依赖图。

```kotlin
class ExportArticleRunner @AssistedInject constructor(
    private val repository: ArticleRepository,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
    @Assisted private val articleId: Long,
) {
    suspend fun run() = withContext(ioDispatcher) {
        repository.exportArticle(articleId)
    }
}

@AssistedFactory
interface ExportArticleRunnerFactory {
    fun create(articleId: Long): ExportArticleRunner
}

@HiltViewModel
class ArticleDetailViewModel @Inject constructor(
    private val exportRunnerFactory: ExportArticleRunnerFactory,
) : ViewModel() {

    fun export(articleId: Long) {
        viewModelScope.launch {
            exportRunnerFactory.create(articleId).run()
        }
    }
}
```

这段代码真正澄清的是“依赖”和“运行时输入”不是同一种东西。`ArticleRepository`、`CoroutineDispatcher` 这种长期协作者适合交给 Hilt 管理，`articleId` 这种只在这次动作里临时决定的参数，则更适合通过 `@Assisted` 在调用点传进来。只要这层边界分清，依赖图就不会为了兼容运行时参数而被迫变形，Hilt 也能继续保持自己的职责范围清楚。

### 15. 当同一类协作者越来越多时，多绑定会比手写调度表更稳

前面已经讲过限定符、`EntryPoint` 和 `@AssistedInject`，但大型项目里还会遇到另一类问题：同一种职责会慢慢长出很多实现，比如启动初始化器、事件上报器、同步处理器。如果每次都靠一个大模块手写 `when` 或手工维护列表，依赖图就会越来越像一个隐式调度表。Hilt 的多绑定正好适合这种场景。

```kotlin
interface AppInitializer {
    suspend fun initialize()
}

class AnalyticsInitializer @Inject constructor() : AppInitializer {
    override suspend fun initialize() = Unit
}

class RemoteConfigInitializer @Inject constructor() : AppInitializer {
    override suspend fun initialize() = Unit
}

@Module
@InstallIn(SingletonComponent::class)
abstract class AppInitializersModule {

    @Binds
    @IntoSet
    abstract fun bindAnalyticsInitializer(
        impl: AnalyticsInitializer,
    ): AppInitializer

    @Binds
    @IntoSet
    abstract fun bindRemoteConfigInitializer(
        impl: RemoteConfigInitializer,
    ): AppInitializer
}

class AppStartupRunner @Inject constructor(
    private val initializers: Set<@JvmSuppressWildcards AppInitializer>,
) {
    suspend fun runAll() {
        initializers.forEach { initializer ->
            initializer.initialize()
        }
    }
}
```

这段代码真正补上的，是“同类协作者如何继续增长”这层工程边界。新增一个初始化器时，你不必再去改一张中心化调度表，只要把它绑定进集合即可。对 Hilt 来说，这也是很重要的一步：依赖图不只是创建对象，它也能让一组协作者按统一契约稳定扩展。

### 16. 昂贵依赖不一定要立即创建，用 `Lazy` 或 `Provider` 把启动成本留到真正需要时

前面已经讲了限定符、多绑定和 `@AssistedInject`，接下来很值得补的一层是：并不是所有依赖都应该一进页面就立即创建。很多大型项目里，WebSocket、导出器、上传器、复杂分析器这类对象本身就比较重，如果每次 ViewModel 初始化都立刻把它们拉起来，启动成本会被提前放大。Hilt 提供的 `Lazy` 和 `Provider` 正好适合这种场景。

```kotlin
class ChatViewModel @Inject constructor(
    private val socketClientProvider: Provider<WebSocketClient>,
) : ViewModel() {

    private var socketClient: WebSocketClient? = null

    fun connectIfNeeded() {
        val client = socketClient ?: socketClientProvider.get().also {
            socketClient = it
        }
        client.connect()
    }
}

class ExportViewModel @Inject constructor(
    private val exporter: dagger.Lazy<ArticleExporter>,
) : ViewModel() {

    fun export(articleId: Long) {
        viewModelScope.launch {
            exporter.get().export(articleId)
        }
    }
}
```

这里真正要分清的是：依赖图负责告诉你“怎么拿到对象”，但不一定要求你“现在立刻就创建对象”。`Provider` 适合每次按需拿实例，`Lazy` 则适合第一次需要时再初始化、后续继续复用。只要这层边界想清楚，依赖注入就不会把所有成本都前置到页面启动时。

### 17. 实践任务

起点条件:

- 已有一个使用 ViewModel、Repository、Room 或 Retrofit 的项目。

步骤:

1. 画出当前一个页面的依赖创建链，标明对象是谁 new 出来的。
2. 找出其中重复创建或生命周期不清楚的对象。
3. 先挑一组稳定基础设施对象交给 Hilt，例如网络客户端或数据库。
4. 再让一个 ViewModel 通过注入拿到 Repository。
5. 检查页面里是否还残留大量手工组装代码。

预期结果:

- 对象创建和对象使用会被明显分开。
- 生命周期判断会比以前更清晰。
- 页面和 ViewModel 的构造会更容易测试和替换。

自检方式:

- 读者应能解释依赖注入为什么不是“少写 new”。
- 读者应能判断一个对象为什么应该是单例，或者为什么不应该。
- 读者应能说明 Hilt 为什么在 Android 中比手工工厂更自然。

调试提示:

- 如果同一个基础设施对象在多个地方反复创建，优先考虑是否缺少统一注入点。
- 如果页面里到处都是手工装配链，说明 Hilt 还没有真正落地。
- 如果你把局部临时对象也都强行注入，说明依赖注入已经开始过度。

### 18. 常见误区

- 把 Hilt 理解成“自动生成对象”的黑盒。
- 只记注解，不理解作用域。
- 什么都交给 Hilt，导致注入过度。
- 把页面里原本就简单清晰的局部创建也强行抽象化。

## 练习题

1. 概念理解题：Hilt 真正解决的是对象创建、复用和生命周期协调问题，为什么这比“少写 `new`”更重要？
2. 编码实现题：为一个 ViewModel 注入 Repository，并补一条接口绑定或限定符示例，验证对象创建职责已经从页面中移走。
3. 拓展思考题：哪些对象适合交给 Hilt 管理，哪些局部对象仍然应该在使用点直接创建？你会怎样避免注入过度？

## 小结

Hilt 与依赖注入真正解决的，是对象创建、复用、替换和生命周期协调问题。它让页面和 ViewModel 不再承担复杂装配职责，也让基础设施对象拥有更清晰的归属。只要先把“谁来创建、谁来使用、对象该活多久”这三件事想明白，Hilt 就不会只是注解集合，而会变成 Android 工程结构中非常实用的一层。

## 参考资料

- 参考并改写自本地 PDF：Bennett M.，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，依赖注入、模块层级与多模块应用装配相关章节。
- 参考并整理自本地 PDF：`Clean Android Architecture`，依赖方向、UseCase/Repository 组装与可替换实现相关章节。
- 参考并整理自本地 PDF：Socorro G.，《Thriving in Android Development Using Kotlin》(2024)，`@Named`、接口绑定与 Hilt 模块职责相关章节。
- 参考并整理自本地 PDF：Codwell H.，《Kotlin Development Complete Guide Create 45 Android Apps》(2025)，Hilt 限定符、`@TestInstallIn` 与测试替换相关章节。
- Hilt on Android: <https://developer.android.com/training/dependency-injection/hilt-android>
- Hilt and Jetpack integrations: <https://developer.android.com/training/dependency-injection/hilt-jetpack>
- Dependency injection guide: <https://developer.android.com/training/dependency-injection>





