# Intent

很多读者第一次学 `Intent`，只把它记成“页面跳转参数包”。这样记可以让第一个页面先跑起来，但很快就会遇到边界问题: 什么时候应该显式跳转，什么时候应该交给系统选择处理者，为什么分享、打开网页、拍照、选文件都离不开 Intent，为什么参数一多以后组件之间很快就开始耦合。真正理解 Intent，关键不是会不会写 `startActivity()`，而是要把它看成 Android 组件世界里“动作请求”的统一表达方式。

这章的重点不是把 API 列一遍，而是让你真正看清 Intent 解决的是什么问题，它和普通对象调用的区别是什么，组件边界为什么必须通过“动作 + 最小必要信息”的方式表达，以及今天在 Activity Result API、系统选择器和跨应用协作场景下，Intent 依然为什么是最基础的那条主线。

## 学习目标

- 理解 Intent 解决的是组件间动作请求问题，而不是单纯页面跳转问题。
- 理解显式 Intent 和隐式 Intent 的使用边界。
- 理解 `Intent Filter`、Chooser 和最小必要参数设计的意义。
- 学会判断什么时候应该用 Intent，什么时候应该留在本地对象调用层。

## 前置知识

- 已理解 Activity、系统组件和基本页面导航。
- 已知道 Android 组件不能像普通对象那样直接长期持有彼此。

## 正文

### 1. 先从一个真实需求开始: “打开详情”和“分享文章”为什么不是同一类动作

设想新闻列表页里有两个按钮。点击文章卡片，需要进入详情页；点击分享按钮，需要把文章标题和链接交给用户选择的应用处理。它们表面上都像“跳一下”，但本质上完全不同。

打开详情页时，你非常清楚目标是谁: 就是你应用内部的详情页组件。分享文章时，你知道要完成的动作，却并不知道最终由微信、浏览器、邮件应用还是别的分享面板来处理。

这就是 Intent 最值得理解的地方: 它既能表达“我要交给这个明确组件做这件事”，也能表达“我要完成这个动作，但处理者由系统匹配决定”。

### 2. Intent 本质上是在描述“我要做什么”

官方文档把 Intent 描述为一种对动作的抽象描述，这句话比很多教程里的“跳转工具”更准确。它真正描述的是:

- 想做什么动作。
- 是否指定了明确处理者。
- 需要附带什么最小必要数据。

所以 Intent 不是普通方法调用，也不是“传对象过去”的替代方案。它面向的是组件边界。只要你把它放回这个语境，就不会再把所有跳转和通信都简单看成参数包传递。

### 3. 显式 Intent: 你知道谁来处理

Big Nerd Ranch 在 `GeoQuiz` 里用 `MainActivity -> CheatActivity` 给了一个很好的显式 Intent 例子：最开始是直接 `Intent(this, CheatActivity::class.java)`，随后又进一步把参数组装收进 `CheatActivity.newIntent(...)`。这个改动很小，却非常值得保留，因为它把“启动目标页”和“目标页到底需要哪些 extra”解耦开了。调用方只知道自己要启动 `CheatActivity`，但不需要知道内部 extra 的键名细节；这正是显式 Intent 边界开始变健康的信号。

显式 Intent 最适合应用内部结构清楚、目标明确的调用，例如:

- 列表页打开详情页。
- 登录页打开主页。
- 设置页打开某个内部功能页。

这类场景的重点是，调用方知道目标组件是谁，也知道自己在走应用内部受控导航。因此显式 Intent 更像“通过系统组件边界进行一次明确调用”。

`The Android Developer's Cookbook` 里 `MenuScreen -> PlayGame` 的例子也很适合拿来说明显式 Intent 的最小闭环：按钮点击后创建 `Intent(this, PlayGame.class)`，调用 `startActivity()`，目标页结束时再通过 `finish()` 把控制权交回去。这个例子来自早期多 `Activity` 写法，但教学点仍然成立：显式 Intent 最核心的是“明确目标组件 + 明确动作”，而不是先把一大包页面状态塞进 extra。

