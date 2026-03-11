# Hilt 与依赖注入

很多 Android 项目在最初只有几个页面时，并不会立刻觉得依赖管理有多痛苦。页面里自己 new 一个 Repository，Repository 里自己 new 一个 Retrofit 或 DAO，似乎也能跑。问题往往要等项目开始增长以后才集中爆发: 同一个依赖被多处重复创建，构造链越来越长，测试替换困难，生命周期和对象作用域开始对不上。到了这一步，你会发现真正麻烦的已经不是“少写了几行代码”，而是对象组装这件事完全失控了。

依赖注入要解决的，就是“对象怎么被创建、怎么被复用、怎么在不同生命周期里稳定地交给需要它的地方”。`Hilt` 在 Android 里的价值，并不只是帮你少写模板，而是把原本分散在各个页面和工厂里的组装逻辑收回到一个更清晰的系统里。

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

所以学 Hilt 时，真正要学的是对象生命周期判断。

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

### 9. 实践任务

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

- 你能解释依赖注入为什么不是“少写 new”。
- 你能判断一个对象为什么应该是单例，或者为什么不应该。
- 你能说明 Hilt 为什么在 Android 中比手工工厂更自然。

调试提示:

- 如果同一个基础设施对象在多个地方反复创建，优先考虑是否缺少统一注入点。
- 如果页面里到处都是手工装配链，说明 Hilt 还没有真正落地。
- 如果你把局部临时对象也都强行注入，说明依赖注入已经开始过度。

### 10. 常见误区

- 把 Hilt 理解成“自动生成对象”的黑盒。
- 只记注解，不理解作用域。
- 什么都交给 Hilt，导致注入过度。
- 把页面里原本就简单清晰的局部创建也强行抽象化。

## 小结

Hilt 与依赖注入真正解决的，是对象创建、复用、替换和生命周期协调问题。它让页面和 ViewModel 不再承担复杂装配职责，也让基础设施对象拥有更清晰的归属。只要先把“谁来创建、谁来使用、对象该活多久”这三件事想明白，Hilt 就不会只是注解集合，而会变成 Android 工程结构中非常实用的一层。

## 参考资料

- Hilt on Android: <https://developer.android.com/training/dependency-injection/hilt-android>
- Hilt and Jetpack integrations: <https://developer.android.com/training/dependency-injection/hilt-jetpack>
- Dependency injection guide: <https://developer.android.com/training/dependency-injection>
