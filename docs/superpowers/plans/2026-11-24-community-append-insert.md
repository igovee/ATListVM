# 增量插入进库实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 `ATListSectionVM` 补上 `insert(_:at:)` / `append(_:)`，做到「只插新行，已有 cell 不重建、不重新量高」，并用它替换社区示例的 `reloadSectionBlock`，消除追加后上滑的抖动。

**Architecture:** `ATListSectionVM` 在 `numberOfItemsInSection` 时记住自己的 `sectionIndex`；`insert` 同步改数据、校验行数、`performBatchUpdates { insertItems }`、再重编号插入点之后 item 与可见 cell 的 `indexPath`。示例的 `appendPost` 收成一行调用。

**Tech Stack:** Swift 5 / UIKit / UICollectionViewFlowLayout（布局级 self-sizing）

**Spec:** `docs/superpowers/specs/2026-11-24-community-append-insert-design.md`

## Global Constraints

- 只改这三个文件：`ATListVM/Classes/ATListVM.swift`、`ATListVM/Classes/ATListViewProxyBase.swift`、`Example/ATListVM/CommunityDemo.swift`。
- 不改 `reloadListBlock` / `reloadSectionBlock` / `reloadItemBlock` 的既有行为。
- 插入是**同步**的（设计稿已定）：数据变更与 `insertItems` 必须在同一轮 runloop。
- `ATListSectionVM` 的扩展写在 `ATListVM.swift` 内，以便直接使用 `fileprivate(set)` 的 `indexPath`，不放宽访问级别。
- iOS 13 / Swift 5，不引入依赖。
- **不自动提交**（沿用既有约定）：每个任务的 commit 步骤替换为「向用户汇报改动清单」。

## Review Focus

- **同轮约束**：数据变更与 `insertItems` 之间夹进一次 layout，UIKit 的旧行数会被顶成新行数 → 数量不匹配硬崩，且 stderr / crash report 为空。
- **重编号只碰已显示过的 item**：`indexPath == nil` 的行说明从没上过屏，给它写 indexPath 会让 `refreshItemBlock` 去打一个不存在的位置。
- **可见 cell 的 indexPath 同步**：`ATListCell.indexPath` 是 `private(set)`，必须通过类内部方法 `syncIndexPath(_:)`，不能从外部赋值。
- **索引越界**：负数与 `> itemVMs.count` 都要夹紧，不能 trap 在 `Array.insert`。
- **列表未显示时调用**：`collectionView` / `sectionIndex` 为 nil 时只保留数据变更、不崩；这条路径在 DEBUG 会 `assertionFailure`，验证脚手架用 `-O` 编译绕开。

---

## 验证脚手架（Task 1 内建立，Task 2 复用）

`xcodebuild test` 在本环境无法分配 pty，沿用之前验证过的做法：把库源码编进一个最小 iOS app，跑断言，结果写进 app 的 Documents，再用 `simctl` 读出来。

**Files（都在 gitignore 的 `Example/build/` 下，不进版本库）:**
- `Example/build/verify/main.swift`
- `Example/build/verify/Info.plist`
- `Example/build/verify/run.sh`

`run.sh` 固定做五件事：`swiftc -O` 编译 `main.swift` + `ATListVM/Classes/` 下全部 4 个 .swift → 装进已启动的模拟器 → 启动 → `sleep 4` → `cat` app Documents 里的 `result.txt`，并 grep `RESULT: ALL PASS` 决定退出码。

---

### Task 1: sectionIndex 管道

**Files:**
- Modify: `ATListVM/Classes/ATListVM.swift`（`ATListSectionVM` 属性区）
- Modify: `ATListVM/Classes/ATListViewProxyBase.swift`（`numberOfItemsInSection`）
- Create: `Example/build/verify/main.swift`、`Info.plist`、`run.sh`

**Interfaces:**
- Consumes: 无
- Produces: `ATListSectionVM.sectionIndex: Int?`（`public fileprivate(set)`）。Task 2 依赖它。

- [ ] **Step 1: 建立脚手架并写入会失败的断言**

