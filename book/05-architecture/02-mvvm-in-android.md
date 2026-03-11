# Android 中的 MVVM

上一章解决了“为什么现代 Android 更常采用 MVVM”，这一章开始解决“它在 Android 里到底怎样落地”。关键不是把 View、ViewModel、Model 三个词背会，而是理解在 Android 的组件体系中，界面层、状态层和数据层应怎样协作。

## 学习目标

- 理解 MVVM 在 Android 中如何落地。
- 理解界面层、状态层和数据层的基本分工。
- 为 ViewModel 与 Flow 的组合使用打基础。

## 前置知识

- 已理解 Activity、Fragment、数据层和网络层的基本角色。
- 已理解 MVVM 相对其他模式的整体优势。

## 正文

### 1. Android 中的 View 不只是 XML

在 MVVM 里，View 通常不只是“布局文件”，而是更广义的界面层，包括：

- Activity。
- Fragment。
- Compose 界面。
- 与界面渲染直接相关的轻量逻辑。

这意味着 View 的职责应尽量聚焦在“展示状态、接收用户输入、转发事件”，而不是大量承载业务决策。

### 2. ViewModel 在 Android 里的核心价值

ViewModel 在 Android 中之所以重要，是因为它非常契合平台中的生命周期和状态问题。它能帮助你：

- 承接页面状态。
- 避免把状态塞进 Activity/Fragment 实例。
- 更自然地与 Flow、Repository 和 Room 协作。

也因此，在现代 Android 项目里，MVVM 往往不是抽象讨论，而是具体地围绕 ViewModel 展开。

### 3. Model 在 Android 里不只是“数据类”

很多初学者会把 Model 理解成几个数据对象。但在更完整的 Android 项目里，Model 往往还包括：

- Repository。
- 网络数据源。
- 本地数据库。
- 领域规则或用例逻辑。

也就是说，MVVM 中的 Model 更像是“整个非界面数据与业务层”的统称，而不只是某个数据类。

### 4. 为什么 MVVM 常与状态流一起使用

因为 Android 界面天然是状态驱动的：页面会重建、会切换、会等待异步结果。Flow 或 LiveData 之类的状态传播机制，正好适合把 ViewModel 内的状态安全地暴露给界面层。

### 5. 最小实践任务

1. 以一个列表页为例，写出 View、ViewModel 和数据层各自的职责。
2. 判断某段逻辑是该留在界面层还是应移到 ViewModel。
3. 观察你自己的代码里有没有“页面既处理界面又处理业务”的混杂情况。

### 6. 常见误区

- 把 MVVM 简化成“Activity + ViewModel”。
- 以为加了 ViewModel 就自动拥有良好架构。
- 不区分界面状态与数据源职责。

## 小结

Android 中的 MVVM 本质上是一种更适合平台现实问题的职责组织方式。理解了它与 Activity、Fragment、ViewModel 和 Repository 的关系，后续的状态流和依赖注入才会更容易落位。
