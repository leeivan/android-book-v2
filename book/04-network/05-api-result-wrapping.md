# API 结果包装

当你已经有了 OkHttp 和 Retrofit，网络层最容易产生的一种错觉是：接口已经能调通了，剩下的只是把返回对象交给页面。这通常正是问题开始的地方。真实项目里，网络请求很少只有“成功返回一个对象”这一种结果。它还可能超时、断网、返回 500、返回 200 但业务码失败、返回 200 且业务成功但列表为空、返回体格式和预期不一致，或者页面已经离开当前场景不再需要这次结果。

如果这些情况都直接以原始异常、裸响应或 `null` 值的形式往上抛，ViewModel 和 UI 很快就会被底层细节淹没。本章的任务，就是把这些零散情况收束成更有限、更稳定、对上层更友好的结果语义。

## 学习目标

- 理解为什么网络结果需要在数据层边界进行统一包装。
- 区分协议错误、业务错误、网络错误和解析错误。
- 理解 API 结果包装与 UI 状态之间的关系。
- 学会用更稳定的结果模型减少重复判断和分散的错误处理。

## 前置知识

- 已理解 Retrofit 返回值不应直接一路传到 UI。
- 已理解 HTTP 成功不等于业务成功。

## 正文

### 1. 为什么原始响应和异常不应该直接穿透到上层

如果 Repository 只是把 Retrofit 的返回值、`HttpException`、`IOException` 或 `null` 原封不动地交给上层，那么上层就不得不自己回答很多本不属于它的问题：

- 这是断网、超时还是服务器异常。
- 这个 200 响应为什么仍然不该显示成功页面。
- 空列表算不算错误。
- 当前错误是否适合重试。
- 哪一类错误需要跳登录，哪一类只需提示重试。

结果就是，每个 ViewModel 都会开始写一套自己的 `try-catch` 和分支判断。同一种错误在不同页面上被重复解释，最终既不统一，也不稳定。

### 2. 结果包装的本质，是把“网络噪声”收束成有限语义

结果包装并不是把所有失败都抹平成一个 `Error`。真正有价值的包装，是在保留关键信息的前提下，把上层不该关心的底层噪声隔离掉。对大多数应用来说，至少应该区分下面几类结果：

- 成功且有数据。
- 成功但数据为空。
- 协议失败，例如 401、404、500 之类的 HTTP 错误。
- 网络失败，例如断网、超时、连接中断。
- 解析失败，例如字段类型不匹配或 JSON 结构异常。
- 业务失败，例如 HTTP 200，但后端业务码表示操作未成功。

一旦你把这些情况全都粗暴地压成“成功 / 失败”两类，上层就很难做出合理的恢复策略。比如断网和 500 都叫失败，但显然不应该提示同一句话；空列表和服务器异常都叫失败，也会让页面状态变得很别扭。

### 3. 协议错误、业务错误和解析错误必须分层理解

这是网络层最常见的认知混乱点之一。它们都可能表现为“页面没拿到理想结果”，但层次完全不同：

- 协议错误：HTTP 层就已经失败，例如 404、500、401。
- 业务错误：HTTP 交互成功，但服务端业务字段明确表示失败。
- 解析错误：返回体字节到了客户端，但结构和预期不一致，无法安全转成对象。

如果这三类问题不拆开，你就很难设计正确的日志、埋点、告警、重试和用户提示。比如协议错误可能要记录状态码，业务错误可能要记录业务码，解析错误则通常意味着接口契约或客户端版本兼容出了问题。

### 4. 包装结果，不等于把用户提示文案写死在 Repository

结果包装的目的是统一语义，不是提前写死页面文案。Repository 更适合返回机器可判断的结果类型，而不是直接返回“请检查网络后重试”这类最终展示文案。因为同一种网络错误，在首页、表单页和支付页上的交互策略可能并不一样。

更稳妥的做法是：

- 数据层返回结构化的结果类型。
- ViewModel 根据页面上下文把结果转换成 `uiState`。
- UI 再决定具体呈现方式。

Android 官方架构建议里明确提到，ViewModel 应对外暴露一个 `uiState`，其中可以包含数据、错误和加载信号。这说明“错误语义先在数据层被整理，再在 ViewModel 映射成页面状态”是非常自然的分工。

### 5. 为什么密封类型很适合表示 API 结果

Kotlin 的 sealed class / sealed interface 非常适合这类有限状态的场景。Kotlin 官方文档强调，密封层级适合表示“编译期已知、范围有限的一组子类型”，而且和 `when` 搭配时可以获得穷尽性检查。对网络结果来说，这正是我们想要的效果：上层在处理结果时，不容易漏掉某一类情况。

下面是一个常见、足够实用的结果模型示例：

```kotlin
sealed interface ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>
    data object Empty : ApiResult<Nothing>
    data class HttpError(val code: Int, val message: String?) : ApiResult<Nothing>
    data class BusinessError(val code: Int, val message: String) : ApiResult<Nothing>
    data class NetworkError(val exception: IOException) : ApiResult<Nothing>
    data class ParseError(val exception: Throwable) : ApiResult<Nothing>
}
```

这个模型并不是唯一答案，但它已经把最常见的结果边界拆清楚了。上层在 `when` 中处理时，也更容易看出自己是否遗漏了某类情况。

### 6. 一个更接近真实项目的最小示例

