# Example Demo 两级菜单实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Example 首页改成「手动布局 / 自动布局」两个分类，各自进入一个 demo 列表，共 12 条示例覆盖 ATListVM 的公开用法，并把社区信息流作为自动类的复杂示例。

**Architecture:** 一个通用 `DemoEntry` + `DemoMenuViewController`（`UITableView` 驱动）承载两张分类列表；每个 demo 文件的 `entries` 静态数组声明自己有哪些条目，`ViewController` 只负责把两类的 entries 拼起来。所有 demo 复用已有的 `config(listVM:)` + `config(viewProxy:)` 接入方式。

**Tech Stack:** Swift 5 / UIKit / SnapKit（已有）/ ATListVM（本地 pod）

**Spec:** `docs/superpowers/specs/2026-11-24-example-demo-menu-design.md`

## Global Constraints

- **只改 `Example/`，不动 `ATListVM/Classes/` 任何文件。**
- 每个新增 `.swift` 必须在 `Example/ATListVM.xcodeproj/project.pbxproj` 补齐四处：`PBXBuildFile`、`PBXFileReference`、所属分组的 `children`、target 的 `Sources` build phase。缺一处就编译不过。
- 现有 `AutoHeightDemoViewController.swift`、`AutoWidthDemoViewController.swift` 的文件内容不改，只被菜单引用。
- iOS 部署目标 13.0；不新增第三方依赖；菜单本身不用 ATListVM 实现。
- **不自动提交**：仓库暂存区里有大量既有改动，`git add && git commit` 会一并提交。每个任务的「Commit」动作统一替换为「向用户汇报本任务改动清单」。

## Review Focus

- **pbxproj 漏登记**：新增文件在 Xcode 里看不到 → `cannot find 'XxxViewController' in scope`。
- **手动 demo 的 itemVM 忘记设 `itemSize`**：默认 `.zero` → cell 高度 0，列表看起来是空白。
- **`headerId` 设了但 `headerSize` 还是 `.zero`**：header 有 view 但高度 0，表现为「header 没生效」。
- **`config(listVM:)` 与 `config(viewProxy:)` 少调一个**：少前者是 cell 未注册 → 空白 cell；少后者是 delegate/dataSource 为 nil → 完全不显示。
- **自适应列表里的 header 只认 `headerSize`**：`ATListViewAutoProxy` 只让 cell 自适应，header 不会跟着内容撑开，必须显式给高度。

---

### Task 1: 菜单骨架与文件登记

**Files:**
- Create: `Example/ATListVM/DemoShared.swift`
- Create stubs: `Example/ATListVM/ManualLayoutDemos.swift`、`ManualBehaviorDemos.swift`、`AutoDemos.swift`、`CommunityDemo.swift`
- Modify: `Example/ATListVM/ViewController.swift`
- Modify: `Example/ATListVM.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces:
  - `struct DemoEntry { let title: String; let detail: String; let make: () -> UIViewController }`
  - `final class DemoMenuViewController: UIViewController { init(title: String, entries: [DemoEntry]) }`
  - 四个 `enum`，各含 `static let entries: [DemoEntry]`：`ManualLayoutDemos`、`ManualBehaviorDemos`、`AutoDemos`、`CommunityDemo`
- Task 2–5 只填充各自的 `entries` 与 demo 类，不改 `DemoShared.swift`。

- [ ] **Step 1: 写 `DemoShared.swift`**

`DemoEntry` 如上；`DemoMenuViewController` 用 `UITableView(style: .insetGrouped)`，每行显示 `title`（17pt）与 `detail`（13pt、secondaryLabel、2 行），点击 `navigationController?.pushViewController(entry.make(), animated: true)`。标题用 `title` 属性。

- [ ] **Step 2: 写四个 stub 文件**

每个文件只有一行有效内容，例如 `ManualLayoutDemos.swift`：

```swift
import UIKit
import ATListVM

enum ManualLayoutDemos {
    static let entries: [DemoEntry] = []
}
```

另外三个同理，`enum` 名字分别为 `ManualBehaviorDemos`、`AutoDemos`、`CommunityDemo`。

- [ ] **Step 3: 改 `ViewController.swift` 首页**

删掉现有的纵向/横向两个按钮与 `clickBtn`，改成两个分类按钮，分别 push：

```swift
DemoMenuViewController(title: "手动布局",
                       entries: ManualLayoutDemos.entries + ManualBehaviorDemos.entries)
DemoMenuViewController(title: "自动布局",
                       entries: AutoDemos.entries + CommunityDemo.entries)
