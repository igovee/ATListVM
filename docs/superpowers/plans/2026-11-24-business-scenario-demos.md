# Example「业务场景」示例集实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Example 首页加第三个入口「业务场景」，用 6 个页面分别演示 ATListVM 直接能承接的业务形状：设置页、商品列表、消息中心、个人中心、搜索结果、横向卡片流。

**Architecture:** 新增 `BusinessScenarioDemos.swift` 一个文件承载全部 6 个页面；文件顶部放一个 `ScenarioPageViewController` 基类（hint + collectionView + eventLabel 的共用骨架），每个页面由「VM（ATListVM 子类）+ 若干 Cell + VC」组成，VC 继承基类。菜单复用现有 `DemoEntry` / `DemoMenuViewController`，`ViewController` 只多一个按钮。

**Tech Stack:** Swift 5 / UIKit / SnapKit（已有）/ ATListVM（本地 pod）

**Spec:** `docs/superpowers/specs/2026-11-24-business-scenario-demos-design.md`

## Global Constraints

- **只改 `Example/`，不动 `ATListVM/Classes/` 任何文件。**
- 新增文件必须在 `Example/ATListVM.xcodeproj/project.pbxproj` 补齐四处：`PBXBuildFile`、`PBXFileReference`、`ATListVM` 分组的 `children`、target 的 `Sources` build phase。缺一处就编译不过。
- iOS 部署目标 13.0；Swift 5；不新增第三方依赖（只用 UIKit + SnapKit + ATListVM）。
- 手动页（设置 / 商品 / 个人中心 / 搜索 / 横向）的 `itemSize` **宽高都必须给全**，宽度按「屏宽 − 32」或均分列宽算；`ATListViewProxy.sizeForItemAt` 原样返回 `itemVM.itemSize`，宽为 0 就什么都不画。
- `ATListSectionVM.insert/append` 是**同步**批量更新，禁止在 `willDisplay` / `cellForItemAt` 里直接调用；分页一律 `DispatchQueue.main.async` 包一层。
- **不自动提交**：仓库暂存区有既存改动，`git add && git commit` 会一并提交。每个任务的「Commit」动作统一替换为「向用户汇报本任务改动清单」。
- **VM 不引用 VC**：需要报告事件的 VM 统一暴露 `var onEvent: ((String) -> Void)?`，由 VC 在 `viewDidLoad` 里接到基类的 `show(_:)`。
- **截图方式**：页面在菜单两层深处，模拟器点不进去。统一用「临时探针」——在 `AppDelegate.application(_:didFinishLaunchingWithOptions:)` 末尾临时插入 `window?.rootViewController = UINavigationController(rootViewController: <目标页>())`，截图后**必须还原**，不留探针进仓库。

## Review Focus

- **手动页 `itemSize` 宽度写成 0 或 `.zero`**：列表整屏空白，看起来像"没数据"。→ Task 1/2/4/5/6 每页截图都要能看到卡片本身。
- **分页在 `willDisplay` 里同步 `append`**：重入 `performBatchUpdates` 直接崩。→ Task 2 的加载更多要连点到底验证不崩。
- **0 条 item 的 section 不给 footer 高度**：空态白屏。→ Task 5 的空态截图。
- **两列 ↔ 单列切换后没有重新取 `itemSize`**：切了没反应。→ Task 2 要拍切换前后两张图对比。
- **自适应页没把 cell 底边钉到 `contentView`**：cell 高度塌成 0 或截断。→ Task 3 长文案要能完整撑开。

---

### Task 1: 骨架、菜单接线与设置页

