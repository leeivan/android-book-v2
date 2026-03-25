# SharedPreferences 与 DataStore

设置项和轻量配置数据，是 Android 应用中最常见的一类持久化需求。它们看起来简单，却几乎存在于所有应用里：主题模式、登录引导状态、上次筛选条件、用户偏好、开关项等。本章的重点，不是把两种 API 并列介绍，而是说明：为什么今天更推荐把 DataStore 作为新项目主线，以及它和早期 SharedPreferences 的边界差异在哪里。

这一章很容易学出两种偏差。第一种是觉得“反正只是几个布尔值，怎么存都行”；第二种是把 DataStore 学成 SharedPreferences 的语法替换。前一种会让配置状态越写越乱，后一种会让你错过 DataStore 真正的价值。DataStore 不只是新的偏好接口，而是更适合现代 Android 状态流和异步模型的一种轻量持久化方案。

## 学习目标

- 理解键值型配置数据适合解决什么问题。
- 理解 SharedPreferences 的历史价值和现实边界。
- 理解 DataStore 为什么更适合作为现代主线。
- 理解“简单配置”为什么不该滥用数据库或文件存储。

## 前置知识

- 已建立基本的数据分类认知。
- 知道配置型数据和业务型数据不是一回事。

## 正文

### 1. 什么数据适合键值型存储

键值型存储最适合那些数据量小、结构简单、不需要复杂查询、读取频繁的配置类状态。例如是否开启通知、当前语言偏好、用户是否完成新手引导、上次使用的筛选方式。这类数据的共同特点是：它们通常服务于界面或用户偏好，不需要排序、分页、关系建模，也不需要按多个字段联合查询。

只要一份数据一开始就需要列表结构、历史记录、字段查询、多表关系或分页能力，它通常就已经不再是键值型存储问题，而是数据库问题。键值存储的边界看似简单，但这条边界一旦守不住，后面就会不断出现“临时先存一下”的数据越积越多，最终既不像配置，也不像业务数据。

### 2. SharedPreferences 为什么长期流行

SharedPreferences 之所以长期流行，是因为它非常直观：读写简单、适合轻量配置、几乎所有 Android 开发者都见过它。它在早期 Android 项目里确实解决了大量基础设置项保存问题，因此你在旧项目或老教程中仍然会频繁遇到它。

但“简单易上手”并不等于“今天仍然是最佳主线”。Android 官方关于 SharedPreferences 的页面已经明确给出提醒：DataStore 是现代数据存储方案，应该替代 SharedPreferences 使用。原因不是 SharedPreferences 完全不能用了，而是它的设计更偏向早期同步读写模式，与今天的协程、Flow 和响应式状态组织方式并不那么契合。

### 3. DataStore 为什么成为现代推荐做法

Android 官方的 DataStore 指南把它定义为一种用于存储 key-value 对或类型化对象的数据存储方案，并明确指出：它使用 Kotlin coroutines 和 Flow 来异步、一致且事务性地存储数据。如果你仍在使用 SharedPreferences 保存数据，官方建议考虑迁移到 DataStore。

这段定义里最值得抓住的，不是“它是 Jetpack 库”，而是三个关键词：异步、一致、事务性。DataStore 更适合现代 Android，不只是因为 API 更新，而是因为它天然更贴近今天的状态流模型。你可以把配置数据直接暴露为 `Flow`，再映射到页面状态；写入通过 `edit` 或 `updateData` 走受控更新路径，而不是四处零散同步读取和提交。

### 4. SharedPreferences 和 DataStore 的边界差异在哪里

如果只从“都能保存布尔值和字符串”去看，两者确实很像。但官方 DataStore 文档明确列出了它相对 SharedPreferences 解决的一组问题：SharedPreferences 的同步 API 容易造成 StrictMode 问题，`apply()` 和 `commit()` 在错误反馈和持久化语义上有局限，缺少一致性和事务语义，解析错误也更容易变成运行时异常。

