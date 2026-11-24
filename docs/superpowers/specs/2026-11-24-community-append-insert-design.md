# 增量插入进库（ATListSectionVM.insert/append）—— 设计稿

日期：2026-11-24
状态：待批准
规模：小改动（库 + 一个示例调用点）

## 为什么改

`CommunityListVM.appendPost()` 用 `reloadSectionBlock?()`（= `reloadSections`）追加一行。
该方法把帖子 section 的所有 cell 作废重建；配合布局级 self-sizing
（`estimatedItemSize = .automaticSize`），FlowLayout 只能重新估高：

1. `contentSize` 立刻缩水 → 当前 `contentOffset` 超上限被夹 → 视线被往上拽；
2. 之后往上滑，新进屏幕的行才逐条测量，`contentSize` 长回去 → 行位置持续推移（抖动）。

实测：静止 `contentSize` 1266 → 滚到 400 时 1643 → 800 时 1674 → 到底 1627。

只改示例（8 行 `performBatchUpdates { insertItems }`）能修好，但有三件事只有库能兜住：

- **同轮 runloop 的硬约束**：改数据与 `insertItems` 之间只要夹一次 layout，UIKit 的旧行数会被
  顶成新行数，进程直接崩溃且 stderr / crash report 都是空的。库现有的 `reloadSectionBlock`
  恰恰是「异步刷新」的写法，照着抄必踩。
- **section 号**：`ATListSectionVM` 只有 `weak collectionView`，算不出自己是第几个 section。
- **索引过期**：插入后，插入点之后的 item 的 `ATListItemVM.indexPath` 仍是旧值，
  对它们调 `refreshItemBlock` / `reloadItemBlock` 会打到错行。`indexPath` 是
  `fileprivate(set)`，外部修不了。

## 目标

- `ATListSectionVM.insert(_:at:)` / `append(_:)`：只插入新行，已有 cell 不重建、不重新量高。
- 插入后自动重编号插入点之后 item（以及可见 cell）的 `indexPath`。
- 社区示例的「加载更多」改为调用它，抖动消失。

## 非目标

- 不改 `reloadSectionBlock` / `reloadListBlock` / `reloadItemBlock` 的既有行为。
- 不做 `remove` / `move` / 批量替换。
- 不做「换过代理 / section 被摘掉」的 owner 校验（见「已知限制」）。

## 反目标

- 用「reload 前后保存恢复 offset」盖症状。
- 为了让这里不抖而关掉自适应。

## 约束

- 只动 `ATListVM/Classes/ATListVM.swift`（`ATListSectionVM` + 扩展 + `ATListItemVM` / `ATListCell` 各一个内部方法）、
  `ATListViewProxyBase.swift`（`numberOfItemsInSection` 里记 `sectionIndex`）、
  `Example/ATListVM/CommunityDemo.swift`（`appendPost`）。
- 扩展写在 `ATListVM.swift` 里，这样能直接使用 `fileprivate(set) var indexPath`，
  不必把访问级别放宽。
- iOS 13 / Swift 5。

## 方案

### 1. section 记住自己是谁

`ATListSectionVM` 增加：

```swift
/// 该 section 在 collectionView 里的下标。numberOfItemsInSection 时赋值。
public fileprivate(set) var sectionIndex: Int?
```

`ATListViewProxyBase.collectionView(_:numberOfItemsInSection:)` 里与既有赋值并列：

```swift
sectionVM?.collectionView = collectionView
sectionVM?.sectionIndex = section
```

### 2. 插入 API

```swift
extension ATListSectionVM {
    /// 在 index 处插入一行并增量刷新：已有 cell 不重建、不重新量高。
    /// 索引夹到 `0...itemVMs.count`。
    public func insert(_ itemVM: ATListItemVM, at index: Int)

    /// 追加到末尾。
    public func append(_ itemVM: ATListItemVM)
}
```

实现要点：

- **同步执行**（不 `DispatchQueue.main.async`）：数据变更与 `insertItems` 必须在同一轮 runloop。
  代价见「已知限制」。
- 先夹索引、**同步**改 `itemVMs`，再取 `collectionView` / `sectionIndex`。
- 刷新前校验：`sectionIndex < collectionView.numberOfSections`
  且 `numberOfItems(inSection: sectionIndex) == 改动前的行数`。
  不满足就只保留数据变更（DEBUG 下 `assertionFailure`），不刷 UI。
- 刷新：`UIView.performWithoutAnimation { performBatchUpdates { insertItems } ; layoutIfNeeded() }`。
- 刷新后重编号：对 `itemVMs[target...]` 中 `indexPath != nil` 的 item 设置新 indexPath；
  再把该 section 里可见 cell 的 `indexPath` 同步过来（`ATListCell` 增加内部方法 `syncIndexPath(_:)`）。

### 3. 示例接线

```swift
func appendPost() {
    let insertAt = postSection.itemVMs.count - 1
    guard insertAt >= 0 else { return }
    let item = makePost(...)
    postSection.insert(item, at: insertAt)
    onTrace?("insert  追加了第 \(insertAt + 1) 条")
}
```

顶部提示与「加载更多」文案从「整段重算」改为「只插入新行」。

## 已知限制

- **同步执行**：在 `willDisplay` / `cellForItemAt` 这类 UIKit 回调里调用 `insert` 会重入批量更新。
  本库把 `willDisplay()` 作为分页钩子暴露出来，所以这是真实风险。设计上选择同步是为了让
  `insert` 返回后 `itemVMs` 立刻可见；如果之后确认 `willDisplay` 里插入是主要用法，
  改成「延后到下一轮、数据与批量刷新同块」只需改这一处。
- 不校验 `collectionView.dataSource` 是否仍是同一个 proxy。section VM 被摘掉、或
  collection view 换了代理之后仍持有旧引用时，行数校验能挡住大部分情况，但不是全部。

## 验证方式

- `xcodebuild` 构建通过，项目源码 0 warning。
- 临时探针（用完还原）断言：
  1. 插入前后 `contentOffset` 完全不变；
  2. 帖子 section 已有行（item 0/1）的 `layoutAttributes.frame` 完全一致；
  3. 已有 cell 的 `refreshSubviews` 次数不增加（证明没重建）；
  4. 新行的高度非零且等于其内容的真实高度；
  5. 插入点之后的 item `indexPath` 已重编号。
- 截图：新帖出现在「加载更多」之前，已有帖子位置不变。
- 人工：点「加载更多」再往上滑，确认不抖。

## 留给实现者

- `append` 是否用 `insert(itemVM, at: itemVMs.count)` 实现 —— 我倾向是，少一份重复。
- 行数校验失败时是否只在 DEBUG 断言 —— 我倾向是，release 下静默保留数据。