**Files:**
- Create: `Example/ATListVM/BusinessScenarioDemos.swift`
- Modify: `Example/ATListVM/ViewController.swift`
- Modify: `Example/ATListVM.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces `class ScenarioPageViewController: UIViewController`
  - `init(title: String, hint: String, listVM: ATListVM, scrollDirection: UICollectionView.ScrollDirection = .vertical, topAccessory: UIView? = nil, collectionViewHeight: CGFloat? = nil)`
  - `private(set) lazy var collectionView: UICollectionView`（内部已调 `config(listVM:)` + `config(viewProxy:)`）
  - `let eventLabel: UILabel`（高 24，底部，12pt、secondaryLabel）
  - `func show(_ event: String)` → 写 `eventLabel.text`
  - `viewDidLoad` 末尾调 `listVM.createData()` 与 `listVM.reloadData()`
  - `collectionViewHeight == nil` 时 collectionView 底边钉到 `eventLabel` 上方；非 nil 时只给 top + 高度，下方留给子类
- Produces `enum BusinessScenarioDemos { static let entries: [DemoEntry] }`
- Produces `final class ScenarioSettingsViewController: ScenarioPageViewController`

- [ ] **Step 1: 写基类**

`ScenarioPageViewController` 按上面的 Interfaces 实现。hint 用 12pt、`secondaryLabel`、`numberOfLines = 0`、左右 16；collectionView 背景 `.systemBackground`；topAccessory 有值时夹在 hint 与 collectionView 之间（高度由子类自己约束）。

- [ ] **Step 2: 写设置页**

`SettingsListVM: ATListVM`（默认 `ATListViewProxy`）+ 三个 cell + `ScenarioSettingsViewController`：

| section | 行 | cell | itemSize |
|---|---|---|---|
| 账号 | 头像与昵称 / 绑定手机 | `SettingsValueRowCell`（标题 + 右侧值 + ›） | `(屏宽−32, 56)` |
| 偏好 | 深色跟随后台 / 消息推送 | `SettingsToggleRowCell`（标题 + `UISwitch`） | `(屏宽−32, 56)` |
| — | 退出登录 | `SettingsDangerRowCell`（红色居中） | `(屏宽−32, 52)` |

- 分组标题用 `ATListReuseableView` 子类 `SettingsSectionHeader`，`headerSize = (屏宽, 28)`，`sectionInset` 左右 16、上下 8。
- 开关切换：改 VM 的 `isOn` 后调 `reloadItemBlock?()`，再 `onEvent?("开关 消息推送 = on")`。
- 点行：在 `onSelectItemBlock` 里 `onEvent?("点击 头像与昵称")`（`onEvent` 由 VC 接到 `show`）。

- [ ] **Step 3: 菜单接线**

`ViewController.setupMenu()` 的 stack 里加第三个按钮「业务场景」，push `DemoMenuViewController(title: "业务场景", entries: BusinessScenarioDemos.entries)`。`BusinessScenarioDemos.entries` 本任务只有一条：

```swift
DemoEntry(title: "设置页", detail: "分组 + 异质行 + 单行刷新", make: { ScenarioSettingsViewController() })
```

- [ ] **Step 4: 登记 pbxproj**

给 `BusinessScenarioDemos.swift` 补 `PBXBuildFile` + `PBXFileReference`，加进 `ATListVM` 分组 `children`，加进 target `Sources`。

- [ ] **Step 5: 构建**

Run: `bash Example/build/demo/build.sh`
Expected: `** BUILD SUCCEEDED **`，无项目源码 warning。

- [ ] **Step 6: 截图验证**

装到已启动的模拟器 `DSH iPhone`（`443E4D5B-2076-4879-A97E-7BEBCF911403`）：
```bash
xcrun simctl install 443E4D5B-2076-4879-A97E-7BEBCF911403 Example/build/demo/derived/Build/Products/Debug-iphonesimulator/ATListVM_Example.app
xcrun simctl launch 443E4D5B-2076-4879-A97E-7BEBCF911403 com.brownlee.Demo
xcrun simctl io 443E4D5B-2076-4879-A97E-7BEBCF911403 screenshot /tmp/home-third-button.png
```
Expected: 首页三个按钮。再进「业务场景 → 设置页」截图 `/tmp/settings.png`，确认三组卡片、开关、红字行都在，行高不发虚。

- [ ] **Step 7: 汇报（不 commit）**

---

### Task 2: 商品列表

**Files:** Modify `Example/ATListVM/BusinessScenarioDemos.swift`

**Interfaces:**
- Consumes: `ScenarioPageViewController`（Task 1）
- Produces `ProductListVM: ATListVM`：`let section = ATListSectionVM()`、`var isGrid: Bool`、`var pageIndex: Int`、`var onEvent: ((String) -> Void)?`、`func toggleStyle()`、`func loadMore()`
- Produces `final class ScenarioProductListViewController: ScenarioPageViewController`；`BusinessScenarioDemos.entries` 追加一条

- [ ] **Step 1: 写 VM 与 cell**

`ProductListVM: ATListVM`（默认手动 proxy），一个 section、无 header。`ProductCell: ATListCell`：顶部色块（高 100，圆角 8）+ 名称（15pt）+ 价格（15pt、橙色）。

- 两列：`itemSize = ((屏宽−32−12)/2, 180)`、`section.minimumInteritemSpacing = 12`
- 单列：`itemSize = (屏宽−32, 120)`、`section.minimumInteritemSpacing = 0`
- `func toggleStyle()`：改 `isGrid` → 遍历 `section.itemVMs` 改写 `itemSize` → 改 `minimumInteritemSpacing` → `section.reloadSectionBlock?()` → `onEvent?("切换为 单列")`

- [ ] **Step 2: 写分页**

`ProductItemVM: ATListItemVM` 增加 `var onDisplay: (() -> Void)?`，`override func willDisplay()` 里调它。

`ProductListVM.loadMore()`：

```swift
guard pageIndex < 3 else { onEvent?("没有更多"); return }
pageIndex += 1
DispatchQueue.main.async { [weak self] in
    guard let self else { return }
    for i in 0..<6 {
        self.section.append(self.makeItem(index: self.section.itemVMs.count + i))
    }
    self.onEvent?("加载第 \(self.pageIndex) 页")
}
```

追加必须走 `section.append(item)`（同步批量更新）：一次追加 6 条就是循环调 6 次，且整段包在
`DispatchQueue.main.async` 里，不能落在 `willDisplay` 的调用栈内。

- [ ] **Step 3: 写 VC**

`ScenarioProductListViewController`：导航栏右侧按钮「切换视图」调 `listVM.toggleStyle()`；hint 文案「右上角切换两列/单列 · 滚到底自动加载」。

- [ ] **Step 4: 构建并截图（两列）**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`
截图 `/tmp/product-grid.png`：确认两列、卡片等宽、留白均匀。

