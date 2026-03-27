# Android 开发教程

这是一个以 Markdown 组织的 Android 中文书稿仓库，目标是把 Android 学习路径整理成一套从基础入门到工程实践、从组件理解到综合项目的连续教程。全书正文默认采用现代 Android 技术口径，优先使用 Kotlin、AndroidX、Jetpack、Compose、Flow、WorkManager、Hilt 等当前主线方案，同时会在必要处交代历史 API 的背景、边界和迁移方向。

仓库内容不只是章节草稿，还包含目录、写作规范、章节模板、参考资料整理和出版级正文扩写后的结构成果。对读者来说，这里可以直接按章节阅读；对继续维护书稿的人来说，这里也保留了清晰的写作入口和组织方式。

## 项目介绍

- 面向对象：希望系统学习 Android 的中文开发者。
- 内容目标：解释 Android 为什么这样设计、今天推荐怎样做、最小实践如何落地，以及真实项目里最常见的工程判断。
- 技术基线：Kotlin、AndroidX、Jetpack、Compose、Flow、WorkManager、现代权限与发布流程。
- 组织方式：按 `基础 -> UI -> 数据 -> 网络 -> 架构 -> 并发 -> 系统组件 -> 工程实践 -> 发布 -> 综合项目 -> 附录` 逐步推进。

## 阅读入口

- [全书目录](SUMMARY.md)
- [写作计划](book-plan.md)
- [正文目录](book/)
- [写作规范](../.agents/skills/android-book-writer/docs/style-guide.md)
- [章节模板](../.agents/skills/android-book-writer/docs/chapter-template.md)
- [完整正文标准](../.agents/skills/android-book-writer/docs/full-prose-standard.md)
- [来源策略](../.agents/skills/android-book-writer/docs/source-policy.md)

## 全书结构

全书由前言、10 个正文部分和附录组成：

1. [基础篇](book/01-foundation/01-android-overview.md)：建立 Android 平台、工具链、项目结构和生命周期的基本认识。
2. [UI 开发](book/02-ui/01-layout-basics.md)：覆盖 View 体系、Fragment、Navigation、RecyclerView、Material Design 和 Compose 基础。
3. [数据存储](book/03-data/01-storage-overview.md)：整理从 DataStore、文件、SQLite、Room 到数据层设计的完整主线。
4. [网络开发](book/04-network/01-network-basics.md)：从网络基础、HTTP、OkHttp、Retrofit 到 API 结果封装和离线缓存。
5. [应用架构](book/05-architecture/01-mvc-mvp-mvvm.md)：从 MVC / MVP / MVVM 出发，逐步进入 ViewModel、Repository、UseCase 和 Hilt。
6. [并发与异步](book/06-concurrency/01-threading-basics.md)：从线程基础、Handler、协程、Flow 到后台任务和 WorkManager。
7. [系统组件](book/07-system-components/01-intent.md)：围绕 Intent、Service、BroadcastReceiver、ContentProvider、通知、权限和桌面集成。
8. [工程实践](book/08-engineering/01-gradle-basics.md)：聚焦 Gradle、构建变体、模块化、调试、测试、CI/CD、性能和安全。
9. [发布应用](book/09-publish/01-signing.md)：整理签名、Release 构建、Google Play 发布和版本维护。
10. [综合项目](book/10-projects/01-todo-app.md)：用 Todo、新闻、聊天和 Clean Architecture 样例把前面内容串起来。

## 快速跳转

- [前言](book/00-frontmatter/preface.md)
- [第一部分 基础篇](book/01-foundation/01-android-overview.md)
- [第二部分 UI 开发](book/02-ui/01-layout-basics.md)
- [第三部分 数据存储](book/03-data/01-storage-overview.md)
- [第四部分 网络开发](book/04-network/01-network-basics.md)
- [第五部分 应用架构](book/05-architecture/01-mvc-mvp-mvvm.md)
- [第六部分 并发与异步](book/06-concurrency/01-threading-basics.md)
- [第七部分 系统组件](book/07-system-components/01-intent.md)
- [第八部分 工程实践](book/08-engineering/01-gradle-basics.md)
- [第九部分 发布应用](book/09-publish/01-signing.md)
- [第十部分 综合项目](book/10-projects/01-todo-app.md)
- [附录](book/11-appendix/01-kotlin-quickstart.md)

## 章节目录

### 前言

- [前言](book/00-frontmatter/preface.md)
- [适读人群](book/00-frontmatter/who-this-book-is-for.md)
- [如何阅读本书](book/00-frontmatter/how-to-read.md)
- [符号说明](book/00-frontmatter/notation.md)

### 第一部分 基础篇

- [Android 概述](book/01-foundation/01-android-overview.md)
- [开发环境搭建](book/01-foundation/02-dev-environment.md)
- [第一个 Android App](book/01-foundation/03-first-app.md)
- [Android 项目结构](book/01-foundation/04-project-structure.md)
- [Activity 生命周期](book/01-foundation/05-activity-lifecycle.md)

### 第二部分 UI 开发

