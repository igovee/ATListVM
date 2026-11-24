# 动态刷新示例页实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增一页「动态刷新」：定时器每秒改一条设备卡片的数据，按变化类型分别走 `refreshItemBlock` / `reloadItemBlock` / `reloadSectionBlock` / `reloadListBlock`，页面实时显示每种 block 的调用次数与内容总高。

**Architecture:** 新文件 `DynamicRefreshDemo.swift`：`DynamicListVM: ATListVM` 持有一个 section 和一份调用统计，`tick()` 每次按固定顺序触发一种变化；`ScenarioPageViewController` 的 `topAccessory` 放统计条，底部 `eventLabel` 显示最近一次调用；VC 只管定时器和按钮。

**Tech Stack:** Swift 5 / UIKit / SnapKit（已有）/ ATListVM（本地 pod）

**Spec:** `docs/superpowers/specs/2026-11-24-dynamic-refresh-demo-design.md`

## Global Constraints

- 只改 `Example/`，不动 `ATListVM/Classes/`。
- 新文件必须登记 pbxproj 四处（PBXBuildFile / PBXFileReference / 分组 children / Sources）。
- iOS 13、Swift 5、只用 UIKit + SnapKit + ATListVM。
- 手动页 `itemSize` 宽高都给全：在线 `(屏宽−32, 84)`，离线 `(屏宽−32, 112)`。
- 每个 cell 的最后子视图钉到 `contentView` 底部（本页是手动定高，钉底只为排版稳定，不依赖自撑开）。
- 定时器必须在 `viewDidDisappear` 停掉。
- 不自动提交；每个任务末尾汇报改动清单。

## 增补（实施后由用户追加要求）

用户要求「ATListItemVM 和 ATListSectionVM 的 refresh block 示例都要包含到」，因此在 Task 2 之后追加：
- 页面加 section header / footer（`DynamicSectionHeader` / `DynamicSectionFooter` + `DynamicSectionVM`）
- tick 扩成 6 拍，新增 `refreshHeaderBlock` / `refreshFooterBlock` 两拍
- 统计条改成两行（item 一组、section 一组），高度 28 → 40
- 修 `ATListSectionVM` 的两个 refresh block 的 supplementary 查找索引（[section,0]）

## 与设计的差异（plan-level 决定）

- 变化类型**顺序循环**（值 → 高度 → 行数 → 整表 → 值 …），不是随机：四种变化依次出现，读者一眼看懂顺序，截图验证也可复现。
- 统计条挂在 `ScenarioPageViewController.topAccessory`，不新增页面骨架。

## Review Focus

- **`refreshItemBlock` 之后行高没变**：这正是这页要展示的"正确行为"，但若改成改高度还走 refresh，cell 会被裁切 → Task 2 验证离线卡片变高。
- **`reloadItemBlock` 前忘了改 `itemSize`**：高度不会变，页面看起来"什么都没发生"。
- **`reloadSectionBlock` 前没改 `itemVMs`**：行数不变，同样看起来没反应。
- **定时器泄漏**：离开页面后还在 tick → 崩溃或后台耗电。→ Task 2 验证 `viewDidDisappear` 停表。
- **统计条高度为 0 或压住列表**：`topAccessory` 必须自己给高度约束。

---

### Task 1: 页面、数据与菜单接线

**Files:**
- Create: `Example/ATListVM/DynamicRefreshDemo.swift`
- Modify: `Example/ATListVM/BusinessScenarioDemos.swift`（`entries` 追加一条）
- Modify: `Example/ATListVM.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces `final class DynamicDeviceItemVM: ATListItemVM`：`var name: String`、`var isOnline: Bool = true`、`var brightness: Int = 0`、`var offlineMinutes: Int = 0`；`setupData()` 设 `cellId = DynamicDeviceCell.reuseId` 与在线尺寸。
- Produces `func syncItemSize()`：按 `isOnline` 设 `itemSize`（在线 84 / 离线 112）。
- Produces `final class DynamicListVM: ATListVM`：`let section = ATListSectionVM()`、`var onEvent: ((String) -> Void)?`、`func makeDevice(_ index: Int) -> DynamicDeviceItemVM`
- Produces `final class DynamicRefreshViewController: ScenarioPageViewController`

- [ ] **Step 1: 写 itemVM 与 cell**

`DynamicDeviceCell: ATListCell`：左侧状态圆点（在线绿 / 离线灰）+ 设备名（15pt）+ 右侧「亮度 70%」或「—」；离线时底部再加一行 12pt 灰字「已离线 3 分钟」（高 28，`isHidden` 控制）。最后一个子视图 `bottom` 钉到 `contentView`。

- [ ] **Step 2: 写 ListVM 的初始数据**

`createData()`：section 上下 inset 12、左右 16、行距 10；造 6 台设备（客厅灯 / 卧室灯 / 阳台灯 / 书房灯 / 厨房灯 / 门厅灯），其中 1 台离线；`viewProxy.sectionVMs = [section]`。

- [ ] **Step 3: 写 VC 骨架**

`DynamicRefreshViewController` 继承 `ScenarioPageViewController`，`title: "动态刷新"`，hint 写「每秒改一条数据：值变化走 refresh，状态变化走 reloadItem，行数变化走 reloadSection，整表换走 reloadList」。

controller 里先留一个占位：`@objc func toggleTimer()`（Task 2 填定时器逻辑）。

- [ ] **Step 4: 菜单接线 + pbxproj**

`BusinessScenarioDemos.entries` 追加：

```swift
DemoEntry(title: "动态刷新",
          detail: "数据变化 → 四种 block 的取舍",
          make: { DynamicRefreshViewController() })
