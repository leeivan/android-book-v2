# Jetpack Compose 基础

即使本书前面的 UI 主线仍以 View/XML 为主，现代 Android 开发已经无法绕开 Compose。本章的目标不是立刻把整本书都切到 Compose，而是帮助你建立声明式 UI 的第一层认知：界面不再主要通过“拿到视图对象然后修改它”来组织，而是直接根据当前状态声明“界面此刻应该长成什么样”。理解这一点，比记住任何单个 Compose 组件都更重要。

很多人初学 Compose 时，会先被“代码看起来不一样”吸引，接着开始背 `Column`、`Row`、`Modifier`、`remember` 和 `Text`。这样当然能写出一些例子，但很容易忽略 Compose 真正改变的不是控件表，而是 UI 建模方式。本章会把重点放在声明式思维、状态、重组和状态提升上，让你后面阅读现代项目时能看清组织逻辑，而不是只看到一堆陌生 API。

## 学习目标

- 理解 Compose 与 View/XML 在界面组织思路上的核心差异。
- 建立声明式 UI、状态驱动和重组的基本认知。
- 理解为什么 Compose 适合作为现代 Android UI 入口之一。
- 为后续阅读现代项目和理解 Material3 in Compose 打基础。

## 前置知识

- 已理解 View/XML 的布局、控件和事件处理方式。
- 已具备页面状态变化的基本概念。

## 正文

### 1. 为什么 Compose 值得单独成为一章

Compose 的意义不在于“Android 又多了一套 UI API”，而在于它改变了界面组织思路。View/XML 更强调先定义结构，拿到视图对象，然后在事件发生后不断修改对象状态。Compose 更强调先定义状态，再根据状态直接声明界面，状态变化后重新计算界面应该呈现的结果。这不是语法差异，而是建模方式差异。

Android 官方的 Thinking in Compose 文档把 composable 函数描述为“接收数据并发出 UI 元素的函数”。这句话非常关键。因为它说明 Compose 的核心不在于“实例化控件对象”，而在于“根据输入数据描述当前 UI”。只要这层认知建立起来，后面很多看似陌生的 Compose 写法都会变得自然。

### 2. 什么叫声明式 UI

所谓声明式 UI，并不是“代码更短”这么简单。它的核心意思是：你描述的是结果，而不是一连串命令式操作步骤。在 View/XML 世界里，你往往会创建或找到某个 View，再调用 setter 去改变它的文本、可见性、启用状态和样式。在 Compose 世界里，你更关注的是：当前状态是什么，在这个状态下界面应该显示什么。

Android 官方的 Compose state 文档也明确说明：Compose 是声明式的，更新 UI 的方式是再次用新的参数调用同一个 composable，而这些参数本身就是页面状态的表示。也就是说，Compose 不期待你到处手工改对象，而是希望你把状态变化当成 UI 变化的唯一来源。

### 3. 状态为什么成为 Compose 的中心

一旦 UI 由状态驱动，状态就成了 Compose 世界里最重要的基础设施。你在 Compose 中最需要持续问自己的问题是：这段界面依赖什么状态，状态归谁管理，状态变化后哪些界面会重新计算。这也是为什么 Compose 学习天然会和 ViewModel、单向数据流和状态提升这些概念绑在一起。

官方文档对 state 的定义非常宽泛：凡是会随时间变化的值，都可以是状态。一个计数器数字、一个输入框内容、一个列表数据源、一个 Snackbar 是否显示，都属于状态。只要你理解了这一点，Compose 页面就不再只是组件拼装，而是“状态如何流动”的问题。

### 4. 重组不是“整页重画”，而是按需重新计算

很多初学者一听到 Compose 会“重组”，就误以为每次状态变化都会把整个页面全盘重建。更合理的理解是：状态变化后，Compose 会重新执行相关的界面描述逻辑，并决定哪些部分需要更新。Thinking in Compose 文档明确指出，Compose 会尽可能只重组需要变化的部分，而跳过其余部分。

这意味着你不需要自己手工追踪每个控件该怎么更新，但也意味着你必须写出更适合重组的代码：尽量避免在 composable 中做昂贵操作，不要依赖副作用来“顺便”修改外部状态，要把 UI 写成真正根据输入参数描述结果的函数。Compose 不是帮你省掉思考，而是要求你用更稳定的方式思考 UI。

这里最容易犯的错，是把 composable 函数体当成“只会执行一次的初始化区”。一旦这样理解，开发者就会在函数体里直接发网络请求、写日志、改外部变量，结果是每次重组都可能重复触发副作用。更准确的认识是：composable 负责描述 UI，副作用则应通过 `LaunchedEffect`、`DisposableEffect` 等机制在明确生命周期里执行；更重的业务工作则继续留在 ViewModel 或数据层。只有把“界面描述”和“副作用执行”分开，Compose 代码才会稳定。

