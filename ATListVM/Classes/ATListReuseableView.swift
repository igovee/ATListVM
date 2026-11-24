//
//  ATListReuseableView.swift
//  ATListVM
//

import UIKit

open class ATListReuseableView: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupData()
        setupSubviews()
        setupLayout()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setupData() {}
    open func setupSubviews() {}
    open func setupLayout() {}
    
    public private(set) var sectionVM: ATListSectionVM?
    public private(set) var indexPath:IndexPath?
    
    final func config(sectionVM: ATListSectionVM, indexPath:IndexPath) {
        self.indexPath = indexPath
        configAndRefresh(sectionVM: sectionVM)
    }
    private func configAndRefresh(sectionVM: ATListSectionVM) {
        self.sectionVM = sectionVM
        refreshSubviews(isFromVM: false)
        layoutIfNeeded()
    }
    open func refreshSubviews(isFromVM:Bool) {
        
    }

    /// 表头 / 表尾进入屏幕时调用，由 `ATListViewProxy` 转发 `collectionView(_:willDisplaySupplementaryView:...)`。
    open func willDisplay() {

    }

    /// 表头 / 表尾离开屏幕时调用。
    open func didEndDisplaying() {

    }
}