DataStore 的优势并不意味着它适合一切。官方同样明确指出：DataStore 适合小而简单的数据集，不支持部分更新，也不适合复杂数据集或引用完整性要求高的场景。如果需要大数据集、部分字段更新、多表结构或复杂查询，就应考虑 Room，而不是继续往 DataStore 上堆业务实体。

### 5. Preferences DataStore、Proto DataStore 和 `PreferenceDataStore` 不是一回事

学习这一章时有一个非常容易混淆的点，必须尽早澄清。Jetpack DataStore 有两种主线形态：Preferences DataStore 用于 key-value 偏好数据；Proto DataStore 用于类型化对象，通常基于 protocol buffers。它们都属于 Jetpack DataStore 体系。

而 AndroidX Preference UI 体系里还有一个名字相似的 `PreferenceDataStore`，那是给设置界面组件自定义持久化后端用的接口，不等于 Jetpack DataStore 本身。两者名字接近，但不是同一个概念。如果把它们混在一起，你后面会在架构和实现层面都越学越乱。

### 6. 为什么“简单配置”也值得认真建模

很多项目里，设置项之所以后来难维护，不是因为数据多，而是因为一开始就没有把它们当正式状态来设计。例如相同配置在多个地方重复保存，布尔值命名含义不清，页面状态和持久配置混杂，同一个含义既在内存里留一份又在存储里留一份。键值型存储虽然简单，但并不意味着可以随意写。

只要命名、边界和来源不清，后面问题一样会堆起来。比如一个 `isDark`，它到底表示“用户手动开启深色模式”，还是“系统当前处于深色环境”，还是“某个页面临时使用深色主题”？如果这些含义混在一起，你换再好的 API 也解决不了维护问题。

在工程实现上，还要再守住一条边界：被持久化的是“跨页面、跨会话后仍然有意义的配置”，不是所有瞬时 UI 状态。比如搜索框当前输入、一次性的 Snackbar 文案、某个面板此刻是否展开，往往更适合留在页面状态或 `SavedStateHandle`，而不是直接写进 DataStore。只有当一个值真正代表用户偏好、功能开关或跨会话配置时，它才值得进入长期键值存储。

### 7. 最小示例：用 Preferences DataStore 保存主题模式

下面这个例子演示一个最小的 Preferences DataStore 用法，用来保存“是否使用深色主题”这类配置。它的重点不是覆盖所有 API，而是展示“读写都围绕状态流组织”的主线。

```kotlin
private val Context.userPrefsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "user_prefs"
)

private object PreferenceKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
}

class SimpleThemePreferencesRepository(
    private val dataStore: DataStore<Preferences>
) {
    val darkModeFlow: Flow<Boolean> = dataStore.data
        .map { preferences -> preferences[PreferenceKeys.DARK_MODE] ?: false }

    suspend fun updateDarkMode(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[PreferenceKeys.DARK_MODE] = enabled
        }
    }
}
```

这个例子里最重要的点有三个。第一，配置不是通过零散同步读取获得，而是作为 `Flow` 暴露出来。第二，写入通过 `edit` 统一管理。第三，DataStore 只保存轻量配置，而不是复杂业务对象。官方 DataStore 文档还特别提醒：同一个文件在同一进程中不要创建多个 DataStore 实例，否则会破坏 DataStore 的正确性。因此在实际项目里，它通常应以单例方式注入到 repository 或状态层中。

如果把迁移、读取和页面消费写成一条完整链路，DataStore 的现代价值会更容易看清。

