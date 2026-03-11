# Hilt 与依赖注入

依赖注入是 Android 工程化里一个非常典型的话题。很多人第一次接触它时，会把目标理解成“少写几个 `new`”或者“自动创建对象”。这种理解太浅。依赖注入真正解决的是对象关系和对象创建责任的问题：谁负责创建对象，谁持有对象，哪些对象应被复用，哪些对象只该活在某个页面流程里，以及测试时如何替换实现。

本章会先把依赖注入讲清楚，再解释为什么 Hilt 成为现代 Android 中最常见的落地主线。重点不是记注解，而是理解对象图与生命周期的治理思路。

## 学习目标

- 理解依赖注入真正要解决的问题。
- 理解 Hilt 在 Android 项目中的主要价值。
- 理解构造注入、模块提供、作用域和组件生命周期的意义。
- 知道什么时候 Hilt 能带来明显收益，什么时候不必过度引入。

## 前置知识

- 已理解 ViewModel、Repository、UseCase 和分层架构的关系。
- 已知道对象之间的依赖关系会随着项目增长迅速复杂化。

## 正文

### 1. Android 项目中的依赖关系为什么会失控

在最小项目里，页面里直接创建一个 Repository、再创建一个 API 服务，看起来没有问题。但只要项目稍大，依赖关系就会快速变复杂：

- 同一个对象需要在多个地方复用。
- 一个对象的创建本身又依赖多个其他对象。
- 某些对象应该全局单例，某些只该跟页面生命周期绑定。
- 测试时希望替换成假实现。

这说明真正的问题不是“能不能构造出来”，而是对象图是否清晰、创建规则是否统一、生命周期是否合理。依赖注入正是为了解决这些问题。

### 2. 依赖注入首先是一种设计思想，不是框架名字

依赖注入的核心思想很简单：对象不自己决定如何创建依赖，而是由外部把依赖提供给它。这样做有几个直接好处：

- 类的职责更聚焦。
- 创建逻辑集中管理。
- 依赖关系一眼可见。
- 测试时更容易替换实现。

所以在学习 Hilt 之前，最重要的是先建立这个意识：DI 解决的是“对象关系治理”，不是“语法省事”。

### 3. 为什么 Android 特别适合做依赖注入

Android 项目天然存在大量跨层对象和不同生命周期对象，例如：

- `OkHttpClient`、Retrofit、RoomDatabase 这类应用级共享对象。
- Repository、UseCase、Manager 这类业务对象。
- ViewModel 这类屏幕级状态对象。
- 某些只在 Activity、Fragment、Service 范围内有效的对象。

如果这些对象全部在页面或工具类里手工创建，项目很快就会变得难以追踪。依赖注入的意义，就是把对象图从“散落的创建代码”收束成“可维护的依赖图”。

### 4. Hilt 为什么成为 Android 中的主线实现

Android 官方明确建议在 Android 上使用 Hilt。原因并不神秘：Hilt 是构建在 Dagger 之上的 Android 专用依赖注入方案，它为常见 Android 类自动生成组件，减少了手工维护对象容器的大量样板代码。

Hilt 的价值主要体现在两点：

- 它让 DI 更自然地和 Android 生命周期对齐。
- 它把 Application、Activity、Fragment、ViewModel、Service 等常见入口都纳入统一对象图中。

这意味着你不必再从零手写整套容器和工厂逻辑，而是能在标准化框架上治理对象关系。

### 5. 构造注入、`@Binds`、`@Provides` 分别在解决什么

Android 官方的 Hilt 文档强调，能用构造注入就优先用构造注入。这是最清晰的方式，因为类需要什么依赖会直接体现在构造函数上。

当一个类型是接口时，通常需要使用 `@Binds` 告诉 Hilt 该注入哪个实现。

当一个类型来自外部库、你并不拥有其构造函数，或者创建过程需要 builder 配置时，则需要 `@Provides`。例如 Retrofit、OkHttpClient、Room 数据库这类对象，通常就会通过模块提供。

这三者不是写法选择题，而是在表达不同类型对象的创建边界。

### 6. 作用域和组件生命周期必须一起理解

Hilt 之所以适合 Android，一个关键原因就是它把对象作用域和组件生命周期连接得很清楚。官方文档列出的组件包括：