```

自动类的两条现有 demo（纵向/横向）由 Task 4 补进 `AutoDemos.entries`；本任务先只拼上述两类。

- [ ] **Step 4: 登记 pbxproj**

为 `DemoShared.swift`、`ManualLayoutDemos.swift`、`ManualBehaviorDemos.swift`、`AutoDemos.swift`、`CommunityDemo.swift` 各补 `PBXBuildFile` + `PBXFileReference`，加入 `ATListVM` 分组 `children`，加入 target 的 `Sources`。

- [ ] **Step 5: 构建**

Run:
```bash
cd Example && CLANG_MODULE_CACHE_PATH="$PWD/build/demo/mc" SWIFT_MODULE_CACHE_PATH="$PWD/build/demo/mc" xcodebuild -workspace ATListVM.xcworkspace -scheme ATListVM-Example -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/build/demo/derived" CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" | sort -u
```
Expected: `** BUILD SUCCEEDED **`，且没有来自项目源码的 warning。

- [ ] **Step 6: 启动截图首页**

装到已启动的模拟器并截图，确认首页只有两个分类入口、标题正确：
```bash
xcrun simctl install <booted-device> Example/build/demo/derived/Build/Products/Debug-iphonesimulator/ATListVM_Example.app
xcrun simctl launch <booted-device> com.brownlee.Demo
xcrun simctl io <booted-device> screenshot /tmp/home.png
```
Expected: 截图里是「手动布局」「自动布局」两个入口。

- [ ] **Step 7: 汇报（不 commit）**

---

### Task 2: 手动布局类 5 条

**Files:** Modify `Example/ATListVM/ManualLayoutDemos.swift`；Modify `Example/ATListVM/DemoShared.swift`（追加手动类公用 cell/itemVM）

**Interfaces:**
- Consumes: `DemoEntry`（Task 1）
- Produces: 5 个 `DemoEntry` + 5 个 `UIViewController` 子类

- [ ] **Step 1: 写手动类公用件**

`DemoTextItemVM: ATListItemVM`（`title` / `subtitle` / `background`）；`DemoTextCell: ATListCell`（标题 16pt + 副标题 13pt、`numberOfLines`，副标题 `bottom` 钉到 `contentView`）；`DemoSectionTitleView: ATListReuseableView`（按 `headerId`/`footerId` 显示不同文案）。

- [ ] **Step 2: 写 5 条 demo**

| 条目 | 要展示的写法 |
|---|---|
| 固定尺寸 | `ATListVM()` 默认即 `ATListViewProxy`；三条 item 的 `itemSize` 分别 48 / 72 / 120 高、宽度 = 屏宽 − 左右 inset；`sectionInset`、`minimumLineSpacing = 10` |
| 两列 | `itemSize.width = (屏宽 − 32 − 12) / 2`，`minimumInteritemSpacing = 12`，6 条不同高度 |
| header / footer | `section.headerId` / `footerId` + `headerSize = 44` / `footerSize = 36`；注册 `DemoSectionTitleView` 两种复用 id |
| 单 section | 只设 `viewProxy.defaultSectionVM`，不填 `sectionVMs` |
| 手算高度 | cell 覆写 `layoutSubviews` 按行数摆子视图；`itemSize.height` 用同一个公式算出来 |

每个 VC：用一个说明 label（13pt、secondaryLabel，2 行）说明「这条在演示什么」，下面是全屏 collectionView。

- [ ] **Step 3: 构建**

Run: 同 Task 1 Step 5。
Expected: `** BUILD SUCCEEDED **`，0 项目源码 warning。

- [ ] **Step 4: 对照 Review Focus 自查**

逐条确认：5 条 demo 的每个 `itemVM.itemSize` 宽度与高度都 > 0；有 `headerId`/`footerId` 的 demo 都同时给了 `headerSize`/`footerSize`；每个 VC 都成对调用了 `config(listVM:)` 与 `config(viewProxy:)`。

- [ ] **Step 5: 汇报（不 commit）**

---

### Task 3: 手动行为类 2 条

**Files:** Modify `Example/ATListVM/ManualBehaviorDemos.swift`

**Interfaces:**
- Consumes: `DemoEntry`（Task 1）、`DemoTextItemVM` / `DemoTextCell`（Task 2）
- Produces: 2 个 `DemoEntry` + 2 个 VC

- [ ] **Step 1: 刷新与 reload**

四颗按钮分别驱动：`refreshItemBlock`（只改第一条的文案，行数不变）、`reloadItemBlock`（第一条高度在 64/120 之间切换）、`reloadSectionBlock`（追加一行）、`reloadListBlock`（整表重来）。页面上显示一条状态文案说明刚才走了哪条路径。

- [ ] **Step 2: 选中与显示回调**

`onSelectItemBlock` 改选中项的标题；`itemVM.willDisplay` / `didEndDisplaying`、`ATListViewProxyDelegate` 的 `cellWillDisplay`、`ATListVMDelegate.listVMDidChange` 都打到页面底部的日志 label（只保留最后一行）。

- [ ] **Step 3: 构建**

Run: 同 Task 1 Step 5。Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 4: 汇报（不 commit）**

---

### Task 4: 自动补充 2 条

**Files:** Modify `Example/ATListVM/AutoDemos.swift`

**Interfaces:**
- Consumes: `DemoEntry`（Task 1）
- Produces: `AutoDemos.entries` 含 4 条：纵向自适应高度、横向自适应宽度、混合、header / footer

- [ ] **Step 1: 接上现有两条**

`AutoDemos.entries` 前两条直接 `make: { AutoHeightDemoViewController() }`、`make: { AutoWidthDemoViewController() }`，标题「纵向自适应高度」「横向自适应宽度」。

- [ ] **Step 2: 混合**

同一 section 里混两类 item：一类 `itemSize = .zero`（交给自适应），一类 `itemSize = CGSize(width: 屏宽 − 32, height: 56)`（走手动分支）。每条 item 的副标题写清楚它属于哪一类。

- [ ] **Step 3: header / footer**

自适应列表 + `headerId`/`footerId`，`headerSize = 44`、`footerSize = 36`，说明写「header 只认 headerSize，不参与自适应」。

- [ ] **Step 4: 构建**

Run: 同 Task 1 Step 5。Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 5: 汇报（不 commit）**

---

### Task 5: 社区信息流

**Files:** Modify `Example/ATListVM/CommunityDemo.swift`

**Interfaces:**
- Consumes: `DemoEntry`（Task 1）、`DemoSectionTitleView`（Task 2）
- Produces: `CommunityDemo.entries`（1 条）+ `CommunityViewController`

- [ ] **Step 1: 数据与 section**

四个 section：搜索条 / 推荐话题 / 帖子 / 评论预览。帖子 section 用 `reloadSectionBlock` 追加行。section 的 `headerId` + `headerSize` 都要给。

- [ ] **Step 2: 帖子 cell**

头像（32×32）+ 昵称 + 正文（`numberOfLines = 0`）+ 九宫格（1 张时 160 宽、3/9 张按 3 列 72 高，行间距 4）+ 标签 + 「赞 N」「评论 N」行。所有约束钉在 `contentView` 上，`numberOfLines = 0`。

- [ ] **Step 3: 三条交互**

- **展开正文 → `itemVM.reloadItemBlock?()`**（高度变了必须重新测量；`refreshItemBlock` 不会）
- **点赞 → `itemVM.refreshItemBlock?()`**（只改数字，不重建）
- **加载更多 → `postSection.reloadSectionBlock?()`**，按钮旁注明「这里会重算整段，是 reloadSections 的固有代价」

- [ ] **Step 4: 事件条**

底部 32pt 高的事件 label，接 `ATListViewProxyDelegate` 与 `ATListVMDelegate`，显示最后一条回调。

- [ ] **Step 5: 构建**

Run: 同 Task 1 Step 5。Expected: `** BUILD SUCCEEDED **`，0 项目源码 warning。

- [ ] **Step 6: 逐屏截图自查（临时脚手架，不提交）**

临时把 `AppDelegate` 的根控制器换成直接 push 某个 demo（每次一个），`simctl` 启动截图，确认该 demo 的列表非空、cell 有高度、header 可见；看完还原 `AppDelegate`。至少覆盖：固定尺寸、两列、社区信息流。

- [ ] **Step 7: 汇报（不 commit）**

---

## 交付后：人工验收（需要用户）

按首页 → 两张列表 → 12 条 demo 走一遍，重点：
- 手动类 7 条是否都非空、尺寸符合说明
- 自动类「混合」里两类 item 是否真的一个手动一个自适应
- 社区示例：展开改高度、点赞只改数字、加载更多后往上滑（预期会闪，属已知取舍）

## 自检结果

- **Spec 覆盖**：菜单两级（Task 1）、手动 7 条（Task 2 的 5 条 + Task 3 的 2 条）、自动 5 条（Task 4 的 4 条 + Task 5 的社区）一一对应。
- **Review Focus 落点**：pbxproj（Task 1 Step 4）、itemSize（Task 2 Step 4 自查）、headerSize（Task 2 Step 4 + Task 4 Step 3）、config 成对（Task 2 Step 4）、自适应 header（Task 4 Step 3）。
- **已知缺口**：Example 没有可用的 XCTest（`xcodebuild test` 在本环境无法分配 pty），所以验证靠「编译 + 逐屏截图 + 人工点」。逐屏检查需要一个临时脚手架（Task 5 Step 6），不会进版本库。
