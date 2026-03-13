# Retrofit

如果说 OkHttp 解决的是“HTTP 请求怎样被可靠地发出去”，那么 Retrofit 解决的就是“接口怎样以更清晰、更稳定的方式被业务代码使用”。这两层很容易被混成同一件事，因为在大多数 Android 项目里，开发者直接接触网络接口时看到的通常是 Retrofit 接口，而不是底层连接细节。但从工程角度看，它们解决的问题并不一样。

Retrofit 的最大价值，并不是帮你少写几行 `Request.Builder()`，而是把零散的请求构造过程提升成“可阅读、可协作、可复用”的接口契约。只要接口数量开始增长，这种契约化能力就会迅速显示出价值。更完整的项目资料也会反复强调，Retrofit 最好的位置不是“直接喂给页面的万能网络层”，而是站在 OkHttp 和 Repository 之间，专注表达接口契约与对象转换。

## 学习目标

- 理解 Retrofit 在 Android 网络栈中的职责。
- 理解 `baseUrl`、转换器、`suspend` 接口和注解声明的意义。
- 理解 Retrofit 与 OkHttp、DTO、Repository 和 UI 状态之间的边界。
- 知道怎样把 Retrofit 用成网络接口层，而不是“万能网络框架”。

## 前置知识

- 已理解 HTTP、REST 和 OkHttp 的基本角色。
- 已建立 DTO 与 UI 模型不必完全一致的意识。

## 正文

### 1. Retrofit 解决的是“接口契约”问题

在没有 Retrofit 的情况下，底层 HTTP 请求往往会散落成很多过程代码：拼接 URL、声明方法、加查询参数、补头信息、构造请求体、拿到响应体后再手工转对象。单个接口看起来问题不大，但接口一多，结构就会迅速变乱。

Retrofit 官方文档对它的定位非常直接：它把 HTTP API 转成 Java 或 Kotlin 接口。这句话看起来简单，真正的价值却很大。因为一旦接口被声明成契约，团队成员在阅读代码时看到的就不再是一段“如何拼请求”的过程，而是“这个接口代表什么能力”的说明。

### 2. 一个 Retrofit 配置真正决定了什么

很多人第一次写 Retrofit，只记住了一个 `Retrofit.Builder()`。但从工程角度看，这个构建过程其实是在定义整个接口层的默认规则。最关键的配置通常有三个：

- `baseUrl`：所有相对路径接口都从这里展开。它不是随便写的字符串，而是整组接口的基础根路径。
- `client`：通常就是前一章配置好的共享 `OkHttpClient`，负责日志、鉴权、超时、TLS 和底层连接。
- `converterFactory`：决定响应体和请求体如何与对象互转。

Retrofit 官方配置文档还特别说明：如果不加转换器，Retrofit 默认只能直接处理 OkHttp 的 `RequestBody` 和 `ResponseBody`。这意味着“对象自动转 JSON”并不是 Retrofit 自带魔法，而是转换器提供的能力。

### 3. 声明式接口为什么会显著改善可维护性

Retrofit 的声明式接口有一个很重要的工程优势：接口签名本身就能传达语义。官方 Declarations 文档把请求方法、路径替换、查询参数、请求体和头信息都放进了注解系统里。这样一来，一个接口方法通常能直接表达这些信息：

- 这是什么 HTTP 方法。
- 路径和参数如何组织。
- 请求体放在哪。
- 返回结果的大致结构是什么。

当团队读到下面这样的接口时，理解成本会明显低于阅读一段底层拼接代码：

```kotlin
interface ArticleApi {
    @GET("articles")
    suspend fun getArticles(
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): List<ArticleDto>
}
```

这段代码的重点不在“语法很短”，而在于它已经把调用意图表达清楚了。接口越多，这种清晰度越重要。

### 4. `suspend` 接口为什么适合现代 Android

Retrofit 官方文档已经把 Kotlin `suspend` 函数列为内建支持能力，不需要额外依赖。对现代 Android 项目来说，这一点很关键，因为它让网络接口天然可以进入协程和结构化并发链路。

这会带来几个直接好处：

- ViewModel 可以直接在 `viewModelScope` 中调用接口。
- 取消和生命周期协作更自然。
- 多个接口并发、串行或超时控制都更容易组织。

Retrofit 对 `suspend` 返回值还有一个非常重要的语义差异：

- 如果接口直接返回 `User`、`List<ArticleDto>` 这类 body 类型，那么非 2xx 响应会抛出 `HttpException`。
- 如果接口返回 `Response<User>`，你就可以自己读取状态码、头信息和 body。

这两种写法都合法，关键在于你是否真的需要协议层细节。多数普通读取接口，直接返回 body 会更简洁；只有当你确实要读取响应头、分页头信息或状态码细节时，再考虑返回 `Response<T>`。

