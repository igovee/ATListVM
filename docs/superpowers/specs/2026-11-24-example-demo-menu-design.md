# Example Demo 两级菜单设计

日期：2026-11-24
状态：待批准
规模：小改动（只动 Example，不动库）

## 为什么做

库重写后（拆成 4 个文件、新增 `attach(collectionView:)`、`ATListViewAutoProxy` 支持混合模式），
Example 首页只剩「纵向自适应高度 / 横向自适应宽度」两个自动类入口，手动的用法一条示例都没有，
自动类也只覆盖了两个方向的自适应。需要一个能当用法说明书看的两级示例集。

## 目标

- 首页两级：`手动布局` / `自动布局` 各进一个列表，列表里每条进一个可交互的 demo。
- 两类合起来覆盖 ATListVM 当前的公开用法，手动类覆盖 `ATListViewProxy` + `itemSize` 的全部写法。
- 自动类补一个复杂社区信息流，演示多 section + 九宫格 + 展开 + 点赞 + 加载更多。

## 非目标

- **不改库**（已定：社区示例的「加载更多」接受 `reloadSectionBlock` 的整段重建/重算）
- 不恢复 `insert(_:at:)` / `append(_:)`，也不做 `sectionIndex`
- 不做组合布局（`ATListSectionVM.layoutSection` 目前无消费方）
- 不改 `Main.storyboard` 的根控制器（仍是 `ViewController`），不加第三方依赖

## 反目标

- 为了让某个 demo 好看而去改库的默认行为。
- 菜单本身用 ATListVM 实现（菜单要简单可靠，直接用 `UITableView`/`UIStackView`，避免用被演示的东西证明自己）。

## 约束

- Example 工程**没有**文件夹同步，每个新增 `.swift` 必须同时登记进 `Example/ATListVM.xcodeproj/project.pbxproj`（PBXBuildFile / PBXFileReference / 分组 / Sources）。
- 现有 `AutoHeightDemoViewController.swift`、`AutoWidthDemoViewController.swift` 原样保留，只换入口。
- 部署目标 13.0，语言 Swift 5。

## 考虑过的方案

- **A（选中）**：社区示例的「加载更多」用 `reloadSectionBlock`，不动库。
  代价：点完「加载更多」再往上滑，整段重建会有一次重算/跳动。
- **B**：把 `insert` 加回库，社区示例演示「只插新行」。
  代价：重做昨天被回退的库改动（含 indexPath 重编号、一致性校验），并把「示例需求」变成「库改需求」。
- **C**：社区示例不做加载更多，一次性给足数据。

选 A：示例的价值在于覆盖用法，库的改动应该由库自己的需求驱动；B 会让这一轮从「改 demo」变成「改库 + 改 demo」。

## 设计

### 菜单结构

```
首页 (ViewController)
├── 手动布局 → ManualMenu (7 条)
│   ├── 固定尺寸
│   ├── 两列
│   ├── header / footer
│   ├── 单 section
│   ├── 手算高度
│   ├── 刷新与 reload
│   └── 选中与显示回调
└── 自动布局 → AutoMenu (5 条)
    ├── 纵向自适应高度      （现有 VC）
    ├── 横向自适应宽度      （现有 VC）
    ├── 混合：手动 + 自适应
    ├── header / footer
    └── 社区信息流          （复杂示例）
```

首页用两个大按钮（沿用现在 `ViewController` 的样式）；两张列表用同一个通用 `DemoMenuViewController`
（`UITableView` + `DemoEntry` 数组），每行标题 + 一行说明 + `>` 箭头。

### 每条 demo 要展示的 API

| demo | 用到的 API |
|---|---|
| 固定尺寸 | `itemSize` 三档高度、`minimumLineSpacing`、`sectionInset` |
| 两列 | 半宽 `itemSize`、`minimumInteritemSpacing` |
| header / footer | `headerId` / `footerId`、`headerSize` / `footerSize`、`ATListReuseableView.refreshSubviews` |
| 单 section | `viewProxy.defaultSectionVM`（不填 `sectionVMs`） |
| 手算高度 | `layoutSubviews` 摆放子视图 + 手动算出的 `itemSize` |
| 刷新与 reload | `refreshItemBlock`（只改可见 cell）、`reloadItemBlock`、`reloadSectionBlock`（追加行）、`reloadListBlock` |
| 选中与显示回调 | `onSelectItemBlock`、`itemVM.willDisplay` / `didEndDisplaying`、`ATListViewProxyDelegate`（cell/header/footer）、`ATListVMDelegate.listVMDidChange` |

| demo | 用到的 API |
|---|---|
| 纵向自适应高度 | 现有：`ATListViewAutoProxy` + `preferredLayoutAttributesFitting` |
| 横向自适应宽度 | 现有：同上，`scrollDirection == .horizontal` |
| 混合 | 同一列表内：`itemSize` 双轴都有值的 item 走手动，其余走 `automaticSize` |
| header / footer | 自适应列表里 header 仍只认 `headerSize`，不参与自适应 |
| 社区信息流 | 见下 |

### 社区信息流

四个 section：搜索条 / 推荐话题 / 帖子 / 评论预览。帖子 cell：头像 + 昵称 + 正文 + 九宫格（1/3/9 张）+ 标签 + 赞/评论行。

- **展开正文 → `reloadItemBlock`**：`refreshItemBlock` 不触发重新测量，高度不会变（已确认）。
- **点赞 → `refreshItemBlock`**：只改数字、高度不变，正好演示「不用重建」。
- **加载更多 → `reloadSectionBlock`**：接受整段重建；按钮上写一句「这里会重算整段，是 reloadSections 的固有代价」。
- 底部一条事件标签，显示 `willDisplay` / proxy delegate / `listVMDidChange` 的回调。

### 文件划分

新增：
- `DemoShared.swift` — `DemoEntry`、`DemoMenuViewController`、手动类公用 cell / itemVM、section 标题视图
- `ManualLayoutDemos.swift` — 固定尺寸 / 两列 / header footer / 单 section / 手算高度
- `ManualBehaviorDemos.swift` — 刷新与 reload / 选中与显示回调
- `AutoDemos.swift` — 混合 / header footer
- `CommunityDemo.swift` — 社区信息流

改动：
- `ViewController.swift` — 首页改成两个分类入口
- `Example/ATListVM.xcodeproj/project.pbxproj` — 登记 5 个新文件

保留：`AutoHeightDemoViewController.swift`、`AutoWidthDemoViewController.swift`。

## 验证方式

- `xcodebuild -workspace ATListVM.xcworkspace -scheme ATListVM-Example -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`，项目源码 0 warning。
- 人工点一遍（需要你）：首页 → 两张列表 → 12 条 demo，重点看社区示例的展开/点赞/加载更多。

## 留给实现者（我的建议，可改）

- `DemoEntry` 用 `struct { title, detail, make: () -> UIViewController }`，与之前的实现一致。
- 手动类 7 条 demo 尽量共用同一个 `DemoTextCell`（一个 label + 一个副标题），差异只放在 VM 的 `itemSize` 和 section 配置上，让「用法差异」一眼看出来。
- 每条 demo 的 VC 顶部加一行小字说明「这条在演示什么」，避免示例变成纯 UI。
