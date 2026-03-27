# UseCase / Domain 层

当项目还比较小时，ViewModel 调 Repository 往往已经够用。但只要功能开始变复杂，你很快会遇到另一类问题: 一个动作不再只是“拿数据”，而是要跨多个 Repository 协作、做一串业务规则判断、决定失败时怎么退让、成功后怎么回写。到了这个阶段，如果所有流程都继续留在 ViewModel 里，页面状态层很快又会膨胀。

`UseCase` 或 `Domain` 层的价值，就在于把“业务动作本身”抽出来。更偏 Clean Architecture 的资料通常会把它放在更稳定的内层来理解：外层技术细节会不断变化，但“用户完成某个业务动作时，系统应该按什么规则运行”这件事更值得被稳定保存。因此 Domain 层不是为了让项目看起来更“企业级”，而是在回答一个问题: 当某个操作已经超出单纯页面状态组织时，这段业务流程应该放在哪里，才能既不压垮 ViewModel，又不把 Repository 变成业务垃圾桶。

## 学习目标

- 理解 UseCase / Domain 层要解决的是业务动作组织问题，而不是分层数量问题。
- 理解它和 ViewModel、Repository 的职责边界。
- 学会判断什么时候值得引入 UseCase，什么时候不用硬加。
- 理解输入输出清晰的 UseCase 为什么有利于复用和测试。

## 前置知识

- 已理解 ViewModel 的页面状态职责。
- 已理解 Repository 负责数据入口和数据策略。

## 正文

### 1. 什么时候 ViewModel 开始显得太重

设想一个“加入稍后阅读”动作。用户点击按钮后，系统可能需要:

- 先检查用户是否登录。
- 再读取文章当前状态。
- 如果本地没有文章详情，先同步一份。
- 最后更新收藏状态并上报分析事件。

如果这整条链路都写在 ViewModel 里，表面上没问题，但很快就会有三个后果:

- ViewModel 开始知道越来越多业务细节。
- 同一动作如果在别的页面也要用，很难复用。
- 测试页面状态时，不得不连带测试整段业务流程。

UseCase 往往就是在这种时刻出现的。

### 2. UseCase 解决的是“一个动作怎么做”，不是“数据从哪来”

这条边界特别重要。Repository 主要回答的是“数据从哪来、怎么同步、谁是可信来源”。UseCase 更关注“为了完成一个业务动作，需要怎样组织这些能力”。

也就是说:

- Repository 偏数据入口。
- UseCase 偏业务动作。

例如“观察文章列表”更像 Repository 的职责；“同步收藏并刷新首页推荐”更像 UseCase 的职责。把这条线分清楚，很多“这段逻辑到底该放哪”的争论都会少很多。

### 3. 不是每个项目都必须有 Domain 层

教材里必须把这件事讲清楚。UseCase / Domain 层不是默认必选项。如果你的项目很小，或者大部分页面动作都只是单个 Repository 调用再转成状态，那么强行加一层只会增加跳转成本。

更适合引入 UseCase 的信号通常包括:

- 一个动作需要跨多个 Repository 协作。
- 同一业务动作会在多个页面或入口重复出现。
- 业务规则本身比页面状态更复杂。
- 你已经在 ViewModel 里看到了明显的流程膨胀。

换句话说，UseCase 是为复杂业务动作服务的，而不是为“看起来标准”服务的。只有当你已经能明确说出“这一层在保护哪些更稳定的业务规则”时，Domain 层才真正开始产生收益。

### 4. 一个好的 UseCase 应该长什么样

一个健康的 UseCase 通常有三个特征:

- 输入清晰。
- 输出清晰。
- 内部只关心完成这个业务动作所需的规则和协作。

它不应该直接持有页面控件，也不应该返回一堆和 UI 强绑定的细节。更理想的状态是，ViewModel 把页面意图交给 UseCase，UseCase 完成业务动作，再把结果返回给 ViewModel 去翻译成页面状态。

### 5. 一个更接近真实项目的例子

