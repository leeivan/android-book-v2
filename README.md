# Android Book v2

《基于 Android 平台的移动应用开发》重写版仓库。

这个仓库不再沿用旧版“以 Java + 早期 View API 为主、现代实践作为补充说明”的组织方式，而是将现代 Android 开发作为正文主线，把历史 API 放到迁移说明或附录中。

当前版本已经完成新版目录、前言、内容简介和 11 章书稿骨架，适合作为后续逐章扩写的基础仓库。

## 在线阅读

- [内容简介](md/book_introduction.md)
- [前言](md/preface.md)

## 章节目录

1. [第1章 现代 Android 开发概览与环境搭建](md/chapter01_modern_android_overview.md)
2. [第2章 项目结构、Gradle 与构建发布基础](md/chapter02_project_structure_and_build.md)
3. [第3章 Activity、Fragment、ViewModel 与生命周期](md/chapter03_components_and_lifecycle.md)
4. [第4章 布局、资源、主题与多设备适配](md/chapter04_layout_resources_and_adaptation.md)
5. [第5章 常用控件、列表界面与交互反馈](md/chapter05_widgets_lists_and_feedback.md)
6. [第6章 导航、菜单、应用栏与结果回调](md/chapter06_navigation_menus_and_results.md)
7. [第7章 Intent、广播与跨应用交互](md/chapter07_intents_broadcasts_and_app_interop.md)
8. [第8章 网络通信与远程数据获取](md/chapter08_networking_and_remote_data.md)
9. [第9章 本地存储、文件访问与媒体能力](md/chapter09_local_storage_and_media_access.md)
10. [第10章 Room、Repository 与本地数据层](md/chapter10_room_and_local_data_layer.md)
11. [第11章 协程、后台任务、通知、定位与综合案例](md/chapter11_coroutines_background_location_and_case_study.md)

## 本版技术基线

- 语言默认采用 Kotlin。
- 界面主线采用 AndroidX + View/XML，相关章节补充 Compose 视角。
- 状态管理默认采用 ViewModel。
- 异步与后台任务默认采用 Coroutine、Flow 与 WorkManager。
- 列表界面默认采用 RecyclerView。
- 本地结构化存储默认采用 Room。
- 结果回调默认采用 Activity Result API。
- 存储与媒体访问默认采用 DataStore、MediaStore、SAF 与 Photo Picker。

## 重写原则

- 正文优先讲当前推荐方案，旧 API 仅用于理解历史代码和迁移思路。
- 每章都围绕“为什么这样设计、什么时候这样用、最小可运行案例”展开。
- 章节之间保持一条统一的工程主线，避免知识点之间割裂。
- 仓库优先服务在线阅读，因此文件结构保持简洁，链接保持稳定。

## 后续扩写方向

- 将每章骨架扩展为正式正文。
- 为关键章节补充完整示例工程。
- 增加附录：Java/Kotlin 对照、旧 API 迁移、测试与发布速查。