对这类场景，更成熟的设计不是把一大坨页面状态塞进去，而是只传目标页真正需要的最小信息，例如主键 ID、筛选条件、模式标记。

### 4. 隐式 Intent: 你知道动作，但不指定处理者

同一本书在后续 `CriminalIntent` 里又把这条线继续推进到了“发送 crime report”“选择联系人”“调起相机”这些场景。这里最值得学的，不是某个 `ACTION_SEND` 常量，而是教学节奏本身：先通过显式 Intent 建立应用内边界意识，再把同一套“动作请求”模型扩展到跨应用协作。只要按这个顺序理解，显式 Intent 和隐式 Intent 就不会再像两套互不相干的 API，而会变成同一套组件动作表达在不同边界下的两种落法。

隐式 Intent 的价值在于解耦。你只声明:

- 我要分享文本。
- 我要打开网页。
- 我要选择图片。
- 我要拨号或查看地图位置。

至于谁能处理，由系统根据 `action`、`data`、`category` 和已安装应用进行匹配。这种方式特别适合系统能力调用和跨应用协作，因为你并不需要预先知道处理者的类名。

这也是为什么现代 Android 很多“尽量不要自己造轮子”的能力，都会优先走系统 Intent 入口。

### 5. Intent Filter 真正定义的是组件愿意对外承诺什么

只要一个组件声明了 `Intent Filter`，它实际上就在告诉系统: “满足这些条件的动作，我愿意处理。” 这不是普通配置项，而是公开边界声明。

这意味着:

- 你不能随便把组件暴露给过宽泛的匹配条件。
- 你必须清楚它到底要处理哪些 action / data 组合。
- 对外暴露组件时，安全和输入校验会变得更重要。

很多“为什么会被意外唤起”“为什么匹配不到”“为什么外部传入的数据让页面崩了”的问题，本质上都和 Filter 边界没想清楚有关。

### 6. 最小必要参数原则，决定了组件能不能长期维护

很多初学者第一次用 Intent，会很自然地想“反正能传，就多传点”。结果详情页依赖十几个 extra，分享页依赖整包对象，编辑页甚至直接依赖上一个页面的整个内存状态。这样做短期方便，长期一定会让组件之间高度耦合。

更成熟的做法通常是:

- 详情页只传 ID 或关键标识。
- 分享动作只传标题、文本、URI 等必要信息。
- 结果回传只回传被确认需要的最小字段。

这条原则非常重要，因为组件边界一旦建立，能不能长期维护，很大程度上就取决于参数有没有保持克制。

### 7. Chooser 的价值不是“再弹一次框”，而是尊重用户决策

当一个隐式 Intent 可能被多个应用处理时，直接交给系统默认匹配并不总是最佳体验。Chooser 的作用不只是让用户选一个应用，更重要的是:

- 让用户清楚知道这次动作将交给谁。
- 避免默认应用直接吞掉用户选择权。
- 在分享、打开文件、发送内容时提供更明确的控制感。

很多跨应用动作如果没有 Chooser，表面上也能跑，但可控性和用户预期往往都更差。

和它一起值得尽早建立的，还有“临时能力授予”这类边界意识。比如通过内容 URI 共享文件、图片或导出结果时，Intent 往往不仅在表达动作，也在附带一次受控的数据访问许可。也就是说，Intent 不只是“把用户带去另一个地方”，它常常还承担着把最小必要数据和最小必要访问权一起带过边界的责任。

### 8. Activity Result API 并没有让 Intent 过时

很多现代教程把 `registerForActivityResult()` 讲得很重，有的读者就会误以为“现在不用 Intent 了”。实际上，Activity Result API 改变的是“结果怎么回收和管理”，并没有改变“动作怎么描述”。系统选图、打开文档、请求某些系统能力，底层仍然离不开 Intent 这一层动作表达。

同一本书还用 `RecognizerIntent` 演示了“启动系统 Activity 并取回结果”的链路：调用方声明 `ACTION_RECOGNIZE_SPEECH`，附上语言模型等必要 extra，再在 `onActivityResult()` 里按 `requestCode` 和 `RESULT_OK` 回收结果。今天结果回调已经更推荐用 Activity Result API，但这个例子恰好说明了一件事：结果封装方式在演进，Intent 作为动作描述层并没有消失。

