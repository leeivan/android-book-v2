# 常用控件

学习控件时，最容易走偏的方向是把它学成一份“控件大全”。这种方式短期看似覆盖很多，实际上帮助不大，因为真实页面并不是靠一堆孤立控件堆出来的，而是靠语义清晰的输入区、信息区和操作区组合出来的。本章不会把重点放在列举所有控件，而是聚焦那些最常见、最值得优先理解的基础控件，并说明它们在真实页面里如何分工。

控件章节真正要解决的，不是“我还没见过哪个控件”，而是“在当前任务里为什么应该选这个控件而不是另一个”。一旦这个问题想清楚，页面的可读性、可访问性和交互反馈都会明显提升；反过来，如果只把控件当成名字和标签去背，页面很快就会沦为语义混乱的拼装品。

## 学习目标

- 理解常见基础控件在页面中的典型职责。
- 知道文本展示、用户输入、开关选择和图像承载的常见做法。
- 理解控件选择和页面语义、可访问性之间的关系。
- 为事件处理、表单设计和列表项设计打基础。

## 前置知识

- 已理解布局基础和资源组织方式。
- 已能运行并修改一个简单页面。

## 正文

### 1. 为什么控件学习不能停留在“会拖控件”

控件的价值，从来不是“把一个东西摆到屏幕上”，而是让用户更自然地理解信息和完成任务。也就是说，控件选择本质上是交互设计问题，而不仅是 API 问题。页面上每一个控件都在向用户表达一种语义：这是说明文字、这是输入入口、这是主操作、这是次操作、这是一个可开关的状态、这是一个图像信息载体。

看似只是控件不同，背后反映的其实是页面语义是否清晰。比如，一段说明文字应该用文本展示，而不是伪装成按钮；一个二元状态更适合开关或勾选控件，而不是手写点击文本切换；一个图片封面更适合专门的图像容器，而不是临时用背景图硬贴。用户不是在看你用了多少控件，而是在理解你是否把任务表达清楚了。

### 2. 文本类控件，是页面的信息骨架

`TextView` 是最基础也最重要的 UI 控件之一。很多页面的结构感，本质上是靠文本层级建立起来的，例如标题、副标题、说明、标签、错误提示和按钮文案。一个页面好不好读，往往首先取决于文本结构是否清晰，而不是颜色有多花、圆角有多多。

学习文本控件时，重点应放在三件事上：文本层级是否清楚，字号和留白是否表达了主次，文案是否来自资源而不是硬编码。只要这三件事做对，页面的可读性通常就已经比“把字显示出来”高出很多。反过来，如果标题、正文、提示和错误信息都长得差不多，用户很快就会失去阅读线索。

### 3. 输入类控件，是用户任务的入口

输入控件通常包括 `EditText`，以及现实项目里更常见的 `TextInputLayout` 与 `TextInputEditText` 组合。它们的关键不是“能不能输入文字”，而是是否提供明确标签、是否声明合适的输入类型、是否处理校验与错误提示，以及是否和页面状态保持一致。官方关于输入法类型的文档也明确建议为文本输入控件设置恰当的 `inputType`，这样系统才能提供更符合场景的软键盘和输入行为。

这也是为什么现代 View 页面中，很多表单不再直接裸用一个简单 `EditText` 就结束。`TextInputLayout` 可以承载浮动标签、错误信息、辅助文案、字数计数和前后缀等能力，能显著改善输入区的语义表达和可访问性。一个好的输入区不仅能收集内容，还应尽量减少用户犯错的概率。

### 4. 操作类控件，要表达动作而不是只提供点击

按钮类控件的重点不是“点了能触发事件”，而是要表达动作的优先级和风险等级。官方按钮文档把按钮定义为“向用户传达点击后会发生什么动作的控件”，这句话很值得记住。页面上最常见的问题不是没有按钮，而是按钮太多、太像、太模糊：所有按钮样式都一样，看不出主操作和次操作；删除、提交、取消没有清晰区分；按钮文案只写“确定”，却不说明具体动作。

按钮控件的选择和样式，本质上服务于任务表达，而不是单纯点击能力。在现代 Android 项目里，主操作往往会优先使用 Material 组件风格的按钮，以获得更一致的视觉反馈和主题整合能力。什么时候该把某个动作做成主要按钮，什么时候只放成文字操作或图标按钮，本质上都属于页面信息架构的一部分。

### 5. 选择与状态类控件，适合表达有限分支

勾选框、单选项、Switch 等控件特别适合表达有限且明确的选择。关键不在于“它能切换状态”，而在于：这个状态是否足够简单，值得直接露出；用户是否能在当前上下文里理解开和关的含义；状态变更后页面是否立即反馈。官方关于切换控件的文档也明确建议，在 View-based 布局中优先考虑 `SwitchMaterial`，因为它更符合当前 Material 体系的交互和视觉规范。

如果一个状态切换的后果非常复杂，却仍然用一个简单开关承载，就很容易让用户困惑。比如，一个开关如果实际上会触发多层权限申请、后台任务变化和通知行为调整，仅靠“开/关”本身往往不够，页面还需要给出解释和反馈。控件选对了，只是开始；上下文是否充分，决定了用户能不能真正理解它。