```

`DynamicRefreshDemo.swift` 按四处登记 pbxproj。

- [ ] **Step 5: 构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 6: 截图（静态列表）**

临时探针把 root 换成 `DynamicRefreshViewController`，截图 `/tmp/dynamic-static.png`。
Expected: 6 张设备卡，其中一张带「已离线」行、明显比别的高；控制台无约束冲突。

- [ ] **Step 7: 汇报（不 commit）**

---

### Task 2: tick 引擎、统计条与暂停

**Files:** Modify `Example/ATListVM/DynamicRefreshDemo.swift`

**Interfaces:**
- Consumes: `DynamicListVM` / `DynamicDeviceItemVM`（Task 1）
- Produces `struct DynamicStats { var refresh = 0; var reloadItem = 0; var reloadSection = 0; var reloadList = 0 }`
- Produces `DynamicListVM.stats: DynamicStats`、`DynamicListVM.tick()`
- Produces `DynamicRefreshViewController.startTimer()` / `stopTimer()`

- [ ] **Step 1: 写 tick（四种变化顺序循环）**

```swift
private var phase = 0

func tick() {
    switch phase % 4 {
    case 0: refreshValue()
    case 1: toggleOnline()
    case 2: changeRowCount()
    default: reloadEverything()
    }
    phase += 1
}
```

- `refreshValue()`：随机挑一台在线设备，`brightness` 改成 10…100 的随机值 → `item.refreshItemBlock?()` → `stats.refresh += 1` → `onEvent?("refreshItemBlock → \(item.name) 亮度 \(value)%（行高不变）")`
- `toggleOnline()`：随机挑一台设备翻转 `isOnline`，离线时给 `offlineMinutes = 3`，**先 `syncItemSize()` 再** `item.reloadItemBlock?()` → `stats.reloadItem += 1` → `onEvent?("reloadItemBlock → \(name) \(在线/离线)（高度 84 ↔ 112）")`
- `changeRowCount()`：在线设备少于 4 台就加一台，否则随机删一台 → `section.reloadSectionBlock?()` → `stats.reloadSection += 1` → `onEvent?("reloadSectionBlock → 当前 \(count) 条")`
- `reloadEverything()`：重建 5–7 台设备写回 `section.itemVMs` → `section.reloadListBlock?()` → `stats.reloadList += 1` → `onEvent?("reloadListBlock → 整表重建 \(count) 条")`

- [ ] **Step 2: 写统计条**

VC 里造一个高 28 的 `UIView` 作为 `topAccessory`（init 时传入），里面一个 12pt 的 label。每次 tick 后刷新文案：

```
refresh 3 · reloadItem 2 · reloadSection 1 · reloadList 0 · 6 条 · 高 1042pt
```

高度取 `collectionView.collectionViewLayout.collectionViewContentSize.height`，在 tick 之后 `DispatchQueue.main.async` 里读（刷新本身是异步的，要等下一次布局）。

- [ ] **Step 3: 定时器与按钮**

VC 用 `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)`，`viewDidAppear` 启动、`viewDidDisappear` 停；导航栏放「暂停 / 继续」按钮切换状态并 `show(...)`。

- [ ] **Step 4: 构建**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`

- [ ] **Step 5: 截图验证四态**

探针进入页面后等 5 秒截图 `/tmp/dynamic-1.png`（应有值刷新与高度变化记录），再等 5 秒截图 `/tmp/dynamic-2.png`（应出现行数变化 / 整表重建记录）。
Expected：统计条数字单调增长且与 eventLabel 的最后一条对得上；离线卡片比其他卡高。

- [ ] **Step 6: 验证离开页面停表**

探针：进入 → 3 秒后 `dismiss/pop` → 控制台观察 3 秒内不再有 `onEvent` 输出（可在 `onEvent` 里 print 验证）。
Expected: 停止后无新增 tick。

- [ ] **Step 7: 汇报（不 commit）**

---

### Task 3: 收尾验证

**Files:** 无新增

- [ ] **Step 1: 移除探针并全量构建**

`grep -n "TEMP PROBE" Example/ATListVM/*.swift` 应为空；`bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`。

- [ ] **Step 2: 约束日志检查**

启动后进页面跑 10 秒，`xcrun simctl spawn <booted> log stream --predicate 'eventMessage CONTAINS "Unable to simultaneously satisfy"'` 期间无输出。

- [ ] **Step 3: 汇报三张截图与最终状态**
