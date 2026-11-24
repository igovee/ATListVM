# 动态刷新示例页设计（短）

日期：2026-11-24
状态：待批准
规模：小改动（新增 1 个页面 + 1 条菜单，不动库）

## 为什么做

现有「刷新与 reload」页是按钮驱动的机制说明（4 个 block 各一个按钮），不回答业务里的真实问题：
**数据自己变了的时候，该用哪个 block？** 读者看完还是不知道"改个数字"和"改个状态导致高度变化"要区别对待。

## 目标

新增一页「动态刷新」进「业务场景」分组：定时器每秒改一条 ItemVM 的数据，按变化类型自动选 block，
并在页面上实时显示"每种 block 调了几次、当前几条、内容总高多少"。

每次 tick 随机挑一种变化：

| 变化 | 用什么 | 读者看到什么 |
|---|---|---|
| 亮度 / 信号值变化 | `refreshItemBlock` | 数字变、行高不变 |
| 在线 → 离线（卡片多一行「已离线」） | 改 `itemSize.height` + `reloadItemBlock` | 这一行变高，别的行不动 |
| 设备上线 / 移除 | 改 `itemVMs` + `reloadSectionBlock` | 行数变 |
| 切换分组（整表换数据） | `reloadListBlock` | 整表重建 |
| 表头文案变化 | `section.refreshHeaderBlock` | 表头变，列表不动 |
| 表尾时间变化 | `section.refreshFooterBlock` | 表尾变，列表不动 |

## 非目标

- 不接网络、不做真实设备协议，数据全在内存里造。
- 不加动画（动画会掩盖"到底有没有重新测量"）。
- 不做性能压测 / 长列表压测（那是另一个示例）。
- ~~不演示 section header 刷新~~ → 已改为必须覆盖（用户明确要求 item 与 section 的 refresh block 都要有示例）。

## 反目标

- 为了看着热闹把刷新频率调到看不清。
- 用 `reloadData` 包打天下——那样这页就失去了意义。

## 约束

- 新文件 `Example/ATListVM/DynamicRefreshDemo.swift`，登记 pbxproj 四处。
- 页面沿用 `ScenarioPageViewController` 骨架（hint / collectionView / eventLabel）。
- 定时器在 `viewDidDisappear` 必须停，避免离开页面还在跑。
- 只改 Example，不动 `ATListVM/Classes/`。

## 交互

- 进页面自动开始，顶部一个「暂停 / 继续」按钮。
- 统计条：`refresh 12 · reloadItem 5 · reloadSection 2 · reloadList 1 · 当前 6 条 · 高度 1042pt`。
- eventLabel：最近一次 `reloadItemBlock → 客厅灯 离线（高度 84 → 112）`。

## 落地时发现的库问题（已修）

`ATListSectionVM.refreshHeaderBlock` / `refreshFooterBlock` 原来用 `sectionVM.indexPath` 去查
supplementary view，而这个值在 `cellForItemAt` 里被记成「最后一个 cell 的 indexPath」；supplementary
view 按 `[section, 0]` 建索引，所以 cell 多于一条时永远查不到，表头表尾刷不动。已改为
`IndexPath(item: 0, section:)`。GoveeHome 里没有使用这两个 block（grep 无引用），对线上无影响。

## 落地时新增的库 API

`ATListReuseableView` 补了两个可重写钩子 `willDisplay()` / `didEndDisplaying()`，由
`ATListViewProxyBase` 从 `willDisplaySupplementaryView` / `didEndDisplayingSupplementaryView`
转发。动态刷新页的表头表尾把次数写进副标题（「出现 N 次 / 离开 M 次」）作为验证。

坑：UIKit 这两个 delegate 的 selector 拼写不一样——`willDisplaySupplementaryView:forElementKind:`
对 `didEndDisplayingSupplementaryView:forElementOfKind:`（多一个 `Of`）。写成前者的拼法，
Swift 会把它当普通方法，**不会进 ObjC 头、UIKit 永远调不到**，而且没有编译告警。

## 考虑过的方案

- **A（选中）**：一页里把一个"设备在线状态"列表交给定时器驱动。
  理由：设备状态天然同时包含"数值变化"和"高度变化"两种，不用硬凑。
- **B**：三个独立小页（各演示一种 block）。页数多，读者要在三页之间对齐，不如一页直观。
- **C**：扩展已有的「刷新与 reload」页。那是手动路径的机制说明，扩它会把它变成两件事混在一起。

## 留给 builder

- 具体假数据文案、设备名、tick 间隔（建议 1 秒）。
- 统计条与列表的排版细节。
- 离线卡片多出来的那一行写什么、占多高（建议 28pt）。