`main.swift`：一个 `UIApplicationMain` 起的最小 app；`Harness.run()` 里建立 3 section（每 section 2 条）的自动撑高列表，`config(listVM:)` + `config(viewProxy:)` + `createData()` + `reloadData()` + `layoutIfNeeded()`，断言：

```swift
check(vm.viewProxy.sectionVMs[0].sectionIndex == 0, "T1 section0 index", "...")
check(vm.viewProxy.sectionVMs[1].sectionIndex == 1, "T1 section1 index", "...")
check(vm.viewProxy.sectionVMs[2].sectionIndex == 2, "T1 section2 index", "...")
```

断言结果每写一条就落盘一次（`check` 内部 flush），最后写 `RESULT: ALL PASS` / `RESULT: N FAILURE(S)`。

- [ ] **Step 2: 运行，确认失败**

Run: `bash Example/build/verify/run.sh`
Expected: 编译失败，报 `value of type 'ATListSectionVM' has no member 'sectionIndex'`

- [ ] **Step 3: 实现**

1. `ATListSectionVM` 里加：
   ```swift
   /// 该 section 在 collectionView 里的下标。numberOfItemsInSection 时赋值。
   public fileprivate(set) var sectionIndex: Int?
   ```
2. `ATListViewProxyBase.collectionView(_:numberOfItemsInSection:)` 里，与既有 `sectionVM?.collectionView = collectionView` 并列加一行 `sectionVM?.sectionIndex = section`。

- [ ] **Step 4: 运行，确认通过**

Run: `bash Example/build/verify/run.sh`
Expected: 3 行 `PASS` + `RESULT: ALL PASS`

- [ ] **Step 5: 汇报（不 commit）**

---

### Task 2: insert / append + 索引重编号

**Files:**
- Modify: `ATListVM/Classes/ATListVM.swift`（`ATListCell` 加内部方法、`ATListSectionVM` 扩展）
- Modify: `Example/build/verify/main.swift`（新增断言）

**Interfaces:**
- Consumes: `ATListSectionVM.sectionIndex`（Task 1）
- Produces:
  ```swift
  extension ATListSectionVM {
      public func insert(_ itemVM: ATListItemVM, at index: Int)
      public func append(_ itemVM: ATListItemVM)
  }
  ```

- [ ] **Step 1: 写入会失败的断言**

一个 section、5 条自动撑高 item（第 i 条 i+1 行，高度各不相同）。`layoutIfNeeded()` 后记录 item 0/1 的 `frame`、`contentOffset`、每个 item 的 `refreshSubviews` 次数（cell 内的静态计数表，key 用 item 的文本）。然后 `section.insert(newItem, at: 2)`，再 `layoutIfNeeded()`，断言：

```swift
check(sec.itemVMs.count == 6, "T2 count", "...")
check(same(attr(0), before0), "T2 item0 unchanged", "...")
check(same(attr(1), before1), "T2 item1 unchanged", "...")
check(abs(attr(2).origin.y - before2.origin.y) < 0.5, "T2 new row starts where index 2 was", "...")
check(abs(attr(2).height - 52) < 0.5, "T2 new row has the 2-line height", "...")
check(abs(attr(3).height - before2.height) < 0.5, "T2 shifted row keeps its height", "...")
check(cv.contentOffset == offsetBefore, "T2 contentOffset unchanged", "...")
check(TCell.configCount["p0"] == 1, "T2 existing cell not reconfigured", "...")
check(sec.itemVMs[3].indexPath == IndexPath(item: 3, section: 0), "T2 shifted indexPath renumbered", "...")
check(sec.itemVMs[4].indexPath == IndexPath(item: 4, section: 0), "T2 last indexPath renumbered", "...")
```

另加两条（同一 Task）：
- **越界**：`insert(item, at: -3)` 插到 0；`insert(item, at: 999)` 插到末尾。
- **未显示过**：新建一个没接入 collectionView 的 `ATListSectionVM`，`insert` 后断言 `itemVMs.count == 1` 且 `sectionIndex == nil`（脚手架用 `-O` 编译，`assertionFailure` 会被编掉）。

- [ ] **Step 2: 运行，确认失败**

Run: `bash Example/build/verify/run.sh`
Expected: 编译失败，报 `value of type 'ATListSectionVM' has no member 'insert'`

