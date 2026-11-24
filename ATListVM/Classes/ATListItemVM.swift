//
//  ATListItemVM.swift
//  ATListVM
//

import UIKit

open class ATListItemVM {
    
    public typealias ReloadBlock = (() -> Void)
    public typealias RefreshBlock = (() -> Void)
    public typealias SelectItemBlock = ((_ collectionView:UICollectionView, _ indexPath:IndexPath, _ itemVM: ATListItemVM) -> Void)
    
    public internal(set) var reloadListBlock:ReloadBlock?
    public internal(set) var reloadSectionBlock:ReloadBlock?
    public internal(set) var reloadItemBlock:ReloadBlock?
    public internal(set) var refreshItemBlock:RefreshBlock?
    public var onSelectItemBlock:SelectItemBlock?
    
    public internal(set) weak var collectionView: UICollectionView?
    public internal(set) var indexPath: IndexPath?
    
    /// 这个 item 是否**至少上过一次屏**（`indexPath != nil`）。
    /// 为 false 时 `refreshItemBlock` / `reloadItemBlock` 都是 no-op。
    /// 注意：为 true 也不代表此刻一定生效——滚出屏幕后 block 同样会 no-op，
    /// 因为刷新走的是 `cellForItem(at:)`，只对可见 cell 有效。
    public var isReadyForItemRefresh: Bool { indexPath != nil }

    public var cellId:String = "UICollectionViewCell"
    public var itemSize:CGSize = .zero
    public var data:Any?
    
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
            guard let self = self, let section = self.indexPath?.section else { return }
            DispatchQueue.main.async {
                // 这一段可能已经被删掉了；越界 reloadSections 会抛 UIKit 异常
                guard let collectionView = self.collectionView,
                      section < collectionView.numberOfSections else { return }
                UIView.performWithoutAnimation {
                    collectionView.reloadSections(IndexSet(integer: section))
                }
            }
        }
        reloadItemBlock = { [weak self] in
            guard let self = self else { return }
            guard let indexPath = self.indexPath else { return }
            DispatchQueue.main.async {
                // 行可能已经被删掉了；越界 reloadItems 会抛 UIKit 异常
                guard let collectionView = self.collectionView,
                      indexPath.section < collectionView.numberOfSections,
                      indexPath.item < collectionView.numberOfItems(inSection: indexPath.section) else { return }
                UIView.performWithoutAnimation {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
        // 只刷新可见 cell，不会 invalidate layout。内容变化导致高度变化时请走 reloadItemBlock。
        refreshItemBlock = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let collectionView = self.collectionView, let indexPath = self.indexPath else { return }
                UIView.performWithoutAnimation {
                    if let cell = collectionView.cellForItem(at: indexPath) as? ATListCell {
                        cell.refreshSubviews(isFromVM: true)
                        cell.layoutIfNeeded()
                    }
                }
            }
        }
    }
    open func setupData() {
        
    }
    open func createLayout() {
        
    }
    open func willDisplay() {
        
    }
    open func didEndDisplaying() {
        
    }
}