```kotlin
private val Context.userPrefsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "user_prefs",
    produceMigrations = { context ->
        listOf(SharedPreferencesMigration(context, "legacy_user_prefs"))
    },
)

private object PreferenceKeys {
    val THEME_MODE = stringPreferencesKey("theme_mode")
    val REMINDER_ENABLED = booleanPreferencesKey("reminder_enabled")
}

enum class ThemeMode { System, Light, Dark }

data class UserPreferences(
    val themeMode: ThemeMode = ThemeMode.System,
    val reminderEnabled: Boolean = false,
)

class AppSettingsRepository(
    private val dataStore: DataStore<Preferences>,
) {

    val preferencesFlow: Flow<UserPreferences> = dataStore.data
        .catch { exception ->
            if (exception is IOException) emit(emptyPreferences()) else throw exception
        }
        .map { preferences ->
            UserPreferences(
                themeMode = ThemeMode.valueOf(
                    preferences[PreferenceKeys.THEME_MODE] ?: ThemeMode.System.name,
                ),
                reminderEnabled = preferences[PreferenceKeys.REMINDER_ENABLED] ?: false,
            )
        }

    suspend fun setThemeMode(themeMode: ThemeMode) {
        dataStore.edit { preferences ->
            preferences[PreferenceKeys.THEME_MODE] = themeMode.name
        }
    }

    suspend fun setReminderEnabled(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[PreferenceKeys.REMINDER_ENABLED] = enabled
        }
    }
}

class SettingsViewModel(
    repository: AppSettingsRepository,
) : ViewModel() {

    val uiState: StateFlow<UserPreferences> = repository.preferencesFlow
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = UserPreferences(),
        )
}
```

这段代码把 DataStore 真正值得保留的三层能力串起来了。第一层是迁移：旧的 `SharedPreferences` 不需要突然作废，而是可以通过 `SharedPreferencesMigration` 平滑并入新入口。第二层是读取：配置不再被零散地同步读取，而是被组织成 `Flow<UserPreferences>` 这种更接近正式状态流的形态。第三层是页面消费：ViewModel 不直接碰底层键名，而是只接收已经建模好的偏好对象。

因此今天的新项目更适合把 DataStore 当成主线，而不是只把它理解成“另一个保存布尔值的 API”。它真正解决的，是配置数据如何进入单一事实来源、如何以异步安全的方式读写，以及如何跟页面状态层自然接起来。只要这条主线建立起来，设置项就不再是散落在不同页面角落里的同步读取片段。

反过来看，如果一个值根本不值得跨会话保存，或者已经开始逼近复杂实体、列表、筛选和历史记录，它就不该继续停留在 DataStore 里。DataStore 的优势正来自边界清晰，一旦你把边界打穿，它反而会变成新的维护负担。

### 8. 什么时候不该再用键值存储

如果你发现某类数据开始具备下面这些特征，就应该重新考虑是否还适合键值存储：有明确列表结构、需要按字段搜索、需要历史记录或分页、需要多个字段组合表达一个复杂实体。这通常意味着数据已经进入数据库问题，而不是配置问题。

一个很常见的误区是“反正不多，先塞进 DataStore 再说”。这类决定短期省事，长期很容易演变成难以维护的混合状态。键值存储的优势在于简单，一旦你的数据不再简单，它的优势就开始变成边界风险。

### 9. 当一组设置需要整体更新时，Proto DataStore 会比多个键更稳

Preferences DataStore 很适合轻量键值配置，但只要你开始遇到“这一组字段本来就属于同一个概念，而且更新时必须一起变化”的场景，Proto DataStore 往往会更稳。比如同步设置同时包含“是否自动同步”“仅 Wi-Fi 同步”“同步时间窗口”和“上次成功同步版本”，如果继续拆成四五个独立键，就很容易在演进时出现默认值不一致、遗漏字段或局部更新后语义失真的问题。

```kotlin
object UserSettingsSerializer : Serializer<UserSettings> {
    override val defaultValue: UserSettings = UserSettings.getDefaultInstance()

    override suspend fun readFrom(input: InputStream): UserSettings = try {
        UserSettings.parseFrom(input)
    } catch (exception: InvalidProtocolBufferException) {
        throw CorruptionException("Cannot read user settings.", exception)
    }

    override suspend fun writeTo(t: UserSettings, output: OutputStream) {
        t.writeTo(output)
    }
}

val Context.userSettingsDataStore: DataStore<UserSettings> by dataStore(
    fileName = "user_settings.pb",
    serializer = UserSettingsSerializer,
)

class UserSettingsStore(
    private val dataStore: DataStore<UserSettings>,
) {
    val settingsFlow: Flow<UserSettings> = dataStore.data

    suspend fun updateSyncSettings(
        enabled: Boolean,
        wifiOnly: Boolean,
        hourOfDay: Int,
    ) {
        dataStore.updateData { current ->
            current.toBuilder()
                .setAutoSyncEnabled(enabled)
                .setWifiOnly(wifiOnly)
                .setSyncHour(if (enabled) hourOfDay else 9)
                .build()
        }
    }
}
```

