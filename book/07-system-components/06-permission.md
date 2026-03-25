# 权限管理

权限往往是 Android 开发里最容易被“只学 API 不学判断”的主题之一。很多初学者一遇到拍照、定位、通知或文件访问，就马上去找“怎么申请权限”，却没有先问更重要的问题：这项能力真的必须要这个权限吗？有没有更小、更现代的替代方案？用户为什么应该信任你现在发起这个请求？如果这些问题不先回答，权限代码即使写对了，体验和合规也很容易出问题。

参考资料里讲权限时，最值得保留的不是某个回调 API，而是“权限是一条信任边界”这个视角。本章就按这个视角组织：先判断是不是必须申请，再判断什么时候申请，再考虑申请失败后功能如何降级。只要这个顺序立住，权限管理就不再只是代码流程，而会真正进入现代 Android 的设计主线。

## 学习目标

- 理解权限管理首先是能力边界和用户信任问题。
- 理解现代 Android 更强调最小权限和系统替代入口。
- 理解运行时权限请求的合理时机和用户解释方式。
- 学会判断什么时候应申请权限，什么时候应改用系统选择器或其他替代方案。

## 前置知识

- 已接触系统组件、Intent、文件访问、定位或通知能力。
- 已理解现代 Android 对后台执行和用户可感知性的要求。

## 正文

### 1. 第一原则不是“怎么申请”，而是“能不能不申请”

这是权限章节最值得先建立的习惯。现代 Android 越来越鼓励优先使用系统提供的受控入口，而不是直接索取底层权限。例如：

- 选图片优先考虑 Photo Picker，而不是直接请求媒体读取权限。
- 打开文档优先考虑系统文件选择器，而不是直接访问整个共享存储。
- 分享文件优先走系统边界，而不是随意暴露路径。

权限管理成熟的第一步，不是拿到更多权限，而是学会尽量绕开不必要的权限。

### 2. 权限本质上是在请求用户信任

用户不会从系统弹窗里看到你的架构有多优雅，只会看到“这个应用为什么现在要访问我的位置、相机、通知或文件”。因此权限设计必须回答两个现实问题：

- 现在请求是不是和用户当前动作强相关。
- 这个请求是不是足够容易被用户理解。

如果权限弹窗出现得太早、太突然、太模糊，用户通常只会拒绝。问题不在于用户“不懂”，而在于请求时机和解释没有围绕用户任务设计。

### 3. 权限的最佳时机通常是在用户动作触发时

最差的权限体验之一，就是应用一打开就连续弹一串权限请求。更合理的方式通常是：

- 用户点击“拍照”时，再说明为什么需要相机权限。
- 用户点击“记录当前位置”时，再解释位置权限的用途。
- 用户真的需要接收提醒时，再说明通知权限的价值。

这种“按需、就地、围绕当前任务”的请求方式，更符合现代 Android 的用户体验逻辑，也更容易获得许可。

### 4. 权限不是一次性结果，而是动态状态

很多开发者习惯把“已经拿到权限”当成永久状态，这在今天已经不够可靠。用户可以随时撤回、改成仅本次允许、改成模糊授权、限制后台访问。权限因此更像动态状态，而不是一次性初始化结果。

Neil Smyth 在 `Android Studio Narwhal Essentials` 里用一个很典型的 `PermissionDemo` 把这件事讲得非常具体：示例先在 Manifest 里声明 `RECORD_AUDIO`，随后用 `ContextCompat.checkSelfPermission()` 检查当前状态，不满足时再通过 `ActivityCompat.requestPermissions()` 发起请求，并在 `onRequestPermissionsResult()` 里处理结果，必要时还会借助 `shouldShowRequestPermissionRationale()` 给出二次解释。这个例子最值得保留的，不是某个旧式回调名，而是它清楚拆开了三层边界：Manifest 声明、运行时授权、被拒绝后的说明与降级。少了任何一层，权限流程都不完整。

这意味着你的应用必须能处理：

- 权限被拒绝。
- 权限以后被撤回。
- 只拿到部分能力。
- 某些功能降级运行。

权限管理成熟的标志，不是“申请成功率高”，而是“权限不在时应用仍然可解释、可降级”。

### 5. 为什么最小权限原则比“以后可能用到”更重要

有些项目会想“反正以后可能要这个功能，不如现在一起申请”。这种思路在今天通常是错误的，因为：