所以理解 Activity Result API 时，最好把它看成“对基于 Intent 的结果交互做了更现代的封装”，而不是另一套完全独立的通信模型。

### 9. 什么时候不该用 Intent

不是所有事情都值得走 Intent。以下场景通常更适合留在本地对象调用或函数调用层:

- 同一组件内部的普通逻辑协作。
- 不涉及系统组件边界的纯业务流程。
- 完全不需要系统调度和匹配的局部调用。

如果应用内部普通类之间也频繁靠 Intent 传来传去，说明问题不是 “Intent 很灵活”，而是对象边界和分层没有理顺。

### 10. 一个最小但健康的例子

例如文章列表页打开详情页，更健康的写法通常是:

```kotlin
val intent = Intent(this, ArticleDetailActivity::class.java).apply {
    putExtra(EXTRA_ARTICLE_ID, article.id)
}
startActivity(intent)
```

真正值得学的是这三个点:

- Intent 描述的是“打开详情页”这个动作。
- 参数只传完成动作所需的文章 ID。
- 详情页根据自己的数据层能力再取完整信息，而不是完全依赖调用方塞给它。

下面把显式跳转、Chooser 分享和结果回收写成同一条连续代码链路，Intent 的边界会清楚很多。

```kotlin
class ArticleDetailActivity : AppCompatActivity() {

    companion object {
        private const val EXTRA_ARTICLE_ID = "extra_article_id"

        fun newIntent(context: Context, articleId: String): Intent {
            return Intent(context, ArticleDetailActivity::class.java)
                .putExtra(EXTRA_ARTICLE_ID, articleId)
        }
    }

    private val articleId: String by lazy {
        requireNotNull(intent.getStringExtra(EXTRA_ARTICLE_ID))
    }
}

class ArticleListActivity : AppCompatActivity() {

    private val speechLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != RESULT_OK) return@registerForActivityResult

        val matches = result.data
            ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            .orEmpty()

        if (matches.isNotEmpty()) {
            searchView.setQuery(matches.first(), true)
        }
    }

    fun openDetail(articleId: String) {
        startActivity(ArticleDetailActivity.newIntent(this, articleId))
    }

    fun shareArticle(article: Article) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, article.title)
            putExtra(Intent.EXTRA_TEXT, "${article.title}\n${article.url}")
        }

        startActivity(Intent.createChooser(shareIntent, "分享到"))
    }

    fun requestVoiceQuery() {
        val speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_PROMPT, "说出想搜索的关键词")
        }

        speechLauncher.launch(speechIntent)
    }
}
```

这段代码里其实放着三层完全不同的 Intent 边界。`openDetail()` 是显式 Intent，因为调用方明确知道目标组件就是 `ArticleDetailActivity`；而且它把参数组装收进 `newIntent()`，让调用方只保留“我要打开详情”这一层语义，不必知道 extra 键名细节。

`shareArticle()` 则是典型隐式 Intent。调用方描述的是“把这篇文章作为文本分享出去”，并不知道最终会落到短信、邮件、浏览器还是别的应用。这里 `Intent.createChooser()` 的作用，不是再弹一次框，而是把跨应用动作的决策权明确交还给用户。

`requestVoiceQuery()` 对应的又是第三层：动作描述依然由 Intent 完成，但结果回收已经换成了 Activity Result API。这个组合非常适合帮助读者建立现代直觉: Activity Result API 改进的是结果管理方式，而不是把 Intent 从动作表达层里拿掉。

再往前走一步，你会发现真正让 Intent 设计长期可维护的，往往不是会不会写 `startActivity()`，而是这三条边界有没有守住。应用内显式跳转只传最小必要参数；跨应用动作只描述动作和必要数据；结果回收则通过现代 API 把生命周期问题收束到更清楚的位置。只要这三层不混，组件之间就不会越来越像“互相偷看内部实现”。

