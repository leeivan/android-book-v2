# BroadcastReceiver

学 `BroadcastReceiver` 时，很多人最先记住的是“收到系统事件以后会回调 `onReceive()`”。这句话不算错，但如果只停在这里，就很容易继续沿着旧教程的思路，把接收器当成一个“后台顺手干活”的地方。到了现代 Android，这种理解已经明显不够用了。平台一方面限制了大量后台执行和隐式广播，另一方面又要求我们更明确地声明组件边界和导出行为。于是，真正应该先建立的认知不是“怎么收广播”，而是“广播在系统里到底承担什么角色”。

放在本书的上下文里看，这一章承接前面的 `Intent` 和 `Service`。`Intent` 讲的是动作表达，`Service` 讲的是持续能力的组件外壳，而 `BroadcastReceiver` 讲的是“某件事已经发生了”这一类事件入口。它不负责长时间执行，也不负责存储共享数据；下一章的 `ContentProvider` 才是结构化数据边界。只要先把这几种组件边界区分清楚，你就不会再把广播、后台任务和普通应用内通知混成一团。

本章要解决的，就是三个很现实的问题：什么时候该用广播接收器，什么时候应该改成运行时注册，什么时候收到事件后应该立刻把工作交给 `WorkManager`、ViewModel 或其他层，而不是继续把逻辑堆在 `onReceive()` 里。

## 学习目标

- 理解 BroadcastReceiver 是事件入口，而不是后台执行容器。
- 理解运行时注册和清单注册各自适合什么场景。
- 理解现代 Android 下广播的限制、导出边界和生命周期要求。
- 学会把广播收到的事件快速转交给更合适的处理层。

## 前置知识

- 已理解 `Intent`、`Service` 和后台任务的基本边界。
- 已接触页面生命周期、通知动作或系统事件一类场景。

## 正文

### 1. BroadcastReceiver 解决的是“谁来接这个事件”

有些事情不是当前页面主动发起的，而是系统或其他组件在告诉你“某件事已经发生了”。例如设备接通电源、时区变化、下载完成、通知操作按钮被点击、画中画窗口中的播放控制被触发。这些场景的共同点是：发送方并不关心你当前有没有某个具体页面实例，只是把一个事件广播出去，等待愿意处理它的组件来接。

这就是 BroadcastReceiver 的位置。它不是普通函数调用，也不是页面之间的导航入口，而是 Android 组件模型里专门负责“接事件”的那一层。事件本身通常仍然通过 `Intent` 承载，但重点已经从“我要做什么动作”变成了“某件事已经发生，谁来响应它”。

### 2. `onReceive()` 是短生命周期入口，不是工作现场

官方文档对广播接收器的定位非常明确：它的职责是快速接收并分发事件，而不是长期占着这条入口做复杂工作。原因很直接。接收器的生命周期很短，默认执行环境也往往落在应用主线程附近；如果你在这里直接发网络请求、跑数据库迁移、做大文件处理，不仅容易阻塞界面，还会和现代 Android 的后台限制发生冲突。

因此，更稳妥的理解方式是：`onReceive()` 只做三件事。第一，判断这是不是自己真正关心的广播；第二，提取最小必要信息；第三，把后续工作转交给更合适的层。这个“更合适的层”可能是页面可见时的 ViewModel，也可能是 Repository，或者是 `WorkManager` 这样的后台调度工具。

官方还提供了 `goAsync()` 这样的接口，用来处理少量必须异步收尾的场景。但它的意义只是“给你一点额外时间把短尾操作交出去”，不是把接收器变成长期任务容器。只要记住这条边界，就能避开广播章节里最常见的一类设计错误。

### 3. 写接收器之前，先用四个问题做判断

广播相关设计很容易一开始就掉进 API 细节里。更有效的做法，是先回答四个问题。

第一个问题是，事件到底来自哪里。它是系统广播、其他应用发来的广播，还是你自己应用里一个受控的通知动作？来源不同，后面涉及的安全边界和导出策略就不同。

第二个问题是，应用是否必须在未打开时也能接到这个事件。如果答案是否定的，那么运行时注册通常更合理，因为它能把监听范围缩到最小。只有在应用没启动也必须响应的少数场景下，才需要认真评估清单注册。

第三个问题是，这个事件是否只在某个页面或某段生命周期里才有意义。例如画中画播放控制、某个可见页面上的外设状态监听，就更适合随着页面注册和注销，而不是长期常驻。

第四个问题是，收到事件后的反应到底是“很快做完”，还是“要继续跑一段时间”。如果是后者，接收器就不该成为执行现场，而应成为转交现场。

### 4. 运行时注册通常是更现代、更克制的默认方案