- [ ] **Step 5: 截图验证切换（先验点）**

点「切换视图」后截图 `/tmp/product-list.png`：卡片应变成整行宽。
**若不生效**（宽度没变）：把 `reloadSectionBlock` 换成 `reloadListBlock`，在 hint 里补一句「整表重建会丢滚动位置」，再截一次。

- [ ] **Step 6: 截图验证分页**

滚到底连续触发 4 次：前 3 次应各追加 6 条，第 4 次 eventLabel 显示「没有更多」，全程不崩。

- [ ] **Step 7: 汇报（不 commit）**

---

### Task 3: 消息中心

**Files:** Modify `Example/ATListVM/BusinessScenarioDemos.swift`

**Interfaces:**
- Consumes: `ScenarioPageViewController`（Task 1）
- Produces `final class ScenarioMessageCenterViewController: ScenarioPageViewController`；`entries` 追加一条

- [ ] **Step 1: 写 VM**

`MessageListVM: ATListVM`，`override init() { super.init(viewProxy: ATListViewAutoProxy()) }`。一个 section，`sectionInset = (8, 16, 8, 16)`，`minimumLineSpacing = 10`。每个 item 的 `itemSize = (屏宽−32, 0)`（宽度必给，高度交给自撑开）。

四种 item：系统通知（标题 + 多行正文）、点赞（头像色块 36 + 一句）、评论（引用块 + 多行正文）、关注（小卡片：头像 + 昵称 + 关注按钮）。`MessageBaseVM` 持有 `isUnread: Bool`。

- [ ] **Step 2: 写 cell**

四个 `ATListCell` 子类。每个都把最后一个子视图的 `bottom` 钉到 `contentView.bottomAnchor`（自撑开的前提），未读行在标题左侧显示一个 6pt 红点。

- [ ] **Step 3: 已读交互**

- 点一行：`isUnread = false` → `refreshItemBlock?()` → `onEvent?("标记已读 第 N 条")`
- 导航栏「全部已读」：遍历所有 item 设 `isUnread = false` 并逐个 `refreshItemBlock?()`，`onEvent?("全部已读")`

- [ ] **Step 4: 构建并截图**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`
截图 `/tmp/messages.png`：四种行高度各不相同、长文案完整显示、没有截断或重叠。

- [ ] **Step 5: 截图验证已读**

点两条未读 → 红点消失、`eventLabel` 更新，其余行位置不跳。

- [ ] **Step 6: 汇报（不 commit）**

---

### Task 4: 个人中心

**Files:** Modify `Example/ATListVM/BusinessScenarioDemos.swift`

**Interfaces:**
- Consumes: `ScenarioPageViewController`（Task 1）
- Produces `final class ScenarioProfileViewController: ScenarioPageViewController`；`entries` 追加一条

- [ ] **Step 1: 写 VM（4 个 section）**

| section | 内容 | itemSize | 其它 |
|---|---|---|---|
| 头像卡 | 1 条：头像块 + 昵称 + 简介 | `(屏宽−32, 120)` | `sectionInset = (12,16,0,16)` |
| 数据 | 3 条：关注 / 粉丝 / 获赞 | `((屏宽−32)/3, 72)` | `minimumInteritemSpacing = 0` |
| 入口 | 8 条：两行 × 四列图标 | `((屏宽−32−36)/4, 76)` | `minimumInteritemSpacing = 12`、`minimumLineSpacing = 12` |
| 设置 | 3 条：消息通知 / 隐私 / 关于 | `(屏宽−32, 56)` | `sectionInset = (0,16,24,16)` |

- [ ] **Step 2: 写四个 cell**

`ProfileAvatarCell`（色块头像 + 两行文字）、`ProfileStatCell`（数字 + 标签，居中）、`ProfileGridCell`（圆角色块图标 + 一行标题，居中）、`ProfileRowCell`（标题 + ›）。

- [ ] **Step 3: 写 VC**

hint：「4 段拼装：大卡 / 统计 / 图标网格 / 列表行」。点击任意 item → `onEvent?("点击 <标题>")`。

- [ ] **Step 4: 构建并截图**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`
截图 `/tmp/profile.png`：四段顺序正确、网格 4 列不换行、每段之间有明显间距。