如果动作来自应用外部，例如浏览器、邮件或聊天工具里的文章链接，更健康的做法也不是让业务页面自己一路解析 `Uri`，而是先在入口层把外部协议翻译成应用内部已经稳定的最小路由。

```xml
<activity
    android:name=".article.ArticleEntryActivity"
    android:exported="true">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="news.example.com"
            android:pathPrefix="/articles" />
    </intent-filter>
</activity>
```

```kotlin
class ArticleEntryActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val articleId = intent?.data
            ?.pathSegments
            ?.lastOrNull()
            ?.takeIf { it.isNotBlank() }

        val nextIntent = if (articleId != null) {
            ArticleDetailActivity.newIntent(this, articleId)
        } else {
            Intent(this, ArticleListActivity::class.java)
        }

        startActivity(nextIntent)
        finish()
    }
}
```

这段代码最值得学习的，不是 `android:autoVerify="true"` 这一个属性，而是它把外部入口协议控制在一层很薄的边界里。浏览器发来的是 `ACTION_VIEW + Uri`，而应用内部真正长期维护的仍然只是 `articleId` 这类稳定参数。这样一来，`ArticleDetailActivity` 不需要知道外部链接长什么样，列表页和详情页也不需要到处散落 URI 解析代码。对长期维护来说，这种“先把外部 Intent 收束，再进入内部路由”的做法会稳很多。

如果你已经知道“某个外部动作最终会返回一类固定结果”，再往前一步的现代做法通常不是继续手写 `ACTION_PICK + StartActivityForResult`，而是优先使用更具体的 Activity Result contract。它的价值不只是代码更短，而是把“我期望什么输入、会拿到什么输出”写成显式契约。

```kotlin
class CrimeDetailFragment : Fragment() {

    private val selectSuspect = registerForActivityResult(
        ActivityResultContracts.PickContact()
    ) { uri: Uri? ->
        uri ?: return@registerForActivityResult
        parseContactSelection(uri)
    }

    fun onChooseSuspectClicked() {
        selectSuspect.launch()
    }

    private fun parseContactSelection(contactUri: Uri) {
        val projection = arrayOf(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
        requireContext().contentResolver.query(
            contactUri,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndexOrThrow(
                    ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
                )
                viewModel.updateSuspect(cursor.getString(nameIndex))
            }
        }
    }
}
```

这段代码真正想教会读者的，不是联系人 API 细节，而是“动作用更明确的 contract 表达，返回值再沿着 URI 协议继续处理”这条现代路径。相比手写 `ACTION_PICK`、自己约定 request code、再手动拆结果，`PickContact()` 让输入输出契约更清楚，也让调用点更接近真正的意图表达。它本质上仍然是在做隐式 Intent，只是把常见场景收进了一个更稳的上层接口。

如果需求是“让用户拍一张照片并把结果带回应用”，现代写法同样更适合用具体 contract，而不是自己手写 `ACTION_IMAGE_CAPTURE` 和 request code。这里最关键的不是拍照本身，而是你必须先为外部相机应用准备一个受控 URI，让它只写入你明确允许的那一个文件。

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>

<!-- res/xml/file_paths.xml -->
<paths>
    <files-path
        name="report_photos"
        path="." />
</paths>
```

```kotlin
class ReportComposerFragment : Fragment() {

    private var pendingPhotoName: String? = null

    private val takePhoto = registerForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { saved ->
        if (saved) {
            pendingPhotoName?.let(viewModel::attachPhoto)
        }
    }

