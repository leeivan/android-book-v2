# OkHttp

当网络章节进入工具层时，很多人会很快把注意力全部转向 Retrofit，因为它更“像业务代码”，也更接近接口声明。但如果没有先看清 OkHttp 这层，后面很多问题都很难真正理解：连接为什么能复用，重定向和压缩是谁在处理，统一鉴权头应该放在哪一层，为什么日志、超时和缓存配置不该散落在每个接口里。

OkHttp 是现代 Android 网络栈里非常重要的一层基础设施。它不是为了让你在每个项目里都手写原始 HTTP 请求，而是为了让你知道，真正负责“把请求可靠地发出去”的组件，应该承担哪些职责。只要这层职责边界理解清楚，Retrofit、Repository 和统一错误处理才不容易互相污染。

## 学习目标

- 理解 OkHttp 在 Android 网络栈中的位置。
- 理解 `OkHttpClient`、`Request`、`Call`、`Response` 和拦截器的职责边界。
- 理解为什么 HTTP 客户端应该集中配置并长期复用。
- 知道哪些横切能力适合放在 OkHttp，哪些不应该放。

## 前置知识

- 已理解网络请求和响应的基本结构。
- 已理解 HTTP、REST 和页面状态不是一回事。

## 正文

### 1. OkHttp 解决的是“通信基础设施”问题

从职责上说，OkHttp 是一个 HTTP 客户端。它关心的是连接、协议、超时、重试、重定向、压缩、缓存协商、TLS、安全连接，以及请求和响应在底层如何流动。OkHttp 官方文档把这些能力概括为：连接池、HTTP/2、透明 GZIP、响应缓存，以及在连接异常时的恢复能力。

这意味着，OkHttp 主要负责的是“网络通信怎么完成”。它不天然负责以下事情：

- 页面最终显示哪种错误文案。
- 返回对象如何转换成业务模型或 UI 模型。
- 某个页面在失败时是展示重试按钮还是空状态插图。

这些问题属于更上层的 Repository、ViewModel 和 UI。只要这条边界不混乱，网络栈就会更清晰。

### 2. `OkHttpClient`、`Request`、`Call`、`Response` 分别是什么

很多初学者第一次接触 OkHttp，会觉得它只是“创建请求对象然后发出去”。但如果把几个核心对象的职责拆开看，结构其实很清楚：

- `OkHttpClient` 是客户端配置中心，负责超时、连接池、缓存、拦截器、TLS、代理等长期复用的能力。
- `Request` 是一次请求的描述，表达目标 URL、方法、头信息和请求体。
- `Call` 是一次“即将执行或正在执行”的请求实例。
- `Response` 是这次调用返回的协议结果，里面包含状态码、头和响应体。

OkHttp 的 Calls 文档强调，每个 `Call` 只能使用一次。如果你需要重发，应该创建新的 `Call`，而不是把已执行过的调用再次使用。这类细节看似底层，实际上和取消、重试、生命周期管理直接相关。

### 3. 为什么 `OkHttpClient` 几乎总是应该复用

这是网络层最值得尽早养成的工程习惯之一。`OkHttpClient` 不应该被当作“每次请求临时 new 一个”的轻量对象，而应该被视为应用中的长期基础设施。OkHttp 官方文档明确把连接池、缓存和连接恢复作为重要特性，而这些能力的价值都建立在客户端实例被复用的前提上。

如果每次请求都创建新客户端，会出现几个问题：

- 连接池无法稳定复用，重复建连成本上升。
- 超时、日志、鉴权、缓存等配置会散落到多个地方。
- 团队很难知道“应用的默认网络规则”到底由谁控制。

更合理的做法通常是：在依赖注入容器、应用级初始化代码或网络模块中创建一个共享的 `OkHttpClient`，然后让 Retrofit 或底层数据源统一复用它。

### 4. `Call` 的生命周期，比“发请求”多得多

OkHttp 并不只是把请求发出去然后拿回一个字符串。一次调用至少还涉及这些问题：

- 这次请求是在主线程还是后台线程上执行。
- 请求是否需要取消。
- 响应体是否被及时关闭。
- 相同请求是否可能被重放或克隆。

OkHttp 支持同步调用和异步回调调用。对现代 Android 项目来说，更常见的做法是把网络请求放进协程或其他后台执行机制中，而不是直接在页面里调用阻塞式代码。无论使用哪种方式，都必须注意响应体的生命周期：`ResponseBody` 是一次性流，读取后就消耗掉了；使用完成后要及时关闭，最稳妥的写法是配合 `use {}`。

如果这一步处理得不规范，后面你可能会遇到连接未释放、重复读取 body 失败、页面离开后仍在等待旧请求结果等问题。

### 5. OkHttp 在底层帮你做的事，很多时候你看不见

OkHttp 的价值很大一部分恰恰在于“你不需要每次都手写这些细节”。根据官方文档，它会在合适的时候重写请求和响应，例如补充某些头信息、处理透明压缩、根据缓存协商追加条件请求头、自动跟随重定向，以及在配置了认证器时处理认证挑战。

这也是为什么不建议把它理解成“发 URL 的工具”。它更像一个遵循现代 HTTP 语义、能处理大量通信细节的客户端运行时。只有先接受这一点，后面你才会自然地把日志、缓存、鉴权头、统一超时这些能力放在 OkHttp 层，而不是散到业务代码里。

### 6. 拦截器是横切能力的入口，但不是业务逻辑容器

拦截器是 OkHttp 最重要的扩展点之一。官方文档把它描述为可以监控、重写和重试调用的强大机制。对 Android 项目来说，这一层特别适合承载“许多请求都共同需要”的规则，例如：