下面这个例子演示“同步待办提醒并安排通知”这种跨层动作该如何被抽成 UseCase:

```kotlin
class ScheduleTodoReminderUseCase(
    private val repository: TodoRepository,
    private val reminderScheduler: ReminderScheduler
) {

    suspend operator fun invoke(todoId: String): Result<Unit> {
        val todo = repository.getTodoById(todoId) ?: return Result.failure(
            IllegalArgumentException("Todo not found")
        )

        if (todo.remindAt == null) {
            reminderScheduler.cancel(todoId)
            return Result.success(Unit)
        }

        repository.markReminderScheduled(todoId)
        reminderScheduler.schedule(todoId, todo.remindAt)
        return Result.success(Unit)
    }
}
```

这个例子里，UseCase 承接的是一个完整业务动作:

- 读当前任务数据。
- 判断是否需要提醒。
- 更新本地状态。
- 调度系统提醒。

如果这些逻辑全部塞在 ViewModel 里，页面层会很快和业务策略耦合得过深。

真正落到项目里时，UseCase 最好不要只停在“单独一个类”，而要和 ViewModel、测试形成一条完整调用链：

```kotlin
@HiltViewModel
class TodoDetailViewModel @Inject constructor(
    private val scheduleTodoReminder: ScheduleTodoReminderUseCase,
) : ViewModel() {
    private val _uiState = MutableStateFlow(TodoDetailUiState())
    val uiState: StateFlow<TodoDetailUiState> = _uiState.asStateFlow()

    fun onReminderChanged(todoId: String) {
        viewModelScope.launch {
            val result = scheduleTodoReminder(todoId)
            _uiState.update {
                it.copy(reminderSaveMessage = if (result.isSuccess) "提醒已更新" else "提醒更新失败")
            }
        }
    }
}

class ScheduleTodoReminderUseCaseTest {
    @Test
    fun schedulesReminderWhenTodoHasRemindAt() = runTest {
        val repository = FakeTodoRepository(todo = Todo(id = "42", remindAt = Instant.parse("2026-03-25T09:00:00Z")))
        val scheduler = FakeReminderScheduler()
        val useCase = ScheduleTodoReminderUseCase(repository, scheduler)

        useCase("42")

        assertTrue(repository.markedIds.contains("42"))
        assertTrue(scheduler.scheduledIds.contains("42"))
    }
}
```

这里最重要的技术点有两个。第一，ViewModel 不再知道“提醒到底怎么安排”，它只负责触发动作并把结果翻译成页面状态。第二，UseCase 可以在完全脱离 Activity、Fragment 和 Android 组件的前提下单独测试，这正是 Domain 层在复杂项目里最有价值的地方之一。

### 6. Domain 层为什么会让“业务规则”更容易被看见

很多项目最大的问题不是没有业务规则，而是业务规则散落得让人看不见。今天写在页面里一点，明天写在 Repository 里一点，后天又在工具类里藏一点。等需求变更时，没有人知道到底要改哪几处。

把动作抽成 UseCase，最大的收益之一就是规则显性化。你终于能直接看到:

- 这个业务动作的输入是什么。
- 它依赖哪些能力。
- 失败和成功路径分别怎么走。

这会让维护和测试都轻松很多。

### 7. ViewModel、UseCase、Repository 的职责链路

可以把它们先记成一条很实用的顺序:

- ViewModel 负责页面状态和事件入口。
- UseCase 负责较复杂的业务动作。
- Repository 负责数据入口和来源策略。

只要记住“页面状态 -> 业务动作 -> 数据策略”这条链路，很多复杂项目里的分工就能看懂。

### 8. 不要把 Domain 层做成新的抽象迷宫

UseCase 也很容易被过度设计。最常见的错误包括:

- 每个 Repository 方法外面都再机械包一层 UseCase。
- 一个极简单动作也要拆出好几个中间对象。
- 为了“纯净”，让代码层层跳转却没有实际收益。

