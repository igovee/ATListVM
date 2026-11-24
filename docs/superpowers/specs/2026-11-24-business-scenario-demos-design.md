# Example「业务场景」示例集设计

日期：2026-11-24
状态：待批准
规模：项目（只动 Example，不动库）

## 为什么做

现有 Demo 是按**技术**分类的（手动布局 / 自动布局）：固定尺寸、两列、header/footer、手算高度、
自撑开、异步图片撑高、展开收起、空态、insert/append、超长列表……覆盖的是机制，没有一个页面
长得像真实业务页。

上一轮讨论把 ATListVM 的适配场景分成了三档，其中「直接能用」这一档有 8 条，Demo 里只覆盖了
2 条（`AutoSceneDemos` 的「卡片内嵌横向列表」、`CommunityDemo` 的「社区信息流」）。剩下 6 条
值得各有一个页面：它们既是用法说明书，也是"这个框架能承接什么页面"的展示。

## 目标

- 首页新增第三个入口「业务场景」，进去是列表，6 条各进一个页面。
- 每个页面聚焦一种业务形状，且**只用 ATListVM 现成能力**，不新增库代码。
- 6 个页面合起来覆盖：分组异质行、尺寸切换、增量加载、自撑开异质高度、多段拼装、
  整表替换与空态、横向布局。

## 非目标

- 不改库（`ATListVM/Classes/**` 一行不动）。
- 不接网络，不做真实搜索匹配和分页接口。
- 不引入图片资源，假数据用色块和文字。
- 不重写菜单（继续用 `DemoMenuViewController` 的 `UITableView`）。
- 不做「综合业务页」（把多种形状塞进一页）。

## 反目标

- 为了页面好看往 cell 里堆与框架用法无关的装饰，把示例变成 UI 作业。
- 以"示例需要"为理由去改库的默认行为。
- 每个页面自成一套风格（字号、圆角、间距各写各的），让读者以为框架有样式约定。

## 约束

- Example 工程**没有**文件夹同步：每个新增 `.swift` 必须同时登记进
  `Example/ATListVM.xcodeproj/project.pbxproj`（PBXBuildFile / PBXFileReference / 分组 / Sources）。
- 部署目标 13.0，Swift 5，只用 SnapKit + ATListVM，不加第三方依赖。
- 菜单保持两级：首页 → 场景列表 → 页面。

## 考虑过的方案

- **A（选中）**：新增第三个顶级分组「业务场景」，一场景一页。
  代价：首页从两个按钮变三个，多一层心智；收益是分类干净，以后加场景只往里塞。
- **B**：塞进现有「自动布局」菜单（`CommunityDemo` 现在就是这么放的）。
  代价：菜单同时按"技术"和"业务"两种维度分类，用户点开后不知道该按哪种找。
- **C**：合成一个「综合业务页」，把 6 种形状揉进一页。
  代价：单场景的边界被耦合淹没，哪块出问题不好定位；它更像验收页，不是示例页。

选 A：示例集的分类应该跟读者的查找方式走——读者要么在找"我要一个设置页"，要么在找
"我这段高度为什么算不出来"，前者归业务场景，后者已有「手动/自动」两个技术分组承接。

## 页面设计

六个页面共用一个骨架，跟 `CommunityDemo` 一致：顶部一行 hint（12 号字、`secondaryLabel`），
底部 `eventLabel`（高 24）显示最近一次回调，中间是 `collectionView`。

### 1. 设置页 · `ScenarioSettingsViewController`

```
 账号
 ┌────────────────────────────┐
 │ 头像与昵称            张同学 › │ 56
 │ 绑定手机         138****0000 › │ 56
 └────────────────────────────┘
 偏好
 ┌────────────────────────────┐
 │ 深色跟随后台              [○] │ 56
 │ 消息推送                  [●] │ 56
 └────────────────────────────┘
 ┌────────────────────────────┐
 │        退出登录（红）          │ 52
 └────────────────────────────┘
```

- `SettingsListVM: ATListVM`，默认手动 proxy，3 个 section，cell 固定高。
- 三种 cell：`SettingsValueRowCell`（标题 + 右侧值 + 箭头）、`SettingsSwitchRowCell`
  （标题 + `UISwitch`）、`SettingsDangerRowCell`（红色居中、无箭头）。
- 开关切换只调 `reloadItemBlock`（不涉及高度）；点行在 `onSelectItemBlock` 里打 eventLabel。
- 行数以草图为准（5 行），不受下文「每页 6–12 条」的约束。
- 证明：分组 + 异质行 + 单行刷新。

### 2. 商品列表 · `ScenarioProductListViewController`

- 导航栏右侧「切换视图」：两列 ↔ 单列。
- 两列 `itemSize = ((屏宽 - 32 - 12) / 2, 180)`；单列 `itemSize = (屏宽 - 32, 120)`。
  切换时逐条改 `itemSize`，再 `reloadSectionBlock` 让布局重算。
- 分页：`ATListItemVM.willDisplay()` 里判断是否是最后一条，追加 6 条，最多 3 页，
  到顶后 eventLabel 显示「没有更多」。
  **注意**：`ATListSectionVM.insert/append` 是同步批量更新，直接在 `willDisplay` 里调会重入
  `performBatchUpdates`，必须 `DispatchQueue.main.async` 包一层。