### 5. 注解表达的是协议结构，不是业务逻辑

Retrofit 的 `@GET`、`@POST`、`@Path`、`@Query`、`@Body`、`@Header` 这些注解，本质上是在描述协议结构，而不是承载业务含义。这个区别很重要，因为它会影响你如何设计接口层。

例如：

- `@Path` 和 `@Query` 表示 URL 的不同位置。
- `@Body` 表示请求体对象需要被转换器序列化。
- `@Header` 表示这次调用需要额外带入的动态头信息。

但如果某个头信息几乎所有请求都要带，例如鉴权 token 或统一语言头，通常更适合交给 OkHttp interceptor，而不是在每个 Retrofit 方法上重复写一遍。Retrofit 官方文档也明确指出，所有请求都需要的头可以通过 OkHttp interceptor 统一追加。

### 6. 转换器解决的是字节与对象互转，不是架构边界

Retrofit 配上转换器后，接口层确实会“好用很多”，因为你不需要再手工把 JSON 字符串转成对象了。但这一步只解决了字节流和对象之间的转换，并没有自动解决下面这些问题：

- 接口字段是否和页面语义一致。
- 某个字段缺失时由谁兜底。
- 网络返回对象是否可以直接进入数据库或 UI。
- 空列表、业务失败码和格式异常该如何解释。

所以 Retrofit 返回的通常应是 DTO 或响应包装对象，而不是 UI 最终使用的模型。真正的转换和边界收束，仍然应该发生在 Repository 或数据层。

### 7. 一个更接近真实项目的最小示例

下面这个例子把共享 OkHttpClient、Retrofit 配置、序列化转换和 DTO 转换串成一条最小可落地链路。为了和前面的 JSON 章节保持一致，这里用 `kotlinx.serialization` 作为示例。

```kotlin
@Serializable
data class ArticleDto(
    val id: String,
    val title: String,
    val summary: String? = null
)

interface ArticleApi {
    @GET("articles")
    suspend fun getArticles(
        @Query("page") page: Int
    ): List<ArticleDto>
}

private val json = Json {
    ignoreUnknownKeys = true
}

private val retrofit = Retrofit.Builder()
    .baseUrl("https://example.com/api/")
    .client(okHttpClient)
    .addConverterFactory(
        json.asConverterFactory("application/json".toMediaType())
    )
    .build()

private val articleApi = retrofit.create(ArticleApi::class.java)

class ArticleRepository(
    private val api: ArticleApi
) {
    suspend fun loadArticles(): List<Article> {
        return api.getArticles(page = 1).map { dto ->
            Article(
                id = dto.id,
                title = dto.title,
                summary = dto.summary.orEmpty()
            )
        }
    }
}
```

这个例子里最重要的不是某个具体库名，而是结构：

- OkHttp 负责底层通信能力。
- Retrofit 负责接口契约和对象转换。
- Repository 负责把 DTO 转成应用真正要使用的模型。

只要这条链路清楚，后面再引入统一错误处理、缓存或离线策略都会顺得多。

### 8. Retrofit 不应该直接把返回值一路传到 UI

这是网络篇最容易踩坑的地方之一。很多项目在早期为了图快，会让 ViewModel 甚至 Fragment 直接拿 Retrofit 返回的对象渲染界面。短期看很省事，长期问题会逐渐暴露：

- 接口字段名变动会直接波及 UI。
- 同一个 DTO 被多个页面以不同方式拼装。
- 页面层开始处理很多空值、业务码和格式兜底逻辑。

更合理的做法通常是：

1. Retrofit 返回 DTO 或响应包装对象。
2. Repository 解释协议层和业务层结果，并完成模型转换。
3. ViewModel 把结果组织成 `uiState`。
4. UI 只渲染状态。

这样，UI 层就不需要知道底层接口长什么样，也不需要直接面对 HTTP 细节。

### 9. 为什么只看 Retrofit 注解文档，内容会很像说明书

Retrofit 官方文档非常适合确认这些事实：注解如何表达请求方法、`baseUrl` 怎样生效、转换器怎么接入、`suspend` 返回值有哪些语义差异。它在“规则和能力边界”这件事上做得很好，但如果学习过程只停留在这里，读者很容易学成“会写注解、会拼接口、却仍然不知道接口层在项目里该怎么站位”。

更接近教材的 Retrofit 学习，需要再补两层资料：

- 语言和序列化层：Kotlin 文档、`kotlinx.serialization` 文档，帮助你理解 `suspend`、序列化和 DTO 为什么会自然地和 Retrofit 接在一起。
- 项目结构层：像 `Now in Android` 这样的官方样例项目，帮助你看见 Retrofit 并不是单独存在的，而是嵌在 Repository、离线缓存、`uiState` 和模块结构里面。