如果一个动作只是 `repository.observeItems()`，那通常没有必要再包成 `ObserveItemsUseCase`。UseCase 真正值得出现，是因为它带来了额外业务组织价值。

### 9. 当业务动作跨多个仓库时，UseCase 的输出应该先服务于领域判断

UseCase 最容易写歪的地方，是它明明处在 Domain 层，却急着返回页面文案、按钮状态或者 Snackbar 文本。更稳的做法，是先让它返回领域层真正关心的结果，再由 ViewModel 翻译成 UI。Bennett 在 `AddToCartUseCase` 这类例子里反复强调的，其实就是这条边界：UseCase 先回答“业务动作结果是什么”，而不是“页面现在该显示哪句话”。

```kotlin
sealed interface AddToCartResult {
    data class Success(val cartItemCount: Int) : AddToCartResult
    data object LoginRequired : AddToCartResult
    data object ProductUnavailable : AddToCartResult
}

interface AddToCartUseCase {
    suspend operator fun invoke(
        productId: String,
        quantity: Int,
    ): AddToCartResult
}

internal class AddToCartUseCaseImpl(
    private val authRepository: AuthRepository,
    private val productRepository: ProductRepository,
    private val cartRepository: CartRepository,
) : AddToCartUseCase {

    override suspend fun invoke(productId: String, quantity: Int): AddToCartResult {
        if (!authRepository.isLoggedIn()) return AddToCartResult.LoginRequired

        val product = productRepository.getProduct(productId)
            ?: return AddToCartResult.ProductUnavailable

        if (!product.canPurchase(quantity)) {
            return AddToCartResult.ProductUnavailable
        }

        cartRepository.add(productId = product.id, quantity = quantity)
        return AddToCartResult.Success(
            cartItemCount = cartRepository.getItemCount(),
        )
    }
}
```

这段代码里真正重要的不是“多写了一个 `sealed interface`”，而是业务结果被稳定收在了 Domain 层语义里。`LoginRequired`、`ProductUnavailable` 和 `Success` 都是业务上成立的结果，它们既能被不同页面复用，也更容易被测试覆盖。到了 ViewModel 层，你再去决定它们分别映射成登录弹窗、缺货提示还是购物车角标更新。

这样做的直接收益有两个。第一，UseCase 不会因为某个页面改文案就一起被牵着改，领域规则的稳定性更高。第二，多个页面如果共享同一个业务动作，也不会因为 UI 表达不同就被迫复制一份逻辑。只要这条边界守住，UseCase 才真正像 Domain 层，而不是“换个名字的页面辅助类”。

### 10. 一个 UseCase 往往也是一次业务事务的边界

`Clean Android Architecture` 和 Bennett 的例子都在强调，UseCase 不只是把几个 Repository 调用排一下序，更像“这次业务动作从哪里开始，到哪里才算完成”的边界。如果一次动作要跨登录、库存、支付和下单多个步骤，ViewModel 就不该再一段段手写流程，而应把这条业务事务收回一个 UseCase 里。

```kotlin
sealed interface CheckoutResult {
    data class Success(val orderId: String) : CheckoutResult
    data object LoginRequired : CheckoutResult
    data object EmptyCart : CheckoutResult
    data object PaymentUnavailable : CheckoutResult
}

class CheckoutCartUseCase(
    private val authRepository: AuthRepository,
    private val cartRepository: CartRepository,
    private val paymentRepository: PaymentRepository,
    private val orderRepository: OrderRepository,
) {
    suspend operator fun invoke(): CheckoutResult {
        if (!authRepository.isLoggedIn()) return CheckoutResult.LoginRequired

        val items = cartRepository.getItems()
        if (items.isEmpty()) return CheckoutResult.EmptyCart

        val paymentToken = paymentRepository.prepare(items)
            ?: return CheckoutResult.PaymentUnavailable

        val orderId = orderRepository.placeOrder(
            items = items,
            paymentToken = paymentToken,
        )

        cartRepository.clear()
        return CheckoutResult.Success(orderId)
    }
}
```