- [布局基础](book/02-ui/01-layout-basics.md)
- [常用 UI 组件](book/02-ui/02-common-widgets.md)
- [事件处理](book/02-ui/03-event-handling.md)
- [Fragment](book/02-ui/04-fragment.md)
- [Navigation](book/02-ui/05-navigation.md)
- [RecyclerView](book/02-ui/06-recyclerview.md)
- [Material Design](book/02-ui/07-material-design.md)
- [Jetpack Compose 基础](book/02-ui/08-compose-basics.md)

### 第三部分 数据存储

- [数据存储概述](book/03-data/01-storage-overview.md)
- [SharedPreferences 与 DataStore](book/03-data/02-sharedpreferences-datastore.md)
- [文件存储](book/03-data/03-file-storage.md)
- [SQLite](book/03-data/04-sqlite.md)
- [Room 数据库](book/03-data/05-room.md)
- [JSON 解析](book/03-data/06-json-parsing.md)
- [数据层设计](book/03-data/07-data-layer-design.md)

### 第四部分 网络开发

- [网络基础](book/04-network/01-network-basics.md)
- [HTTP 与 REST](book/04-network/02-http-and-rest.md)
- [OkHttp](book/04-network/03-okhttp.md)
- [Retrofit](book/04-network/04-retrofit.md)
- [API 结果封装](book/04-network/05-api-result-wrapping.md)
- [离线缓存](book/04-network/06-offline-cache.md)

### 第五部分 应用架构

- [MVC / MVP / MVVM](book/05-architecture/01-mvc-mvp-mvvm.md)
- [Android 中的 MVVM](book/05-architecture/02-mvvm-in-android.md)
- [ViewModel](book/05-architecture/03-viewmodel.md)
- [LiveData 与 Flow](book/05-architecture/04-livedata-flow.md)
- [Repository 模式](book/05-architecture/05-repository-pattern.md)
- [UseCase / Domain 层](book/05-architecture/06-usecase-domain-layer.md)
- [依赖注入 Hilt](book/05-architecture/07-hilt-di.md)

### 第六部分 并发与异步

- [线程基础](book/06-concurrency/01-threading-basics.md)
- [Handler 与 Looper](book/06-concurrency/02-handler-looper.md)
- [Kotlin Coroutines](book/06-concurrency/03-coroutines.md)
- [Flow](book/06-concurrency/04-flow.md)
- [后台任务](book/06-concurrency/05-background-work.md)
- [WorkManager](book/06-concurrency/06-workmanager.md)

### 第七部分 系统组件

- [Intent](book/07-system-components/01-intent.md)
- [Service](book/07-system-components/02-service.md)
- [BroadcastReceiver](book/07-system-components/03-broadcastreceiver.md)
- [ContentProvider](book/07-system-components/04-contentprovider.md)
- [Notification](book/07-system-components/05-notification.md)
- [权限管理](book/07-system-components/06-permission.md)
- [桌面组件与快捷方式](book/07-system-components/07-app-widgets-and-shortcuts.md)

### 第八部分 工程实践

- [Gradle 基础](book/08-engineering/01-gradle-basics.md)
- [构建变体](book/08-engineering/02-build-variants.md)
- [模块化开发](book/08-engineering/03-modularization.md)
- [日志与调试](book/08-engineering/04-logging-and-debugging.md)
- [测试](book/08-engineering/05-testing.md)
- [CI/CD](book/08-engineering/06-ci-cd.md)
- [性能优化](book/08-engineering/07-performance-optimization.md)
- [安全基础](book/08-engineering/08-security-basics.md)

### 第九部分 发布应用

- [应用签名](book/09-publish/01-signing.md)
- [Release 构建](book/09-publish/02-release-build.md)
- [Google Play 发布](book/09-publish/03-play-store.md)
- [版本管理与维护](book/09-publish/04-versioning-and-maintenance.md)

### 第十部分 综合项目

- [Todo App](book/10-projects/01-todo-app.md)
- [新闻 App](book/10-projects/02-news-app.md)
- [聊天 App](book/10-projects/03-chat-app.md)
- [Clean Architecture 示例](book/10-projects/04-clean-architecture-sample.md)

### 附录

- [Kotlin 快速入门](book/11-appendix/01-kotlin-quickstart.md)
- [Java 转 Kotlin](book/11-appendix/02-java-to-kotlin.md)
- [常见错误](book/11-appendix/03-common-errors.md)
- [Android 面试题](book/11-appendix/04-interview-topics.md)
- [参考资料](book/11-appendix/05-reference-resources.md)

## 仓库结构

- `SUMMARY.md`：全书目录与导航入口。
- `book/`：章节正文、前言、附录和配图资源。
- `book/media/`：正文插图、流程图、结构图和界面图。
- `book-plan.md`：写作计划与章节推进依据。
- `../.agents/skills/android-book-writer/`：本仓库使用的写作技能包与规范文档。

## 当前状态

- 已完成 `SUMMARY.md` 对应章节文件的全量落地。
- 已完成全书首轮重写、扩写与多轮正文润色。
- 已补充大量参考资料整合、代码示例、技术讲解和图例。
- 当前可继续围绕全书审校、统一示例边界、时效性复核和最终出版整理推进。
