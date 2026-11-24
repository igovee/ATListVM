# 自动布局示例扩充实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给自动布局分类补 9 条 demo —— 业务场景 5 条（异步照片撑高、宽度变化、展开收起、空态、卡片内嵌横向）与边界情况 4 条（insert 三连、超长列表、极端高度、整表重载），使自动分类从 5 条扩到 14 条。

**Architecture:** 新增两个文件 `AutoSceneDemos.swift` / `AutoBoundaryDemos.swift`，各自用 `enum` 暴露 `entries: [DemoEntry]`；`AutoDemos.entries` 按「现有 4 条 + 业务 5 条 + 边界 4 条 + 社区」拼装。每条 demo 复用 `DemoListViewController`（说明 + 列表）与 `DemoTextCell`，只有需要特殊 cell 时才新写。

**Tech Stack:** Swift 5 / UIKit / SnapKit / ATListVM（本地 pod）

**Spec:** `docs/superpowers/specs/2026-11-24-auto-demo-scenarios-design.md`

## Global Constraints

- **只改 `Example/`，不改库。** 某条 demo 若暴露库缺陷，只记录、不当场修。
- 每个新增 `.swift` 必须补齐 `Example/ATListVM.xcodeproj/project.pbxproj` 四处：`PBXBuildFile`、`PBXFileReference`、分组 `children`、target 的 `Sources`。
- 不改 `DemoMenuViewController`（已定平铺方案）。
- 复用 `DemoShared.swift` 的 `DemoListViewController` / `DemoTextCell` / `DemoTextItemVM`；特殊 cell 才新写。
- iOS 13 / Swift 5，不引入依赖。
- **不自动提交**：每个任务的 commit 步骤替换为「向用户汇报改动清单」。

## Review Focus

- **pbxproj 漏登记** → `cannot find 'XxxViewController' in scope`。
- **异步撑高用错 block**：`refreshItemBlock` 不触发重新测量，图片「加载完成」后高度不会变，必须用 `reloadItemBlock`。
- **嵌套横向内容没有显式高度**：`UIScrollView` / 横向列表没有固有高度时，`systemLayoutSizeFitting` 会算出 0，卡片塌成一条线。
- **空态时 header 仍占位**：`headerId` 设了就会渲染 header，即使该 section 没有 item；空态需要显式处理。
- **宽度变化后不重测**：`preferredLayoutAttributesFitting` 按 `collectionView.bounds.width` 量，容器变宽后已排好的 cell 未必重新测——若 demo 显示高度不更新，记录，不改库。

---

### Task 1: 业务场景 5 条 + 文件骨架

**Files:**
- Create: `Example/ATListVM/AutoSceneDemos.swift`、`Example/ATListVM/AutoBoundaryDemos.swift`（后者本任务只放空 `entries`）
- Modify: `Example/ATListVM/AutoDemos.swift`（拼装 entries）
- Modify: `Example/ATListVM.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `DemoEntry`、`DemoListViewController`、`DemoTextCell`、`DemoTextItemVM`（既有）
- Produces: `enum AutoSceneDemos { static let entries: [DemoEntry] }`（5 条）、`enum AutoBoundaryDemos { static let entries: [DemoEntry] }`（Task 2 填充）

- [ ] **Step 1: 建骨架并登记**

`AutoBoundaryDemos.swift` 只放 `static let entries: [DemoEntry] = []`。把两个文件登记进 pbxproj 四处。

- [ ] **Step 2: 接线菜单**

`AutoDemos.entries` 改为：

```swift
[纵向, 横向, 混合, header/footer] + AutoSceneDemos.entries + AutoBoundaryDemos.entries + CommunityDemo.entries
```

顺带把「混合」「header / footer」两条的 `detail` 前缀补成「业务场景 ·」以外的中性描述（这两条属于基础用法，不加前缀）。

- [ ] **Step 3: 业务场景 5 条**

| 条目 | 实现要点 |
|---|---|
| 图片异步加载撑高 | `AsyncImageItemVM`（`loaded: Bool`、`aspect: CGFloat`）；cell 里一个占位块，高度约束常量在 120 / 240 间切；`viewDidAppear` 后 1.5 秒把前 3 条的 `loaded` 置真并调 `reloadItemBlock`。说明写「异步内容回来必须 reloadItemBlock」 |
| 宽度变化重排 | VC 顶部三颗按钮改 collectionView 宽度约束（320/375/414）；条目为多行文本；切宽度后调 `collectionView.collectionViewLayout.invalidateLayout()`，并在说明里点出「宽度是测量 key」 |
| 展开 / 收起 | 复用 `DemoTextCell` 不行（需要按钮），新写 `ExpandCell`：标题 + 正文 + 「展开全文」按钮；翻 `expanded` 调 `reloadItemBlock`；按钮在 cell 内，需要避免触发选中 |
| 空态 / 只有 header / 单条 | 三颗按钮切 `sectionVMs` 数据量并 `reloadListBlock`；空态时把 `headerId` 也清掉，说明写清「空态要去掉 headerId，否则 header 仍占位」 |
| 卡片内嵌横向列表 | `CardWithTagsCell`：卡片里纵向标题 + 一行横向 `UIScrollView`（内含标签 `UIStackView`）；横滑容器必须给显式高度约束（36），否则自适应算出 0 |

- [ ] **Step 4: 构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`，0 项目源码 warning