### 6. 图像类控件，不只是“显示一张图”

`ImageView` 或其他图像承载控件的意义，也不只是显示一张图。它经常参与列表封面展示、用户头像、商品图、状态图标、空状态插图等场景。只要控件开始承载图像，你就不能只关心图片路径本身，还要同时考虑尺寸、裁切方式、占位图、加载失败和内容描述。

这也是很多页面在早期看似没问题、后期却迅速变乱的原因之一。图像类控件如果没有明确尺寸和语义，很容易让列表项高度不稳定、图片比例失控、辅助功能读不出内容，甚至在加载失败时留下大片空白。图像不是点缀，它往往和信息结构本身绑定在一起。

### 7. 为什么 Material 组件值得优先考虑

现代 Android 项目里，很多基础控件的现实用法已经不再是最原始的系统控件，而是 Material 组件体系。原因不只是“看起来更现代”，更重要的是它提供了更稳定的视觉规范、状态反馈和主题集成能力。以输入区为例，`TextInputLayout` 已经把标签、错误、辅助信息等常见需求整合成更成熟的组件模型；以开关为例，`SwitchMaterial` 能更自然地融入 Material 风格页面。

这也是为什么本书后续示例会尽量优先使用 Material 风格组件，而不是只展示最早期的原始控件。学习控件时，读者要逐步建立一个现实认知：原生基础控件仍然重要，但真正的项目实践往往是在它们之上再结合 AndroidX 和 Material 组件体系。

### 8. 最小示例：一个最小资料表单由哪些控件组成

下面这个例子演示一个最小资料填写页面。它的重点不是表单多复杂，而是观察不同控件如何共同承担页面任务。

```xml
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <TextView
        android:id="@+id/titleText"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="@string/profile_title"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/nameInputLayout"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:hint="@string/name_label"
        app:layout_constraintTop_toBottomOf="@id/titleText"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/nameInput"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:inputType="textPersonName" />
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.switchmaterial.SwitchMaterial
        android:id="@+id/notifySwitch"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="@string/enable_notify"
        app:layout_constraintTop_toBottomOf="@id/nameInputLayout"
        app:layout_constraintStart_toStartOf="parent" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/saveButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="@string/save"
        app:layout_constraintTop_toBottomOf="@id/notifySwitch"
        app:layout_constraintEnd_toEndOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

这段代码展示了一个非常重要的事实：真实页面里的控件几乎总是成组出现，而不是孤立存在。标题控件负责建立页面语义，输入控件负责收集信息，开关负责表达简单状态选择，按钮负责承接主要操作。你学习控件时，始终应该带着“它在当前任务里扮演什么角色”的问题，而不是只记它的名字和属性。

### 9. 实践任务

起点条件：

- 已完成上一章的布局练习。
- 当前工程可以编辑 XML 布局并运行到设备。

步骤：

1. 做一个简单资料填写页面，至少包含标题、两个输入框、一个开关和一个提交按钮。
2. 给两个输入框分别设置合适的标签和 `inputType`。
3. 给其中一个输入框补上错误提示或辅助说明。
4. 检查页面中的控件文案是否都来自资源文件。
5. 运行页面，观察在未输入、输入错误和输入完成时，页面语义是否仍然清晰。

预期结果：

- 你能做出一个最小但语义完整的表单页面。
- 输入区不再只是“两个空白框”，而是带有明确标签和状态反馈。
- 主操作、状态切换和信息展示在页面上职责分明。

自检方式：

- 你能为每个控件说出一句话：它在这个页面里承担什么任务。
- 你能指出哪个控件负责信息展示，哪个负责输入，哪个负责状态选择，哪个负责主操作。
- 你能判断一个控件如果被替换成别的控件，页面语义会不会变差。

调试提示：

- 如果输入框提示和样式表现异常，先检查 `TextInputEditText` 是否放在 `TextInputLayout` 内部。
- 如果键盘类型不对，先检查 `android:inputType` 是否与场景匹配。
- 如果页面看起来“能用但很乱”，优先回头检查控件职责是否清楚，而不是先补动画和颜色。

### 10. 常见误区

- 把控件学习理解成控件名字背诵。
- 所有操作都用按钮，所有状态都用文本伪装。
- 输入框没有标签、没有校验、没有错误反馈。
- 只关心能显示，不关心可访问性和语义。

## 小结

控件不是页面的零件仓库，而是页面语义和任务流程的具体承载。真正重要的，不是你认识多少个控件名字，而是能否根据任务选择合适控件，并让信息展示、用户输入、状态切换和主操作形成清晰分工。

下一章我们会继续讨论，当这些控件被用户真正操作时，事件应该如何组织，页面又该如何对这些交互做出稳定反馈。


## 参考资料

- 按钮：<https://developer.android.com/develop/ui/views/components/button>
- 切换控件：<https://developer.android.com/develop/ui/views/components/togglebutton>
- 输入类型：<https://developer.android.com/training/keyboard-input/style>
- TextInputLayout：<https://developer.android.com/reference/com/google/android/material/textfield/TextInputLayout>
- TextInputEditText：<https://developer.android.com/reference/com/google/android/material/textfield/TextInputEditText>