- [ ] **Step 5: 汇报（不 commit）**

---

### Task 5: 搜索结果页

**Files:** Modify `Example/ATListVM/BusinessScenarioDemos.swift`

**Interfaces:**
- Consumes: `ScenarioPageViewController`（Task 1）
- Produces `final class ScenarioSearchViewController: ScenarioPageViewController`；`entries` 追加一条

- [ ] **Step 1: 写搜索条**

`topAccessory` 是一个高 44 的容器：`UITextField`（圆角 8、`secondarySystemBackground`、placeholder「输入关键词」）+ 右侧「搜索」按钮。容器宽度由子类约束为屏宽−32。

- [ ] **Step 2: 写 VM**

`SearchResultVM: ATListVM`（默认手动 proxy）。`func apply(query: String)`：

- 命中（关键词包含 "灯" 或 "h"）→ 新建 section：`itemVMs` = 6 条 `SearchResultItemVM`（标题 + 摘要），`itemSize = (屏宽−32, 72)`，无 footer
- 未命中 → 新建 section：`itemVMs = []`，`footerId = SearchEmptyFooterView.footerId`，`footerSize = (屏宽, 160)`
- 最后 `viewProxy.sectionVMs = [section]` + `reloadData()`

`SearchEmptyFooterView: ATListReuseableView` 显示「没有找到相关结果」。

- [ ] **Step 3: 写 VC**

点「搜索」：`show("搜索中…")` → `DispatchQueue.main.asyncAfter(deadline: .now() + 0.4)` → `apply(query:)` → `show("命中 N 条" / "无结果")`。页面初始为空态（按未命中处理）。

- [ ] **Step 4: 构建并截图（先验点）**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`
输入 `abc` 截图 `/tmp/search-empty.png`：**0 条 item 的 section 是否显示了 footer 空态**。
**若 footer 不显示**：改成 overlay 方案——在 collectionView 之上叠一个空态 `UIView`（图片占位 + 文案），`apply` 里切 `isHidden`，不依赖 footer；同步在设计文档里改这一页的写法。

- [ ] **Step 5: 截图验证命中态**

输入 `灯` 截图 `/tmp/search-hit.png`：6 条结果、无 footer、`eventLabel` 显示「命中 6 条」。再输入 `abc` 确认能回到空态。

- [ ] **Step 6: 汇报（不 commit）**

---

### Task 6: 横向卡片流

**Files:** Modify `Example/ATListVM/BusinessScenarioDemos.swift`

**Interfaces:**
- Consumes: `ScenarioPageViewController`（Task 1）
- Produces `final class ScenarioHorizontalRankViewController: ScenarioPageViewController`；`entries` 追加一条

- [ ] **Step 1: 写 VC 与 VM**

`ScenarioHorizontalRankViewController` 用 `super.init(..., scrollDirection: .horizontal, collectionViewHeight: 180)`。`RankListVM: ATListVM` 一个 section：12 张卡 + 末尾「更多」卡，`itemSize = (140, 180)`、`minimumLineSpacing = 12`、`sectionInset = (0, 16, 0, 16)`。

`RankCell: ATListCell`：封面色块（高 110）+ 序号 + 标题；「更多」卡用虚线边框 + 居中「更多」。

- [ ] **Step 2: 补说明区**

collectionView 只占 180 高，下面补一个多行 `UILabel`（13pt、`secondaryLabel`）：说明「横向流只需一个 section；卡片宽由 itemSize 决定；collectionView 自身高度要单独约束」，约束为 top = collectionView.bottom + 16、左右 16。避免页面下半屏空白。

- [ ] **Step 3: 构建并截图**

Run: `bash Example/build/demo/build.sh` → `** BUILD SUCCEEDED **`
截图 `/tmp/horizontal.png`：一行卡片、可横滑、「更多」卡在最右、下方有说明文字、没有半屏空白。

- [ ] **Step 4: 汇报（不 commit）**

---

## 收尾（全部任务后一次）

- [ ] 从首页依次点进 6 条，逐页截图，确认无 Auto Layout 冲突日志：
      `xcrun simctl spawn 443E4D5B-2076-4879-A97E-7BEBCF911403 log stream --predicate 'eventMessage CONTAINS "Unable to simultaneously satisfy"'`
      运行期间不应有输出。
- [ ] 把 6 张截图和一句结论汇报给用户，说明与设计文档的差异（尤其是 Task 2 / Task 5 的先验点走了主路还是退路）。