这样一来，Retrofit 章节就不会只剩下“注解说明”和“Builder 配置”，而会更像一门关于接口层设计的课程。

### 10. 更适合 Retrofit 入门的资料组合

如果你想把 Retrofit 学得更稳，可以按下面的顺序用资料：

1. 先用本章建立 Retrofit 的职责边界，明确它解决的是接口契约，而不是完整架构。
2. 再读 Retrofit 官方 `Introduction`、`Declarations` 和 `Configuration`，确认注解、返回值和转换器的正式语义。
3. 然后回到 Kotlin 和序列化文档，理解 `suspend`、DTO 和 JSON 转换在语言层面的依据。
4. 最后阅读官方样例项目，观察 Retrofit 如何与 OkHttp、Repository 和 `uiState` 真正协作。

这条路线能避免两个常见问题：只会写注解却不懂架构位置，或者只会抄样例却说不清 Retrofit 本身的能力边界。

### 11. 实践任务

起点条件：

- 已完成一个共享 `OkHttpClient`。
- 项目中已有一个简单公开接口，或愿意用文章列表接口做练习。

步骤：

1. 选择一个 JSON 接口，先写出它的请求方法、相对路径和关键参数。
2. 用 Retrofit 定义一个 `suspend` 接口方法，返回 DTO 列表或 `Response<DTO>`。
3. 配置一个转换器，让响应体可以自动转成对象。
4. 在 Repository 中调用这个接口，并把 DTO 转成你自己的业务模型。
5. 打开一个官方样例项目，观察接口层文件是否直接被 UI 调用，还是先经过 Repository 和状态层。
6. 检查页面层是否已经不再直接依赖 Retrofit 接口返回的原始对象。

预期结果：

- 你能把“接口声明”和“底层通信”明确分层。
- 你能用更稳定的接口契约描述网络能力。
- 你能区分：Retrofit 文档、Kotlin/序列化文档和样例项目分别解决什么问题。
- 你会更容易在下一章里做统一结果包装和错误处理。

自检方式：

- 你能解释：Retrofit 和 OkHttp 分别解决什么问题。
- 你能判断：什么时候接口适合直接返回 body，什么时候需要 `Response<T>`。
- 你能说明：为什么 DTO 不应直接一路传到 UI。
- 你能确认：统一头信息是否已经回到 OkHttp 层，而不是散落在 Retrofit 方法签名里。
- 你能解释：为什么只会写 Retrofit 注解，还不等于已经会设计接口层。

调试提示：

- 如果你一旦不用 Retrofit 就说不清接口的 HTTP 结构，说明协议层理解还不够扎实。
- 如果你的 `baseUrl`、客户端和转换器配置分散在多个类里，后面维护成本会很快升高。
- 如果页面层还在直接接收 `ArticleDto` 之类的对象，说明边界还没有真正建立。
- 如果每个接口都在单独处理 token、日志和公共头，说明 Retrofit 和 OkHttp 的职责没有拆开。
- 如果你越学越像在背注解表，先去看一个真实样例项目里的网络模块，再回头理解 Builder 和接口定义。

### 12. 常见误区

- 把 Retrofit 当成完整网络架构本身。
- 只会写注解，不理解它和 HTTP 结构的对应关系。
- 转换器一配上就默认所有边界问题都解决了。
- 让 Retrofit 返回值直接进入 ViewModel 或 UI。
- 只读 Retrofit 文档，不读 Kotlin/序列化文档和样例项目。

## 小结

Retrofit 把网络接口从零散过程代码提升成了清晰契约，这是它最重要的工程价值。但它并没有取代 OkHttp，也不会自动替你完成模型转换和结果解释。真正稳固的网络层，是让 Retrofit 专注接口声明，让 OkHttp 专注通信基础设施，再把结果交给 Repository 继续收束。

下一章我们继续处理“结果怎样稳定地交给上层”这个问题，也就是统一的 API 结果包装。

## 参考资料

- 参考并整理自本地 PDF：`Real-World Android by Tutorials`，Retrofit、DTO 与项目中网络接口层组织相关内容。
- 参考并整理自本地 PDF：Bennett M.，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，网络模块、Repository 边界与多模块应用中的接口契约相关章节。
- Retrofit Introduction：<https://square.github.io/retrofit/>
- Retrofit Declarations：<https://square.github.io/retrofit/declarations/>
- Retrofit Configuration：<https://square.github.io/retrofit/configuration/>
- OkHttp Overview：<https://square.github.io/okhttp/>
- Kotlin Coroutines：<https://kotlinlang.org/docs/coroutines-overview.html>
- Kotlin Serialization：<https://kotlinlang.org/docs/serialization.html>
- Now in Android：<https://github.com/android/nowinandroid>

