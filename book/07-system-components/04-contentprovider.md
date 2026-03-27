# ContentProvider

`ContentProvider` 可能是系统组件里最让读者困惑的一章之一。很多人学完以后只记住了一堆 URI、`ContentResolver` 和 CRUD 方法，却仍然不知道现实项目里到底什么时候会碰它，什么时候需要自己写一个 Provider，什么时候其实只是在使用系统已经提供好的 Provider。结果就是，这一章要么被当成纯理论，要么被误认为“每个应用都应该自定义一个 Provider”。

真正更稳的理解方式是，把 ContentProvider 看成 Android 生态里“跨应用或跨进程共享结构化数据”的正式边界。只要你沿着这条线去看，为什么联系人、媒体库、文件共享和 `FileProvider` 会出现，为什么大多数普通业务应用其实不需要自定义 Provider，也就都能讲清楚了。

## 学习目标

- 理解 ContentProvider 解决的是结构化数据共享和访问边界问题。
- 理解 `ContentResolver`、URI 和 CRUD 在这套模型中的角色。
- 理解为什么大多数应用更常“使用 Provider”，而不是“编写 Provider”。
- 学会判断什么时候真的需要自定义 Provider。

## 前置知识

- 已理解数据存储、本地文件和系统组件边界。
- 已接触过联系人、媒体库或文件分享场景。

## 正文

### 1. 先回答一个现实问题: 为什么数据库不能直接共享给别的应用

每个 Android 应用都有自己的内部数据空间和数据访问方式。如果你直接把数据库或本地文件路径暴露给外部应用，不仅接口不统一，而且权限、安全、兼容性都会变得很脆弱。

ContentProvider 的价值，就是提供一个正式、统一、可授权的数据边界。外部不需要知道你内部到底用 Room、SQLite 还是文件，只需要通过稳定的 URI 和约定的操作方式访问数据。

### 2. ContentProvider 真正解决的是“共享边界”，不是“本地增删改查”

这点很重要。你当然可以在应用内部也通过 Provider 暴露数据，但它最核心的存在理由，不是替代 DAO 或 Repository，而是为跨组件、跨应用甚至跨进程访问提供统一协议。

所以如果你的问题只是“页面要读写本地数据库”，那通常不需要自定义 ContentProvider。Room、DAO、Repository 已经是更自然的应用内数据方式。只有当你真的需要把数据作为正式边界开放出去，Provider 才会变得重要。

### 3. ContentResolver、URI 和 Provider 的关系

可以先用一条简单链路记住这套模型:

- `ContentProvider` 负责提供数据边界。
- URI 负责定位“想访问哪一类数据、哪一条数据”。
- `ContentResolver` 负责让调用方按照统一方式访问这些数据。

这样理解以后，Provider 就不会再是一堆零散 API，而是一套很完整的共享数据协议。

### 4. 为什么大多数应用更常“用 Provider”，而不是“写 Provider”

在真实项目里，你更常遇到的情况是:

- 用 `ContentResolver` 读取联系人。
- 访问系统媒体库。
- 通过 `FileProvider` 安全共享文件 URI。

这些场景说明，Provider 更多时候是 Android 平台和系统能力已经为你准备好的边界。你作为业务应用开发者，真正需要的是学会如何尊重和使用这条边界，而不是默认每个项目都要自建一个。

### 5. FileProvider 为什么特别值得学

很多读者第一次真正“用到 Provider”，其实不是因为共享联系人，而是因为想把图片、文件或导出的文档安全地交给别的应用。如果你直接暴露文件路径，会立即碰到安全和权限问题。`FileProvider` 的价值，就是把本地文件转换成可控、可授权的内容 URI。

这能让你更直观地理解 Provider 的核心精神: 不是让外部直接看到你的内部实现，而是通过正式边界、安全地共享必要数据。

这里还有一个很实用的判断框架：如果你只是要把某个文件安全地交给别的应用处理，`FileProvider` 往往比自定义完整 Provider 更合适；只有当你需要长期公开一套可查询、可遍历、可更新的结构化数据接口时，自定义 Provider 的成本才真正值得承担。这个边界一旦想清楚，Provider 就不会再显得“要么很重、要么完全没用”。

### 6. 什么时候才真的值得自定义 Provider

更适合自定义 ContentProvider 的信号通常包括:

- 你的应用确实需要向外部应用公开一组稳定数据。
- 这些数据有结构化访问价值，而不是一次性导出文件。
- 你愿意长期维护这条外部数据协议。

