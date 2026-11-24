//
//  ATListViewProxy.swift
//  ATListVM
//
//  Created by abiaoyo on 2025/3/11.
//

import UIKit

/// 默认 Proxy：手动计算高度，`sizeForItemAt` 直接返回 `itemVM.itemSize`。
open class ATListViewProxy: ATListViewProxyBase {

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        getItemVM(indexPath: indexPath)?.itemSize ?? .zero
    }
}