这段代码的关键，不是“动作更多所以要多建一层”，而是业务完成条件终于被收成了一处。只有当下单成功时才清空购物车，只有登录通过后才继续准备支付，这些顺序和条件都属于业务事务本身，而不是页面渲染逻辑。只要读者把这一点想清楚，就会更容易判断哪些流程该继续留在 ViewModel，哪些已经值得抽成 UseCase。

### 11. UseCase 一旦能被独立测试，业务边界就会非常清楚

UseCase 之所以值得单独存在，很大一个原因是它终于把“业务规则是否成立”从页面和框架里剥离出来了。Bennett 和 Big Nerd Ranch 都给过类似启发：只要一个动作真的被抽成稳定输入输出，你就可以先测试规则本身，再去测试 ViewModel 怎样把它翻译成界面状态。

```kotlin
class CheckoutCartUseCaseTest {

    @Test
    fun returns_login_required_when_user_is_not_signed_in() = runTest {
        val useCase = CheckoutCartUseCase(
            authRepository = FakeAuthRepository(isLoggedIn = false),
            cartRepository = FakeCartRepository(items = listOf(fakeCartItem())),
            paymentRepository = FakePaymentRepository(),
            orderRepository = FakeOrderRepository(),
        )

        val result = useCase()

        assertEquals(CheckoutResult.LoginRequired, result)
    }
}
```

这段测试的价值在于：页面文案、导航动作和按钮状态都还没出现，但业务规则已经能被确认了。只要 UseCase 可以在纯 Kotlin 语境里被验证，Domain 层边界就会清楚很多。反过来，如果一个所谓的 UseCase 还必须依赖页面对象、资源字符串或 Android 组件才能测，通常也说明它还没有真正从 UI 层里抽出来。

### 12. 观察型 UseCase 也很常见，但输出仍然应该先服务业务语义

很多读者一提到 UseCase，脑子里首先想到的都是“点一下按钮，执行一次动作”。这当然是常见场景，但 Bennett 和 `Clean Android Architecture` 都提醒过，Domain 层也经常要提供“持续观察某个业务结果”的能力。关键不是它是不是 `Flow`，而是它的输出是否仍然在表达业务语义，而不是直接把原始数据源扔给 UI。

```kotlin
data class CheckoutSummary(
    val totalPrice: Money,
    val canSubmit: Boolean,
    val blockedReason: CheckoutBlockedReason?,
)

class ObserveCheckoutSummaryUseCase(
    private val cartRepository: CartRepository,
    private val accountRepository: AccountRepository,
    private val couponRepository: CouponRepository,
) {
    operator fun invoke(): Flow<CheckoutSummary> {
        return combine(
            cartRepository.observeItems(),
            accountRepository.observeLoginState(),
            couponRepository.observeAppliedCoupon(),
        ) { items, isLoggedIn, coupon ->
            val totalPrice = coupon.applyTo(items.totalPrice())
            val blockedReason = when {
                items.isEmpty() -> CheckoutBlockedReason.EMPTY_CART
                !isLoggedIn -> CheckoutBlockedReason.LOGIN_REQUIRED
                else -> null
            }

            CheckoutSummary(
                totalPrice = totalPrice,
                canSubmit = blockedReason == null,
                blockedReason = blockedReason,
            )
        }
    }
}
```

这段代码的价值，在于它把“购物车总价怎样计算、什么时候允许提交、当前被什么业务条件拦住”先收成了一份领域结果。到了 ViewModel，你再把 `LOGIN_REQUIRED` 映射成登录引导，把 `EMPTY_CART` 映射成空购物车提示；但这些都已经建立在 Domain 层先把业务判断算清楚的前提上。只要读者把这一点想通，就不会再把“返回 `Flow`”误解成“直接把 Repository 流照搬出来”。

### 13. 当 UseCase 输入开始膨胀时，用 Command 对象会比长参数表更稳