### 5. `remember`、`rememberSaveable` 和状态提升分别在解决什么问题

`remember` 的作用，是让某个值在重组之间保留下来。官方 state 文档明确说明，`remember` 会把对象存储在 Composition 中，并在重组时返回先前保存的值。它适合保存那些只需要在当前 Composition 生命周期中延续的本地状态。比如一个展开/收起状态、一个局部输入值、一个临时选中项。

但 `remember` 并不能跨配置变化自动保留状态。对于需要在 Activity 重建后继续保留的简单值，通常应考虑 `rememberSaveable`。而当状态规模变大、逻辑变复杂，或者你需要让多个 composable 共享同一份状态时，就不应该把所有东西都塞在某个子 composable 里，而应该把状态提升到更合适的位置。

状态提升的价值，在于让组件更可复用、状态来源更清晰，也更容易与 ViewModel 配合。Compose Architecture 文档把这套模式总结成单向数据流：state flows down，events flow up。也就是说，状态往下传，事件往上传。只要这个方向清晰，Compose 页面就更容易维护。

和这些概念经常一起出现的，还有 `Modifier`。它并不是“随手往组件后面串的一堆样式参数”，而是 Compose 里统一表达布局、绘制、交互和语义的链式机制。为什么 `padding()` 写在前后顺序会影响结果、为什么 `clickable()` 和 `background()` 的组合会改变点击区域，本质上都和 `Modifier` 的顺序有关。把 `Modifier` 当成 Compose 的结构语言，而不是零散样式开关，会更容易读懂真实项目里的界面代码。

### 6. 最小示例：一个状态驱动的计数器

下面这个极简例子可以帮助你观察 Compose 的核心思路：

```kotlin
@Composable
fun CounterScreen() {
    var count by rememberSaveable { mutableStateOf(0) }

    Column {
        Text(text = "当前计数：$count")
        Button(onClick = { count++ }) {
            Text("增加")
        }
    }
}
```

这个示例的重点不是 `Button` 或 `Text` 本身，而是你能否看出：`count` 是状态，界面显示取决于 `count`，点击按钮后状态变化，界面自然更新。你并没有去“找到某个文本控件再改它”，而是再次描述了“在最新状态下 UI 应该是什么样”。这正是 Compose 最核心的学习入口。

### 7. 从本地状态，走向状态提升

随着页面变复杂，你很快会发现：并不是所有状态都应该放在同一个 composable 内部。一个局部展开状态可以留在局部，但如果多个区域都依赖同一份数据，或者父组件需要统一控制行为，状态就应被提升。也就是说，把当前值和事件回调作为参数传给下层组件，让子组件更像“只负责展示和发事件”的单元。

这一步对阅读真实项目非常重要。因为现代 Compose 项目里，很多 composable 并不自己保存所有状态，而是接收来自 ViewModel、状态持有者或父级 composable 的参数，然后通过 `onClick`、`onValueChange` 等事件把意图往上发。只要这条数据流看清楚，Compose 代码就不会再像“层层嵌套的函数迷宫”。

下面这个例子把“本地状态”改成了“父级持有、子级展示”的写法：

```kotlin
@Composable
fun CounterRoute() {
    var count by rememberSaveable { mutableStateOf(0) }

    CounterContent(
        count = count,
        onIncrement = { count++ }
    )
}

@Composable
fun CounterContent(
    count: Int,
    onIncrement: () -> Unit
) {
    Column {
        Text(text = "当前计数：$count")
        Button(onClick = onIncrement) {
            Text("增加")
        }
    }
}
```

这个版本的关键不是代码更多了，而是角色更清楚了：`CounterRoute` 负责持有状态，`CounterContent` 负责根据状态渲染并把事件抛回去。很多官方样例项目，包括 `Now in Android`，都会把屏幕拆成 route 层和 content 层，本质上就是在贯彻这种“状态上提、展示下沉”的结构思路。

### 8. 为什么 Compose 和 Material 3 往往一起出现

在现代 Android 项目中，Compose 往往会和 Material 3 一起出现。原因很简单：Compose 提供声明式 UI 组织方式，Material 3 提供现代设计语言和组件体系。两者结合后，界面结构、状态驱动和设计系统更容易统一。Android 官方的 Material Design for Android 页面也直接指出：如果应用使用 Compose，可以使用 Compose Material 3 library。

这也是为什么理解 Compose 时，不要把它当成孤立 UI 技术。它和前一章的 Material 设计系统、和后续章节的状态管理、ViewModel、单向数据流都紧密相关。

