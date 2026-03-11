# Room 数据库

如果说 SQLite 提供了 Android 本地结构化存储的底层能力，那么 Room 提供的就是更适合现代工程使用的数据库表达方式。它的价值不在于“让数据库看起来更高级”，而在于把那些重复、分散且容易出错的底层数据库代码收束成更清晰的结构：实体负责描述数据，DAO 负责表达访问，数据库类负责统一组织入口。本章要建立的，就是这种结构化数据库思维。

Room 很容易被学成“注解怎么写”的章节，但那不是它最重要的价值。真正值得理解的是：为什么 Room 能成为今天 Android 本地数据库的默认主线，它相对原生 SQLite 解决了什么工程问题，又为什么它天然适合和 Flow、ViewModel、Repository 这类现代架构能力连接在一起。

## 学习目标

- 理解 Room 的核心组成和职责边界。
- 理解 Room 与 SQLite 的关系。
- 理解 Room 为什么适合与 ViewModel、Flow 和 Repository 结合。
- 建立对实体建模、查询设计和迁移问题的初步认识。

## 前置知识

- 已理解 SQLite 的基本角色和核心概念。
- 已具备列表和本地结构化数据展示的基本认知。

## 正文

### 1. Room 解决了哪些真实问题

Android 官方的 Room 文档对它的定位非常明确：Room 是构建在 SQLite 之上的抽象层，用来提供更流畅的数据库访问，同时利用 SQLite 的能力。官方同时列出了它的几个关键收益：SQL 查询的编译期校验、减少重复且易错样板代码的便利注解、更清晰的迁移路径。

这意味着 Room 解决的并不是“数据库太难，所以把数据库隐藏起来”，而是把原生 SQLite 最常见的工程痛点收束成更稳定的结构。你仍然需要理解数据库模型和查询，只是不必再在项目的各个角落散落原始映射代码和数据库生命周期逻辑。

### 2. Entity、DAO、Database 三个角色分别负责什么

理解 Room 时，最重要的是先分清三个角色。Entity 描述的是表结构对应的数据模型，它回答的是“这类记录长什么样”。DAO 用来表达查询、插入、更新和删除等数据访问行为，它回答的是“我怎样和这类数据交互”。Database 类把实体和 DAO 统一组织起来，形成数据库入口，它负责“总装配”，而不是承载业务逻辑。

只要这三者职责清楚，Room 的整体结构就不会显得抽象。你也会更容易判断某段代码到底该放在哪：表字段属于 Entity，访问方法属于 DAO，业务规则和多数据源协调则不该直接塞进数据库类里。

### 3. Entity 最重要的不是注解，而是建模

很多人学 Room 时会把注意力全部放在注解和 API 上，反而忽略真正更重要的问题：一个 Entity 是否真的表达了真实业务对象。比如待办条目究竟应该有哪些字段，哪些字段是稳定记录的一部分，哪些只是页面瞬时状态，哪些未来可能进入查询条件，这些都属于建模问题，而不是注解问题。

Room 让数据库代码更好写，但它不会替你做建模决策。建模一旦混乱，再优雅的注解也救不了后续维护。对真实项目来说，Entity 的任务不是“把页面上看到的字段都塞进去”，而是承载可长期存在、可稳定读写的本地业务记录。

### 4. DAO 的核心，是把真实读取场景表达出来

DAO 很容易被误解成“数据库 API 清单”。更准确的理解是：DAO 用来表达真实业务读取和写入场景。例如“读取全部待办并按创建时间倒序”“更新某条待办的完成状态”“插入一条新记录”。只要这些方法围绕真实场景来设计，DAO 就会非常稳定；如果只是把所有可能操作都机械铺开，DAO 很快也会变成另一个杂乱入口。

Android 官方 Room 文档也把 DAO 放在非常重要的位置，因为它是 Room 里真正承接 SQL 语义的地方。注解和返回类型当然重要，但比这些更重要的是：你有没有先想清楚页面究竟会怎样读取这批数据。

### 5. 最小示例：一个待办 Room 结构如何接上页面

下面这个例子用最小待办条目展示 Room 的主干结构：

```kotlin
@Entity(tableName = "task")
data class TaskEntity(
    @PrimaryKey val id: Long,
    val title: String,
    @ColumnInfo(name = "is_done") val isDone: Boolean,
    @ColumnInfo(name = "created_at") val createdAt: Long
)

@Dao
interface TaskDao {
    @Query("SELECT * FROM task ORDER BY created_at DESC")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(task: TaskEntity)

    @Query("UPDATE task SET is_done = :done WHERE id = :taskId")
    suspend fun updateDone(taskId: Long, done: Boolean)
}

@Database(entities = [TaskEntity::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
    abstract fun taskDao(): TaskDao
}
```

