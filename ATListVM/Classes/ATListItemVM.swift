//
//  ATListItemVM.swift
//  ATListVM
//

import UIKit

open class ATListItemVM {
    
    public typealias ReloadBlock = (() -> Void)
    public typealias RefreshBlock = (() -> Void)
    public typealias SelectItemBlock = ((_ collectionView:UICollectionView, _ indexPath:IndexPath, _ itemVM: ATListItemVM) -> Void)
    
    public fileprivate(set) var reloadListBlock:ReloadBlock?
    public fileprivate(set) var reloadSectionBlock:ReloadBlock?
    public fileprivate(set) var reloadItemBlock:ReloadBlock?
    public fileprivate(set) var refreshItemBlock:RefreshBlock?
    public var onSelectItemBlock:SelectItemBlock?
    
    public internal(set) weak var collectionView: UICollectionView?
    public internal(set) var indexPath: IndexPath?
    
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
            guard let self = self else { return }
            let section = self.indexPath?.section ?? 0
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadSections(IndexSet(integer: section))
                }
            }
        }
        reloadItemBlock = { [weak self] in
            guard let self = self else { return }
            guard let indexPath = self.indexPath else { return }
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
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