### 9. 学 Compose 时，先抓思维模型，再扩组件表

Compose 最容易学偏的地方，是按 API 页面逐个认识 `Text`、`Button`、`Modifier` 和 `LazyColumn`，却没有先建立“状态驱动 UI”的核心直觉。更稳的顺序通常是：先理解声明式 UI 和重组，再做一个最小状态驱动页面，然后再通过布局练习和样例项目理解真实工程组织。这样你看到的就不是零散组件，而是界面如何随状态变化重新表达。

如果你还想继续扩展阅读，可以把附录“参考资料与后续学习路径”当作资料地图。那里会把 Compose 相关资料分成思维模型、布局练习和项目结构三类，不必在章内继续追着组件目录跑。

### 10. 实践任务

起点条件：

- 已能创建或打开一个最小 Compose 页面。
- 已具备基本 Kotlin 语法能力。

步骤：

1. 先实现一个最小计数器页面，观察状态变化如何驱动界面更新。
2. 把页面拆成显示区和操作区两个 composable，体验组合式结构。
3. 尝试把状态从子组件提升到父组件，观察数据流是否更清晰。
4. 再把局部状态从 `remember` 改成 `rememberSaveable`，体验它在配置变化后的区别。
5. 打开 `Jetpack Compose basics` 或 `Basic layouts in Compose` codelab，对照你自己的实现检查命名、结构和状态组织方式。
6. 用自己的话解释 Compose 与 View/XML 最大的思维差异是什么。

预期结果：

- 你能感受到 Compose 的核心不是“控件语法变化”，而是“状态驱动 UI”。
- 你能区分局部本地状态、可保存状态和应提升的状态。
- 你能看懂：为什么真实项目会把 route 层和 content 层拆开。
- 你开始习惯从“状态和事件”角度理解界面，而不是从“对象和 setter”角度理解界面。

自检方式：

- 你能解释：为什么 Compose 是声明式 UI。
- 你能说出：`remember` 和 `rememberSaveable` 各自解决什么问题。
- 你能判断：某个状态应该留在本地，还是应该被提升或交给 ViewModel。
- 你能解释：为什么只刷 Compose 组件 API 仍然可能学不会 Compose。

调试提示：

- 如果状态一变页面却没更新，先检查这个值是不是 Compose 可观察的状态。
- 如果每次重组状态都重置，先检查是否忘了使用 `remember` 或把状态放在了错误位置。
- 如果 composable 里开始出现大量逻辑判断和状态修改，通常说明该考虑状态提升或引入状态持有者了。
- 如果你写了很多 Compose 组件却仍然觉得“思路不清”，先回头做一遍官方 codelab，而不是继续堆新组件。

### 11. 常见误区

- 把 Compose 当成一套“新的控件表”。
- 只看语法糖，不理解状态驱动思想。
- 状态随意分散在多个组件里，导致数据流不清晰。
- 以为学了 Compose 就不需要理解 Android 平台基础。
- 只刷 API 或组件目录，却不做 codelab 和样例项目拆读。

## 小结

Compose 是现代 Android UI 的重要方向，但它不是平台基础的替代，而是一种更现代的界面组织方式。只要你先抓住声明式 UI、状态驱动、重组和状态提升这几条主线，后面阅读 Compose 项目就不会只看到一堆陌生 API，而能看清界面的组织逻辑。

至此，第 2 部分关于 View/XML 和 Compose 的基础桥接就基本搭好了。后续进入数据、架构和并发章节时，你会不断看到这里建立的“事件上行、状态下行、结构先行”的思路继续发挥作用。

## 参考资料

- 参考并改写自：Bill Phillips、Chris Stewart、Kristin Marsicano、Brian Gardner，《Android Programming: The Big Nerd Ranch Guide, 5th Edition》(2022)，第 26-29 章。
- 参考并改写自：Costeira R.，《Real-World Android by Tutorials, 2nd Edition》(2022)，Compose、状态与项目结构相关章节。
- 参考并改写自：Matt Bennett，《Scalable Android Applications in Kotlin and Jetpack Compose》(2025)，Compose 屏幕组织、状态持有与工程结构相关章节。

- Thinking in Compose：<https://developer.android.com/develop/ui/compose/mental-model>
- State and Jetpack Compose：<https://developer.android.com/develop/ui/compose/state>
- Compose UI Architecture：<https://developer.android.com/develop/ui/compose/architecture>
- Jetpack Compose basics codelab：<https://developer.android.com/codelabs/jetpack-compose-basics>
- Basic layouts in Compose codelab：<https://developer.android.com/codelabs/jetpack-compose-layouts>
- Material 3：<https://m3.material.io/>
- Now in Android：<https://github.com/android/nowinandroid>