- 证明：尺寸切换 + 增量加载。

### 3. 消息中心 · `ScenarioMessageCenterViewController`

- `ATListViewAutoProxy`，宽度锁定为屏宽 - 32，cell 自撑开。
- 四种行：系统通知（标题 + 多行正文）、点赞（头像块 + 一句）、评论（引用块 + 正文）、
  关注（小卡片）。
- 未读点一行变已读 → `refreshItemBlock`（只改可见 cell 的样式，不重算高度）；
  顶部「全部已读」批量 refresh。
- 证明：自撑开 + 异质高度 + 局部刷新。

### 4. 个人中心 · `ScenarioProfileViewController`

- 手动定高，**4 个 section**：头像卡 120、数据统计行 72、功能入口网格（一行 4 个、两行）、
  设置行 3 条。
- 功能入口的 8 个方形 item 共用一个 section，位置夹在两段列表之间；每段用自己的
  `sectionInset` 做出"卡片分开"的感觉。
- 证明：多段拼装 + 网格与列表混排。

### 5. 搜索结果页 · `ScenarioSearchViewController`

- 顶部 `UITextField` + 「搜索」按钮（不用 `UISearchController`，避免跟示例导航互相干扰）。
- 点搜索后 0.4s 出结果：命中给 1 个 section + N 条（标题 + 摘要）；没命中时新建一个 section：
  0 条 item + `footerId` / `footerSize`（高 160，内容「没有找到相关结果」）撑出空态。
  有结果的那个 section 不带 footer——每次搜索都重建 section 对象，不要复用。
- 换关键词就是整表替换：`viewProxy.sectionVMs = [...]` + `reloadData()`。
- **先验**：0 条 item 的 section 会不会布局 footer。本仓库只跑过"0 条 + header"的空态
  （`AutoSceneDemos`），footer 这条路没被验证过；验不过就退成 collectionView 之外的
  overlay，仍然只动 Example。
- 证明：整表替换 + 空态。

### 6. 横向卡片流 · `ScenarioHorizontalRankViewController`

- 单 section，`layout.scrollDirection = .horizontal`，`itemSize = (140, 180)`，
  `minimumLineSpacing = 12`，`sectionInset = (0, 16, 0, 16)`。
- 末位是「更多」卡（虚线边框），点击进 eventLabel。
- collectionView 高度约束到「卡片高 + 上下 inset」，**不要**撑满整屏——横向条只有一行，
  拉满会留出两屏空白，正好违反验收里的"不空半屏"。
- 证明：横向 + 固定尺寸。

## 共用约定

- 每个 cell 用 `static let reuseId`，在对应 VM 的 `register(collectionView:)` 里注册；
  数据在 `createData()` 里造，`viewDidLoad` 末尾调 `reloadData()`。
- 手动页的 `itemSize` **宽高都要给全**（`ATListViewProxy.sizeForItemAt` 原样返回 `itemVM.itemSize`，
  宽度为 0 就什么都画不出来），例如 `屏宽 - 32`。
- 视觉沿用现有 Demo 风格：`secondarySystemBackground` 底、8 圆角、16 号标题、13 号副标题。
- 假数据纯代码，每个页面 6–12 条。
- 文件组织：新增一个 `BusinessScenarioDemos.swift`（约 800 行，按 `// MARK:` 分段）。
  如果超过 900 行，按「列表型（设置/商品/消息）」和「页面型（个人中心/搜索/横向）」拆成两个文件。

## 落地顺序

1. 菜单接线（`ViewController` 第三个按钮 + `BusinessScenarioDemos.entries`）
2. 设置页（最小闭环，先跑通手动 proxy）
3. 商品列表（尺寸切换 + 增量加载）
4. 消息中心（自撑开）
5. 个人中心
6. 搜索结果
7. 横向卡片流

每个页面独立可验收，做完一个就能点开看，不必等全部做完。

## 验证重点（先验这两个）

两条路径本仓库**都没跑过**，且各自是页面证明点的全部，所以先验再写业务：

1. **两列 ↔ 单列切换后，`reloadSectionBlock` 会不会让布局重新取 `itemSize`**——这是第 2 页的
   全部证明点。验不过就退成整表 `reloadData()`，并在页面上注明"整段重建会丢滚动位置"。
2. **0 条 item 的 section 会不会布局 footer**——这是第 5 页的空态。验不过就退成
   collectionView 之外的 overlay 空态视图。

编译与截图沿用现有路子：`bash Example/build/demo/build.sh` 出 `BUILD SUCCEEDED`，
模拟器用临时探针 + `xcrun simctl io ... screenshot`。

## 验收

- 6 个入口都能进、能滚，控制台没有 Auto Layout 冲突日志。
- 每个页面的 eventLabel 对点击/切换/已读/搜索有可见反馈。
- 手动页的 `itemSize` 与实际显示一致，不出现半行截断或空半屏。
- 自动页长文案撑高、短文案不留空。

## 留给 builder

- 每个 cell 的具体视觉细节（字号、颜色、圆角、间距）按上面约定自行决定。
- 假数据的文案、条数（每页 6–12 条）。
- 分页每次追加的条数。
- 是否按 900 行阈值拆文件。
