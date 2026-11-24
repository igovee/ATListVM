# 自动布局示例扩充（业务场景 + 边界情况）—— 设计稿

日期：2026-11-24
状态：待批准
规模：中（9 条新 demo，约 900–1100 行，只动 Example）

## 为什么做

自动分类现在 5 条：纵向、横向、混合、header/footer、社区信息流。它们覆盖了库的**配置项**，
但没覆盖使用者在真实页面里会卡住的两类情况：

- **业务场景**：图片异步加载后高度变化、宽度变化后重排、展开收起、空态、卡片内嵌横向列表。
- **边界情况**：动态插入、超长列表、极端高度、整表重载。

这两类是「照着抄」和「压边界」两种用途，缺一都会让示例变成配置说明而不是用法说明。

## 目标

- 自动分类从 5 条扩到 14 条：业务场景 5 条 + 边界情况 4 条，接在现有 4 条之后，社区信息流放最后。
- 每条 demo 都是独立可运行的页面，带一行「这条在演示什么」的说明。
- 只动 `Example/`，不改库。

## 非目标

- 不做两级菜单、不改 `DemoMenuViewController`（已定 A 方案：平铺，靠 `detail` 前缀区分组）。
- 不改库的既有行为。**如果某条 demo 暴露了库的缺陷，只报告，不当场改库。**
- 不做 iPad/横屏专项（宽度变化用可调宽容器模拟）。

## 反目标

- 为了让某条 demo 好看而给库加特例。
- 把示例写成「只有 UI、看不出用了哪个 API」的样子。

## 约束

- Example 工程没有文件夹同步：新增 2 个 `.swift` 必须登记进 `Example/ATListVM.xcodeproj/project.pbxproj` 四处。
- 复用 `DemoShared.swift` 里已有的 `DemoListViewController`（说明 + 列表）与 `DemoTextCell` / `DemoTextItemVM`，只在需要特殊 cell 时新写。
- iOS 13 / Swift 5，不引入依赖。

## 方案（菜单：平铺 vs 分节）

- **A（选中）平铺**：14 行仍在同一张 `insetGrouped` 表里，`detail` 以「业务场景 ·」/「边界 ·」开头。
  零菜单代码改动。
- B 分两节：需要把 `DemoMenuViewController` 改成接受分组，多改一个已验收的文件。

选 A：这一轮的价值在 demo 内容，菜单先不动。

## 九条 demo

### 业务场景组（`AutoSceneDemos.swift`）

| # | 条目 | 数据与交互 | 证明什么 |
|---|---|---|---|
| 1 | 图片异步加载撑高 | cell 里一个占位块，高度约束在 120 / 240 之间切；1.5 秒后「加载完成」，翻 `aspect` 并调 `reloadItemBlock` | 异步内容回来必须 `reloadItemBlock`；`refreshItemBlock` 撑不高 |
| 2 | 宽度变化重排 | 顶部三个按钮把列表宽度切到 320 / 375 / 414；条目是多行文本 | 宽度是测量 key，宽度变了高度要重算 |
| 3 | 展开 / 收起 | 长文本 + 「展开全文 / 收起」，翻 `expanded` 后 `reloadItemBlock` | 最常见的高度变化路径；也是「点 cell 内的按钮不要触发选中」的写法 |
| 4 | 空态 / 只有 header / 单条 | 三个按钮切数据量：0 条、只有 header 的 0 条、1 条 | 边界形态下 header、分区 inset、内容高度的表现 |
| 5 | 卡片内嵌横向列表 | 自适应卡片里放一行横向 `UIScrollView` + 标签 | 嵌套滚动的测量；横向内容不参与纵向高度计算 |

### 边界情况组（`AutoBoundaryDemos.swift`）

| # | 条目 | 数据与交互 | 证明什么 |
|---|---|---|---|
| 6 | insert / append 三种用法 | 三个按钮：末尾追加、中间插入、同一轮连续两次；底部日志显示插入位置与后继 item 的 `indexPath` | `insert` 的行为契约，索引重编号看得见 |
| 7 | 超长列表 120 条 | 120 条，行高在 1–3 行之间变化 | `contentSize` 从估到准的收敛过程（上次那个 bug 的正面演示） |
| 8 | 极端高度混排 | 30pt 与 600pt 交替 | 估算高度与真实高度差 20 倍时的排版行为 |
| 9 | 整表重载 | 一个按钮换一批数据后 `reloadListBlock` | 重载后高度是否还准 |

## 菜单顺序

```
纵向自适应高度 / 横向自适应宽度 / 混合 / header footer      ← 现有
业务场景 · 图片异步加载撑高
业务场景 · 宽度变化重排
业务场景 · 展开与收起
业务场景 · 空态 / 只有 header / 单条
业务场景 · 卡片内嵌横向列表
边界 · insert / append
边界 · 超长列表 120 条
边界 · 极端高度
边界 · 整表重载
社区信息流                                                 ← 现有，放最后当综合示例
```

`AutoDemos.entries` 变成：`[现有 4 条] + AutoSceneDemos.entries + AutoBoundaryDemos.entries + CommunityDemo.entries`。

## 可能踩到库的问题（先记录，不在本轮修）

- **第 2 条（宽度变化）**：`ATListCell.preferredLayoutAttributesFitting` 按 `collectionView.bounds.width`
  测量。容器变宽后，已排好的 cell 会不会重新测，取决于 FlowLayout 有没有被失效。
  如果没有，这条 demo 会直接暴露「改宽度后高度不更新」——**报告，不当场改库**。
- **第 8 条（极端高度）**：估算高度与真实高度差很大时，`contentSize` 的收敛会很明显，
  可能表现为滚动条长度突变。同样只记录。
- **第 5 条（嵌套横向）**：横向 `UIScrollView` 的固有高度需要显式约束，否则 `systemLayoutSizeFitting`
  会算成 0。

## 验证方式

- `xcodebuild` 构建通过，项目源码 0 warning。
- 逐屏截图：至少覆盖 1（异步撑高前后）、2（三种宽度）、6（三种插入）、7（滚到底）。
- 人工：14 条各点一遍，重点看 1、2、7。

## 留给实现者

- 文件划分：`AutoSceneDemos.swift`（业务 5 条）+ `AutoBoundaryDemos.swift`（边界 4 条），
  这样新增文件最少、pbxproj 只改两处。
- 第 4 条「空态」是否需要空态占位图 —— 我倾向用一个 label 说明，不做美术资源。
- 第 7 条要不要在页面上显示实时 `contentSize` —— 我倾向不加（会引导视线），靠滚动条长度观察即可。