- 统一追加 `Authorization`、`Accept-Language`、`User-Agent` 等头信息。
- 打印请求和响应日志。
- 记录耗时、链路标记或埋点。
- 针对某类响应头做统一处理。

但拦截器不适合做页面级业务判断，例如“订单列表失败时显示哪张插图”“登录页是否弹对话框”。这类逻辑属于上层状态组织，而不是底层通信规则。

还需要注意一个很容易被忽略的区分：OkHttp 文档把拦截器分成 application interceptor 和 network interceptor。前者更适合处理应用视角的一次逻辑请求，后者更接近真实网络交互，能看到重定向等细节。多数业务项目先从 application interceptor 用起就够了，只有在确实需要观察更底层网络过程时，再考虑 network interceptor。

### 7. 一个更接近真实项目的最小示例

下面这个例子不追求覆盖所有网络层细节，只展示一个比较健康的最小结构：共享客户端、集中配置、在后台线程执行请求，并及时关闭响应体。

```kotlin
private val httpClient = OkHttpClient.Builder()
    .addInterceptor { chain ->
        val newRequest = chain.request().newBuilder()
            .header("Accept", "application/json")
            .build()
        chain.proceed(newRequest)
    }
    .build()

suspend fun fetchArticlesJson(): String = withContext(Dispatchers.IO) {
    val request = Request.Builder()
        .url("https://example.com/api/articles")
        .get()
        .build()

    httpClient.newCall(request).execute().use { response ->
        if (!response.isSuccessful) {
            error("HTTP ${response.code}")
        }

        response.body?.string() ?: error("Response body is empty")
    }
}
```

这个例子的重点不是“以后所有请求都直接这样写”，而是：

- 客户端配置被集中到一个地方。
- 统一头信息通过拦截器追加。
- 阻塞式 `execute()` 没有出现在主线程。
- `Response` 用 `use {}` 关闭，避免资源泄漏。

当你再往上接 Retrofit 时，底层很多事情仍然会落到这层客户端上完成。

### 8. 在完整架构里，OkHttp 应该放在哪里

更成熟的 Android 项目通常不会让页面直接依赖 OkHttp。更常见的链路是：

1. 网络模块创建共享的 `OkHttpClient`。
2. Retrofit 复用这个客户端，负责接口声明和对象转换。
3. Repository 负责把 DTO 转成领域模型或 UI 需要的数据结构。
4. ViewModel 把数据和错误结果转换成 `uiState`。

这意味着，OkHttp 的最佳位置往往是“网络基础设施层”，而不是“页面可直接使用的请求工具层”。如果你的 Fragment 或 Activity 里出现了大量 `Request.Builder()`，通常说明网络职责分层还不够清楚。

### 9. 实践任务

起点条件：

- 已有一个可运行的 Android 项目，或者已有第 4 部分前两章里的示例项目。

步骤：

1. 在项目里集中创建一个共享的 `OkHttpClient`，不要在每次请求时临时创建。
2. 添加一个简单的 application interceptor，统一追加 `Accept: application/json` 请求头。
3. 写一个最小请求函数，在后台线程中请求一个公开 JSON 接口。
4. 用 `use {}` 读取响应体，并在非 2xx 时打印状态码。
5. 检查当前工程里是否还有页面层直接拼装 URL 和请求头的代码。

预期结果：

- 你能明确区分客户端配置、单次请求描述和单次调用实例。
- 你会开始把横切能力收回到 OkHttp 层，而不是散落在页面和 Repository。
- 你能更容易看懂后面 Retrofit 为什么要复用 OkHttpClient。

自检方式：

- 你能解释：为什么 `OkHttpClient` 应该长期复用。
- 你能说出：拦截器适合处理什么，不适合处理什么。
- 你能判断：什么时候需要 application interceptor，什么时候才需要 network interceptor。
- 你能确认：网络调用没有运行在主线程，响应体也被正确关闭。

调试提示：

- 如果每个请求都手动加同样的头信息，通常说明拦截器层还没立起来。
- 如果你看到页面层直接 new `OkHttpClient()`，结构几乎一定会失控。
- 如果响应体读取后还想再次读取，或忘记关闭 body，后面会出现很难查的资源问题。
- 如果你把大量业务判断放进拦截器，后续排查错误时会发现通信层和业务层边界非常模糊。

### 10. 常见误区

- 把 OkHttp 当成“一次性发请求的小工具”。
- 每个请求都重新创建 `OkHttpClient`。
- 把所有业务逻辑都塞进拦截器。
- 只关注请求能不能成功，不关注客户端统一配置、资源释放和生命周期。

## 小结

OkHttp 是网络栈的基础设施层。它的价值不在于“语法会不会写”，而在于你是否知道哪些能力应该在客户端层统一处理，哪些问题应交给更上层的 Repository 和 ViewModel。只要这层职责边界建立起来，Retrofit 的角色就会变得非常自然。

下一章我们继续往上走，看 Retrofit 如何把底层 HTTP 通信包装成更适合业务协作的声明式接口。


## 参考资料

- 参考并改写自：Harun Wangereka，《Mastering Kotlin for Android 14》(2024)，第 6 章。
- 参考并改写自：Kickstart Modern Android Development With Jetpack And Kotlin (2024)，第 3-4 章。
- 参考并改写自：Damilola Panjuta、Linda Nwokike，《Tiny Android Projects Using Kotlin》(2024)，第 6 章。

- OkHttp Overview：<https://square.github.io/okhttp/>
- OkHttp Calls：<https://square.github.io/okhttp/features/calls/>
- OkHttp Interceptors：<https://square.github.io/okhttp/features/interceptors/>