- [ ] **Step 5: 截图验证（临时探针，用完还原）**

临时在 `AppDelegate` 里按顺序 push 三条：图片异步加载撑高（截两张，间隔 2 秒看高度变化）、宽度变化重排（截一张）、卡片内嵌横向列表（截一张）。还原 `AppDelegate` 并重新构建。

- [ ] **Step 6: 汇报（不 commit）**

---

### Task 2: 边界情况 4 条

**Files:**
- Modify: `Example/ATListVM/AutoBoundaryDemos.swift`

**Interfaces:**
- Consumes: `DemoEntry`、`DemoListViewController`（Task 1 已登记文件）
- Produces: `AutoBoundaryDemos.entries` 的 4 条

- [ ] **Step 1: insert / append 三种用法**

三颗按钮：末尾追加（`append`）、中间插入（`insert(at: count/2)`）、同一轮连续两次（两次 `append`）。底部日志显示插入位置与「插入点之后第一条现在的 indexPath」，让索引重编号可见。说明写「不要从 willDisplay 里调用」。

- [ ] **Step 2: 超长列表 120 条**

120 条，文本行数在 1–3 间循环。说明写「滚动时 contentSize 会先估后准，滚动条长度会变」。

- [ ] **Step 3: 极端高度混排**

30pt 与 600pt 交替：`DemoTextItemVM` 的 `itemSize` 不给值（走自适应），cell 用一个固定高度约束的色块把高度撑到 30 / 600。需要新 cell：`ExtremeHeightCell`。

- [ ] **Step 4: 整表重载**

一颗按钮：换一批数据后 `reloadListBlock`，并 `collectionView.setContentOffset(.zero, animated: false)`，说明写「重载后高度按新内容重算」。

- [ ] **Step 5: 构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`，0 项目源码 warning

- [ ] **Step 6: 截图验证（临时探针，用完还原）**

push「insert / append」与「超长列表」各截一张；还原 `AppDelegate` 并重新构建。

- [ ] **Step 7: 汇报（不 commit）**

---

## 交付后：人工验收（需要用户）

进「自动布局」，把新增 9 条各点一遍。重点：
- 图片异步加载：1.5 秒后卡片是否变高
- 宽度变化：切 320 / 414 后文本是否重新折行、高度是否变
- insert 三种用法：新行是否出现、日志里的 indexPath 是否正确
- 超长列表：能否顺滑滚到第 120 条

## 自检结果

- **Spec 覆盖**：业务 5 条（Task 1）、边界 4 条（Task 2）、平铺菜单与顺序（Task 1 Step 2）、只动 Example（Global Constraints）一一对应。
- **Review Focus 落点**：pbxproj（Task 1 Step 1）、刷新 vs 重载（Task 1 图片条目）、嵌套横向显式高度（Task 1 卡片条目）、空态 headerId（Task 1 空态条目）、宽度不重测（Task 1 宽度条目 + 只报告）。
- **已知缺口**：无自动化测试（Example 无可用 XCTest），验证靠构建 + 截图 + 人工。