官方文档明确建议：如果可以，就把接收器注册在尽可能小的作用域里。原因不难理解。很多广播只在应用处于某个活跃阶段时才有意义，把它们长期暴露出来只会增加生命周期管理和安全负担。

运行时注册的典型优势有三点。第一，它更容易贴合页面或组件生命周期，例如在 `onStart()` 注册、在 `onStop()` 注销。第二，它让事件来源和监听范围更加可读，不会把所有接收器都埋进清单文件。第三，它通常更符合现代 Android“按需唤醒、按需监听”的方向。

这也是为什么很多过去喜欢写成清单接收器的场景，今天更适合运行时注册。例如通知操作、画中画控制、只在前台页面有意义的系统状态监听，都更适合这种方式。

### 5. 清单注册仍然有价值，但它不再是“先声明再说”的默认做法

清单注册的意义，在于某些广播发生时，即使应用当前没有页面存活，系统也应该有机会唤起你的接收器。这种能力很强，但也正因为太强，平台对它的约束逐年增加。

Android 8.0 开始，系统已经不允许应用像早期那样在清单里接收大多数隐式广播，只有少数豁免场景或显式广播仍然适合这样做。这个变化的核心目的，是减少系统级事件触发时对整机性能和电量的冲击。

所以今天判断清单注册时，不能再沿用“只要想接系统广播，就先在 `AndroidManifest.xml` 里写一个 receiver”的习惯。更稳妥的问题应该是：这个事件是否真的要求在应用不活跃时也唤醒我？如果要求，再进一步确认它是否允许通过清单方式接收。

### 6. 导出边界必须说清楚，不能再依赖“默认猜测”

广播接收器天然位于组件边界上，因此它的安全问题比很多普通类更直接。只要一个接收器可能被应用外部触达，你就要明确知道：谁能给它发广播，它能接收什么 action，接到之后是否会触发敏感逻辑。

对于清单注册的接收器，这个边界主要体现在 `android:exported`、权限要求和 `intent-filter` 的设计上。对于运行时注册的接收器，Android 13 引入了 `RECEIVER_EXPORTED` 和 `RECEIVER_NOT_EXPORTED` 标志，Android 14 又进一步收紧了相关检查。它背后的原则很清楚：接收器是否对外可见，不能再靠含糊默认值来猜。

写代码时可以先抓住一个实用原则。如果接收器只用于本应用内部或受控来源事件，优先把它限制在不导出的边界内；如果它确实需要接受外部应用发来的广播，再显式评估导出行为、权限和输入校验。官方文档还特别说明：对于只接收系统广播的运行时注册场景，`Context.registerReceiver()` 在 Android 14 有专门例外，使用时要按当前平台文档选择对应重载和标志，而不要死记某一套写法。

### 7. 一个更健康的最小例子：只在页面活跃时接收播放控制广播

为了让边界更清楚，我们先看一个运行时注册的最小例子。场景是播放器页面在前台或画中画状态下，需要接收一个受控的播放/暂停广播动作。这个动作只在播放器页面活跃时才有意义，因此它适合运行时注册；同时，接收器不负责播放逻辑本身，只负责把事件交给 ViewModel。

```kotlin
class PlaybackActionReceiver(
    private val onTogglePlay: () -> Unit,
) : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE_PLAY) {
            onTogglePlay()
        }
    }

    companion object {
        const val ACTION_TOGGLE_PLAY = "com.example.player.action.TOGGLE_PLAY"
    }
}

class PlaybackActivity : ComponentActivity() {
    private val playerViewModel: PlayerViewModel by viewModels()

    private val playbackReceiver = PlaybackActionReceiver {
        playerViewModel.togglePlayback()
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter(PlaybackActionReceiver.ACTION_TOGGLE_PLAY)
        ContextCompat.registerReceiver(
            this,
            playbackReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onStop() {
        unregisterReceiver(playbackReceiver)
        super.onStop()
    }
}
```

这个例子真正值得学习的不是“如何把广播收进来”，而是它的职责拆分。第一，接收器只在页面活跃时存在，作用域很小。第二，它通过 `RECEIVER_NOT_EXPORTED` 明确表达自己不对外暴露。第三，`onReceive()` 没有承担播放逻辑，而是立即把动作交给 `playerViewModel`。这就让接收器保持了“事件入口”的本来角色。

如果你的项目没有使用 AndroidX Core，也可以按 API level 调用平台提供的 `registerReceiver()` 重载；重点不在具体重载名字，而在于作用域和导出边界必须明确。

### 8. 真正需要长一点的工作时，应该立刻转交给 `WorkManager`

有些广播触发的后续动作确实不会在几毫秒内结束，例如设备接通电源后安排一次图片备份，或在某个条件满足时补做离线同步。这类场景里，Receiver 仍然不该亲自把全部工作做完，而应该尽快提交一个后台任务请求。

