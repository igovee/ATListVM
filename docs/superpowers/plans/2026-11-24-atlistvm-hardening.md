# ATListVM 健壮性修复实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修掉 3 个静默失效缺陷 + 3 个 API 陷阱，并给库建立第一套 windowed 回归测试；全程不改变 GoveeHome 现有调用点的语义。

**Architecture:** 先写测试证明问题存在（3 条会红），再改库让它们变绿；最后跑示例与全量测试做回归。库内改动集中在 `ATListViewProxyBase` / `ATListItemVM` / `ATListSectionVM` / `ATListViewAutoProxy` 四个文件。

**Tech Stack:** Swift 5 / UIKit / XCTest（`ATListVM_Tests` target，host = 示例 App）

**Spec:** `docs/superpowers/specs/2026-11-24-atlistvm-hardening-design.md`

## Global Constraints

- **不改 `defaultSectionVM` 行为**；不改 podspec 版本；不改 GoveeHome 任何文件。
- 不新增公开协议方法；除 `isReadyForItemRefresh` 外不新增公开符号。
- 不给 `reloadItemBlock` / `refreshItemBlock` 加断言（GoveeHome 真实调用中，断言会炸它们的 Debug 包）。
- 测试文件沿用 `Example/Tests/Tests.swift` 路径，只换内容，不动 pbxproj。
- 不自动提交；每个任务末尾汇报改动清单。

## Review Focus

- **断言误伤**：任何加到 item 级刷新块的断言都会让使用方 Debug 崩。只能在 AutoProxy 那条 GoveeHome 不用的路径上加断言。
- **测试时序**：库内块全部 `DispatchQueue.main.async`，断言前必须把主队列跑空（不用 `sleep`，用 expectation / runloop 自旋）。
- **越界崩溃无法用 XCTest 直接断言**：`reloadItems(at:)` 越界抛的是 NSException，会让整个测试进程崩，不是 fail。这条用代码评审 + 手动探针验，不写成用例。
- **section.indexPath 删除**：删完 `refreshHeaderBlock` 仍要能命中；这是公开 API 删除，需随版本说明。

---

### Task 1: 测试骨架与 5 条用例（先红）

**Files:**
- Modify: `Example/Tests/Tests.swift`（整文件替换）

**Interfaces:**
- Produces（文件内私有）：
  - `final class SpyCell: ATListCell` —— `var refreshCount = 0`，重写 `refreshSubviews(isFromVM:)` 累加
  - `final class SpyHeader: ATListReuseableView` / `SpyFooter` —— 同上，`static let reuseId`
  - `final class TestItemVM: ATListItemVM` —— `var text = ""`
  - `final class TestListVM: ATListVM` —— 注册 SpyCell/SpyHeader/SpyFooter，`createData()` 建 1–2 个 section
  - `final class Harness` —— 持有 `UIWindow` / `UICollectionView`(FlowLayout) / `ATListViewProxy` / `TestListVM`；方法 `layout()` 与 `waitMainQueue()`

- [ ] **Step 1: 写 harness**

要点：`UIWindow(frame: UIScreen.main.bounds)` + `makeKeyAndVisible()`；collectionView 加到 window，
`config(listVM:)` + `config(viewProxy:)`；`layout()` 里 `collectionView.layoutIfNeeded()`；
`waitMainQueue()` 用 `RunLoop.main.run(until: Date().addingTimeInterval(0.05))`。

- [ ] **Step 2: 写 5 条用例**

| 用例 | 断言 | 修前预期 |
|---|---|---|
| `testRefreshItemBlockUpdatesVisibleCell` | cell 的 `refreshCount` 从 0 变 1 | 绿 |
| `testReloadItemBlockAppliesNewItemSize` | 改 `itemSize.height` 后 cell 高度变化 | 绿 |
| `testRefreshHeaderBlockReachesHeader` | header 的 `refreshCount` 变 1 | **红** |
| `testRefreshFooterBlockReachesFooter` | footer 的 `refreshCount` 变 1 | **红** |
| `testRefreshHeaderBlockTargetsItsOwnSection` | 两段时刷第 1 段，第 0 段 spy 计数保持 0 | **红** |