- 用户没有上下文，很难理解请求。
- 权限越多，信任成本越高。
- 真正不需要时，过早申请只会增加拒绝概率。

最小权限原则的核心是：只申请当前任务真正需要的能力，只要足够完成目标，就不要额外扩张。

`Android Security - Attacks and Defenses` 在讲 Manifest permission 时给了一个很直接的例子：应用通过 `<uses-permission>` 声明 `INTERNET`、读取 MMS/SMS 等能力，系统再据此决定代码能否触碰这些受保护资源；如果应用去执行没有授权的操作，平台会直接抛出 `SecurityException`。这个例子虽然来自安全语境，但对日常开发很有提醒作用：权限不是“先写着备用”的标签，而是平台用来截断越界能力的硬边界。放到今天的产品设计里，这就意味着如果某个功能只需要用户选一张图，就不该顺手把更大范围的媒体访问能力也声明进去。

### 6. 一个现实例子：选图为什么已经不该优先想到存储权限

早期很多教程一讲选图，就先讲存储权限。今天更合理的入口通常是 Photo Picker 或系统文档选择器。它们的价值不只是“更简单”，而是：

- 用户边界更清楚。
- 应用只得到被选中的内容。
- 不需要拿整片媒体库访问权。

这就是现代权限思维和旧式“先把权限拿到”思维之间最大的差异。

### 7. 权限请求前的说明，重点不是长篇解释，而是对齐用户动作

一个好的说明通常很短，但必须清楚：

- 你正在做什么。
- 为什么必须现在请求。
- 用户允许后能得到什么价值。

例如“为了在到点时提醒你待办事项，我们需要通知权限”，就比“应用需要通知权限以保证功能正常”更容易被理解。前者围绕用户任务，后者只是系统口径。

### 8. 权限结果处理必须进入页面状态设计

权限请求不是一条外部支线，它应该进入页面状态模型。页面至少要能区分：

- 还没请求。
- 请求中。
- 已授予。
- 被拒绝。
- 被永久拒绝或需要去设置页开启。

如果页面把权限结果只当作回调里的一次性事件，体验很容易破碎。权限本质上也是页面当前能力边界的一部分。

这也是为什么现代权限设计越来越强调“被拒绝后仍然可解释”。如果用户拒绝了位置、通知或媒体访问权限，应用不应只剩下一句模糊报错，而应明确告诉用户当前缺少什么能力、还能做什么、如果愿意开启应去哪里重新授权。权限被拒绝不是异常分支，而是必须提前设计的常态路径。

把“优先绕开权限”和“确实需要权限时怎样请求”写成同一条代码链，现代权限思维会更容易落地。

```kotlin
class NoteComposerActivity : ComponentActivity() {

    private val pickPhoto = registerForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            viewModel.onPhotoPicked(uri)
        }
    }

    private val requestRecordAudioPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        viewModel.onRecordAudioPermissionResult(
            granted = granted,
            shouldShowRationale = shouldShowRequestPermissionRationale(
                Manifest.permission.RECORD_AUDIO,
            ),
        )
        if (granted) {
            viewModel.startVoiceRecording()
        }
    }

    fun onAttachPhotoClicked() {
        pickPhoto.launch(
            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
        )
    }

    fun onRecordVoiceClicked() {
        when {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED -> {
                viewModel.startVoiceRecording()
            }

            shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO) -> {
                viewModel.showMicrophoneRationale()
            }

            else -> {
                requestRecordAudioPermission.launch(Manifest.permission.RECORD_AUDIO)
            }
        }
    }

    fun onOpenSettingsClicked() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        startActivity(intent)
    }
}
```

这段代码里最关键的对比是：`onAttachPhotoClicked()` 完全没有权限请求，因为选图已经优先走了 Photo Picker；而 `onRecordVoiceClicked()` 则明确表明“录音”是一个真的需要运行时授权的能力。把这两个入口并排写出来，比单独背权限 API 更能帮助读者建立现代直觉：权限管理的第一步永远是先看能不能不申请。

权限真正进入现代项目时，还应该被拉进页面状态模型，而不是停留在回调函数里一闪而过。

