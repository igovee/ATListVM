import XCTest
import UIKit
import ATListVM

// MARK: - Spy 视图

final class SpyCell: ATListCell {
    static let reuseId = "SpyCell"
    private(set) var refreshCount = 0

    override func refreshSubviews(isFromVM: Bool) {
        refreshCount += 1
    }
}

final class SpyHeader: ATListReuseableView {
    static let reuseId = "SpyHeader"
    private(set) var refreshCount = 0

    override func refreshSubviews(isFromVM: Bool) {
        refreshCount += 1
    }
}

final class SpyFooter: ATListReuseableView {
    static let reuseId = "SpyFooter"
    private(set) var refreshCount = 0

    override func refreshSubviews(isFromVM: Bool) {
        refreshCount += 1
    }
}

// MARK: - VM

final class TestItemVM: ATListItemVM {
    var text = ""

    override func setupData() {
        super.setupData()
        cellId = SpyCell.reuseId
        itemSize = CGSize(width: 320, height: 44)
    }
}

// MARK: - Harness

/// 真窗口 + 真 collectionView + 真 proxy。库内刷新块都 dispatch 到主队列，
/// 所有断言前要先 `waitMainQueue()` 把主队列跑空。
final class Harness {

    let window: UIWindow
    let collectionView: UICollectionView
    let listVM: ATListVM
    let proxy = ATListViewProxy()

    init() {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: window.bounds, collectionViewLayout: layout)
        collectionView.register(SpyCell.self, forCellWithReuseIdentifier: SpyCell.reuseId)
        collectionView.register(SpyHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SpyHeader.reuseId)
        collectionView.register(SpyFooter.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: SpyFooter.reuseId)

        listVM = ATListVM(viewProxy: proxy)

        window.addSubview(collectionView)
        window.makeKeyAndVisible()

        collectionView.config(listVM: listVM)
        collectionView.config(viewProxy: proxy)
    }

    /// 配一次数据：`sectionCount` 段，每段 `itemsPerSection` 条，可选 header/footer。
    func configure(sectionCount: Int = 1,
                   itemsPerSection: Int = 2,
                   headerId: String? = nil,
                   footerId: String? = nil) -> [ATListSectionVM] {
        var sections: [ATListSectionVM] = []
        for _ in 0..<sectionCount {
            let section = ATListSectionVM()
            section.itemVMs = (0..<itemsPerSection).map { _ in
                let item = TestItemVM()
                item.text = "item"
                return item
            }
            if let headerId = headerId {
                section.headerId = headerId
                section.headerSize = CGSize(width: 320, height: 30)
            }
            if let footerId = footerId {
                section.footerId = footerId
                section.footerSize = CGSize(width: 320, height: 30)
            }
            sections.append(section)
        }
        proxy.sectionVMs = sections
        reload()
        return sections
    }

    func reload() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

    func waitMainQueue(_ interval: TimeInterval = 0.05) {
        RunLoop.main.run(until: Date().addingTimeInterval(interval))
    }

    func cell(at indexPath: IndexPath) -> SpyCell? {
        collectionView.cellForItem(at: indexPath) as? SpyCell
    }

    func header(section: Int) -> SpyHeader? {
        collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
                                         at: IndexPath(item: 0, section: section)) as? SpyHeader
    }

    func footer(section: Int) -> SpyFooter? {
        collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter,
                                         at: IndexPath(item: 0, section: section)) as? SpyFooter
    }
}

// MARK: - 用例

final class ATListVMTests: XCTestCase {

    private var harness: Harness!

    override func setUp() {
        super.setUp()
        harness = Harness()
    }

    override func tearDown() {
        harness.window.isHidden = true
        harness = nil
        super.tearDown()
    }

    /// refreshItemBlock 只重绘可见 cell，不触发重新测量
    func testRefreshItemBlockUpdatesVisibleCell() {
        _ = harness.configure()
        guard let cell = harness.cell(at: IndexPath(item: 0, section: 0)) else {
            return XCTFail("第 0 条没有可见 cell")
        }
        let before = cell.refreshCount
        harness.proxy.sectionVMs[0].itemVMs[0].refreshItemBlock?()
        harness.waitMainQueue()
        XCTAssertEqual(cell.refreshCount, before + 1, "refreshItemBlock 应重绘可见 cell 一次")
    }

