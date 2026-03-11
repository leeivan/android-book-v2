# Fragment

Fragment 是 Android 界面结构中非常重要、也经常被误解的一类组件。很多初学者第一次接触 Fragment 时，会觉得它像“半个 Activity”或者“可以嵌在页面里的小页面”。这种描述有一点直观性，但不够准确。Fragment 的真正价值，在于它提供了一种更细粒度的界面和生命周期组织方式，让同一个 Activity 可以承载多个可组合、可替换的 UI 片段。

这一章最容易学偏的地方，是把 Fragment 当成“必须会的另一个页面类”，或者反过来认为“既然 Activity 也能做页面，Fragment 只是多余复杂度”。这两种理解都不够好。Fragment 真正解决的，是页面结构的拆分、替换和复用问题，以及同一宿主中多个界面单元如何更清晰地组织生命周期与交互。

## 学习目标

- 理解 Fragment 为什么存在，以及它解决了什么问题。
- 理解 Fragment 与 Activity 的职责边界。
- 认识 Fragment 自己的生命周期和视图生命周期。
- 为 Navigation、多页面结构和主从布局打基础。

## 前置知识

- 已理解 Activity 生命周期和基本页面结构。
- 已掌握布局和事件处理的基础概念。

## 正文

### 1. 为什么 Activity 不足以承载所有页面结构

如果一个应用只有几个简单页面，全部用 Activity 组织当然可以。但随着页面变复杂，你会逐渐遇到这些需求：一个页面里有多个可独立变化的区域；同一业务流在手机和平板上的布局不同；某个内容区需要被替换或复用；列表和详情可能要在同一宿主里协同显示。只要继续把所有内容都塞进 Activity，Activity 很快就会变得过重、结构难拆、复用困难。

Fragment 正是为了解决这类问题而出现的。Android 官方将 Fragment 描述为 Activity 中一块模块化的用户界面，它有自己的生命周期，也能接收自己的输入事件。这句话很关键，因为它说明 Fragment 不是 Activity 的附庸视图，而是受宿主承载、但又拥有自己组织能力的界面单元。

### 2. Fragment 更像“可组合的界面单元”

相比把 Fragment 理解成“小型 Activity”，更准确的理解是：它是一个由宿主 Activity 承载、具备自己生命周期和视图层的可组合界面单元。这种理解有两个重要含义。第一，Fragment 不是脱离 Activity 独立存在的。第二，Fragment 不只是为了“多页面切换”，同样适合复杂页面内部结构拆分。

一旦把 Fragment 看成“可组合的界面单元”，很多设计判断就更自然了。比如，一个页面的筛选区、内容区和详情区是否应该拆开；平板双栏结构中的右侧详情是否应该是一个独立单元；同一内容区是否要在不同宿主中复用。这些都比“它是不是小页面”更接近 Fragment 的真实价值。

### 3. Activity 和 Fragment 的边界应该怎么划

在现代 Android 中，一个很常见且有价值的边界是：Activity 更适合作为系统级入口、导航宿主和页面外壳；Fragment 更适合作为具体内容区域和交互单元。这并不是唯一组织方式，但它符合今天较常见的“单 Activity + 多 Fragment”思路，也更容易和 Navigation 组件配合。

这样划分的价值，在于减少 Activity 之间反复传递状态和切换成本，让页面流转更容易统一管理。读者可以把 Activity 理解成“系统如何进入这一块界面流程”，把 Fragment 理解成“流程里每个具体目的地或内容区域如何组织”。只要边界清楚，页面结构就会比“每个页面都是一个独立 Activity”更稳定。

### 4. Fragment 有两个生命周期，这一点必须尽早建立直觉

Fragment 比 Activity 更容易让初学者迷惑的地方，在于它同时涉及 Fragment 本身的生命周期，以及 Fragment 视图的生命周期。Android 官方 Fragment lifecycle 文档明确强调，Fragment 的 view 有独立生命周期，应该通过 `viewLifecycleOwner` 来感知。换句话说，Fragment 实例还在，并不等于它的 View 还在。

这个区别非常重要，因为大量内存泄漏、空指针和“界面明明销毁了为什么还在更新”的问题，都来自没有区分“Fragment 活着”和“Fragment 的视图已经销毁”。在现代 Fragment 开发里，绑定视图、观察界面状态、设置适配器和清理视图引用时，都必须非常注意这个边界。

### 5. 什么时候最适合用 Fragment

Fragment 最常见、最有价值的场景包括：页面内容区替换、标签页和主从结构、导航图中的多个目的地、复杂页面内部的结构拆分。它也特别适合那些“宿主不变，但局部内容会切换”的界面。比如一个设置页面的多个子面板，一个列表页进入详情页后的内容替换，或者大屏幕上的双栏详情结构。

但 Fragment 不是越多越好。如果只是一个非常简单且不会复用的小页面，也不必为了“看起来更现代”强行拆出多个 Fragment。结构的目标永远是让页面更清晰，而不是增加层数。Fragment 只有在它确实能帮助你拆分职责、承载替换、改善复用时才有价值。

### 6. `FragmentContainerView` 和事务，决定了 Fragment 怎么落到页面里

Android 官方的 Create a fragment 指南明确建议，用 `FragmentContainerView` 作为 Fragment 的容器，而不是随便找一个 `FrameLayout` 来代替，因为它包含了专门针对 Fragment 的行为修复。你可以在 XML 中直接让容器承载一个 Fragment，也可以在 Activity 中通过 `FragmentManager` 和事务把 Fragment 加入或替换进去。