- `SingletonComponent`
- `ActivityRetainedComponent`
- `ViewModelComponent`
- `ActivityComponent`
- `FragmentComponent`
- `ServiceComponent`

作用域的意义并不是“对象越全局越省事”，而是让对象活得刚刚好。比如：

- `OkHttpClient`、数据库这类对象通常适合应用级共享。
- ViewModel 依赖可以与 `ViewModelComponent` 绑定。
- 某些仅在页面内有效的对象不应该错误地提升为全局单例。

只要作用域判断错了，要么会重复创建浪费资源，要么会意外共享不该共享的状态。

### 7. Hilt 可以管理对象关系，但不会自动修好架构

这是最容易被忽略的一点。即使引入了 Hilt，如果你的 Repository 边界本来就混乱，ViewModel 本来就过重，那么 Hilt 只会把这些问题更自动化地延续下去。它擅长的是依赖关系治理，不擅长替你决定职责归属。

所以更合理的顺序通常是：

1. 先让层次和边界大致清楚。
2. 再用 Hilt 统一对象创建和生命周期管理。

否则，DI 框架本身也可能成为新的复杂度来源。

### 8. 一个更接近真实项目的最小示例

下面的例子展示一个典型的 Hilt 配置主线：外部库对象通过模块提供，业务类优先使用构造注入，ViewModel 通过 Hilt 自动拿到依赖。

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder().build()

    @Provides
    fun provideRetrofit(client: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://example.com/api/")
            .client(client)
            .build()
    }
}

class ArticleRepository @Inject constructor(
    private val api: ArticleApi
)

@HiltViewModel
class ArticleViewModel @Inject constructor(
    private val repository: ArticleRepository,
    private val savedStateHandle: SavedStateHandle
) : ViewModel()
```

这个示例真正重要的不是注解数量，而是对象关系被清晰表达出来了：外部对象由模块提供，业务对象由构造注入，ViewModel 依赖则由 Hilt 管理其创建。

### 9. 实践任务

起点条件：

- 已有一个具备 ViewModel、Repository、网络层或数据库层的 Android 项目。

步骤：

1. 列出项目中最核心的 5 到 8 个共享对象。
2. 判断这些对象分别应处于应用级、页面级还是更短生命周期。
3. 把可以构造注入的类改为构造注入。
4. 为无法构造注入的第三方对象编写一个最小 Hilt 模块。
5. 检查是否仍有页面层直接手工创建 Repository、Retrofit 或数据库实例。

预期结果：

- 依赖关系会比之前更可追踪。
- 对象创建逻辑更集中，替换实现和测试都更容易。
- 生命周期与对象复用关系会更清晰。

自检方式：

- 你能解释：为什么依赖注入解决的是对象关系，而不只是少写 `new`。
- 你能判断：一个对象更适合构造注入、`@Binds` 还是 `@Provides`。
- 你能确认：当前作用域是否与对象实际生命周期匹配。
- 你能说出：为什么 Hilt 不能替代职责边界设计。

调试提示：

- 如果页面仍在手工创建核心依赖，说明 DI 还没有真正接管对象图。
- 如果所有对象都被放成单例，优先检查是否错误扩大了生命周期。
- 如果 Hilt 模块过多但类本身依赖不清晰，通常说明应该先整理边界再加框架。

### 10. 常见误区

- 把依赖注入理解成“少写 new”。
- 在边界不清晰的前提下过早引入 Hilt。
- 不区分作用域，什么都当临时对象或全局单例。
- 以为用了 Hilt 就自动拥有良好架构。

## 小结

依赖注入的核心，不是框架，而是对象关系的清晰治理。Hilt 在现代 Android 中之所以成为主线，是因为它把这种治理自然地和 Android 生命周期、ViewModel、Navigation、WorkManager 等生态接到了一起。只要边界本身清楚，Hilt 会显著降低对象创建和维护成本。

## 参考资料

- Dependency injection with Hilt：<https://developer.android.com/training/dependency-injection/hilt-android>
- Use Hilt with other Jetpack libraries：<https://developer.android.com/training/dependency-injection/hilt-jetpack>
- Recommendations for Android architecture：<https://developer.android.com/topic/architecture/recommendations>