```kotlin
override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != Intent.ACTION_POWER_CONNECTED) return

    val request = OneTimeWorkRequestBuilder<PhotoBackupWorker>().build()
    WorkManager.getInstance(context).enqueueUniqueWork(
        "photo-backup-on-charge",
        ExistingWorkPolicy.KEEP,
        request,
    )
}
```

这段代码里，接收器做的仍然只是判断事件和转交任务。真正的备份工作由 `PhotoBackupWorker` 在后台执行。这样的职责划分有两个直接收益：一是 `onReceive()` 能快速结束；二是后续执行能交给系统更擅长的调度模型，而不是把一次广播回调强行拉成长生命周期流程。

### 9. 应用内状态流转，不要默认继续靠广播

很多旧项目会把广播当成应用内事件总线：谁也不想直接依赖谁，就发一个广播，让别处自己去接。这种做法短期看似解耦，长期通常会带来可读性差、追踪困难、测试困难的问题。

在现代 Android 项目里，应用内状态更常通过 ViewModel、`StateFlow`、`SharedFlow`、明确的接口调用或 Repository 更新来传播。广播仍然有位置，但它更适合“跨组件边界的外部事件”而不是“应用内所有状态通知的兜底方案”。如果一个功能完全发生在你自己应用的同一层级内部，那么优先检查是否存在更直接、更可测试的状态通道。

### 10. 实践任务

起点条件：

- 项目里已经有一个 BroadcastReceiver，或者你正准备接入一个系统/通知动作事件。

步骤：

1. 先写下这个事件的来源，是系统、外部应用，还是本应用内的受控来源。
2. 判断它是否真的要求应用未打开时也能接收。
3. 如果不要求，优先改成运行时注册，并把注册范围缩到页面或组件的最小生命周期。
4. 检查 `onReceive()` 里是否存在网络请求、数据库重操作或其他长任务。
5. 如果有，把这些工作转交给 ViewModel、Repository 或 `WorkManager`。
6. 最后检查导出边界、权限和注销逻辑是否明确。

预期结果：

- 你能把接收器从“执行现场”改回“事件入口”。
- 你能判断一个场景到底该运行时注册还是清单注册。
- 你能说清接收器对谁可见，以及它收到事件后要把工作交给谁。

自检方式：

- 你能解释为什么 `onReceive()` 不适合承载长时间工作。
- 你能判断某个广播场景是否真的需要在应用未启动时也响应。
- 你能说明 `RECEIVER_NOT_EXPORTED` 或 `android:exported` 在当前场景里的意义。

调试提示：

- 如果广播一到就开始跑大段业务逻辑，优先检查是不是缺了一层任务转交。
- 如果接收器总是忘记注销，优先把注册位置继续缩小并贴近生命周期。
- 如果你说不清谁能给这个接收器发广播，说明边界还没有设计稳。

### 11. 常见误区

- 把 BroadcastReceiver 当成后台任务容器。
- 只要想接系统事件，就先写成清单注册。
- 运行时注册后忘记注销，导致泄漏或重复接收。
- 不区分导出与非导出边界，把外部输入默认当成可信。
- 把广播当成应用内通用事件总线。

## 小结

BroadcastReceiver 在现代 Android 里的真正角色，是接住“某件事发生了”这一类事件，并把它快速分发到更合适的处理层。它不是线程，不是后台万能入口，也不应该成为长任务执行现场。只要你先判断事件来源、生命周期范围和后续工作时长，再决定使用运行时注册还是清单注册，广播相关设计就会清晰很多。

理解了这条边界之后，系统组件之间的分工也会更明确：`Intent` 负责表达动作，`BroadcastReceiver` 负责接事件，`Service` 和 `WorkManager` 负责持续或延迟执行，而下一章的 `ContentProvider` 则负责结构化数据的共享边界。

## 参考资料

- 参考并改写自：Neil Smyth，《Android Studio Narwhal Essentials》(2025)，广播接收器、系统事件与运行时注册相关章节。
- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，Fragment 生命周期、事件入口与现代组件边界相关章节。
- 参考并改写自：Costeira R.，《Real-World Android by Tutorials, 2nd Edition》(2022)，通知动作与事件驱动 UI 相关章节。
- Broadcasts overview: <https://developer.android.com/develop/background-work/background-tasks/broadcasts>
- BroadcastReceiver reference: <https://developer.android.com/reference/android/content/BroadcastReceiver>
- Background work overview: <https://developer.android.com/develop/background-work>
- Android 14 behavior changes for runtime-registered receivers: <https://developer.android.com/about/versions/14/behavior-changes-14#runtime-registered-broadcasts-receivers-exported>