如果是代码方式添加，官方同样建议在事务中调用 `setReorderingAllowed(true)`。这个细节很容易被忽略，但它关系到 FragmentManager 正确处理事务、生命周期和回退行为。对当前阶段的读者来说，最重要的不是记住所有事务方法，而是理解：Fragment 不是自动漂浮在页面里的，它必须有宿主、有容器、有明确的添加或替换入口。

### 7. 最小示例：把内容区从 Activity 中拆成 Fragment

下面这个例子演示如何让 Activity 只保留容器，而把真正的内容区交给 Fragment。首先是 Activity 的布局：

```xml
<androidx.fragment.app.FragmentContainerView
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/contentContainer"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

然后在宿主 Activity 中，只在首次创建时把 Fragment 放进去：

```kotlin
class HostActivity : AppCompatActivity(R.layout.activity_host) {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (savedInstanceState == null) {
            supportFragmentManager.commit {
                setReorderingAllowed(true)
                add(R.id.contentContainer, DetailFragment())
            }
        }
    }
}
```

这个例子的重点不在于多了一个类，而在于页面结构第一次出现了清晰分层：Activity 负责承载宿主和系统入口，Fragment 负责具体内容。后续如果你要把 `DetailFragment` 替换成其他内容，或者在平板上同时显示两个 Fragment，这个结构都会比“所有逻辑全在 Activity”更稳定。

### 8. Fragment 通信为什么要尽早重视

只要一个页面里有多个 Fragment，或者 Fragment 需要和宿主 Activity 协作，通信问题就会很快出现。这个问题的关键不是“技术上能不能拿到引用”，而是：谁持有页面级状态，谁只负责展示，谁负责协调多个区域之间的交互。如果一开始就选择彼此直接强引用调用，代码很快就会陷入高度耦合。

现代实践通常更倾向于通过共享 ViewModel、宿主协调或更清晰的事件传递方式来管理通信，而不是让 Fragment 彼此直接互调。现在你不需要一次掌握所有通信模式，但至少要形成一个原则：Fragment 的价值在于拆分结构，不要马上又通过强耦合把它们重新绑死。

### 9. 实践任务

起点条件：

- 已有一个简单 Activity 页面。
- 已能编辑 Activity 布局并运行工程。

步骤：

1. 在 Activity 布局中加入一个 `FragmentContainerView`。
2. 新建一个简单 Fragment，把原来 Activity 中的内容区搬进去。
3. 让 Activity 只承担容器和页面框架职责，不再直接持有内容区控件。
4. 运行页面，观察 Fragment 创建、显示和返回时的行为。
5. 尝试在 `onViewCreated()` 中绑定视图，并思考为什么这一步不应混到更早或更晚的位置。

预期结果：

- 页面结构比“所有内容都在 Activity”更清晰。
- 你能感受到 Activity 和 Fragment 的职责边界开始分化。
- 你对“Fragment 自己有生命周期，View 也有生命周期”会有更具体的理解。

自检方式：

- 你能解释：为什么 Fragment 不是“缩小版 Activity”。
- 你能说出：为什么 `viewLifecycleOwner` 重要。
- 你能判断：当前页面是真的需要 Fragment，还是只是为了拆而拆。

调试提示：

- 如果 Fragment 重复添加，先检查是否忘了用 `savedInstanceState == null` 限制首次添加。
- 如果你在错误时机访问 View，先回头检查是否把视图相关操作放到了 `onViewCreated()` 一类更合适的阶段。
- 如果返回行为异常，先检查当前事务是否被加到了 back stack，或者是否本应交给 Navigation 统一管理。

### 10. 常见误区

- 把 Fragment 理解成“缩小版 Activity”。
- 不区分 Fragment 生命周期和视图生命周期。
- 为很简单的页面强行拆过多 Fragment。
- 通过直接互相引用做 Fragment 通信，导致耦合失控。

## 小结

Fragment 的意义不在于“多学一个组件”，而在于它提供了更灵活的界面组织能力。只要你理解了 Fragment 与 Activity 的边界，以及 Fragment 自己和其 View 的双重生命周期，后面的 Navigation、多页面结构和大屏适配就会更容易站稳。

下一章我们会在这个基础上继续讨论页面流转，也就是导航。到那时，你会看到 Fragment 不只是“内容单元”，更是现代 Navigation 结构中的主要目的地承载者。

### 教材化延伸：为什么 Fragment 不能只靠 API 文档理解

Fragment 章节如果只看 API 或回调说明，很容易学成“会提交事务”，但仍然说不清宿主关系、视图生命周期和回退栈的边界。更稳妥的教材写法，是把官方文档、最小宿主示例和导航样例结合起来。这样读者看到的就不是一组零散调用，而是“页面为什么要拆”“拆开后谁负责状态、谁负责容器、谁负责导航”的完整结构。

### 资料路线

- 先用本章最小示例理解 Activity 宿主、Fragment 视图和事务的关系。
- 再查官方 Fragment create、lifecycle 和 transactions 文档，确认回调和管理器边界。
- 最后结合 Navigation 或样例项目，观察真实项目如何避免在 Fragment 中堆过多职责。

## 参考资料

- 创建 Fragment：<https://developer.android.com/guide/fragments/create>
- Fragment 生命周期：<https://developer.android.com/guide/fragments/lifecycle>
- FragmentManager：<https://developer.android.com/guide/fragments/fragmentmanager>
- Fragment 事务：<https://developer.android.com/guide/fragments/transactions>