换句话说，自定义 Provider 是一种“公开数据接口”的承诺，而不是普通本地存储技巧。大多数纯业务应用，如果没有明显跨应用共享需求，完全可以不写。

`The Android Developer's Cookbook` 里的日记应用，则把“自定义 Provider 是对外协议”这件事讲得很落地：一边通过 `DiaryContentProvider` 暴露 `content://com.cookbook.datastorage/diaries`，另一边再用单独的 `DataStorageTester` 应用通过 `ContentResolver.query()` 把标题列表读出来。这个例子最值得保留的，不是早期 `Cursor` 细节，而是它清楚展示了 Provider 的真正对象永远是“另一个调用者”，而不是你自己应用内部的页面代码。

### 7. 自定义 Provider 最难的不是 CRUD，而是边界承诺

很多教程写 Provider 时，把重点放在增删改查方法实现上。但真正困难的部分其实是:

- URI 结构怎么设计。
- 哪些数据允许外部看。
- 哪些操作允许外部改。
- 权限和导出边界怎么控制。

一旦你对外公布了一套 URI 和访问语义，本质上就是在维护一套外部接口。这远比“把数据库封一下”更严肃。

`Android Security - Attacks and Defenses` 用联系人 Provider 做了一个很好的参照：系统联系人应用和第三方应用之所以能共享同一批底层数据，不是因为它们共用数据库文件，而是因为它们都通过同一条 Provider 边界访问数据。书里还特别强调，`<provider>` 可以分别声明 `android:readPermission` 和 `android:writePermission`，系统会在 `ContentResolver.query()`、`insert()`、`update()`、`delete()` 调用时逐一检查权限。这个例子非常适合帮助我们建立正确直觉：Provider 不是一层方便写 CRUD 的包装，它首先是一道带门禁的数据接口。

Neil Smyth 在 Jellyfish/Koala 这套教程里，又用一对 provider/client 示例把“默认边界”和“显式门禁”之间的差别讲得很清楚：当示例里的 SQLDemo 只把 Provider 声明到 Manifest、却没有额外声明权限时，作者明确指出“其他应用只要知道 content URI 和列名，就可能直接访问这批数据”；随后客户端教程再补上一层“先在 Manifest 中请求 query permission”，才让访问边界重新变得可控。这个例子特别适合放在这里，因为它提醒读者：Provider 一旦对外可见，真正危险的不是 CRUD 代码本身，而是你有没有把默认开放的门关上。

### 8. 一个更健康的理解路径

如果你是初学者，更建议按这个顺序理解 Provider:

1. 先会使用系统已有 Provider，例如联系人、媒体库、`FileProvider`。
2. 再理解 URI 和 `ContentResolver` 的基本协作。
3. 最后再思考自定义 Provider 是否真的有业务价值。

这样学出来的 Provider 会更贴近真实项目，而不是停留在“为了学一个组件而学一个组件”。

如果把“使用 Provider”和“编写 Provider”各写一个最小闭环，ContentProvider 这章会清楚得多。

先看最常见、也最现实的一类：通过 `FileProvider` 把文件安全地交给别的应用处理。这种场景的重点不是 CRUD，而是临时 URI 授权边界。

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/share_paths" />
</provider>
```

```xml
<paths>
    <cache-path
        name="shared_reports"
        path="reports/" />
