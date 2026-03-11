# 布局基础

布局是 Android 界面开发中最早接触、也最容易被低估的一层。很多初学者会把布局理解为“把控件摆到屏幕上”，但真正好的布局设计解决的是更本质的问题：页面结构如何分区、控件之间如何约束、不同屏幕尺寸下如何保持一致、未来改版时是否容易维护。本章以 View/XML 为主线，不是为了怀旧，而是为了帮助你先建立稳定的界面结构认知。

## 学习目标

- 理解布局容器的职责和常见适用边界。
- 理解尺寸、间距、对齐和层级为什么直接影响可维护性。
- 理解为什么现代 View 布局通常以 ConstraintLayout 为主线。
- 为常用控件、RecyclerView、Fragment 宿主和多设备适配打基础。

## 前置知识

- 已理解 Activity 与布局文件的基本关系。
- 已能创建并运行最小 Android 工程。

## 正文

### 1. 布局真正解决的是什么问题

布局的核心问题不是“把控件显示出来”，而是回答下面这些更底层的问题：

- 页面有哪些稳定区域。
- 各区域之间如何对齐和分配空间。
- 页面改版时局部调整是否容易。
- 在不同屏幕和方向下，结构是否仍然成立。

如果把布局仅仅当成视觉摆放工具，一旦页面复杂起来，就会迅速出现层级过深、结构不清、改一点牵一大片的问题。

### 2. 从“页面结构”而不是“控件清单”开始思考

初学布局时，最容易犯的错误是看到设计稿就开始堆控件。更合理的顺序通常是：

1. 先判断页面大区域怎么分。
2. 再确定每个区域内的主次和对齐关系。
3. 最后才决定具体控件和属性。

这个顺序很重要，因为布局首先是结构设计，其次才是控件摆放。结构一旦清晰，后续样式和数据绑定都会更顺。

### 3. 为什么现代 View 布局通常以 ConstraintLayout 为主

早期 Android 教程经常大量讲解 `LinearLayout`、`RelativeLayout`、`FrameLayout`、`TableLayout` 等容器。它们仍然值得认识，但在现代 View 体系下，`ConstraintLayout` 往往更适合作为主线，因为它更擅长表达复杂对齐关系，同时能减少不必要嵌套。

并不是所有页面都应该无脑使用 `ConstraintLayout`。更合理的理解是：

- 简单线性结构，用 `LinearLayout` 很自然。
- 单容器覆盖或占位结构，`FrameLayout` 很合适。
- 一旦页面出现多控件相互约束，`ConstraintLayout` 往往更清晰。

学习布局时，重点不是“哪个容器最强”，而是“当前结构最自然的表达方式是什么”。

### 4. 布局层级为什么会影响性能和维护性

布局层级越深，通常意味着：

- 页面结构更难读。
- 微调位置时更容易产生连锁修改。
- 后续适配和平板布局替换更困难。
- 测量和布局过程也可能产生额外开销。

因此，一个成熟的布局习惯是：先尽量把结构扁平化，再去优化局部细节，而不是一开始就堆多层容器把页面围起来。

### 5. 尺寸、间距和单位为什么不能随意写

布局不仅是容器选择，还包括尺寸表达方式。Android 中常见的基本约定包括：

- 距离和尺寸优先使用 `dp`。
- 字体大小优先使用 `sp`。
- 文本、颜色和尺寸尽量抽到资源中管理。

这些约定存在的原因不是“规范好看”，而是为了：

- 保持不同密度设备上的一致性。
- 支持用户字体缩放。
- 便于主题切换和资源复用。

只要你开始把尺寸、颜色和文本直接硬编码进布局文件，页面很快就会在迭代中失控。

### 6. 一个健康页面结构通常长什么样

无论设计稿多复杂，一个健康页面通常都能被拆成清晰的几个层次：

- 顶部区域：标题、筛选、导航入口或状态信息。
- 主内容区：表单、列表、卡片或正文。
- 辅助操作区：按钮、浮动操作、底部栏。

这种分区思维很重要，因为它会直接影响你后面如何组织 Fragment 容器、RecyclerView、工具栏和操作按钮。

### 7. 最小示例：一个由标题区、内容区、操作区组成的页面

下面是一个极简的布局示例，用来观察页面分区，而不是追求视觉完整度：

```xml
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:id="@+id/titleText"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:padding="16dp"
        android:text="今日任务"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/taskList"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintTop_toBottomOf="@id/titleText"
        app:layout_constraintBottom_toTopOf="@id/addButton"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/addButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_margin="16dp"
        android:text="新增"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

这个示例的重点不是属性细节，而是你能否一眼看出页面被分成了三块稳定区域。只要结构一目了然，后面增加真实数据、空状态或加载状态都会更容易。

### 8. 布局如何为后续章节服务

布局不是孤立知识。后续很多内容都建立在这一层之上：

- 常用控件依赖布局组织成表单和页面。
- Fragment 需要稳定宿主容器。
- RecyclerView 依赖清晰的列表项结构。
- Material Design 依赖统一的间距、层级和语义分区。

如果布局基础不稳，后面所有 UI 章节都会变成局部修补。

### 9. 最小实践任务

1. 用 XML 写一个包含标题区、内容区和操作区的页面。
2. 先用 `LinearLayout` 做，再用 `ConstraintLayout` 重写，比较两者结构表达的差异。
3. 把明显多余的嵌套层删除，观察布局可读性是否提高。
4. 把文本、尺寸和颜色抽成资源，而不是直接硬编码在布局中。

### 10. 常见误区

- 先想到控件，再临时补结构。
- 所有页面都无脑堆多层 `LinearLayout`。
- 把尺寸、颜色和文本直接写死在布局文件里。
- 为了“快速搞定”，让布局层级越来越深。

## 小结

布局基础解决的是页面结构问题，而不是单个控件问题。只有先把结构、层级和约束关系建立清楚，后续的输入、列表、导航和适配才不会陷入反复返工。
