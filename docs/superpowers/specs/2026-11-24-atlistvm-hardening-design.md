# ATListVM 健壮性修复设计（兼容 GoveeHome）

日期：2026-11-24
状态：待批准
规模：项目（库内 5 个文件 + 第一套测试基建）

## 为什么做

整体 review 出一批"编译零告警、运行静默失效"的问题；今天已经有两个同类 bug 咬过人
（supplementary 索引、`forElementOfKind` 拼写）。库本身没有任何测试，改完只能靠肉眼。

真实使用方 GoveeHome 的 `Busi_Community` 四个页面在跑这套库，任何修改都不能改变它们现有调用点的语义。

## 目标

1. 修掉 3 个会静默出错的缺陷（索引语义、越界 reload、断言后数据已改）。
2. 给调用方一个"这个块到底能不能生效"的判据，替代"调用后祈祷"。
3. 建第一套 windowed 回归测试，把四个刷新块和今天两个 bug 钉住。

## 非目标

- **不改 `defaultSectionVM` 的行为**（读取即切换单段是设计缺陷，但改了会破坏已写法的语义，留到大版本）。
- 不改 podspec 版本号 / GoveeHome 的分支引用（独立一次发布动作）。
- 不新增公开协议方法、不改任何现有方法签名。
- 不做性能优化、不重命名文件。

## 兼容基线（实测，不是推断）

| GoveeHome 用到的 API | 本次是否触及 | 证据 |
|---|---|---|
| `ATListVM` 子类化（setupData/register/reloadData） | 否 | 4 个 VM 均只重写这几个 |
| `init(viewProxy:)` + 自定义 Proxy 子类 | 否 | `SUListViewProxy` / `CoCircleRecommend.ViewProxy` |
| `viewProxy.sectionVMs` / `forwarder` / `delegate` | 否 | 7 处赋值，均为读写属性 |
| `reloadItemBlock?()` / `refreshItemBlock?()` | **是**（只加保护） | CoCreate 6 处、Activity 1 处 |
| `sectionVM.indexPath` | 否 | 3 处命中的文件都 `import ATMVVM`，是另一个框架的同名属性 |
| `defaultSectionVM` | 否 | 唯一命中是注释掉的代码，且属于 ATMVVM |
| `insert/append` | 否 | 无调用 |
| `ATListViewAutoProxy` | 否 | 无引用 |

结论：只有"两个 item 级刷新块"需要特别小心——它们被真实调用，所以**不能**改成断言。

## 逐项设计

### 1. 删掉 `ATListSectionVM.indexPath`

`section` 才是这个 section 在列表里的唯一真源（在 `numberOfItemsInSection` 赋值，空 section 也有值），
`indexPath` 是它的重复投影，而且历史上被写成了"最后一个 cell 的位置"。直接删除：

- 删属性；`reloadSectionBlock` / `refreshHeaderFooterBlock` 的兜底改成 `self.section`（没有就 no-op）；
- `ATListViewProxyBase` 里不再写它。
- 兼容性：全仓库只有一处写入、三处兜底读取，没有任何业务读它（GoveeHome 那 3 处命中在 ATMVVM 模块）。
- **这是一次公开 API 删除**，语义化版本上属于 breaking；趁 0.1.3 还没发出去、且唯一使用方不读它，现在删最便宜。

### 2. 新增 `ATListItemVM.isReadyForItemRefresh`

```swift
/// 这个 item 是否已经上过屏（有 indexPath）。为 false 时 refresh/reloadItem 都是 no-op。
public var isReadyForItemRefresh: Bool { indexPath != nil }
```

纯增量。目的是让调用方（比如定时刷新）先判断再调用，而不是调用完不知道有没有生效。

### 3. `reloadItemBlock` / `reloadSectionBlock` 越界保护

`reloadItems(at:)` 传入已失效的 indexPath 会抛 UIKit 异常。两个块在 dispatch 之后加范围校验：

