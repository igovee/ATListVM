//
//  ATListVM.swift
//  ATMVVMDemo
//
//  Created by abiaoyo on 2025/3/11.
//

import UIKit

public enum ATListVMState {
    case idl
    case add
    case delete
    case update
    case query
    case success
    case failure
    case error
    case empty
    case noNet
    case noData
    case load
    case custom(Int)
}

public protocol ATListVMDelegate: AnyObject {
    func listVMDidChange(state:ATListVMState, tag:Int, msg:String?, err:Error?)
}

open class ATListVM: NSObject {
    
    public private(set) var viewProxy: ATListViewProxyBase
    fileprivate weak var collecitonView:UICollectionView?
    
    public weak var delegate:ATListVMDelegate?
    
    public override init() {
        self.viewProxy = ATListViewProxy()
        super.init()
        setupData()
    }
    
    public init(viewProxy: ATListViewProxyBase) {
        self.viewProxy = viewProxy
        super.init()
        setupData()
    }
    
    open func setupData() {
        
    }
    
    open func createData() {
        
    }
    
    open func reloadData() {
        DispatchQueue.main.async {
            self.collecitonView?.reloadData()
        }
    }
    
    open func register(collectionView: UICollectionView) {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        self.collecitonView = collectionView
    }
    
}

extension ATListVM: ATListVMDelegate {
    public func listVMDidChange(state: ATListVMState, tag: Int, msg: String?, err: (any Error)?) {
        delegate?.listVMDidChange(state: state, tag: tag, msg: msg, err: err)
    }
}

extension UICollectionView {
    public func config(listVM: ATListVM) {
        listVM.register(collectionView: self)
    }
    
    public func config(viewProxy: ATListViewProxyBase) {
        delegate = viewProxy
        dataSource = viewProxy
        viewProxy.attach(collectionView: self)
        register(ATListReuseableView.self, forSupplementaryViewOfKind: ATCollectionElementKind.sectionHeader, withReuseIdentifier: "ATListReuseableView")
        register(ATListReuseableView.self, forSupplementaryViewOfKind: ATCollectionElementKind.sectionFooter, withReuseIdentifier: "ATListReuseableView")
    }
}
