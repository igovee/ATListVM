//
//  ATListSectionVM.swift
//  ATListVM
//

import UIKit

open class ATListSectionVM {
    public typealias ReloadBlock = (() -> Void)
    public typealias RefreshBlock = (() -> Void)
    
    public internal(set) var reloadListBlock:ReloadBlock?
    public internal(set) var reloadSectionBlock:ReloadBlock?
    public internal(set) var refreshHeaderBlock:RefreshBlock?
    public internal(set) var refreshFooterBlock:RefreshBlock?
    
    public internal(set) weak var collectionView: UICollectionView?
    /// 该 section 在 collectionView 里的下标，`numberOfItemsInSection` 时赋值。
    /// 与 `collectionView` 一样，同一时刻只属于「最后一个查询过数量的」那个 collection view。
    public internal(set) var section: Int?

    public var headerId:String?
    public var footerId:String?
    public var layoutSection:NSCollectionLayoutSection?
    public var headerSize:CGSize = .zero
    public var footerSize:CGSize = .zero
    public var sectionInset:UIEdgeInsets = .zero
    public var minimumLineSpacing:CGFloat = 0
    public var minimumInteritemSpacing:CGFloat = 0
    public var itemVMs:[ATListItemVM] = []
    
    public init() {
        _setupBlock()
        setupData()
    }
    func _setupBlock() {
        reloadListBlock = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadData()
                }
            }
        }
        reloadSectionBlock = { [weak self] in
            guard let self = self, let section = self.section else { return }
            DispatchQueue.main.async {
                guard let collectionView = self.collectionView,
                      section < collectionView.numberOfSections else { return }
                UIView.performWithoutAnimation {
                    collectionView.reloadSections(IndexSet(integer: section))
                }
            }
        }
        refreshHeaderBlock = { [weak self] in
            guard let self = self else { return }
            // supplementary view 按 [section, 0] 建索引；self.section 在 numberOfItemsInSection 里赋值，
            // 空 section 也有值（不像 item 的 indexPath 要靠 cell 上屏才有）。
            guard let section = self.section else { return }
            let indexPath = IndexPath(item: 0, section: section)
            DispatchQueue.main.async {
                guard let collectionView = self.collectionView else { return }
                UIView.performWithoutAnimation {
                    if let header = collectionView.supplementaryView(forElementKind: ATCollectionElementKind.sectionHeader, at: indexPath) as? ATListReuseableView {
                        header.refreshSubviews(isFromVM: true)
                        header.layoutIfNeeded()
                    }
                }
            }
        }
        refreshFooterBlock = { [weak self] in
            guard let self = self else { return }
            guard let section = self.section else { return }
            let indexPath = IndexPath(item: 0, section: section)
            DispatchQueue.main.async {
                guard let collectionView = self.collectionView else { return }
                UIView.performWithoutAnimation {
                    if let footer = collectionView.supplementaryView(forElementKind: ATCollectionElementKind.sectionFooter, at: indexPath) as? ATListReuseableView {
                        footer.refreshSubviews(isFromVM: true)
                        footer.layoutIfNeeded()
                    }
                }
            }
        }
    }
    open func setupData() {
        
    }
    open func createLayout() {
        
    }
}

extension ATListSectionVM {
    /// 在 itemVMs 的 index 处插入一行并增量刷新：已有 cell 不重建、不重新量高。
    /// 索引会夹到 `0...itemVMs.count`。
    ///
    /// 数据变更与 `insertItems` 必须在同一轮 runloop 内完成：中间夹一次 layout，
    /// UIKit 的旧行数会被顶成新行数，`insertItems` 会因数量对不上而崩溃。
    /// 因此本方法是同步的，不像 `reloadSectionBlock` 那样派发到下一轮。
    ///
    /// - Warning: 只能在主线程、稳定的时机调用。不要在 `willDisplay` / `cellForItemAt`
    ///   这类 UICollectionView 回调里，或另一个批量更新内部调用——会重入批量更新并崩溃。
    ///   `ATListItemVM.willDisplay()` 是分页钩子，从那里调用本方法就属于这种情况。
    /// - Warning: 列表尚未上屏时只改数据、不动 UI；数据源与 UI 行数错位时，
    ///   Release 下会立即整表 `reloadData` 自愈，Debug 下会断言 trap。
    public func insert(_ itemVM: ATListItemVM, at index: Int) {
        let target = min(max(index, 0), itemVMs.count)
        let countBefore = itemVMs.count
        itemVMs.insert(itemVM, at: target)
        // 「列表还没上屏」是正常情况（例如先把数据备好、页面还没显示）：只保留数据变更。
        // 这条路径**不能**断言，否则 Debug 构建里正常用法会直接 trap。
        guard let collectionView = self.collectionView, let section = self.section else { return }
        // 走到这里说明已经挂上了列表，但数据源与 UI 的行数对不上（真异常）。
        guard section < collectionView.numberOfSections, collectionView.numberOfItems(inSection: section) == countBefore else {
            // 数据已经改掉了，UI 不会跟着变；这里整表 reloadData 自愈。
            assertionFailure("ATListSectionVM.insert 数据源与列表行数不一致：只改了数据")
            // Release 下别把 UI 留在错位状态，整表重载自愈
            collectionView.reloadData()
            return
        }
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: [IndexPath(item: target, section: section)])
            }
            collectionView.layoutIfNeeded()
        }
        renumberIndexPaths(from: target, section: section, collectionView: collectionView)
    }

    /// 追加到末尾。
    public func append(_ itemVM: ATListItemVM) {
        insert(itemVM, at: itemVMs.count)
    }

    /// 插入点之后的行位置都变了，把已经显示过的 item / cell 的 indexPath 一起改过来，
    /// 否则 `refreshItemBlock` / `reloadItemBlock` 会按旧位置刷到别人身上。
    private func renumberIndexPaths(from start: Int, section: Int, collectionView: UICollectionView) {
        guard start < itemVMs.count else { return }
        for i in start..<itemVMs.count {
            // 没有 indexPath 说明这行从没上过屏，不要给它伪造一个。
            guard itemVMs[i].indexPath != nil else { continue }
            itemVMs[i].indexPath = IndexPath(item: i, section: section)
        }
        for visible in collectionView.indexPathsForVisibleItems where visible.section == section && visible.item >= start {
            (collectionView.cellForItem(at: visible) as? ATListCell)?.syncIndexPath(visible)
        }
    }
}