    /// reloadItemBlock 会按新的 itemSize 重新测量
    func testReloadItemBlockAppliesNewItemSize() {
        let sections = harness.configure()
        let item = sections[0].itemVMs[0]
        item.itemSize = CGSize(width: 320, height: 88)
        item.reloadItemBlock?()
        harness.waitMainQueue()
        harness.collectionView.layoutIfNeeded()

        let height = harness.cell(at: IndexPath(item: 0, section: 0))?.frame.height ?? 0
        XCTAssertEqual(height, 88, accuracy: 1, "reloadItemBlock 后 cell 高度应变成 88")
    }

    /// refreshHeaderBlock 要能刷到表头
    func testRefreshHeaderBlockReachesHeader() {
        let sections = harness.configure(itemsPerSection: 20, headerId: SpyHeader.reuseId)
        // 收缩到 2 条：制造「数据变了、UI 还没跟上」的时机
        sections[0].itemVMs = Array(sections[0].itemVMs.prefix(2))
        sections[0].reloadSectionBlock?()
        harness.waitMainQueue()

        guard let header = harness.header(section: 0) else {
            return XCTFail("表头没有出现")
        }
        let before = header.refreshCount
        sections[0].refreshHeaderBlock?()
        harness.waitMainQueue()
        XCTAssertEqual(header.refreshCount, before + 1, "refreshHeaderBlock 应刷到表头")
    }

    /// refreshFooterBlock 要能刷到表尾
    func testRefreshFooterBlockReachesFooter() {
        let sections = harness.configure(itemsPerSection: 20, footerId: SpyFooter.reuseId)
        sections[0].itemVMs = Array(sections[0].itemVMs.prefix(2))
        sections[0].reloadSectionBlock?()
        harness.waitMainQueue()
        guard let footer = harness.footer(section: 0) else {
            return XCTFail("表尾没有出现")
        }
        let before = footer.refreshCount
        sections[0].refreshFooterBlock?()
        harness.waitMainQueue()
        XCTAssertEqual(footer.refreshCount, before + 1, "refreshFooterBlock 应刷到表尾")
    }


    /// item 没上过屏时，调用方可以先用 isReadyForItemRefresh 判断
    func testIsReadyForItemRefresh() {
        let fresh = TestItemVM()
        XCTAssertFalse(fresh.isReadyForItemRefresh, "没被展示过的 item 不应 ready")

        let sections = harness.configure()
        XCTAssertTrue(sections[0].itemVMs[1].isReadyForItemRefresh, "上屏后应 ready")
    }

    /// reloadItemBlock 拿到失效 indexPath 时不能抛 UIKit 异常（旧实现会崩）
    func testReloadItemBlockWithStaleIndexPathDoesNotCrash() {
        let sections = harness.configure(itemsPerSection: 20)
        // 取一条「已经上过屏」的（20 条里只有前 10 条左右在窗口内）
        guard sections[0].itemVMs.count > 8 else {
            return XCTFail("数据不够")
        }
        let staleItem = sections[0].itemVMs[8]
        XCTAssertNotNil(staleItem.indexPath, "这一条应该已经上过屏")

        // 裁到 2 条并重载：staleItem 的 indexPath 还停在旧位置，已越界
        sections[0].itemVMs = Array(sections[0].itemVMs.prefix(2))
        sections[0].reloadSectionBlock?()
        harness.waitMainQueue()

        staleItem.reloadItemBlock?()
        harness.waitMainQueue()

        XCTAssertEqual(harness.collectionView.numberOfItems(inSection: 0), 2, "列表应保持 2 条且不崩")
    }

    /// 从没上过屏的空 section 刷表头：不能退回 0 号段
    func testRefreshHeaderBlockTargetsItsOwnSection() {
        let section0 = ATListSectionVM()
        section0.itemVMs = (0..<2).map { _ in TestItemVM() }
        section0.headerId = SpyHeader.reuseId
        section0.headerSize = CGSize(width: 320, height: 30)

        // 第 1 段一开始就没有 item，cellForItemAt 从未为它跑过 → indexPath 一直是 nil
        let section1 = ATListSectionVM()
        section1.headerId = SpyHeader.reuseId
        section1.headerSize = CGSize(width: 320, height: 30)

        harness.proxy.sectionVMs = [section0, section1]
        harness.reload()

        guard let header0 = harness.header(section: 0),
              let header1 = harness.header(section: 1) else {
            return XCTFail("两段表头应都在屏上")
        }
        let before0 = header0.refreshCount
        let before1 = header1.refreshCount

        section1.refreshHeaderBlock?()
        harness.waitMainQueue()

        XCTAssertEqual(header1.refreshCount, before1 + 1, "第 1 段的表头应该被刷到")
        XCTAssertEqual(header0.refreshCount, before0, "第 0 段的表头不应该被误刷")
    }
}