</paths>
```

```kotlin
fun shareWeeklyReport(context: Context, reportFile: File) {
    val reportUri = FileProvider.getUriForFile(
        context,
        "${BuildConfig.APPLICATION_ID}.fileprovider",
        reportFile,
    )

    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = "application/pdf"
        putExtra(Intent.EXTRA_STREAM, reportUri)
        clipData = ClipData.newUri(context.contentResolver, "weekly_report", reportUri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    context.startActivity(Intent.createChooser(shareIntent, "分享周报"))
}
```

这段代码几乎把“使用 Provider”这件事的现实价值讲完了。调用方没有暴露文件真实路径，只是把文件包装成一个内容 URI，再通过 `FLAG_GRANT_READ_URI_PERMISSION` 把一次临时读取能力交给真正的处理者。对大多数业务应用来说，这已经是最常见、也最值得先掌握的 Provider 用法。

只有当你真的准备长期公开一套结构化数据协议时，才值得进入“编写 Provider”这条更重的路径。下面这个最小骨架，适合帮助你建立自定义 Provider 的接口直觉。

```xml
<provider
    android:name=".task.TaskProvider"
    android:authorities="${applicationId}.tasks"
    android:exported="true"
    android:readPermission="com.example.task.permission.READ_TASKS"
    android:writePermission="com.example.task.permission.WRITE_TASKS" />
```

```kotlin
class TaskProvider : ContentProvider() {

    companion object {
        private const val AUTHORITY = "com.example.task.tasks"
        private const val TASKS = 1
        private const val TASK_ID = 2

        val CONTENT_URI: Uri = Uri.parse("content://$AUTHORITY/tasks")

        private val uriMatcher = UriMatcher(UriMatcher.NO_MATCH).apply {
            addURI(AUTHORITY, "tasks", TASKS)
            addURI(AUTHORITY, "tasks/#", TASK_ID)
        }
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val db = taskOpenHelper.readableDatabase
        return when (uriMatcher.match(uri)) {
            TASKS -> db.query("tasks", projection, selection, selectionArgs, null, null, sortOrder)
            TASK_ID -> db.query(
                "tasks",
                projection,
                "_id = ?",
                arrayOf(ContentUris.parseId(uri).toString()),
                null,
                null,
                sortOrder,
            )
            else -> error("Unknown uri: $uri")
        }.apply {
            setNotificationUri(context?.contentResolver, uri)
        }
    }

    override fun getType(uri: Uri): String {
        return when (uriMatcher.match(uri)) {
            TASKS -> "vnd.android.cursor.dir/vnd.com.example.task.tasks"
            TASK_ID -> "vnd.android.cursor.item/vnd.com.example.task.tasks"
            else -> error("Unknown uri: $uri")
        }
    }
}
```

```kotlin
fun loadSharedTasks(context: Context): List<String> {
    return context.contentResolver.query(
        TaskProvider.CONTENT_URI,
        arrayOf("title"),
        null,
        null,
        "updated_at DESC",
    )?.use { cursor ->
        buildList {
            val titleIndex = cursor.getColumnIndexOrThrow("title")
            while (cursor.moveToNext()) {
                add(cursor.getString(titleIndex))
            }
        }
    }.orEmpty()
}
```

这里真正需要你关注的，不是 `Cursor` 语法有多繁琐，而是三条外部边界已经被正式写出来了。第一，URI 结构定义了调用者能访问哪些集合和单项资源；第二，`readPermission` / `writePermission` 决定了谁有资格读写；第三，调用方只通过 `ContentResolver` 看到一个稳定协议，而看不到你内部到底是 SQLite、Room 还是别的存储实现。

把 `FileProvider` 和自定义 `TaskProvider` 放在一起看，会很容易建立一个成熟判断：如果你只是做一次受控文件共享，就优先用系统已经给好的 Provider；如果你要长期对外开放一套结构化数据接口，才认真承担 URI 设计、权限门禁和协议维护的成本。ContentProvider 的难点从来不是“会不会写四个 CRUD 方法”，而是你是否真的准备好了这份对外承诺。

Provider 真正比普通 DAO 多出来的一层价值，是“数据变化后，调用方还能沿着同一个 URI 协议继续保持同步”。这时 `query()` 里的 `setNotificationUri()`、写操作里的 `notifyChange()` 和客户端侧的 `ContentObserver` 才会连成完整闭环。

```kotlin
override fun insert(uri: Uri, values: ContentValues?): Uri {
    val db = taskOpenHelper.writableDatabase
    val newId = db.insertOrThrow("tasks", null, values)
    val createdUri = ContentUris.withAppendedId(CONTENT_URI, newId)
    context?.contentResolver?.notifyChange(createdUri, null)
    return createdUri
}
```

```kotlin
fun observeSharedTasks(context: Context): Flow<List<String>> = callbackFlow {
    val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            trySend(loadSharedTasks(context))
        }
    }

    context.contentResolver.registerContentObserver(
        TaskProvider.CONTENT_URI,
        true,
        observer,
    )
    trySend(loadSharedTasks(context))

    awaitClose {
        context.contentResolver.unregisterContentObserver(observer)
    }
}
```

这组代码最值得学习的，不是 `ContentObserver` 的回调语法，而是 Provider 的“变化通知协议”终于完整了。`setNotificationUri()` 让查询结果和某个 URI 绑定，`notifyChange()` 在写入后向这个 URI 广播变更，`ContentObserver` 再把“重新查询”收进客户端自己的状态流。只有把这三步一起理解，读者才会真正明白 Provider 为什么不仅是“别人能查一下数据”，而是一份可以长期维护、可被观察的共享接口。

还有一类 Provider 场景不是“返回几行结构化数据”，而是直接对外暴露一个受控文件句柄。这时重点就不在 `Cursor`，而在于 Provider 如何把 URI 映射成一个可授权、可读取的二进制入口。

```kotlin
override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
    require(mode == "r") { "TaskAttachmentProvider 只支持只读访问" }

    val attachmentId = ContentUris.parseId(uri)
    val file = attachmentRepository.resolveSharedAttachment(attachmentId)

    return ParcelFileDescriptor.open(
        file,
        ParcelFileDescriptor.MODE_READ_ONLY,
    )
}
```

```kotlin
fun openSharedAttachment(context: Context, attachmentUri: Uri): InputStream? {
    return context.contentResolver.openInputStream(attachmentUri)
}
```

这组代码真正补上的，是 Provider 的另一条现实用法：它不仅能共享“表里的数据”，也能共享“通过 URI 才能安全打开的内容”。一旦对外部调用者承诺了 `content://.../attachments/42` 这样的 URI，调用方就不需要知道文件真正落在哪个目录，也不需要直接触碰绝对路径。对 Provider 来说，这仍然是一种协议设计，只是返回的不再是 `Cursor`，而是可授权的文件访问入口。