这里的 `UserSettings` 不是手写的 Kotlin `data class`，而是由 `.proto` 定义生成的类型。Proto DataStore 的意义，不是“写起来更高级”，而是它把一组本来就属于同一语义边界的设置收成一个正式对象，再通过 `updateData()` 以整体方式更新。这样一来，默认值、解析错误、字段演进和多字段一致性都会更容易管理。

这也正是 Preferences DataStore 和 Proto DataStore 的真实分工。前者更像“轻量键值偏好箱”，适合几个独立设置项；后者更像“被正式建模的小型配置对象”，适合字段彼此有关联、更新要保持整体一致的场景。只要读者把这条边界立起来，后面就不容易把所有配置都塞回一堆零散 key 里。

### 10. 实践任务

起点条件：

- 已有一个正在设计的应用，或者使用“待办/笔记”作为练习对象。

步骤：

1. 列出应用中所有“设置项类”数据，不要把业务实体混进来。
2. 判断它们是否真的都适合键值型存储。
3. 选两个最典型的配置项，重新命名并明确其含义和默认值。
4. 设计一个最小的 DataStore repository，把其中一个配置项暴露为 `Flow`。
5. 额外思考：如果这份数据未来需要列表化、历史记录或复杂筛选，它是否还适合留在 DataStore。

预期结果：

- 读者应能更清晰地区分配置状态和业务状态。
- 读者会开始把配置读取组织进状态流，而不是散落在各个页面里同步读取。
- 读者应能判断何时继续使用 DataStore，何时应该转向 Room。

自检方式：

- 读者应能解释：为什么今天的新项目更适合以 DataStore 为主线。
- 读者应能区分：Preferences DataStore、Proto DataStore 和 `PreferenceDataStore` 不是同一个东西。
- 读者应能判断：某个数据属于“简单配置”，还是已经在逼近结构化业务数据。

调试提示：

- 如果你想在多个地方各自 new 一个 DataStore，先停下来，回到单例或注入思路。
- 如果某个值每次读取都想直接同步拿出来，先问自己它是不是其实更适合进入状态流。
- 如果你开始往 DataStore 里塞越来越复杂的对象，通常说明边界已经错了。

### 11. 常见误区

- 把 SharedPreferences 当成所有小数据的永久默认答案。
- 用键值存储承载已经明显结构化的业务数据。
- 配置项命名含糊，导致后续维护困难。
- 把配置读取写成零散同步调用，而不是纳入状态流组织。

## 小结

键值型存储解决的是“轻量配置如何持久化”的问题。今天的新项目更适合以 DataStore 作为主线，而不是继续默认从 SharedPreferences 起步。真正重要的不是 API 名字，而是你能否清楚区分配置数据和业务数据，并让配置读取自然融入现代状态管理模型。

下一章将把视角从轻量配置转到文件型数据，去看缓存文件、导出文档、图片附件和共享文件在现代 Android 中应该如何划分边界。

## 参考资料

- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，第 21 章及 DataStore 相关内容。
- 参考并改写自：Neil Smyth，`Android Studio Narwhal Essentials`，SharedPreferences、DataStore 与设置项持久化相关章节。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，配置状态、单一事实来源与状态持有相关章节。
- 参考并改写自：Gustavo Socorro，《Thriving in Android Development Using Kotlin》(2024)，Preferences DataStore、Proto DataStore 与本地偏好建模相关章节。

- DataStore guide：<https://developer.android.com/topic/libraries/architecture/datastore>
- SharedPreferences：<https://developer.android.com/training/data-storage/shared-preferences>
- Preferences DataStore codelab：<https://developer.android.com/codelabs/android-preferences-datastore>
