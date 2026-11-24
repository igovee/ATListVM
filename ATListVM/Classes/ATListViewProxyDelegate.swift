//
//  ATListViewProxyDelegate.swift
//  ATListVM
//

import UIKit

public protocol ATListViewProxyDelegate: AnyObject {
    func listViewProxy(collectionView: UICollectionView, cell:UICollectionViewCell, indexPath:IndexPath)
    func listViewProxy(collectionView: UICollectionView, cellWillDisplay:UICollectionViewCell, indexPath:IndexPath)
    func listViewProxy(collectionView: UICollectionView, cellDidEndDisplaying:UICollectionViewCell, indexPath:IndexPath)
    func listViewProxy(collectionView: UICollectionView, header:UICollectionReusableView, kind:String, indexPath:IndexPath)
    func listViewProxy(collectionView: UICollectionView, footer:UICollectionReusableView, kind:String, indexPath:IndexPath)
}

extension ATListViewProxyDelegate {
    public func listViewProxy(collectionView: UICollectionView, cell:UICollectionViewCell, indexPath:IndexPath) {}
    public func listViewProxy(collectionView: UICollectionView, cellWillDisplay:UICollectionViewCell, indexPath:IndexPath) {}
    public func listViewProxy(collectionView: UICollectionView, cellDidEndDisplaying:UICollectionViewCell, indexPath:IndexPath) {}
    public func listViewProxy(collectionView: UICollectionView, header:UICollectionReusableView, kind:String, indexPath:IndexPath) {}
    public func listViewProxy(collectionView: UICollectionView, footer:UICollectionReusableView, kind:String, indexPath:IndexPath) {}
}