Provider 的权限边界还有一个特别容易被忽略的细节：把一个 `content://` URI 交给外部组件，并不等于对方天然就能读写它。真正的临时授权，要么跟着 Intent 一起通过 flag 交出去，要么在你明确知道目标包名时，用 `grantUriPermission()` 做一次更窄的定向授权。

```kotlin
fun openAttachmentInViewer(context: Context, attachmentUri: Uri, mimeType: String) {
    val intent = Intent(Intent.ACTION_VIEW).apply {
        setDataAndType(attachmentUri, mimeType)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    context.startActivity(Intent.createChooser(intent, "打开附件"))
}

fun handoffEditableDraft(
    context: Context,
    targetPackage: String,
    draftUri: Uri,
) {
    context.grantUriPermission(
        targetPackage,
        draftUri,
        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
    )
}

fun revokeEditableDraft(context: Context, draftUri: Uri) {
    context.revokeUriPermission(
        draftUri,
        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
    )
}
```

这段代码真正想补上的，是 Provider 权限的时间维度。`FLAG_GRANT_READ_URI_PERMISSION` 很适合“我现在通过 Intent 把这个内容交给查看器”，它把读取资格跟这次动作一起打包出去；`grantUriPermission()` 则更适合“我明确知道要把哪一个 URI 临时交给哪个包处理”。一旦这次协作结束，再用 `revokeUriPermission()` 把入口收回来，Provider 才算把共享边界、目标对象和有效时长一起管理清楚。


如果调用方要一次提交多条相关修改，Provider 还有一个比“连着调很多次 insert/update”更稳的入口：`ContentProviderOperation` 和 `applyBatch()`。它的意义不是让代码看起来高级，而是把“一组应该一起成功或一起失败的修改”真正收成一次批量协议。

```kotlin
fun importTaskTemplate(
    context: Context,
    projectId: Long,
    titles: List<String>,
) {
    val operations = ArrayList<ContentProviderOperation>()

    titles.forEach { title ->
        operations += ContentProviderOperation.newInsert(TaskProvider.CONTENT_URI)
            .withValue("project_id", projectId)
            .withValue("title", title)
            .withValue("status", "todo")
            .build()
    }

    context.contentResolver.applyBatch(
        TaskProvider.CONTENT_URI.authority ?: error("Missing authority"),
        operations,
    )
}
```

这段代码真正补上的，是 Provider 作为共享协议的“批量语义”。如果你导入的是一整套任务模板、一次联系人合并，或者某组修改天然应该被视为同一批动作，那么 `applyBatch()` 会比连续散落的多次 `insert()` 更容易保持一致性，也更容易让调用方明确知道：这不是几条互相独立的写入，而是一份应该整体处理的共享请求。
### 9. 合同类会让 Provider 协议长期可维护

Provider 一旦真的要对外暴露，就不只是“我这里有几个 CRUD 方法”，而是“我准备长期维护一套 URI、列名、类型和访问规则”。这也是为什么很多老资料都会引入 contract class。它的价值不在于多建一个对象，而在于让客户端和 Provider 自己都围绕同一份协议工作，而不是各自手写字符串。