`Clean Android Architecture` 和 Bennett 在复杂业务动作的例子里都做了同一个取舍：一旦一个动作需要的输入开始变多，就不要再让 ViewModel 把一串彼此有关联的参数拆开传进去。对 Domain 层来说，这些输入通常本来就属于同一个业务命令，把它们收成 `Command` 对象，会比维护一长串参数表更稳，也更方便在边界上做验证。

```kotlin
data class SubmitReviewCommand(
    val articleId: Long,
    val rating: Int,
    val comment: String,
    val containsSpoiler: Boolean,
)

sealed interface SubmitReviewResult {
    data object Success : SubmitReviewResult
    data object RatingOutOfRange : SubmitReviewResult
    data object CommentTooLong : SubmitReviewResult
}

class SubmitReviewUseCase(
    private val repository: ReviewRepository,
) {
    suspend operator fun invoke(
        command: SubmitReviewCommand,
    ): SubmitReviewResult {
        if (command.rating !in 1..5) {
            return SubmitReviewResult.RatingOutOfRange
        }
        if (command.comment.length > 300) {
            return SubmitReviewResult.CommentTooLong
        }

        repository.submit(
            articleId = command.articleId,
            rating = command.rating,
            comment = command.comment,
            containsSpoiler = command.containsSpoiler,
        )
        return SubmitReviewResult.Success
    }
}
```

这里真正稳定下来的，是输入语义本身。评分、评论内容和 spoiler 标记不再只是三四个零散参数，而是同一次“提交评论”业务动作的完整命令。这样一来，UseCase 就更容易在边界上做校验、做测试，也更不容易在参数逐渐变多后退化成看不懂的长方法签名。

### 14. 实践任务

起点条件:

- 已有一个 ViewModel 中开始出现多步业务流程的页面。

步骤:

1. 找出一段包含多个条件、多个数据来源或多个后续动作的逻辑。
2. 判断它是否已经超出页面状态组织范围。
3. 把它提炼成一个输入和输出清晰的 UseCase。
4. 让 ViewModel 只负责调用 UseCase 并把结果映射成 `uiState`。
5. 检查这个 UseCase 是否还有复用价值，或是否仍旧过度依赖页面细节。

预期结果:

- ViewModel 会比以前更聚焦于页面状态。
- 复杂业务动作会有更明确的边界和命名。
- 业务规则的可见性和可测试性都会提高。

自检方式:

- 读者应能解释 Repository 和 UseCase 的根本区别。
- 读者应能判断某段逻辑为什么适合抽成 UseCase。
- 读者应能说出什么时候不需要强行引入 Domain 层。

调试提示:

- 如果 ViewModel 里开始出现大量跨 Repository 编排，优先考虑 UseCase。
- 如果每个简单调用都被机械包一层，说明 Domain 层过度了。
- 如果 UseCase 里还在操作页面文案和导航，说明边界划错了。

### 15. 常见误区

- 把 UseCase 当成所有方法都要套的一层模板。
- 分不清业务动作和数据策略。
- 为了“架构整齐”过度抽象。
- 把页面细节继续带进 Domain 层。

## 小结

UseCase / Domain 层真正要解决的，是复杂业务动作应该放在哪里的问题。它让 ViewModel 不必承载过多流程编排，也让 Repository 不必吞下所有规则。只要引入时机合理、输入输出清晰、边界不过度，Domain 层就会成为复杂项目里非常有价值的一层；反过来，如果项目本身还很简单，克制地不加这层，往往也是更成熟的选择。

## 参考资料

- 参考并改写自本地 PDF：`Clean Android Architecture`，UseCase、Repository 接口、Domain 内层边界与依赖规则相关章节。
- 参考并整理自本地 PDF：Bennett M.，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，data-domain-presentation 分层与多模块应用中的业务动作组织相关章节。
- Domain layer guide: <https://developer.android.com/topic/architecture/domain-layer>
- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>
- Now in Android: <https://github.com/android/nowinandroid>