- [ ] **Step 3: 实现**

1. `ATListCell` 加内部方法：
   ```swift
   func syncIndexPath(_ newValue: IndexPath) { indexPath = newValue }
   ```
2. `ATListVM.swift` 里新增扩展（必须在这个文件内，才能写 `fileprivate(set)` 的 `indexPath`）：

```swift
extension ATListSectionVM {
    /// 在 index 处插入一行并增量刷新；已有 cell 不重建、不重新量高。
    public func insert(_ itemVM: ATListItemVM, at index: Int) {
        let target = min(max(index, 0), itemVMs.count)
        let countBefore = itemVMs.count
        itemVMs.insert(itemVM, at: target)
        guard let collectionView = self.collectionView,
              let sectionIndex = self.sectionIndex,
              sectionIndex < collectionView.numberOfSections,
              collectionView.numberOfItems(inSection: sectionIndex) == countBefore else {
            assertionFailure("ATListSectionVM.insert 无法安全刷新：只改了数据")
            return
        }
        // 数据变更与批量插入必须同轮完成，中间夹一次 layout 会让行数对不上而崩溃。
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: [IndexPath(item: target, section: sectionIndex)])
            }
            collectionView.layoutIfNeeded()
        }
        renumberIndexPaths(from: target, section: sectionIndex, collectionView: collectionView)
    }

    public func append(_ itemVM: ATListItemVM) {
        insert(itemVM, at: itemVMs.count)
    }

    private func renumberIndexPaths(from start: Int, section: Int, collectionView: UICollectionView) {
        guard start < itemVMs.count else { return }
        for i in start..<itemVMs.count {
            guard itemVMs[i].indexPath != nil else { continue }
            itemVMs[i].indexPath = IndexPath(item: i, section: section)
        }
        for visible in collectionView.indexPathsForVisibleItems where visible.section == section && visible.item >= start {
            (collectionView.cellForItem(at: visible) as? ATListCell)?.syncIndexPath(visible)
        }
    }
}
```

- [ ] **Step 4: 运行，确认通过**

Run: `bash Example/build/verify/run.sh`
Expected: 全部 `PASS` + `RESULT: ALL PASS`

- [ ] **Step 5: 汇报（不 commit）**

---

### Task 3: 社区示例接线

**Files:**
- Modify: `Example/ATListVM/CommunityDemo.swift`（`appendPost` 与两处文案）

**Interfaces:**
- Consumes: `ATListSectionVM.insert(_:at:)`（Task 2）

- [ ] **Step 1: 改 `appendPost()`**

删掉 `postSection.reloadSectionBlock?()`，改为：

```swift
postSection.insert(item, at: insertAt)
onTrace?("insert  追加了第 \(insertAt + 1) 条")
```

并把顶部提示里的「加载更多会整段重算」与 `CommunityMoreCell` 相关文案改成「只插入新行」。

- [ ] **Step 2: 构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`，0 项目源码 warning

- [ ] **Step 3: 截图验证（临时探针，用完还原）**

临时在 `AppDelegate` 里 push `CommunityViewController()`，用 `simctl` 截图确认 4 个 section 正常；还原 `AppDelegate` 并重新构建。

- [ ] **Step 4: 汇报（不 commit）**

---

## 交付后：人工验收（需要用户）

进「自动布局 → 社区信息流」，点一次「加载更多」，再往上滑到顶。预期：新帖出现在「加载更多」之前，上方帖子高度与位置纹丝不动。

## 自检结果

- **Spec 覆盖**：sectionIndex 管道（Task 1）、`insert`/`append` + 重编号（Task 2）、示例接线（Task 3）与设计稿一一对应；「同步执行」「不做 owner 校验」写进 Global Constraints / 留给实现者。
- **Review Focus 落点**：同轮约束（Task 2 实现注释 + 崩溃验证）、只重编号已显示 item（Task 2 的 `guard indexPath != nil` + 断言只查 item 3/4）、cell 同步（Task 2 Step 3-1）、越界（Task 2 断言）、未显示（Task 2 断言 + `-O`）。
- **已知缺口**：验证靠脚手架 + 构建 + 人工，没有 XCTest（环境限制，spec 已接受）。