```kotlin
object TasksContract {
    const val AUTHORITY = "com.example.todo.tasks"
    const val PATH_TASKS = "tasks"

    val CONTENT_URI: Uri = Uri.parse("content://$AUTHORITY/$PATH_TASKS")

    object Columns : BaseColumns {
        const val TITLE = "title"
        const val IS_DONE = "is_done"
    }

    fun itemUri(id: Long): Uri = ContentUris.withAppendedId(CONTENT_URI, id)
}

class TaskProvider : ContentProvider() {

    companion object {
        private const val TASKS = 1
        private const val TASK_ID = 2
    }

    private val uriMatcher = UriMatcher(UriMatcher.NO_MATCH).apply {
        addURI(TasksContract.AUTHORITY, TasksContract.PATH_TASKS, TASKS)
        addURI(TasksContract.AUTHORITY, "${TasksContract.PATH_TASKS}/#", TASK_ID)
    }
}
```

这段代码最值得学走的是协议意识。`authority`、路径、列名和 item URI 都集中在一处之后，Provider 自己、`ContentResolver` 调用方和后续测试就能围绕同一份约定说话。这样一来，自定义 Provider 的难点才会真正回到“这份协议该怎样承诺”，而不是散落在各处的字符串有没有写对。

### 10. 实践任务

起点条件:

- 已有一个涉及联系人、媒体库、文件共享或跨应用数据访问的场景。

步骤:

1. 找一个当前使用或计划使用的共享数据场景。
2. 判断它是“使用系统已有 Provider”还是“需要自定义 Provider”。
3. 如果是文件共享，优先思考是否应走 `FileProvider`。
4. 如果你打算自定义 Provider，先写出 URI 设计和权限边界，而不是立刻写代码。
5. 检查页面层是否错误地把 Provider 当成普通本地数据入口来用。

预期结果:

- 读者会把 Provider 看成共享边界，而不是本地 CRUD 组件。
- 读者应能更清晰地区分“用 Provider”和“写 Provider”。
- 读者会更谨慎地对待自定义 Provider 的对外承诺。

自检方式:

- 读者应能解释 ContentResolver、URI 和 Provider 的关系。
- 读者应能判断某个需求为什么不需要自定义 Provider。
- 读者应能说明为什么 FileProvider 是更现实、更常用的入门点。

调试提示:

- 如果你的问题只是应用内页面读写数据，优先别急着上 Provider。
- 只想着 CRUD 不想着权限和 URI 承诺，说明 Provider 边界还没想清楚。
- 需要共享文件时还在直接传文件路径，优先考虑 FileProvider。

### 11. 常见误区

- 认为每个应用都应该有一个自定义 ContentProvider。
- 把 Provider 当成普通本地数据库接口。
- 只会写 CRUD，不思考 URI 和权限边界。
- 不理解 FileProvider 的现实价值。

## 小结

ContentProvider 真正要解决的，是结构化数据在组件和应用边界上的共享问题。它的核心不是“又一种本地数据访问方式”，而是一套对外可授权、可维护的数据协议。对大多数业务应用来说，更重要的是学会使用系统已有 Provider 和 FileProvider；只有在确实需要对外公开稳定数据接口时，才值得认真设计并实现自己的 Provider。

## 参考资料

- 参考并改写自：Neil Smyth，《Android Studio Narwhal Essentials》(2025)，ContentProvider、文件共享与 URI 边界相关章节。
- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，系统数据访问与组件边界相关内容。
- 参考并改写自：`Android Security - Attacks and Defenses`，ContentProvider 权限边界与访问控制相关章节。
- 参考并改写自：James Steele、Nelson To，《The Android Developer's Cookbook》(2011)，自定义 ContentProvider 与跨应用查询相关 recipes。
- 参考并改写自：Neil Smyth，《Android Studio Jellyfish Essentials》(2024)，Provider 客户端访问、内容 URI 与 query permission 相关章节。
- 参考并改写自：Reto Meier、Ian Lake，《Android in Action, 2nd Edition》(2011)，ContentObserver、registerContentObserver() 与数据变化通知相关内容。
- 参考并改写自：Mark Murphy，《Programming Android》(2011)，`openFile()`、内容 URI、`ContentProviderOperation` 与 `applyBatch()` 相关内容。
- 参考并改写自：Neil Daswani、Anubhav Singh，《Application Security for the Android Platform》(2012)，URI 临时授权、grantUriPermission() 与 revokeUriPermission() 相关内容。
- Content providers overview: <https://developer.android.com/guide/topics/providers/content-providers>
- ContentResolver reference: <https://developer.android.com/reference/android/content/ContentResolver>
- FileProvider reference: <https://developer.android.com/reference/androidx/core/content/FileProvider>





