# UseCase / Domain 层

当项目还比较小时，ViewModel 调 Repository 往往已经够用。但只要功能开始变复杂，你很快会遇到另一类问题: 一个动作不再只是“拿数据”，而是要跨多个 Repository 协作、做一串业务规则判断、决定失败时怎么退让、成功后怎么回写。到了这个阶段，如果所有流程都继续留在 ViewModel 里，页面状态层很快又会膨胀。

`UseCase` 或 `Domain` 层的价值，就在于把“业务动作本身”抽出来。它不是为了让项目看起来更“企业级”，也不是每个项目都必须有，而是在回答一个问题: 当某个操作已经超出单纯页面状态组织时，这段业务流程应该放在哪里，才能既不压垮 ViewModel，又不把 Repository 变成业务垃圾桶。

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
- 测试页面状态时，不得不顺手测试整段业务流程。

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

换句话说，UseCase 是为复杂业务动作服务的，而不是为“看起来标准”服务的。

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

### 9. 实践任务

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

- 你能解释 Repository 和 UseCase 的根本区别。
- 你能判断某段逻辑为什么适合抽成 UseCase。
- 你能说出什么时候不需要强行引入 Domain 层。

调试提示:

- 如果 ViewModel 里开始出现大量跨 Repository 编排，优先考虑 UseCase。
- 如果每个简单调用都被机械包一层，说明 Domain 层过度了。
- 如果 UseCase 里还在操作页面文案和导航，说明边界划错了。

### 10. 常见误区

- 把 UseCase 当成所有方法都要套的一层模板。
- 分不清业务动作和数据策略。
- 为了“架构整齐”过度抽象。
- 把页面细节继续带进 Domain 层。

## 小结

UseCase / Domain 层真正要解决的，是复杂业务动作应该放在哪里的问题。它让 ViewModel 不必承载过多流程编排，也让 Repository 不必吞下所有规则。只要引入时机合理、输入输出清晰、边界不过度，Domain 层就会成为复杂项目里非常有价值的一层；反过来，如果项目本身还很简单，克制地不加这层，往往也是更成熟的选择。

## 参考资料

- 参考并改写自：Harun Wangereka，《Mastering Kotlin for Android 14》(2024)，第 5 章。
- 参考并改写自：Kickstart Modern Android Development With Jetpack And Kotlin (2024)，第 2、7-9、12 章。
- 参考并改写自：Damilola Panjuta、Linda Nwokike，《Tiny Android Projects Using Kotlin》(2024)，第 8 章。
- 参考并改写自：Gabriel Socorro，《Thriving in Android Development Using Kotlin》(2024)，第 1 章。

- Domain layer guide: <https://developer.android.com/topic/architecture/domain-layer>
- Recommendations for Android architecture: <https://developer.android.com/topic/architecture/recommendations>
- Now in Android: <https://github.com/android/nowinandroid>