这个例子的重点不是 API 完整性，而是让你看到一条更完整的数据链：Entity 描述条目结构，DAO 提供读取和更新入口，Database 统一暴露 DAO，后续 ViewModel 或 Repository 则可直接围绕 `Flow<List<TaskEntity>>` 组织状态。Room 的现实价值，就在于它天然能接上现代 Android 的状态流模型。

### 6. 为什么 Room 特别适合与 Flow、ViewModel 和 Repository 结合

Room 很少孤立存在。它通常会和 ViewModel、Flow、Repository、Paging 等能力一起工作。原因很直接：本地数据库里的变化，本身就适合作为页面可观察的状态来源。Android 官方 Room 文档也明确把“离线浏览内容缓存”作为常见用例，这与现代 ViewModel 和状态流组织方式天然契合。

也就是说，Room 不只是“把数据存一下”，而是成为稳定数据流的一部分。数据库变化通过 DAO 暴露给上层，Repository 决定本地与远程如何协作，ViewModel 再把结果组织成页面状态。只要这条链路清晰，页面就不再需要自己直接协调数据库细节。

### 7. 查询设计和迁移，决定 Room 能不能撑住长期演进

很多本地数据库设计失败，不是因为存不进去，而是因为最常见的读取场景没有被提前考虑，或者数据库结构一变化就缺乏明确迁移策略。Android 官方 Room 文档把迁移路径列为它的重要价值之一，这一点非常值得重视。数据库不是永远不变的，新增字段、调整默认值、增加索引、重构关系，这些变化在长期项目里迟早都会出现。

入门阶段你不必掌握所有迁移细节，但必须建立一个意识：数据库结构不是一次性定下就永远不变的。Room 可以帮你把迁移纳入更明确的工程管理，但它无法替你决定该如何演进结构，也无法替你回避建模失误。

### 8. 什么时候不该再往 Room 里塞逻辑

Room 虽然很适合本地数据库开发，但它不是所有数据问题的终点。只要某段逻辑开始涉及远程同步策略、本地和远程冲突解决、文件与数据库协作、页面专属状态转换，它通常就不该继续留在 DAO 或数据库类里，而应上移到 Repository 或数据层其他部分。Room 负责的是本地结构化存储，不是全能业务层。

这条边界一旦清楚，Room 反而会更稳定。数据库相关代码专注在实体、查询和本地写入上，Repository 再去承担多数据源协调和单一可信来源的组织。下一章的数据层设计，其实就是在这层边界上继续展开。

### 9. 实践任务

起点条件：

- 已有一个待办、笔记或清单类应用设想。
- 已能接受本地结构化数据应交给数据库处理。

步骤：

1. 为待办列表设计一个最小 Room 实体。
2. 为它设计一个插入方法、一个按时间排序的查询方法和一个更新完成状态的方法。
3. 用自己的话说明 Entity、DAO 和 Database 各自解决什么问题。
4. 额外思考：如果后续要增加分类字段、索引或迁移版本，这次结构变更会影响哪些层。

预期结果：

- 你能把 Room 看成一条完整结构，而不是几种注解组合。
- 你会开始围绕真实读取场景设计 DAO，而不是围绕 API 数量设计 DAO。
- 你会对后续 Repository 和数据层设计有更清晰的衔接感。

自检方式：

- 你能解释：Room 相对原生 SQLite 具体简化了什么。
- 你能判断：某段逻辑应放在 DAO，还是应放到 Repository。
- 你能说出：为什么查询设计和迁移意识比“注解背得熟”更重要。

调试提示：

- 如果你发现 DAO 方法越来越像业务服务，通常说明边界已经错了。
- 如果 Entity 开始混入大量页面瞬时状态，先回头区分“持久化记录”和“UI 状态”。
- 如果你还没想清读取场景，就不要急着设计很多复杂关系和注解。

### 10. 常见误区

- 只关注注解写法，不关注实体和查询设计。
- 把 Room 当成会自动替你解决所有数据库问题的黑盒。
- 在还没明确实际读取场景时就过度设计复杂关系。
- 认为数据库结构一旦定下就永远不会变化。

## 小结

Room 把 Android 本地数据库开发从“低层 API 使用”提升成了“结构清晰的数据层设计”。真正重要的不是注解本身，而是你是否能围绕真实业务场景，把实体、查询、状态流和页面展示组织成一条稳定的数据链路。只要这一层站稳，后面的 Repository、本地与远程协作以及离线能力设计都会更容易展开。

下一章我们会继续往上走，进入数据层设计，把 Room、DataStore、网络和页面状态真正组织成现代 Android 工程里的完整数据流。


## 参考资料

- Save data in a local database using Room：<https://developer.android.com/training/data-storage/room>
- Room and Flow：<https://developer.android.com/kotlin/flow>