```kotlin
enum class AudioPermissionState {
    Unknown,
    Granted,
    ShowRationale,
    Denied,
    PermanentlyDenied,
}

data class NoteComposerUiState(
    val audioPermissionState: AudioPermissionState = AudioPermissionState.Unknown,
    val canRecordVoice: Boolean = false,
    val permissionMessage: String? = null,
)

class NoteComposerViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(NoteComposerUiState())
    val uiState: StateFlow<NoteComposerUiState> = _uiState.asStateFlow()

    fun showMicrophoneRationale() {
        _uiState.update {
            it.copy(
                audioPermissionState = AudioPermissionState.ShowRationale,
                permissionMessage = "为了录制语音备注，我们需要麦克风权限。",
            )
        }
    }

    fun onRecordAudioPermissionResult(granted: Boolean, shouldShowRationale: Boolean) {
        _uiState.update {
            when {
                granted -> it.copy(
                    audioPermissionState = AudioPermissionState.Granted,
                    canRecordVoice = true,
                    permissionMessage = null,
                )

                shouldShowRationale -> it.copy(
                    audioPermissionState = AudioPermissionState.Denied,
                    canRecordVoice = false,
                    permissionMessage = "你可以稍后再次授权来使用语音备注。",
                )

                else -> it.copy(
                    audioPermissionState = AudioPermissionState.PermanentlyDenied,
                    canRecordVoice = false,
                    permissionMessage = "如果你想开启语音备注，需要前往系统设置重新授权。",
                )
            }
        }
    }
}
```

这部分代码真正解决的是“权限结果应该落到哪里”。一旦把它收进 `NoteComposerUiState`，页面就能自然地表达“现在可以录音”“应该显示简短说明”“需要引导去设置页重新授权”这些状态，而不是在某个回调里临时弹一条 Toast 就结束。

把 Photo Picker、`RequestPermission()` 和页面状态放在一起看，权限管理的主线就会变得非常稳定：先优先采用更小范围的系统入口；只有在能力确实需要授权时，才围绕用户当前动作申请；申请结果则继续作为页面能力边界的一部分被建模和解释。这样写出来的权限流程，才真正符合今天 Android 的设计方向。

### 9. 实践任务

起点条件：

- 已有一个涉及相机、定位、通知、媒体或文件访问的功能。

步骤：

1. 先判断这个功能是否真的必须请求权限。
2. 检查是否存在系统替代入口，例如 Photo Picker 或系统文档选择器。
3. 如果必须请求，确定最合适的触发时机。
4. 写出一句围绕用户动作的说明文案，而不是系统术语解释。
5. 把权限结果纳入页面状态，而不是只在回调里临时处理。

预期结果：

- 你会优先思考“能否不申请权限”。
- 权限请求会更贴近用户当前任务。
- 权限被拒绝后的体验也会更完整。

自检方式：

- 你能解释为什么权限是信任边界而不是普通 API。
- 你能判断某个能力是否存在更小范围的替代入口。
- 你能说明权限状态为什么应进入页面状态设计。

调试提示：

- 一打开应用就请求多项权限，通常说明设计从系统角度出发，而不是从用户任务出发。
- 功能只要权限被拒就完全瘫痪，优先检查是否缺少降级路径。
- 还在把选图默认写成“先申请存储权限”，说明思路还停在旧范式。

### 10. 常见误区

- 一上来就问“怎么申请”，不先问“需不需要申请”。
- 过早、过多、无上下文地弹权限。
- 把权限状态当成一次性初始化结果。
- 不考虑系统选择器和其他现代替代方案。

## 小结

权限管理真正考验的，不是你会不会写请求代码，而是你能不能尊重用户边界。只在必要时请求、优先使用更小范围的系统入口、围绕当前任务解释原因、把结果纳入页面状态，这四件事做好了，权限设计才算真正进入现代 Android 主线。

## 参考资料

- 参考并改写自：Neil Smyth，《Android Studio Narwhal Essentials》(2025)，权限请求、媒体访问与系统能力调用相关章节。
- 参考并改写自：`Android Security - Attacks and Defenses`，权限边界、最小授权与平台安全模型相关章节。
- 参考并改写自：`The Android Malware Handbook`，权限滥用、风险面与安全判断相关章节。
- Request app permissions: <https://developer.android.com/training/permissions/requesting>
- App permission best practices: <https://developer.android.com/privacy-and-security/minimize-permission-requests>
- Photo Picker: <https://developer.android.com/training/data-storage/shared/photopicker>