下面的例子演示 Repository 怎样把 Retrofit 的原始结果收束成更稳定的 `ApiResult`。这里假设后端返回的是常见的业务包装结构：`code`、`message` 和 `data`。

```kotlin
@Serializable
data class ApiEnvelope<T>(
    val code: Int,
    val message: String? = null,
    val data: T? = null
)

class ArticleRepository(
    private val api: ArticleApi
) {
    suspend fun loadArticles(): ApiResult<List<Article>> {
        return try {
            val envelope = api.getArticles()

            if (envelope.code != 0) {
                ApiResult.BusinessError(
                    code = envelope.code,
                    message = envelope.message ?: "Unknown business error"
                )
            } else {
                val articles = envelope.data.orEmpty().map { dto ->
                    Article(
                        id = dto.id,
                        title = dto.title,
                        summary = dto.summary.orEmpty()
                    )
                }

                if (articles.isEmpty()) {
                    ApiResult.Empty
                } else {
                    ApiResult.Success(articles)
                }
            }
        } catch (e: HttpException) {
            ApiResult.HttpError(e.code(), e.message())
        } catch (e: IOException) {
            ApiResult.NetworkError(e)
        } catch (e: Throwable) {
            ApiResult.ParseError(e)
        }
    }
}
```

这个例子里最关键的，不是某个具体类名，而是结果在 Repository 这里被“解释过一轮”了。ViewModel 再往上拿到的就不再是凌乱的原始异常，而是更有限、更稳定的结果语义。

### 7. API 结果包装和 UI 状态是什么关系

两者关系非常紧密，但不能混为一谈。API 结果包装发生在数据边界，解决的是“网络结果如何被解释”。UI 状态发生在 ViewModel 和 UI 边界，解决的是“页面现在应该显示什么”。

更自然的链路通常是：

1. Retrofit 负责拿到原始响应或抛出异常。
2. Repository 把结果包装成 `ApiResult`。
3. ViewModel 把 `ApiResult` 转换成 `uiState`。
4. UI 根据 `uiState` 渲染加载、内容、空状态或错误态。

这样一来，页面不需要知道 `HttpException` 和 `IOException` 的区别，也不需要知道后端业务码长什么样。它只关心“当前该显示列表、空页面还是错误提示”。

### 8. 统一包装能减少的，不只是重复代码

很多人会把结果包装理解成“封一层类，少写点 if”。这当然是一个结果，但更重要的价值在于它强迫团队把错误语义讲清楚。只要有了统一的结果模型，你就更容易：

- 统一日志与监控维度。
- 明确哪些错误可重试，哪些不应自动重试。
- 让多个页面对同类问题保持一致的处理原则。
- 在 ViewModel 层更稳定地生产 `uiState`。

所以结果包装并不是多余抽象，而是网络层开始进入工程化阶段的标志之一。

### 9. 实践任务

起点条件：

- 已有一个 Retrofit 接口和对应的 Repository。
- 项目里至少存在一个需要处理成功、空数据和失败三类情况的页面。

步骤：

1. 选一个接口，列出它在真实运行中至少可能出现的五种结果。
2. 将这些结果按协议错误、业务错误、网络错误、解析错误、空数据和成功进行分类。
3. 设计一个 `ApiResult` 密封层级，至少能表达你列出的这些结果。
4. 在 Repository 中统一把 Retrofit 的结果和异常映射为 `ApiResult`。
5. 在 ViewModel 中把 `ApiResult` 映射成页面 `uiState`，不要让 UI 直接处理原始异常。

预期结果：

- 你能把“网络发生了什么”和“页面显示什么”分成两层处理。
- 你能明显减少 ViewModel 里重复的 `try-catch` 和空值判断。
- 你会更容易在后续章节里加入缓存、离线优先或统一重试策略。

自检方式：

- 你能解释：协议错误、业务错误和解析错误为什么不是同一类问题。
- 你能判断：哪些信息应保留在 `ApiResult` 里，哪些应留给 UI 再决定。
- 你能确认：UI 已经不再直接依赖 `HttpException`、`IOException` 或裸响应对象。
- 你能检查：同一类错误在不同页面是否至少有一致的处理起点。

调试提示：

- 如果每个 ViewModel 都在自己写一套异常分类逻辑，说明结果包装还没形成。
- 如果 Repository 直接返回“请稍后重试”这类文案，通常说明页面语义被提前写死了。
- 如果空列表和失败状态共用同一种 UI，往往说明结果模型不够细。
- 如果你在 View 层还能直接看到 `HttpException`，说明数据边界没有真正挡住底层细节。

### 10. 常见误区

- 直接把原始响应、异常或 `null` 一路传到 UI。
- 把所有失败都压成一种 `Error`。
- 把最终用户提示文案提前写死在 Repository。
- 把 `ApiResult` 和 `uiState` 当成同一个概念。

## 小结

API 结果包装的核心价值，不是多写一个类，而是把复杂、嘈杂、层次不同的网络结果整理成更稳定的上层语义。只要这一步做得好，ViewModel 生产 UI 状态会简单很多，页面也不再需要直接理解底层通信细节。

下一章我们再往前走一步，处理“当网络并不稳定甚至不可用时，应用如何通过缓存和离线策略保持可用性”。


## 参考资料

- State holders and UI state：<https://developer.android.com/topic/architecture/ui-layer/stateholders>
- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
- Retrofit Declarations：<https://square.github.io/retrofit/declarations/>
- Sealed classes and interfaces：<https://kotlinlang.org/docs/sealed-classes.html>