    fun onAddPhotoClicked() {
        val photoName = "report_${System.currentTimeMillis()}.jpg"
        val photoFile = File(requireContext().filesDir, photoName)
        val photoUri = FileProvider.getUriForFile(
            requireContext(),
            "${BuildConfig.APPLICATION_ID}.fileprovider",
            photoFile,
        )

        pendingPhotoName = photoName
        takePhoto.launch(photoUri)
    }
}
```

这段代码真正值得学习的，不是相机 Intent 的旧 action 名字，而是它把“外部应用帮你完成动作”和“结果文件仍受你控制”这两件事同时保住了。`FileProvider` 负责把私有文件翻译成一次性的可分享 URI，`TakePicture()` 负责把输入输出契约收紧成“给我一个 Uri，最后告诉我是否真的写入成功”。和前面的 `PickContact()` 放在一起看，你会更容易建立现代直觉：Intent 仍然在描述跨组件动作，但权限范围和结果边界应该尽量被 contract 和受控 URI 收紧，而不是散落在 request code 和临时 extra 里。


如果你要把应用私有目录里的文件交给外部应用处理，Intent 还多了一层经常被忽略的职责：它不只是描述“我要分享这个附件”，还要把“这次允许对方读哪一个 URI”一起安全地带出去。只把 `file://` 路径塞进 extra 已经不是健康做法，更稳的路径是继续结合 `FileProvider` 和临时读取授权。

```kotlin
fun shareReportPdf(context: Context, reportFile: File) {
    val reportUri = FileProvider.getUriForFile(
        context,
        "${BuildConfig.APPLICATION_ID}.fileprovider",
        reportFile,
    )

    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = "application/pdf"
        putExtra(Intent.EXTRA_STREAM, reportUri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newUri(context.contentResolver, "report", reportUri)
    }

    context.startActivity(Intent.createChooser(shareIntent, "发送报告"))
}
```

这段代码真正要建立的直觉是：Intent 有时不仅在表达动作，还在临时转交访问边界。`ACTION_SEND` 说明“我要把这个内容交给别的应用处理”，`FLAG_GRANT_READ_URI_PERMISSION` 则说明“但这次只允许读取这一份受控 URI”。把它和前面的 `TakePicture()` 放在一起看，读者会更容易理解：跨应用 Intent 设计的关键，始终不是把数据塞出去，而是把动作、结果和权限范围一起收紧到最小必要集。
### 11. 实践任务

起点条件:

- 已有一个列表页、详情页或至少一个系统能力调用场景。

步骤:

1. 找一个页面跳转场景，判断它应该是显式 Intent 还是隐式 Intent。
2. 检查当前是否传了过多 extra。
3. 找一个系统能力场景，评估是否应该使用系统入口而不是自己实现。
4. 如果有多个外部处理者，考虑是否加入 Chooser。
5. 检查项目里是否有本来不该用 Intent 的本地调用。

预期结果:

- 读者会把 Intent 理解成组件动作请求，而不是简单跳转语法。
- 参数设计会更克制，组件边界会更清晰。
- 读者会更自然地区分应用内导航和跨应用动作。

自检方式:

- 读者应能解释显式 Intent 和隐式 Intent 的根本差异。
- 读者应能说明为什么 Intent 参数应坚持最小必要原则。
- 读者应能判断某个需求为什么不需要 Intent。

调试提示:

- 一个页面如果必须依赖大量 extra 才能工作，优先检查边界是否过重。
- 隐式 Intent 总是匹配不到，优先检查 action、data、category 组合是否一致。
- 应用内普通对象也在滥用 Intent，说明分层还没理顺。

### 12. 常见误区

- 把 Intent 理解成“页面跳转参数包”。
- 用大量 extra 拼凑组件能力。
- 不理解 Intent Filter，就随意公开组件。
- 把 Activity Result API 误解成“Intent 已经过时”。

## 小结

Intent 真正的价值，不是让页面跳起来，而是用统一语义表达组件边界上的动作请求。理解了显式与隐式 Intent、Filter、Chooser 和最小参数原则之后，你就不会再把组件通信看成“传点参数过去”，而会开始真正按系统边界设计应用。

## 参考资料

- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，第 7 章、第 13 章与第 17 章。
- 参考并改写自：Neil Smyth，《Android Studio Narwhal Essentials》(2025)，Intent、Activity Result 与系统能力调用相关章节。
- 参考并改写自：James Steele、Nelson To，《The Android Developer's Cookbook》(2011)，显式 Intent、结果回传与 `RecognizerIntent` 相关 recipes。
- Intents and intent filters: <https://developer.android.com/guide/components/intents-filters>
- Common intents: <https://developer.android.com/guide/components/intents-common>
- Get a result from an activity: <https://developer.android.com/training/basics/intents/result>