- [ ] **Step 3: 跑测试，记录红态**

Run:
```bash
xcodebuild test -workspace Example/ATListVM.xcworkspace -scheme ATListVM-Example \
  -destination 'platform=iOS Simulator,name=DSH iPhone' \
  -derivedDataPath Example/build/demo/derived 2>&1 | tail -40
```
Expected: 5 条里 3 条失败（header / footer / 第 1 段），2 条通过。把失败信息原文记录下来。

- [ ] **Step 4: 汇报（不 commit）**

---

### Task 2: 库内 6 项修复（让测试变绿）

**Files:**
- Modify: `ATListVM/Classes/ATListViewProxyBase.swift`
- Modify: `ATListVM/Classes/ATListItemVM.swift`
- Modify: `ATListVM/Classes/ATListSectionVM.swift`
- Modify: `ATListVM/Classes/ATListViewAutoProxy.swift`

**Interfaces:**
- Consumes: Task 1 的 5 条用例
- Produces: `ATListItemVM.isReadyForItemRefresh: Bool`（新增唯一公开符号）

- [ ] **Step 1: 删掉 `ATListSectionVM.indexPath`**

`section` 已是唯一真源（`numberOfItemsInSection` 里赋值，空 section 也有值）。删除属性；
`reloadSectionBlock` / `refreshHeaderBlock` / `refreshFooterBlock` 改 `guard let section = self.section else { return }`；
`ATListViewProxyBase` 删掉写入。**这是公开 API 删除**，随 0.1.3 一起发。

- [ ] **Step 2: 加 `isReadyForItemRefresh`**

`ATListItemVM` 里加 `public var isReadyForItemRefresh: Bool { indexPath != nil }`，并给
`refreshItemBlock` / `reloadItemBlock` 补注释说明"未上屏时是 no-op，用 isReadyForItemRefresh 判断"。

- [ ] **Step 3: 越界保护**

`reloadItemBlock` 与 `reloadSectionBlock` 的 dispatch 闭包内，调用 UIKit 前校验：
section 在 `numberOfSections` 内、item 在 `numberOfItems(inSection:)` 内；不满足直接 return。
`ATListSectionVM.reloadSectionBlock` 同样校验 `section < numberOfSections`。

- [ ] **Step 4: `insert` 失败自愈**

`ATListSectionVM.insert` 的断言分支补一次 `collectionView.reloadData()` 再 return。

- [ ] **Step 5: AutoProxy 断言**

`ATListViewAutoProxy.attach` 里 `guard let flow = ... as? UICollectionViewFlowLayout else` →
`assertionFailure("ATListViewAutoProxy 需要 UICollectionViewFlowLayout")` 后 return。

- [ ] **Step 6: 访问级别对齐**

`ATListItemVM` 四个 block：`public fileprivate(set)` → `public internal(set)`。

- [ ] **Step 7: 跑测试，记录绿态**

Run: 同 Task 1 Step 3。
Expected: 5 条全绿。

- [ ] **Step 8: 汇报（不 commit）**

---

### Task 3: 回归验证

**Files:** 无新增（只验证）

- [ ] **Step 1: 示例构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 2: 全量测试**

Run: 同 Task 1 Step 3。
Expected: 5/5 通过。

- [ ] **Step 3: 页面回归截图**

用临时探针依次进「动态刷新」「社区信息流」各截一张，与修改前对比（表头/表尾刷新、
行高变化、只刷单行都应和之前一致）。截完删探针，`grep "TEMP PROBE"` 应为空。

- [ ] **Step 4: 越界保护人工验证**

探针里造一条 item、手动把 `indexPath` 设成越界值再调 `reloadItemBlock`，确认不再抛异常
（不写成 XCTest 用例的原因见 Review Focus）。

- [ ] **Step 5: 差异复核**

Run: `git diff --stat ATListVM/`
Expected: 只有 4 个文件；`git diff` 里没有除 `isReadyForItemRefresh` 外的公开符号新增。

- [ ] **Step 6: 汇报最终状态**