```swift
guard let cv = collectionView, let ip = indexPath,
      ip.section < cv.numberOfSections,
      ip.item < cv.numberOfItems(inSection: ip.section) else { return }
```

- 行为变化：越界从"崩溃"变成"静默跳过"。
- 兼容性：GoveeHome 现在的调用都是有效 indexPath，行为不变。

### 4. `insert` 断言失败后 Release 自愈

`ATListSectionVM.insert` 在"数据源与 UI 行数不一致"时现在只 `assertionFailure` 然后 return，
数据已改、UI 没刷。改成：断言后补一次 `collectionView.reloadData()`，让 Release 下能自愈。

- Debug 行为不变（断言仍然会 trap）。
- 兼容性：GoveeHome 不调用 insert。

### 5. `ATListViewAutoProxy.attach` 增加 layout 类型断言

非 `UICollectionViewFlowLayout` 时 `assertionFailure("ATListViewAutoProxy 需要 FlowLayout…")`。

- 兼容性：GoveeHome 不使用 AutoProxy。

### 6. 四个 block 的访问级别对齐

`public fileprivate(set)` → `public internal(set)`（item 与 section 两组共 8 个 block 一起改）。

- 纯放宽 setter，getter 不变，源兼容。

### 7. 第一套 windowed 回归测试

- 位置：`Example/Tests/Tests.swift`（现有模板，改内容不改路径，避免动 pbxproj）。
- Harness：`UIWindow` + `UICollectionView` + `FlowLayout` + `ATListViewProxy` + spy cell / spy reuse view。
- 用例（每个都能在修复前红、修复后绿）：

| 用例 | 钉住的行为 | 修复前 |
|---|---|---|
| `testRefreshItemBlockUpdatesVisibleCell` | `refreshItemBlock` 调到可见 cell 且不重测高度 | 通过 |
| `testReloadItemBlockAppliesNewItemSize` | `reloadItemBlock` 生效后 cell 变高 | 通过 |
| `testRefreshHeaderBlockReachesHeader` | header 的 `refreshSubviews(isFromVM: true)` 被调到 | **红**（旧索引 bug） |
| `testRefreshFooterBlockReachesFooter` | footer 同上 | **红** |
| `testRefreshHeaderBlockTargetsItsOwnSection` | 两段列表里刷第 1 段只命中第 1 段 | **红**（`indexPath?.section ?? 0`） |
| `testReloadItemBlockIgnoresStaleIndexPath` | 越界时不抛异常 | **红**（会崩） |

- 异步处理：库内块都 dispatch 到主队列，测试用 `XCTestExpectation` + 主 runloop 自旋。

## 测试运行方式

```bash
xcodebuild test -workspace Example/ATListVM.xcworkspace -scheme ATListVM-Example \
  -destination 'platform=iOS Simulator,name=DSH iPhone' \
  -derivedDataPath Example/build/demo/derived
```

（`ATListVM_Tests` 已配置 `TEST_HOST` 指向示例 App，scheme 已有 TestAction。）

## 边界与风险

- **Debug 断言风险**：本次只在 AutoProxy 一条路径加断言，GoveeHome 不用；其余全部走保护/no-op。
- **测试时序**：所有断言都要等主队列；不用 `sleep`，用 expectation。
- **回归验证**：除测试外，还要把示例的「动态刷新」页和「社区信息流」页各跑一遍截图，确认没有行为漂移。

## 验收

1. `bash Example/build/demo/build.sh` → BUILD SUCCEEDED。
2. `xcodebuild test …` → 7 个用例全绿。红→绿只真实复现了 1 条（空 section 刷表头）；越界 reload 在 iOS 26 上即使去掉保护也不崩，所以它是护栏而非证据。
3. 示例两页截图与修改前一致（除已知要修的行为）。
4. `git diff ATListVM/` 只包含上述 5 个文件，且没有新增公开符号（除 `isReadyForItemRefresh`）。
