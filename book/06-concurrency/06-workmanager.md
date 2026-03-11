# WorkManager

在现代 Android 后台任务体系中，WorkManager 是最常见的主线工具之一。它并不试图覆盖所有场景，但对于那些“可以延迟执行、需要约束条件、希望即使应用退出后也尽量完成”的任务，它通常是最值得优先考虑的方案。本章的重点，不是把 WorkManager 学成 API 目录，而是理解它为什么会成为今天 Android 推荐的后台工作主线。

Android 官方对 WorkManager 的定位非常明确：它适用于 deferrable, guaranteed background work，也就是可延迟、但希望有较高完成保证的后台任务。只要你抓住这句话，很多边界就会变得清楚：它不是即时交互工具，也不是长期用户可感知任务工具，而是系统感知调度型后台工作主线。

## 学习目标

- 理解 WorkManager 最适合解决什么类型的任务。
- 理解约束、重试、唯一任务和链式任务的基本意义。
- 理解 WorkManager 与页面协程、前台服务的边界。
- 为离线同步、上传和定期刷新设计打基础。

## 前置知识

- 已理解后台任务不是所有异步工作的总称。
- 已知道不同任务类型应选择不同机制。

## 正文

### 1. WorkManager 最适合什么任务

WorkManager 最适合那些具备以下特征的任务：

- 不需要立刻完成。
- 可以接受系统择机执行。
- 希望即使应用退出后也尽量完成。
- 可能需要网络、充电、空闲等约束条件。

典型例子包括：

- 延迟上传草稿。
- 周期性同步部分数据。
- 在合适网络下上传日志或附件。
- 定期清理缓存或执行后台整理任务。

这些任务的共同点是：结果重要，但不是“用户眼前立刻就要看到”的结果。

### 2. 为什么 WorkManager 比手工后台线程更适合这类场景

如果你试图用页面协程、普通线程甚至临时 Service 去硬撑这些任务，通常会很快遇到问题：

- 页面结束后任务失去自然宿主。
- 进程被回收后很难继续。
- 网络、充电等约束条件需要自己维护。
- 重试逻辑分散且不稳定。

WorkManager 的价值，就是把这类任务从“手工维持”交给系统感知的调度模型来处理。官方文档也明确说明，它会根据设备状态和系统版本选择更底层的最佳执行方式。

### 3. 约束条件为什么值得认真设计

很多后台任务并不是“越快越好”。例如上传大量数据时，用户未必希望你在弱网、低电量或漫游状态下强行执行。WorkManager 的约束能力之所以重要，就是因为它把“任务何时执行更合适”作为模型的一部分，而不是留给开发者事后补救。

这也体现了现代 Android 的设计方向：后台工作必须更尊重设备资源和用户体验，而不是默认抢占执行。

### 4. 重试和唯一任务是可靠性的关键部分

WorkManager 常被误用成“任务交给它就好了”。实际上，真正有价值的设计还包括：

- 失败后是否应该重试。
- 多次触发同类任务时是否应合并。
- 某一类任务是否应该全局唯一。

比如草稿上传、日志同步、周期性刷新，如果不认真处理唯一任务策略，很容易出现多个重复工作互相覆盖或浪费资源。官方提供的唯一任务 API 和现有工作策略，正是为了帮助你定义这些行为边界。

### 5. 链式任务和可观察状态为什么重要

真实项目里的后台工作很少只是“一次执行一个函数”。有些任务可能需要：

- 先压缩文件，再上传。
- 先同步远程，再清理本地。
- 先生成缩略图，再写数据库。

WorkManager 的链式任务能力，让这类后台流程可以像有结构的工作流一样被表达，而不是由多个位置分散触发。同样，它也支持观察工作状态，让 UI 能在需要时知道任务是排队中、运行中还是失败重试中。

### 6. WorkManager 不适合什么

理解边界比记用法更重要。下面这些场景通常不应优先考虑 WorkManager：

- 用户当前正在等待结果的即时操作。
- 必须立即完成的页面交互。
- 用户明确感知且需要持续运行的长任务，例如导航、录音、持续定位、音乐播放。

前两类更适合页面协程和 ViewModel 任务链；后一类更接近前台服务。只要这条边界不清，WorkManager 就会被误用成“后台万能工具”。

### 7. 草稿上传为什么是 WorkManager 的理想案例

草稿上传通常具备这些特点：

- 页面关闭后仍有价值。
- 不一定要立刻完成。
- 网络可用时再执行更合理。
- 失败后通常可以重试。

这几乎就是 WorkManager 的理想场景。相比在页面层硬维持上传协程，它更符合平台规则，也更利于统一管理失败、重试和任务合并。

### 8. 一个更接近真实项目的最小示例

下面的示例展示 WorkManager 的典型结构：定义约束、编写 Worker、入队唯一任务。

```kotlin
class SyncDraftWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        return try {
            draftRepository.syncPendingDrafts()
            Result.success()
        } catch (e: IOException) {
            Result.retry()
        } catch (e: Throwable) {
            Result.failure()
        }
    }
}

val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.CONNECTED)
    .build()

val request = OneTimeWorkRequestBuilder<SyncDraftWorker>()
    .setConstraints(constraints)
    .build()

WorkManager.getInstance(context).enqueueUniqueWork(
    "sync_drafts",
    ExistingWorkPolicy.KEEP,
    request
)
```

这个例子里最重要的不是语法，而是这几个判断：

- 任务可以延迟。
- 任务需要网络约束。
- 同一类任务应避免重复入队。
- 失败并不总是终局，有些情况适合重试。

### 9. 实践任务

起点条件：

- 已有一个可延迟执行的需求，例如同步、上传、整理、清理或定期刷新。

步骤：

1. 选一个任务，确认它是否真的可以接受延迟。
2. 为它设计最小约束条件，例如联网、充电或存储充足。
3. 判断它是否应该作为唯一任务存在，以及失败后是否应该重试。
4. 说明为什么它不适合继续放在页面协程或前台服务里。
5. 观察该任务如果被频繁触发，应该采用替换、保留还是追加策略。

预期结果：

- 你能把 WorkManager 用在真正适合的场景，而不是泛化使用。
- 你会更认真地设计约束、唯一任务和失败策略。
- 你能为后续系统组件和工程实践章节打下更稳的后台工作基础。

自检方式：

- 你能解释：WorkManager 为什么适合可延迟但重要的后台任务。
- 你能判断：一个任务更应该交给页面协程、WorkManager 还是前台服务。
- 你能说出：唯一任务和重试策略为什么对可靠性有直接影响。

调试提示：

- 如果用户当前正在等待结果，就先不要急着选 WorkManager。
- 如果相同任务不断重复执行，优先检查唯一任务策略是否缺失。
- 如果任务对网络、电量敏感，却没有任何约束条件，后续表现通常会很不稳定。

### 10. 常见误区

- 把 WorkManager 当成所有后台工作的万能答案。
- 不先判断任务是否真的可延迟。
- 忽略唯一任务、约束和重试设计。
- 把用户当前等待的即时操作也塞给 WorkManager。

## 小结

WorkManager 是现代 Android 后台工作的主线之一。理解它的关键，不是会不会写 Worker，而是知道它最适合哪类任务，以及为什么这类任务交给系统感知的调度模型会比手工维持更稳定。只要任务分类正确，它会成为后台可靠性设计中非常稳的一块基础。


## 参考资料

- WorkManager overview：<https://developer.android.com/topic/libraries/architecture/workmanager>
- Define your work requests：<https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work>
- Manage work：<https://developer.android.com/develop/background-work/background-tasks/persistent/how-to/manage-work>
